import { FallbackLlmProvider } from './fallback-llm.provider';
import { LlmHttpError, LlmProvider, LlmResult } from './llm.provider';

function result(model: string): LlmResult {
  return {
    text: `${model} 의 답`,
    promptTokens: 1,
    completionTokens: 1,
    model,
    truncated: false,
    fallback: false,
  };
}

function provider(modelId: string, complete: jest.Mock): LlmProvider {
  return { modelId, maxTokens: 8192, complete };
}

const messages = [{ role: 'user' as const, content: '질문' }];
const options = { maxTokens: 8192, temperature: 0 };

describe('FallbackLlmProvider', () => {
  it('주 모델이 답하면 전환하지 않는다', async () => {
    const primary = jest.fn().mockResolvedValue(result('gemini-3.5-flash'));
    const fallback = jest.fn();
    const llm = new FallbackLlmProvider(
      provider('gemini:gemini-3.5-flash', primary),
      provider('gemini:gemini-3.1-flash-lite', fallback),
    );

    const r = await llm.complete(messages, options);

    expect(r).toEqual(result('gemini-3.5-flash'));
    expect(fallback).not.toHaveBeenCalled();
  });

  it.each([429, 500, 503])(
    '★ 주 모델이 %i 이면 전환 모델로 답하고 fallback 을 표시한다',
    async (status) => {
      const primary = jest.fn().mockRejectedValue(new LlmHttpError('x', status));
      const fallback = jest.fn().mockResolvedValue(result('gemini-3.1-flash-lite'));
      const llm = new FallbackLlmProvider(
        provider('gemini:gemini-3.5-flash', primary),
        provider('gemini:gemini-3.1-flash-lite', fallback),
      );

      const r = await llm.complete(messages, options);

      expect(fallback).toHaveBeenCalledWith(messages, options);
      expect(r.model).toBe('gemini-3.1-flash-lite');
      expect(r.fallback).toBe(true);
    },
  );

  it.each([400, 401, 404])(
    '%i 은 전환하지 않고 던진다 — 요청이 잘못된 것이라 다른 모델도 같다',
    async (status) => {
      const primary = jest.fn().mockRejectedValue(new LlmHttpError('x', status));
      const fallback = jest.fn();
      const llm = new FallbackLlmProvider(
        provider('gemini:gemini-3.5-flash', primary),
        provider('gemini:gemini-3.1-flash-lite', fallback),
      );

      await expect(llm.complete(messages, options)).rejects.toMatchObject({ status });
      expect(fallback).not.toHaveBeenCalled();
    },
  );

  it('네트워크 실패는 전환하지 않는다 — 같은 호스트라 전환 모델도 닿지 않는다', async () => {
    const primary = jest.fn().mockRejectedValue(new TypeError('fetch failed'));
    const fallback = jest.fn();
    const llm = new FallbackLlmProvider(
      provider('gemini:gemini-3.5-flash', primary),
      provider('gemini:gemini-3.1-flash-lite', fallback),
    );

    await expect(llm.complete(messages, options)).rejects.toBeInstanceOf(TypeError);
    expect(fallback).not.toHaveBeenCalled();
  });

  it('전환 모델도 실패하면 그 오류를 던진다 — 큐가 상태로 재시도를 판정한다', async () => {
    const primary = jest.fn().mockRejectedValue(new LlmHttpError('x', 429));
    const fallback = jest.fn().mockRejectedValue(new LlmHttpError('y', 503, 30));
    const llm = new FallbackLlmProvider(
      provider('gemini:gemini-3.5-flash', primary),
      provider('gemini:gemini-3.1-flash-lite', fallback),
    );

    await expect(llm.complete(messages, options)).rejects.toMatchObject({
      status: 503,
      retryAfterSec: 30,
    });
  });

  it('★ modelId · maxTokens 는 주 모델의 것이다 — promptHash 가 전환 여부로 흔들리지 않는다', () => {
    const llm = new FallbackLlmProvider(
      provider('gemini:gemini-3.5-flash', jest.fn()),
      provider('gemini:gemini-3.1-flash-lite', jest.fn()),
    );
    expect(llm.modelId).toBe('gemini:gemini-3.5-flash');
    expect(llm.maxTokens).toBe(8192);
  });
});
