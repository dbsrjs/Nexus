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

  async complete(
    messages: LlmMessage[],
    options: LlmOptions,
  ): Promise<LlmResult> {
    const base = this.config.base ?? DEFAULT_BASE;
    const system = messages.filter((m) => m.role === 'system');
    const user = messages.filter((m) => m.role === 'user');

    const res = await fetch(
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
          contents: [{ role: 'user', parts: user.map((m) => ({ text: m.content })) }],
          generationConfig: {
            temperature: options.temperature,
            maxOutputTokens: options.maxTokens,
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
      candidates?: Array<{ content?: { parts?: Array<{ text?: string }> } }>;
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
    };
  }
}
