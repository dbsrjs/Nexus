import { Logger } from '@nestjs/common';
import {
  LlmHttpError,
  LlmMessage,
  LlmOptions,
  LlmProvider,
  LlmResult,
} from './llm.provider';

/**
 * 주 모델이 **429(한도) · 5xx(혼잡)** 를 주면 전환 모델로 한 번 더 부른다
 * (LLM 교체, 2026-09-23).
 *
 * **재시도 대신 전환하는 이유** — 무료 티어는 실패한 호출도 하루 한도에서
 * 깎는다(AI Studio 에서 503 만 받은 모델의 RPD 가 올라가 있었다). 5xx 를
 * 큐가 5회 다시 걸면 하루 20회가 금방 녹는다. 전환 모델은 한도가 따로다.
 *
 * **전환하지 않는 것** — 4xx(429 제외)는 요청이 잘못된 것이라 다른 모델도
 * 같다. 네트워크 실패는 같은 호스트라 전환 모델도 닿지 않는다. 둘 다 그대로
 * 던져 큐의 판정(`classifyFailure`)에 맡긴다.
 *
 * `modelId` · `maxTokens` 는 **주 모델의 것이다** — `promptHash` 는 적재 시점에
 * 정해지므로 누가 답할지에 흔들리면 안 된다. 대신 결과에 `fallback: true` 를
 * 달아 캐시가 그 행을 쓰지 않게 한다.
 */
export class FallbackLlmProvider implements LlmProvider {
  private readonly logger = new Logger(FallbackLlmProvider.name);

  constructor(
    private readonly primary: LlmProvider,
    private readonly fallback: LlmProvider,
  ) {}

  get modelId(): string {
    return this.primary.modelId;
  }

  get maxTokens(): number {
    return this.primary.maxTokens;
  }

  async complete(messages: LlmMessage[], options: LlmOptions): Promise<LlmResult> {
    try {
      return await this.primary.complete(messages, options);
    } catch (err) {
      if (!(err instanceof LlmHttpError) || !shouldFallBack(err.status)) throw err;
      this.logger.warn(
        `${this.primary.modelId} 가 ${err.status} — ${this.fallback.modelId} 로 전환한다`,
      );
      const result = await this.fallback.complete(messages, options);
      return { ...result, fallback: true };
    }
  }
}

function shouldFallBack(status: number): boolean {
  return status === 429 || status >= 500;
}
