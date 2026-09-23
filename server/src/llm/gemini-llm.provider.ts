import { Logger } from '@nestjs/common';
import { LlmConfig } from './llm.config';
import {
  LlmHttpError,
  LlmMessage,
  LlmOptions,
  LlmProvider,
  LlmResult,
} from './llm.provider';

const DEFAULT_BASE = 'https://generativelanguage.googleapis.com/v1beta';

/**
 * **생각 수준은 `low` 로 고정한다** (2026-09-23 실측).
 *
 * Gemini 3.x Flash 는 생각을 끌 수 없고(`minimal` 이 가장 낮다) 생각 토큰도
 * `maxOutputTokens` 안에서 쓴다. 기본값 `medium` 으로 코드 질문을 돌리자 생각에만
 * 1,850~2,645 토큰을 써, 옛 상한 2048 에서는 답이 몇 줄에서 끊겼다.
 *
 * | 수준 | 생각 토큰 | 코드 질문 답 |
 * |---|---|---|
 * | `minimal` | 0 | 원인은 맞지만 버그가 나는 순간을 뭉뚱그림 |
 * | **`low`** | 0~1,923 | **버그가 나는 창을 한 단계씩 정확히 짚음** |
 * | `medium`(기본) | 1,850~2,645 | `low` 와 비슷, 더 느림 |
 *
 * `low` 는 `gemini-3.1-flash-lite` · `3.5-flash-lite` · `3.5-flash` ·
 * `3-flash-preview` 가 모두 받았다 — `LLM_MODEL` 을 되돌려도 400 이 나지 않는다.
 * 모르는 값은 400(`INVALID_ARGUMENT ... thinking_level`)이다.
 */
const THINKING_LEVEL = 'low';

/** 헤더가 없거나 숫자가 아니면 undefined. 0 을 지어내지 않는다. */
function retryAfterOf(res: { headers: { get(name: string): string | null } }) {
  const raw = res.headers.get('retry-after');
  if (!raw || !/^\d+$/.test(raw.trim())) return undefined;
  return Number(raw.trim());
}

/**
 * Gemini 생성. **기본 provider 다** (설계 §0) — Phase 1 배포 대상에 GPU 가 없다.
 *
 * `system` 역할을 `systemInstruction` 으로 옮긴다 — 이 API 는 `contents` 에
 * system 을 받지 않는다. **어댑터 밖으로 새지 않는 번역이다.**
 *
 * 경로·필드 모양은 ai.google.dev/api/generate-content 와
 * ai.google.dev/gemini-api/docs/api-key 로 확인했다(2026-09-20):
 * - 엔드포인트는 `POST {base}/models/{model}:generateContent`
 * - `systemInstruction.parts[].text` · `usageMetadata.promptTokenCount` ·
 *   `usageMetadata.candidatesTokenCount` · `modelVersion` 그대로 맞다
 * - API 키는 쿼리 파라미터 예시가 문서 대부분이지만, `x-goog-api-key` 헤더도
 *   문서가 직접 예로 든다 — `gemini-embedding.provider.ts` 와 같은 이유로
 *   헤더를 쓴다(URL 에 실으면 액세스 로그에 남는다).
 */
export class GeminiLlmProvider implements LlmProvider {
  private readonly logger = new Logger(GeminiLlmProvider.name);

  constructor(private readonly config: LlmConfig) {}

  get modelId(): string {
    return `gemini:${this.config.model}`;
  }

  get maxTokens(): number {
    return this.config.maxTokens;
  }


  /**
   * 시간 제한을 건 `fetch`. **넘으면 504 로 던진다** — 전환 모델이 5xx 로 받고,
   * 전환이 없으면 큐가 5xx 처럼 다시 건다(`classifyFailure`). 네트워크 실패
   * (`TypeError`)는 그대로 둔다 — 그쪽은 「오프라인은 오류가 아니다」 갈래다.
   */
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
        this.logger.warn(`Gemini LLM 시간 초과: ${this.config.model}`);
        throw new LlmHttpError(
          `Gemini 가 ${Math.round((timeoutMs ?? 0) / 1000)}초 안에 답하지 않았습니다.`,
          504,
        );
      }
      throw err;
    }
  }
  async complete(
    messages: LlmMessage[],
    options: LlmOptions,
  ): Promise<LlmResult> {
    const base = this.config.base ?? DEFAULT_BASE;
    const system = messages.filter((m) => m.role === 'system');
    // 메시지마다 content 하나 — 합치면 멀티턴의 차례가 사라진다(13-3).
    const turns = messages.filter((m) => m.role !== 'system');

    const res = await this.post(
      `${base}/models/${this.config.model}:generateContent`,
      {
        method: 'POST',
        headers: {
          'content-type': 'application/json',
          // 키를 URL 에 넣지 않는다 — 액세스 로그에 남는다.
          'x-goog-api-key': this.config.apiKey ?? '',
        },
        body: JSON.stringify({
          ...(system.length > 0
            ? { systemInstruction: { parts: system.map((m) => ({ text: m.content })) } }
            : {}),
          contents: turns.map((m) => ({
            role: m.role === 'assistant' ? 'model' : 'user',
            parts: [{ text: m.content }],
          })),
          generationConfig: {
            temperature: options.temperature,
            maxOutputTokens: options.maxTokens,
            thinkingConfig: { thinkingLevel: THINKING_LEVEL },
            ...(options.json ? { responseMimeType: 'application/json' } : {}),
          },
        }),
      },
    );

    if (!res.ok) {
      this.logger.warn(`Gemini LLM 호출 실패: ${res.status}`);
      throw new LlmHttpError(
        `Gemini 가 ${res.status} 를 주었습니다.`,
        res.status,
        retryAfterOf(res),
      );
    }

    const body = (await res.json()) as {
      candidates?: Array<{
        content?: { parts?: Array<{ text?: string }> };
        finishReason?: string;
      }>;
      usageMetadata?: { promptTokenCount?: number; candidatesTokenCount?: number };
      modelVersion?: string;
    };

    const text =
      body.candidates?.[0]?.content?.parts?.map((p) => p.text ?? '').join('') ?? '';

    return {
      text,
      promptTokens: body.usageMetadata?.promptTokenCount ?? null,
      completionTokens: body.usageMetadata?.candidatesTokenCount ?? null,
      model: body.modelVersion ?? this.config.model,
      truncated: body.candidates?.[0]?.finishReason === 'MAX_TOKENS',
      fallback: false,
    };
  }
}
