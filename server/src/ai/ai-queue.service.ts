import { Injectable, Logger } from '@nestjs/common';
import { AiRunKind, AiRunState, Prisma } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';

/**
 * **raw SQL 에서 `now()` 를 쓰지 않는다.** 이 테이블의 시각 컬럼은
 * `timestamp without time zone` 인데 Prisma 는 거기에 UTC 를 쓰고 `now()` 는
 * DB 로컬(이 PC 는 `Asia/Seoul`)을 준다. 12단계에서 이것 때문에 리스가 한
 * 번도 동작하지 않았다. `check:sql-time` 이 CI 에서 잡는다.
 */
const UTC_NOW = Prisma.sql`(now() at time zone 'utc')`;

/**
 * **인덱싱의 10분이 아니라 3분이다.** LLM 한 번이 그보다 오래 걸리면 뭔가
 * 잘못된 것이다 (설계 §2).
 */
const LEASE_MS = 3 * 60 * 1000;

/** 네트워크 실패·429 로 미룰 때의 기본 대기. `Retry-After` 가 있으면 그것을 쓴다. */
const BACKOFF_MS = 60 * 1000;

/**
 * 5xx 를 다시 걸 때의 대기 단위. 시도마다 늘린다(5초 · 10초).
 *
 * **인덱싱처럼 1분을 기다리지 않는다** — AI 는 사람이 패널 앞에서 답을
 * 기다린다. 13-2 실제 태우기에서 `gemini-3.1-flash-lite` 가 새벽에 503 을
 * 자주 주었고, 1분 간격이면 한 번의 503 이 답을 60~110초로 늘렸다. 503 은
 * 대개 몇 초 안에 풀리는 과부하다.
 */
const SERVER_ERROR_BACKOFF_MS = 5 * 1000;

/**
 * 서버 오류를 몇 번까지 다시 해 보나. 네트워크 실패는 여기 세지 않는다.
 *
 * **3 이 아니라 5 다.** 대기를 몇 초로 줄이면서(`SERVER_ERROR_BACKOFF_MS`)
 * 세 번이 30초 안에 다 타 버렸다 — 13-2 실제 태우기에서 503 이 몰린 순간
 * 요청 여덟 중 셋이 그렇게 실패했다. 다섯 번이면 최악이 100초 안팎이고,
 * 대개는 한두 번 만에 풀린다.
 */
export const AI_MAX_ATTEMPTS = 5;

export interface LeasedRun {
  id: string;
  spaceId: string;
  userId: string;
  kind: AiRunKind;
  input: Prisma.JsonValue;
  attempts: number;
}

export interface AiFailOptions {
  countsAsAttempt: boolean;
  retryAfterSec?: number;
  fatal?: boolean;
}

/**
 * 포기할지 판정한다. **export 하는 이유는 단위 테스트가 실 DB 없이 이것만
 * 보기 위함이다** — 큐의 나머지는 계약 검증이 덮는다.
 */
export function shouldGiveUp(attempts: number, options: AiFailOptions): boolean {
  if (options.fatal === true) return true;
  return options.countsAsAttempt && attempts >= AI_MAX_ATTEMPTS;
}

/**
 * 다시 걸기까지 얼마나 기다리나. `Retry-After` 가 있으면 그것(0 도 살린다 —
 * `!= null` 로 본다, 12단계), 5xx 는 몇 초, 그 밖(네트워크 · 헤더 없는 429)은
 * 1분이다 — 오프라인에서 서버를 두드리지 않는다.
 */
export function retryDelayMs(attempts: number, options: AiFailOptions): number {
  if (options.retryAfterSec != null) return options.retryAfterSec * 1000;
  if (options.countsAsAttempt) return SERVER_ERROR_BACKOFF_MS * Math.max(1, attempts);
  return BACKOFF_MS;
}

/**
 * AI 실행 큐. **`ai_runs` 가 곧 큐다** — `state` enum 이 이미 있어 새 테이블을
 * 만들지 않았다 (설계 §2).
 *
 * **인덱싱 큐와 달리 합치지 않는다.** 저장소는 한 행이라 합침이 구조였지만,
 * AI 는 요청마다 한 행이고 합치면 사용자가 두 번 물은 것이 한 번이 된다.
 * 같은 요청의 재실행은 합침이 아니라 `promptHash` 캐시가 맡는다 (설계 §4).
 */
@Injectable()
export class AiQueueService {
  private readonly logger = new Logger(AiQueueService.name);

  constructor(private readonly prisma: PrismaService) {}

  /** 언제나 INSERT 다. `runId` 를 돌려준다. */
  async enqueue(input: {
    spaceId: string;
    userId: string;
    kind: AiRunKind;
    input: object;
    promptHash: string;
  }): Promise<string> {
    const run = await this.prisma.aiRun.create({
      data: {
        spaceId: input.spaceId,
        userId: input.userId,
        kind: input.kind,
        state: AiRunState.queued,
        promptHash: input.promptHash,
        input: input.input as Prisma.InputJsonValue,
      },
      select: { id: true },
    });
    return run.id;
  }

  /**
   * 하나를 잡는다. 없으면 `null`.
   *
   * **`FOR UPDATE SKIP LOCKED`** 라 인스턴스가 여럿이어도 같은 작업을 둘이
   * 잡지 않는다. Redis 없이 다중 인스턴스 안전성을 확보하는 지점이다.
   *
   * **리스가 만료된 `running` 도 잡는다** — 프로세스가 죽으면 리스만 만료되고
   * 작업은 살아 있다.
   *
   * **트랜잭션을 작업 내내 붙들지 않는다.** 리스를 쓰고 곧바로 커밋한다.
   */
  async lease(): Promise<LeasedRun | null> {
    return this.prisma.$transaction(async (tx) => {
      const picked = await tx.$queryRaw<Array<{ id: string }>>`
        SELECT id FROM ai_runs
         WHERE state IN ('queued', 'running')
           AND (lease_until IS NULL OR lease_until < ${UTC_NOW})
         ORDER BY created_at
         LIMIT 1
         FOR UPDATE SKIP LOCKED
      `;
      const id = picked[0]?.id;
      if (!id) return null;

      return tx.aiRun.update({
        where: { id },
        data: {
          state: AiRunState.running,
          leaseUntil: new Date(Date.now() + LEASE_MS),
          startedAt: new Date(),
        },
        select: {
          id: true,
          spaceId: true,
          userId: true,
          kind: true,
          input: true,
          attempts: true,
        },
      });
    });
  }

  /** 끝났다. 인덱싱과 달리 「그사이 바뀌었나」 판정이 없다 — 입력이 고정이다. */
  async succeed(
    runId: string,
    result: object,
    meta: {
      model: string;
      promptTokens: number | null;
      completionTokens: number | null;
      /** 전환 모델이 답했는지 — 캐시가 이 행을 쓰지 않는다. */
      fallback: boolean;
    },
  ): Promise<void> {
    await this.prisma.aiRun.update({
      where: { id: runId },
      data: {
        state: AiRunState.done,
        result: result as Prisma.InputJsonValue,
        model: meta.model,
        promptTokens: meta.promptTokens,
        completionTokens: meta.completionTokens,
        fallback: meta.fallback,
        leaseUntil: null,
        error: null,
        finishedAt: new Date(),
      },
    });
  }

  /**
   * 실패했다.
   *
   * **네트워크 실패는 시도 횟수로 치지 않는다**(12단계 · 6-2 전송 큐와 같은
   * 규칙). 오프라인은 오류가 아니고, 429 도 "잠시 뒤 다시"라는 뜻이다.
   *
   * **다시 걸기까지의 대기(ms)를 돌려준다** — 포기했거나 행이 없으면 `null`.
   * 워커가 이 값으로 깨우기를 예약한다. 없으면 대기가 몇 초여도 다음 30초
   * 크론까지 아무도 이 행을 다시 잡지 않는다.
   */
  async fail(
    runId: string,
    message: string,
    options: AiFailOptions,
  ): Promise<number | null> {
    const run = await this.prisma.aiRun.findUnique({
      where: { id: runId },
      select: { attempts: true },
    });
    if (!run) return null;

    const attempts = options.countsAsAttempt ? run.attempts + 1 : run.attempts;
    const giveUp = shouldGiveUp(attempts, options);
    const wait = retryDelayMs(attempts, options);

    await this.prisma.aiRun.update({
      where: { id: runId },
      data: {
        state: giveUp ? AiRunState.failed : AiRunState.queued,
        attempts,
        error: message,
        // 포기하지 않았으면 곧바로 다시 잡히지 않게 미룬다. `lease` 가
        // `lease_until < UTC_NOW` 를 보므로 이 값이 곧 대기다.
        leaseUntil: giveUp ? null : new Date(Date.now() + wait),
        finishedAt: giveUp ? new Date() : null,
      },
    });

    this.logger.warn(`AI 실행 실패: run=${runId} (${attempts}회) ${message}`);
    return giveUp ? null : wait;
  }
}
