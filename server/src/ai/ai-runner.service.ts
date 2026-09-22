import { Inject, Injectable, Logger } from '@nestjs/common';
import { AiRunKind } from '@prisma/client';
import { LLM_PROVIDER, LlmHttpError, LlmProvider } from '../llm/llm.provider';
import { RealtimeEmitter } from '../realtime/realtime-emitter';
import { AiFailOptions, AiQueueService, LeasedRun } from './ai-queue.service';
import { AiService } from './ai.service';
import { Citation } from './code-context';
import { parseIssueDraft } from './prompts/issue';

/** 요약 · 이슈 초안 · 자유 질문 모두 자료에 근거한 답이라 흔들 이유가 없다. */
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

  /**
   * 하나를 돈다. **재시도로 미뤘으면 그 대기(ms)를, 아니면 `null` 을 돌려준다**
   * — 워커가 그 시점에 다시 깨운다(`AiWorker`).
   */
  async runOne(run: LeasedRun): Promise<number | null> {
    if (!this.llm) {
      // 설정이 도중에 사라질 수는 없지만, 큐에 남은 것을 영원히 돌리지 않는다.
      await this.queue.fail(run.id, 'AI 가 설정되지 않았습니다', {
        countsAsAttempt: true,
        fatal: true,
      });
      this.notify(run, 'failed');
      return null;
    }

    try {
      const prompt = await this.ai.loadPrompt(run.spaceId, run.input);
      // **하드코딩 상수를 쓰지 않는다** — `this.llm.maxTokens` 는
      // `LLM_MAX_TOKENS`(`llm.config.ts`)에서 온 값이다. 러너가 자기
      // 상수를 넘기면 그 설정이 아무 일도 하지 않는다(최종 whole-branch
      // 리뷰 Important ②).
      const out = await this.llm.complete(prompt.messages, {
        maxTokens: this.llm.maxTokens,
        temperature: TEMPERATURE,
        json: prompt.json,
      });

      // **빈 응답을 성공으로 굳히지 않는다.** Gemini 가 `finishReason:
      // SAFETY` 로 막으면 candidates[0].content.parts 가 아예 없어
      // text 가 빈 문자열로 온다(gemini-llm.provider.ts). 그대로
      // succeed() 하면 그 행이 곧 캐시라(설계 §4) 같은 구간을 다시
      // 요약해도 영원히 빈 결과가 나온다 — 판단 #4(조용히 버리지 않는다)
      // 위반이다. 같은 프롬프트에 같은 차단이 다시 올 것이므로 재시도로
      // 낫지 않는다 — `classifyFailure` 의 기본 분기(그 밖의 오류는
      // fatal)에 맡긴다(최종 whole-branch 리뷰 Important ③).
      if (out.text.trim().length === 0) {
        throw new Error('LLM 이 빈 응답을 주었습니다.');
      }

      await this.queue.succeed(run.id, resultOf(prompt.kind, out.text, prompt.citations), {
        model: out.model,
        promptTokens: out.promptTokens,
        completionTokens: out.completionTokens,
      });
      this.notify(run, 'done');
      return null;
    } catch (err) {
      const options = classifyFailure(err);
      const message = err instanceof Error ? err.message : String(err);
      const retryIn = await this.queue.fail(run.id, message, options);

      // **포기했을 때만 알린다.** 재시도로 넘어간 것은 아직 실패가 아니고,
      // 알리면 화면이 실패를 보였다가 되살아난다.
      if (options.fatal === true || options.countsAsAttempt) {
        const stillQueued = !(await this.isFailed(run.id));
        if (!stillQueued) this.notify(run, 'failed');
      }
      return retryIn;
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

/**
 * `kind` 마다 결과 모양이 다르다 (13-2 설계 §5). **이슈 초안을 못 읽으면
 * 던진다** — `classifyFailure` 가 fatal 로 친다. 인용은 셋 모두에 싣는다
 * (저장소가 없으면 빈 배열).
 */
export function resultOf(kind: AiRunKind, text: string, citations: Citation[]): object {
  if (kind === AiRunKind.draft_issue) return { ...parseIssueDraft(text), citations };
  return { markdown: text, citations };
}
