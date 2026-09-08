import { Injectable, Logger } from '@nestjs/common';
import { RepoIndexReason, RepoIndexState } from '@prisma/client';
import { PrismaService } from '../../prisma/prisma.service';

/** 한 번 잡으면 이만큼 내 것이다. 지나면 다른 인스턴스가 가져간다 = 크래시 복구. */
const LEASE_MS = 10 * 60 * 1000;

/** 429 · 네트워크 실패로 미룰 때의 기본 대기. `Retry-After` 가 있으면 그것을 쓴다. */
const BACKOFF_MS = 60 * 1000;

/** 서버 오류를 몇 번까지 다시 해 보나. 네트워크 실패는 여기 세지 않는다. */
export const MAX_ATTEMPTS = 3;

export interface LeasedJob {
  repoId: string;
  spaceId: string;
  reason: RepoIndexReason;
  headSha: string | null;
  baseSha: string | null;
  attempts: number;
}

/**
 * 인덱싱 작업 큐.
 *
 * **저장소마다 한 행**이라 합침이 구조다 — push 가 열 번 와도 인덱싱은 한 번
 * 이고, 목표 커밋만 최신으로 덮인다 (설계 §2).
 */
@Injectable()
export class IndexQueueService {
  private readonly logger = new Logger(IndexQueueService.name);

  constructor(private readonly prisma: PrismaService) {}

  /**
   * 작업을 넣는다. 이미 있으면 목표만 갱신한다.
   *
   * **돌고 있는 중이면 `state` 를 건드리지 않는다.** 워커가 리스를 쥐고 있는
   * 작업을 `queued` 로 되돌리면 같은 저장소를 둘이 돌게 된다. 대신 `headSha`
   * 만 바뀌고, 워커가 끝낼 때 그것이 달라진 것을 보고 다시 `queued` 로 둔다.
   */
  async enqueue(input: {
    spaceId: string;
    repoId: string;
    reason: RepoIndexReason;
    headSha: string | null;
    baseSha: string | null;
  }): Promise<void> {
    const { spaceId, repoId, reason, headSha, baseSha } = input;

    await this.prisma.repoIndexJob.upsert({
      where: { repoId },
      create: {
        repoId,
        spaceId,
        reason,
        headSha,
        baseSha,
        state: RepoIndexState.queued,
      },
      update: {
        reason,
        headSha,
        baseSha,
        // running 은 그대로 둔다(위 주석). 그 밖에는 다시 줄을 세운다.
        state: RepoIndexState.queued,
        attempts: 0,
        lastError: null,
        truncated: false,
        finishedAt: null,
      },
    });
  }

  /**
   * 하나를 잡는다. 없으면 `null`.
   *
   * **`FOR UPDATE SKIP LOCKED`** 라 인스턴스가 여럿이어도 같은 작업을 둘이
   * 잡지 않는다. Redis 없이 다중 인스턴스 안전성을 확보하는 지점이다 (설계 §0).
   *
   * **리스가 만료된 `running` 도 잡는다** — 프로세스가 죽으면 리스만 만료되고
   * 작업은 살아 있다.
   *
   * **트랜잭션을 작업 내내 붙들지 않는다.** 리스를 쓰고 곧바로 커밋한다.
   */
  async lease(): Promise<LeasedJob | null> {
    return this.prisma.$transaction(async (tx) => {
      const picked = await tx.$queryRaw<Array<{ repo_id: string }>>`
        SELECT repo_id FROM repo_index_jobs
         WHERE state IN ('queued', 'running')
           AND (lease_until IS NULL OR lease_until < now())
         ORDER BY created_at
         LIMIT 1
         FOR UPDATE SKIP LOCKED
      `;
      const repoId = picked[0]?.repo_id;
      if (!repoId) return null;

      const job = await tx.repoIndexJob.update({
        where: { repoId },
        data: {
          state: RepoIndexState.running,
          leaseUntil: new Date(Date.now() + LEASE_MS),
          startedAt: new Date(),
        },
        select: {
          repoId: true,
          spaceId: true,
          reason: true,
          headSha: true,
          baseSha: true,
          attempts: true,
        },
      });
      return job;
    });
  }

  /** 파일 배치마다 부른다. 오래 걸리는 작업이 리스를 잃고 중복으로 돌지 않게 한다. */
  async renew(repoId: string): Promise<void> {
    await this.prisma.repoIndexJob.updateMany({
      where: { repoId, state: RepoIndexState.running },
      data: { leaseUntil: new Date(Date.now() + LEASE_MS) },
    });
  }

  /**
   * 끝났다.
   *
   * **`headSha` 가 그사이 바뀌었으면 `done` 이 아니라 `queued` 다** — 돌고 있는
   * 중에 push 가 들어온 경우다. 추가 컬럼 없이 이것이 처리된다 (설계 §2).
   */
  async succeed(repoId: string, indexedSha: string, truncated: boolean): Promise<void> {
    await this.prisma.$transaction(async (tx) => {
      const job = await tx.repoIndexJob.findUnique({
        where: { repoId },
        select: { headSha: true },
      });
      const stale = job !== null && job.headSha !== indexedSha;

      await tx.repoIndexJob.update({
        where: { repoId },
        data: {
          state: stale ? RepoIndexState.queued : RepoIndexState.done,
          leaseUntil: null,
          attempts: 0,
          lastError: null,
          truncated,
          finishedAt: stale ? null : new Date(),
        },
      });

      // 저장소 전체의 기준은 여기 하나다. 청크의 commit_sha 는 "그 청크의
      // 내용을 뜬 시점"이라 파일마다 다를 수 있다 (설계 §4).
      await tx.repo.update({
        where: { id: repoId },
        data: { indexedAt: new Date(), indexedCommitSha: indexedSha },
      });
    });

    this.logger.log(`인덱싱 완료: repo=${repoId} sha=${indexedSha}`);
  }

  /**
   * 실패했다.
   *
   * **네트워크 실패는 시도 횟수로 치지 않는다**(6-2 전송 큐와 같은 규칙).
   * 오프라인은 오류가 아니다 — 429 도 "잠시 뒤 다시"라는 뜻이지 우리 잘못이 아니다.
   */
  async fail(
    repoId: string,
    message: string,
    options: { countsAsAttempt: boolean; retryAfterSec?: number },
  ): Promise<void> {
    const job = await this.prisma.repoIndexJob.findUnique({
      where: { repoId },
      select: { attempts: true },
    });
    if (!job) return;

    const attempts = options.countsAsAttempt ? job.attempts + 1 : job.attempts;
    const giveUp = options.countsAsAttempt && attempts >= MAX_ATTEMPTS;

    const wait = options.retryAfterSec ? options.retryAfterSec * 1000 : BACKOFF_MS;

    await this.prisma.repoIndexJob.update({
      where: { repoId },
      data: {
        state: giveUp ? RepoIndexState.failed : RepoIndexState.queued,
        attempts,
        lastError: message,
        // 포기하지 않았으면 곧바로 다시 잡히지 않게 미룬다. `lease` 가
        // `lease_until < now()` 를 보므로 이 값이 곧 대기다.
        leaseUntil: giveUp ? null : new Date(Date.now() + wait),
        finishedAt: giveUp ? new Date() : null,
      },
    });

    this.logger.warn(`인덱싱 실패: repo=${repoId} (${attempts}회) ${message}`);
  }
}
