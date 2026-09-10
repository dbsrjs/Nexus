import { Injectable, Logger } from '@nestjs/common';
import { Prisma, RepoIndexReason, RepoIndexState } from '@prisma/client';
import { PrismaService } from '../../prisma/prisma.service';

/**
 * **raw SQL 에서 `now()` 를 쓰지 않는다.**
 *
 * 이 테이블의 시각 컬럼은 `TIMESTAMP(3)` = `timestamp without time zone` 인데,
 * **Prisma 는 거기에 UTC 를 쓰고 `now()` 는 DB 의 로컬 시간을 준다.** 이 PC 의
 * Postgres 는 `Asia/Seoul` 이라 아홉 시간이 어긋나, `lease_until < now()` 가
 * **언제나 참**이 됐다 — 리스가 아무것도 막지 못했다.
 *
 * 그 결과가 둘이었다: ① 실패 뒤 `BACKOFF_MS` 만큼 물러서야 하는데 곧바로 다시
 * 잡혀 **초당 한 번씩 재시도하는 회전**이 됐고(429 를 주는 provider 에서 실제로
 * 겪었다), ② 돌고 있는 작업을 다른 인스턴스가 곧바로 가져갈 수 있었다.
 * 인스턴스가 하나일 때는 워커의 `running` 플래그가 ②를 가려 준다.
 *
 * **가짜 GitHub 은 전부 빨리 성공해 물러설 일이 없어** 계약 검증이 못 잡았다.
 */
const UTC_NOW = Prisma.sql`(now() at time zone 'utc')`;

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
   * **단일 raw SQL upsert 다.** `SELECT` 후 분기하거나 `updateMany` 를 상태별로
   * 둘로 나누면 그 사이에 워커가 상태를 바꿀 틈이 생긴다 — 특히 `running` 용
   * 문장과 그 밖의 문장으로 나누면, 두 문장 사이에 `lease()` 나 `succeed()` 가
   * 끼어들 때 **적재 자체가 통째로 사라지는 인터리브**가 있다. `ON CONFLICT`
   * 한 문장이면 그 틈이 없다.
   *
   * **`running` 이면 `state` · `attempts` · `lastError` · `truncated` ·
   * `finishedAt` · `leaseUntil` 을 그대로 두고 목표(`reason` · `headSha` ·
   * `baseSha`)만 갱신한다.** 워커가 리스를 쥐고 있는 작업을 `queued` 로
   * 되돌리면, `renew()` 는 `state: running` 인 행만 찾으므로 그 순간부터
   * 리스가 더 이상 연장되지 않는다 — 원래 리스가 만료되면 아직 살아서 돌고
   * 있는 저장소를 다른 워커가 다시 잡는다(같은 작업을 둘이 도는 사고, 설계
   * §2). `attempts` 를 건드리지 않는 것도 같은 이유다 — `fail()` 은 DB 에
   * 쌓인 값을 이어서 세므로, 여기서 0으로 되돌리면 push 가 잦은 저장소는
   * `MAX_ATTEMPTS` 를 영영 못 채워 실패가 조용히 사라진다.
   */
  async enqueue(input: {
    spaceId: string;
    repoId: string;
    reason: RepoIndexReason;
    headSha: string | null;
    baseSha: string | null;
  }): Promise<void> {
    const { spaceId, repoId, reason, headSha, baseSha } = input;

    await this.prisma.$executeRaw`
      INSERT INTO repo_index_jobs
        (repo_id, space_id, state, reason, head_sha, base_sha, created_at, updated_at)
      VALUES
        (${repoId}, ${spaceId}, 'queued'::"RepoIndexState", ${reason}::"RepoIndexReason", ${headSha}, ${baseSha}, ${UTC_NOW}, ${UTC_NOW})
      ON CONFLICT (repo_id) DO UPDATE SET
        reason = EXCLUDED.reason,
        head_sha = EXCLUDED.head_sha,
        base_sha = EXCLUDED.base_sha,
        updated_at = ${UTC_NOW},
        -- running 이면 그대로 둔다(위 JSDoc). 그 밖에는 다시 줄을 세운다.
        state = CASE WHEN repo_index_jobs.state = 'running'::"RepoIndexState"
                      THEN repo_index_jobs.state
                      ELSE 'queued'::"RepoIndexState"
                 END,
        attempts = CASE WHEN repo_index_jobs.state = 'running'::"RepoIndexState"
                         THEN repo_index_jobs.attempts
                         ELSE 0
                    END,
        last_error = CASE WHEN repo_index_jobs.state = 'running'::"RepoIndexState"
                           THEN repo_index_jobs.last_error
                           ELSE NULL
                      END,
        truncated = CASE WHEN repo_index_jobs.state = 'running'::"RepoIndexState"
                          THEN repo_index_jobs.truncated
                          ELSE false
                     END,
        finished_at = CASE WHEN repo_index_jobs.state = 'running'::"RepoIndexState"
                            THEN repo_index_jobs.finished_at
                            ELSE NULL
                       END
    `;
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
           AND (lease_until IS NULL OR lease_until < ${UTC_NOW})
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
    options: { countsAsAttempt: boolean; retryAfterSec?: number; fatal?: boolean },
  ): Promise<void> {
    const job = await this.prisma.repoIndexJob.findUnique({
      where: { repoId },
      select: { attempts: true },
    });
    if (!job) return;

    const attempts = options.countsAsAttempt ? job.attempts + 1 : job.attempts;
    // **다시 걸어도 같은 실패는 세 번을 기다리지 않는다** — 401(토큰 만료) ·
    // 404(저장소 사라짐)가 그렇다. 6-2 의 전송 큐가 같은 구분을 했다.
    const giveUp = options.fatal === true || (options.countsAsAttempt && attempts >= MAX_ATTEMPTS);

    const wait = options.retryAfterSec ? options.retryAfterSec * 1000 : BACKOFF_MS;

    await this.prisma.repoIndexJob.update({
      where: { repoId },
      data: {
        state: giveUp ? RepoIndexState.failed : RepoIndexState.queued,
        attempts,
        lastError: message,
        // 포기하지 않았으면 곧바로 다시 잡히지 않게 미룬다. `lease` 가
        // `lease_until < UTC_NOW` 를 보므로 이 값이 곧 대기다.
        leaseUntil: giveUp ? null : new Date(Date.now() + wait),
        finishedAt: giveUp ? new Date() : null,
      },
    });

    this.logger.warn(`인덱싱 실패: repo=${repoId} (${attempts}회) ${message}`);
  }
}
