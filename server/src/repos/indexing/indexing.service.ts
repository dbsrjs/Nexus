import {
  Inject,
  Injectable,
  Logger,
  NotFoundException,
  ServiceUnavailableException,
} from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { EmbeddingHttpError } from '../../embedding/gemini-embedding.provider';
import { GithubOauthClient, GithubTreeEntry } from '../../oauth/github-oauth.client';
import { OauthService } from '../../oauth/oauth.service';
import { resolveGithubOauth, type GithubOauthConfig } from '../../config/oauth.config';
import { ConfigService } from '@nestjs/config';
import { RepoIndexReason, RepoProvider } from '@prisma/client';
import { resolveBlobBody } from '../blob-content';
import {
  EMBEDDING_PROVIDER,
  EmbeddingProvider,
  assertDimensions,
} from '../../embedding/embedding.provider';
import { IndexChunksRepository } from './index-chunks.repository';
import { IndexQueueService, LeasedJob } from './index-queue.service';
import { chunkText } from './chunker';
import { isGenerated, isTooLarge, langOf } from './index-filter';

/** 동시에 몇 개의 blob 을 받나. 분당 900점 한도에 여유 있게 못 미친다 (설계 §3). */
const FETCH_CONCURRENCY = 4;

/** 이만큼 처리할 때마다 리스를 갱신한다. */
const RENEW_EVERY = 20;

/** GitHub 이 아니라 우리 쪽 사정으로 실패했다는 표시. */
class IndexingAbort extends Error {
  constructor(
    message: string,
    readonly countsAsAttempt: boolean,
    readonly retryAfterSec?: number,
  ) {
    super(message);
  }
}

/**
 * 저장소 하나를 인덱싱한다.
 *
 * **토큰은 저장소를 붙인 사람이 아니라 「지금 이 스페이스의 누군가」의 것을
 * 쓴다** — 등록자를 기록해 두면 그 사람이 연결을 해제한 순간 아무도 인덱싱할
 * 수 없게 된다(10-2b 가 훅 관리에서 한 판단과 같다).
 */
@Injectable()
export class IndexingService {
  private readonly logger = new Logger(IndexingService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly config: ConfigService,
    private readonly github: GithubOauthClient,
    private readonly oauth: OauthService,
    private readonly chunks: IndexChunksRepository,
    private readonly queue: IndexQueueService,
    @Inject(EMBEDDING_PROVIDER)
    private readonly embedder: EmbeddingProvider | null,
  ) {}

  /**
   * 인덱싱 상태.
   *
   * **한 번도 인덱싱하지 않았으면 `state: 'none'` 이다.** `null` 을 돌려
   * 「없음」과 「모름」을 헷갈리게 하지 않는다(10-3b · 11 의 규칙).
   */
  async status(spaceId: string, repoId: string) {
    const repo = await this.prisma.repo.findFirst({
      where: { id: repoId, spaceId },
      select: { indexedAt: true, indexedCommitSha: true },
    });
    // 403 이 아니라 404 다 — 403 은 그 저장소가 존재한다를 알려 준다.
    if (!repo) throw new NotFoundException('저장소를 찾을 수 없습니다');

    const job = await this.prisma.repoIndexJob.findUnique({ where: { repoId } });
    const chunkCount = await this.chunks.countFor(spaceId, repoId);

    return {
      state: job?.state ?? 'none',
      reason: job?.reason ?? null,
      indexedAt: repo.indexedAt,
      indexedCommitSha: repo.indexedCommitSha,
      chunkCount,
      truncated: job?.truncated ?? false,
      attempts: job?.attempts ?? 0,
      lastError: job?.lastError ?? null,
    };
  }

  /** 사람이 다시 태운다. **전체 재인덱싱**이다 — `baseSha` 를 비운다. */
  async requeue(spaceId: string, repoId: string) {
    const repo = await this.prisma.repo.findFirst({
      where: { id: repoId, spaceId },
      select: { id: true },
    });
    if (!repo) throw new NotFoundException('저장소를 찾을 수 없습니다');

    await this.queue.enqueue({
      spaceId,
      repoId,
      reason: RepoIndexReason.manual,
      headSha: null,
      baseSha: null,
    });
    // 깨우지 않는다. 서비스가 워커를 부르면 둘이 서로를 참조해 순환 의존이
    // 된다(IndexingWorker 가 이미 IndexingService 를 쓴다). 깨우는 것은
    // 컨트롤러의 일이다.
    return { state: 'queued' as const };
  }

  /**
   * 벡터 검색. **13단계 AI 가 그대로 쓸 자리다.**
   *
   * 질문을 임베딩하는 데도 인덱싱과 같은 provider 를 쓴다 — 다른 것으로
   * 임베딩한 벡터끼리는 거리가 뜻을 갖지 않는다.
   */
  async search(spaceId: string, repoId: string, query: string, topK: number) {
    const repo = await this.prisma.repo.findFirst({
      where: { id: repoId, spaceId },
      select: { id: true },
    });
    if (!repo) throw new NotFoundException('저장소를 찾을 수 없습니다');

    if (!this.embedder) {
      throw new ServiceUnavailableException(
        '임베딩이 설정되지 않아 검색할 수 없습니다.',
      );
    }

    const [vector] = await this.embedder.embed([query]);
    return { chunks: await this.chunks.search(spaceId, repoId, vector, topK) };
  }

  async runOne(job: LeasedJob): Promise<void> {
    try {
      await this.index(job);
    } catch (err) {
      if (err instanceof EmbeddingHttpError) {
        // provider 의 429 도 GitHub 의 것과 같게 다룬다 — 시도 횟수로 세지
        // 않고 미룬다. 우리 잘못이 아니라 "잠시 뒤 다시"라는 뜻이다.
        await this.queue.fail(job.repoId, err.message, {
          countsAsAttempt: err.status !== 429,
          retryAfterSec: err.retryAfterSec,
        });
        return;
      }
      if (err instanceof IndexingAbort) {
        await this.queue.fail(job.repoId, err.message, {
          countsAsAttempt: err.countsAsAttempt,
          retryAfterSec: err.retryAfterSec,
        });
        return;
      }
      // 우리 코드의 버그다. 시도 횟수로 세고 세 번이면 포기한다.
      this.logger.error(`인덱싱 중 예기치 못한 오류: repo=${job.repoId}`, err as Error);
      await this.queue.fail(job.repoId, (err as Error).message, { countsAsAttempt: true });
    }
  }

  private async index(job: LeasedJob): Promise<void> {
    if (!this.embedder) {
      // **부팅을 막지 않고 여기서 멈춘다.** 상태 조회가 이 문구를 그대로 말한다.
      throw new IndexingAbort(
        'EMBEDDING_PROVIDER 가 설정되지 않아 인덱싱할 수 없습니다.',
        false,
      );
    }

    const { repo, cfg, token } = await this.ready(job);

    // 목표 커밋. 연결로 깨어난 작업은 모르므로 여기서 정한다 (설계 §2).
    let headSha = job.headSha;
    if (!headSha) {
      if (!repo.defaultBranch) {
        throw new IndexingAbort('저장소의 default 브랜치를 알 수 없습니다.', true);
      }
      const res = await this.github.branchHead(cfg, token, repo.fullPath, repo.defaultBranch);
      if (!res.ok) throw this.abortFor(res.status, res.retryAfter, 'default 브랜치 조회');
      headSha = res.value;
      await this.prisma.repoIndexJob.update({
        where: { repoId: job.repoId },
        data: { headSha },
      });
    }

    const tree = await this.github.getTree(cfg, token, repo.fullPath, headSha);
    if (!tree.ok) throw this.abortFor(tree.status, tree.retryAfter, '트리 조회');

    // **전체 재인덱싱이다.** 증분은 12-3(Task 13·14)에서 이 자리에 붙는다.
    await this.chunks.deleteRepo(job.spaceId, job.repoId);

    const targets = tree.value.entries.filter((e) => !isTooLarge(e.size));
    this.logger.log(
      `인덱싱 시작: ${repo.fullPath}@${headSha.slice(0, 7)} ` +
        `대상 ${targets.length}/${tree.value.entries.length}`,
    );

    let done = 0;
    for (const batch of chunked(targets, FETCH_CONCURRENCY)) {
      // **`index()` 가 반환할 때 떠 있는 요청이 없어야 한다.** `Promise.all` 은
      // 먼저 실패한 것만 알려 주고 나머지를 취소하지 않아, 낙오된 쓰기가
      // 재시도의 `deleteRepo()` 뒤에 착지하면 옛 커밋의 청크가 남는다.
      // `allSettled` 로 배치 전체가 정착하기를 기다린 뒤에야 실패를 판단한다.
      const results = await Promise.allSettled(
        batch.map((entry) =>
          this.indexOneFile(job, cfg, token, repo.fullPath, entry, headSha as string),
        ),
      );
      const rejections = results.filter(
        (r): r is PromiseRejectedResult => r.status === 'rejected',
      );
      if (rejections.length > 0) {
        // 거부가 여럿이면 IndexingAbort 를 먼저 던진다 — 실패 종류(시도 횟수로
        // 셀지, Retry-After 가 얼마인지)를 담고 있어 runOne() 이 그 정보로
        // 큐를 다룬다. 없으면 첫 거부를 그대로 던진다. 다음 배치로 넘어가지
        // 않도록 배치 루프 안에서 던진다.
        const abort = rejections.find((r) => r.reason instanceof IndexingAbort);
        throw abort ? (abort.reason as IndexingAbort) : (rejections[0].reason as unknown);
      }
      done += batch.length;
      if (done % RENEW_EVERY < FETCH_CONCURRENCY) await this.queue.renew(job.repoId);
    }

    await this.queue.succeed(job.repoId, headSha, tree.value.truncated);
  }

  private async indexOneFile(
    job: LeasedJob,
    cfg: GithubOauthConfig,
    token: string,
    fullPath: string,
    entry: GithubTreeEntry,
    headSha: string,
  ): Promise<void> {
    const blob = await this.github.getBlob(cfg, token, fullPath, entry.sha);
    if (!blob.ok) throw this.abortFor(blob.status, blob.retryAfter, `blob ${entry.path}`);

    // 바이너리 판별을 새로 쓰지 않는다 — 열람이 쓰는 것과 같은 함수다.
    const body = resolveBlobBody(blob.value.contentBase64, blob.value.size);
    if (body.content === null) return;
    if (isGenerated(body.content)) return;

    const chunks = chunkText(body.content);
    if (chunks.length === 0) return;

    const vectors = await (this.embedder as EmbeddingProvider).embed(
      chunks.map((c) => c.content),
    );
    assertDimensions(vectors);

    await this.chunks.replaceFile({
      spaceId: job.spaceId,
      repoId: job.repoId,
      path: entry.path,
      lang: langOf(entry.path),
      commitSha: headSha,
      chunks,
      embeddings: vectors,
    });
  }

  /**
   * 저장소 · 설정 · 토큰.
   *
   * `RepoAccessService.ready()` 를 그대로 쓰지 못하는 이유는 **그쪽이 요청한
   * 사람의 userId 를 받기 때문이다.** 워커에는 요청한 사람이 없다 — 그 스페이스
   * 에서 GitHub 을 연결해 둔 아무나의 토큰을 쓴다.
   */
  private async ready(job: LeasedJob) {
    const repo = await this.prisma.repo.findFirst({
      where: { id: job.repoId, spaceId: job.spaceId, provider: RepoProvider.github },
      select: { fullPath: true, defaultBranch: true },
    });
    if (!repo) throw new IndexingAbort('저장소를 찾을 수 없습니다.', true);

    const cfg = resolveGithubOauth(this.config);
    if (!cfg) throw new IndexingAbort('GitHub 연결이 설정되지 않았습니다.', false);

    const members = await this.prisma.spaceMember.findMany({
      where: { spaceId: job.spaceId },
      select: { userId: true },
    });
    for (const member of members) {
      const token = await this.oauth.githubTokenFor(member.userId);
      if (token) return { repo, cfg, token };
    }

    // **시도 횟수로 세지 않는다.** 아무도 연결하지 않은 것은 우리 잘못이
    // 아니고, 누군가 연결하면 그대로 풀린다.
    throw new IndexingAbort(
      '이 스페이스에 GitHub 을 연결한 사람이 없습니다.',
      false,
    );
  }

  private abortFor(status: number, retryAfter: number | undefined, what: string): IndexingAbort {
    // 0 은 네트워크 자체가 실패한 것이다(클라이언트 규약).
    if (status === 0) return new IndexingAbort(`${what} 중 네트워크 실패`, false);
    if (status === 429) {
      return new IndexingAbort(`GitHub 요청 한도를 넘었습니다 (${what})`, false, retryAfter);
    }
    // 다시 걸어도 같다. 즉시 포기한다.
    if (status === 401) return new IndexingAbort('GitHub 연결이 만료되었습니다.', true, undefined);
    if (status === 404) return new IndexingAbort(`${what}: 찾을 수 없습니다.`, true);
    return new IndexingAbort(`${what}: GitHub 이 ${status} 를 주었습니다.`, true);
  }
}

/** 배열을 n개씩 자른다. */
function chunked<T>(items: T[], size: number): T[][] {
  const out: T[][] = [];
  for (let i = 0; i < items.length; i += size) out.push(items.slice(i, i + size));
  return out;
}
