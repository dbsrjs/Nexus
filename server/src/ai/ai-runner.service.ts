import { Inject, Injectable, Logger } from '@nestjs/common';
import { AiRunKind } from '@prisma/client';
import { LLM_PROVIDER, LlmHttpError, LlmProvider } from '../llm/llm.provider';
import { RealtimeEmitter } from '../realtime/realtime-emitter';
import { AiFailOptions, AiQueueService, LeasedRun } from './ai-queue.service';
import { AiService } from './ai.service';

/** 요약은 사실을 뽑는 일이라 흔들 이유가 없다. */
const TEMPERATURE = 0.2;

/**
 * 실패를 재시도 판정으로 바꾼다 (설계 §5).
 *
 * **네트워크 실패와 429 는 시도로 세지 않는다** — 우리 잘못이 아니다.
 * **4xx 는 fatal** — 다시 걸어도 같은 프롬프트에 같은 거절이 온다.
 *
 * `retryAfterSec` 을 `!= null` 로 보는 이유: `x ? … : …` 는 **0 을 거짓으로**
 * 본다. 12단계에서 `retryAfter: 0` 이 통째로 무시되는 것을 겪었다.
 */
export function classifyFailure(err: unknown): AiFailOptions {
  if (err instanceof LlmHttpError) {
    if (err.status === 429) {
      return err.retryAfterSec != null
        ? { countsAsAttempt: false, retryAfterSec: err.retryAfterSec }
        : { countsAsAttempt: false };
    }
    if (err.status >= 500) return { countsAsAttempt: true };
    return { countsAsAttempt: true, fatal: true };
  }
  // fetch 가 못 닿으면 TypeError 다. 오프라인은 오류가 아니다.
  if (err instanceof TypeError) return { countsAsAttempt: false };
  return { countsAsAttempt: true, fatal: true };
}

@Injectable()
export class AiRunnerService {
  private readonly logger = new Logger(AiRunnerService.name);

  constructor(
    @Inject(LLM_PROVIDER) private readonly llm: LlmProvider | null,
    private readonly queue: AiQueueService,
    private readonly ai: AiService,
    private readonly realtime: RealtimeEmitter,
  ) {}

  async runOne(run: LeasedRun): Promise<void> {
    if (!this.llm) {
      // 설정이 도중에 사라질 수는 없지만, 큐에 남은 것을 영원히 돌리지 않는다.
      await this.queue.fail(run.id, 'AI 가 설정되지 않았습니다', {
        countsAsAttempt: true,
        fatal: true,
      });
      this.notify(run, 'failed');
      return;
    }

    try {
      const prompt = await this.ai.loadPrompt(run.spaceId, run.kind, run.input);
      // **하드코딩 상수를 쓰지 않는다** — `this.llm.maxTokens` 는
      // `LLM_MAX_TOKENS`(`llm.config.ts`)에서 온 값이다. 러너가 자기
      // 상수를 넘기면 그 설정이 아무 일도 하지 않는다(최종 whole-branch
      // 리뷰 Important ②).
      const out = await this.llm.complete(prompt, {
        maxTokens: this.llm.maxTokens,
        temperature: TEMPERATURE,
      });

      await this.queue.succeed(run.id, resultOf(run.kind, out.text), {
        model: out.model,
        promptTokens: out.promptTokens,
        completionTokens: out.completionTokens,
      });
      this.notify(run, 'done');
    } catch (err) {
      const options = classifyFailure(err);
      const message = err instanceof Error ? err.message : String(err);
      await this.queue.fail(run.id, message, options);

      // **포기했을 때만 알린다.** 재시도로 넘어간 것은 아직 실패가 아니고,
      // 알리면 화면이 실패를 보였다가 되살아난다.
      if (options.fatal === true || options.countsAsAttempt) {
        const stillQueued = !(await this.isFailed(run.id));
        if (!stillQueued) this.notify(run, 'failed');
      }
    }
  }

  /** 결과가 실패로 굳었는지. `fail()` 이 재시도로 돌렸을 수 있다. */
  private async isFailed(runId: string): Promise<boolean> {
    const run = await this.ai.getRunState(runId);
    return run === 'failed';
  }

  /**
   * **요청자에게만** 보낸다. 결과 본문을 싣지 않는 이유는 설계 §10 —
   * 소켓을 놓친 경우와 받은 경우가 같은 코드 경로를 타게 한다.
   */
  private notify(run: LeasedRun, state: 'done' | 'failed'): void {
    this.realtime.toUser(run.userId, 'ai:run:done', {
      runId: run.id,
      kind: run.kind,
      state,
    });
  }
}

/** `kind` 마다 결과 모양이 다르다. 13-1 은 요약 하나다. */
function resultOf(kind: AiRunKind, text: string): object {
  if (kind === AiRunKind.summarize) return { markdown: text };
  throw new Error(`아직 지원하지 않는 종류입니다: ${kind}`);
}
