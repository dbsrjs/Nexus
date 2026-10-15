import { Logger } from '@nestjs/common';
import {
  LlmHttpError,
  LlmMessage,
  LlmOptions,
  LlmProvider,
  LlmResult,
  retryAfterOf,
} from './llm.provider';

const DEFAULT_BASE = 'https://api.anthropic.com/v1';
const API_VERSION = '2023-06-01';

/**
 * **생각 수준은 `low` 다** — Gemini 어댑터와 같은 값이다. Haiku 5.5 는 생각을
 * 기본으로 켜고 기본 수준이 `medium` 이며, 생각 토큰도 `max_tokens` 에서 쓴다.
 * 주 모델과 같은 상한(8192)에서 답이 잘리지 않게 낮춘다.
 */
const EFFORT = 'low';

export interface AnthropicLlmConfig {
  model: string;
  apiKey: string;
  maxTokens: number;
  timeoutMs: number | null;
  /** 시험용. 운영은 비워 공식 엔드포인트를 쓴다. */
  base?: string;
}

/**
 * Claude(Messages API). **지금은 전환 모델로만 쓴다**(2026-10-15) — 주 모델은
 * 여전히 gemini 다(`llm.config.ts`).
 *
 * **SDK(`@anthropic-ai/sdk`)를 들이지 않았다** — 판단 #8. 엔드포인트 하나에
 * 본문 모양 하나라 `gemini-llm.provider.ts` 처럼 `fetch` 로 충분하다. SDK 의
 * 자체 재시도(기본 2회)가 큐의 재시도 판정과 겹치지 않는 것도 이유다.
 *
 * 번역 — 어댑터 밖으로 새지 않는다:
 * - `system` 역할은 최상위 `system` 으로 옮긴다(`messages` 에 섞으면 연산자
 *   지시가 아니라 대화 중 지시로 읽힌다)
 * - **`temperature` 를 보내지 않는다** — Haiku 5.5 는 기본값이 아닌 값을 400 으로
 *   거절한다. 러너가 주는 `0.2` 를 그대로 보내면 전환이 늘 실패한다
 * - `json` 은 시스템 지시로 바꾼다. 구조화 출력(`output_config.format`)은
 *   스키마가 있어야 하는데 이 어댑터는 스키마를 모른다. 받는 쪽(`issue.ts`)이
 *   코드 울타리를 벗겨 파싱하고, 실패하면 fatal 이다
 */
export class AnthropicLlmProvider implements LlmProvider {
  private readonly logger = new Logger(AnthropicLlmProvider.name);

  constructor(private readonly config: AnthropicLlmConfig) {}

  get modelId(): string {
    return `anthropic:${this.config.model}`;
  }

  get maxTokens(): number {
    return this.config.maxTokens;
  }

  /** Gemini 어댑터와 같다 — 시간 초과는 504 로 던진다. */
  private async post(url: string, init: RequestInit): Promise<Response> {
    const timeoutMs = this.config.timeoutMs;
    try {
      return await fetch(url, {
        ...init,
        ...(timeoutMs !== null ? { signal: AbortSignal.timeout(timeoutMs) } : {}),
      });
    } catch (err) {
      const name = (err as { name?: unknown } | null)?.name;
      if (name === 'TimeoutError' || name === 'AbortError') {
        this.logger.warn(`Claude 시간 초과: ${this.config.model}`);
        throw new LlmHttpError(
          `Claude 가 ${Math.round((timeoutMs ?? 0) / 1000)}초 안에 답하지 않았습니다.`,
          504,
        );
      }
      throw err;
    }
  }

  async complete(messages: LlmMessage[], options: LlmOptions): Promise<LlmResult> {
    const base = this.config.base ?? DEFAULT_BASE;
    const system = messages.filter((m) => m.role === 'system').map((m) => m.content);
    if (options.json) {
      system.push(
        'JSON 객체 하나만 출력한다. 앞뒤에 설명 · 코드 울타리를 붙이지 않는다.',
      );
    }
    const turns = messages.filter((m) => m.role !== 'system');

    const res = await this.post(`${base}/messages`, {
      method: 'POST',
      headers: {
        'content-type': 'application/json',
        'x-api-key': this.config.apiKey,
        'anthropic-version': API_VERSION,
      },
      body: JSON.stringify({
        model: this.config.model,
        max_tokens: options.maxTokens,
        ...(system.length > 0 ? { system: system.join('\n\n') } : {}),
        messages: turns.map((m) => ({ role: m.role, content: m.content })),
        output_config: { effort: EFFORT },
      }),
    });

    if (!res.ok) {
      // 529(overloaded)도 5xx 라 큐 · 전환 판정에서 503 과 같게 다뤄진다.
      this.logger.warn(`Claude 호출 실패: ${res.status}`);
      throw new LlmHttpError(
        `Claude 가 ${res.status} 를 주었습니다.`,
        res.status,
        retryAfterOf(res),
      );
    }

    const body = (await res.json()) as {
      content?: Array<{ type?: string; text?: string }>;
      stop_reason?: string;
      usage?: { input_tokens?: number; output_tokens?: number };
      model?: string;
    };

    // **거절한 답을 굳히지 않는다.** 앞부분만 쓰다 멈춘 글이 캐시가 되면 같은
    // 질문마다 되풀이된다. 같은 프롬프트는 또 거절되니 재시도도 없다 — 러너의
    // 기본 분기(fatal)로 간다. Gemini 의 `SAFETY` 가 빈 답으로 가는 것과 같은 자리다.
    if (body.stop_reason === 'refusal') {
      throw new Error('Claude 가 답을 거절했습니다.');
    }

    // 생각 블록(`thinking`)은 표시가 기본으로 비어 있고, 답이 아니다.
    const text = (body.content ?? [])
      .filter((b) => b.type === 'text')
      .map((b) => b.text ?? '')
      .join('');

    return {
      text,
      promptTokens: body.usage?.input_tokens ?? null,
      completionTokens: body.usage?.output_tokens ?? null,
      model: body.model ?? this.config.model,
      truncated: body.stop_reason === 'max_tokens',
      fallback: false,
    };
  }
}
