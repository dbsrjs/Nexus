import { Logger } from '@nestjs/common';
import { LlmConfig } from './llm.config';
import {
  LlmHttpError,
  LlmMessage,
  LlmOptions,
  LlmProvider,
  LlmResult,
} from './llm.provider';

const DEFAULT_BASE = 'http://127.0.0.1:11434';

/** 헤더가 없거나 숫자가 아니면 undefined. 0 을 지어내지 않는다. */
function retryAfterOf(res: { headers: { get(name: string): string | null } }) {
  const raw = res.headers.get('retry-after');
  if (!raw || !/^\d+$/.test(raw.trim())) return undefined;
  return Number(raw.trim());
}

/**
 * Ollama 로컬 생성. **배포 대안이 아니라 개발 도구다** (설계 §0) — 무료 티어
 * 한도에 걸리지 않고 프롬프트를 다듬을 때 쓴다. Phase 1 배포 대상(ARM · GPU
 * 없음)에서는 쓸 수 없다.
 */
export class LocalLlmProvider implements LlmProvider {
  private readonly logger = new Logger(LocalLlmProvider.name);

  constructor(private readonly config: LlmConfig) {}

  get modelId(): string {
    return `local:${this.config.model}`;
  }

  get maxTokens(): number {
    return this.config.maxTokens;
  }

  async complete(
    messages: LlmMessage[],
    options: LlmOptions,
  ): Promise<LlmResult> {
    const base = this.config.base ?? DEFAULT_BASE;

    const res = await fetch(`${base}/api/chat`, {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify({
        model: this.config.model,
        messages,
        stream: false,
        ...(options.json ? { format: 'json' } : {}),
        options: {
          temperature: options.temperature,
          num_predict: options.maxTokens,
        },
      }),
    });

    if (!res.ok) {
      this.logger.warn(`로컬 LLM 호출 실패: ${res.status}`);
      throw new LlmHttpError(
        `로컬 LLM 이 ${res.status} 를 주었습니다.`,
        res.status,
        retryAfterOf(res),
      );
    }

    const body = (await res.json()) as {
      message?: { content?: string };
      model?: string;
      prompt_eval_count?: number;
      eval_count?: number;
      /** `stop` · `length`(num_predict 에서 멈춤) 등. 옛 Ollama 는 주지 않는다. */
      done_reason?: string;
    };

    return {
      text: body.message?.content ?? '',
      promptTokens: body.prompt_eval_count ?? null,
      completionTokens: body.eval_count ?? null,
      model: body.model ?? this.config.model,
      truncated: body.done_reason === 'length',
    };
  }
}
