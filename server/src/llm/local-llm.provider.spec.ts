import { LocalLlmProvider } from './local-llm.provider';
import { LlmHttpError } from './llm.provider';

const config = {
  provider: 'local' as const,
  model: 'test-model',
  apiKey: null,
  base: 'http://127.0.0.1:9',
  maxTokens: 256,
};

describe('LocalLlmProvider', () => {
  afterEach(() => jest.restoreAllMocks());

  it('응답 본문에서 text 와 토큰 수를 꺼낸다', async () => {
    jest.spyOn(global, 'fetch').mockResolvedValue({
      ok: true,
      json: async () => ({
        message: { content: '요약입니다' },
        model: 'test-model',
        prompt_eval_count: 12,
        eval_count: 7,
      }),
    } as unknown as Response);

    const r = await new LocalLlmProvider(config).complete(
      [{ role: 'user', content: '안녕' }],
      { maxTokens: 256, temperature: 0 },
    );
    expect(r.text).toBe('요약입니다');
    expect(r.promptTokens).toBe(12);
    expect(r.completionTokens).toBe(7);
    expect(r.model).toBe('test-model');
  });

  it('토큰 수를 안 주면 null 이다 — 0 으로 지어내지 않는다', async () => {
    jest.spyOn(global, 'fetch').mockResolvedValue({
      ok: true,
      json: async () => ({ message: { content: 'x' } }),
    } as unknown as Response);

    const r = await new LocalLlmProvider(config).complete(
      [{ role: 'user', content: 'a' }],
      { maxTokens: 256, temperature: 0 },
    );
    expect(r.promptTokens).toBeNull();
    expect(r.completionTokens).toBeNull();
  });

  it('실패 상태는 LlmHttpError 로 던진다 — 큐가 상태로 재시도를 판정한다', async () => {
    jest.spyOn(global, 'fetch').mockResolvedValue({
      ok: false,
      status: 503,
      headers: { get: () => null },
    } as unknown as Response);

    await expect(
      new LocalLlmProvider(config).complete([{ role: 'user', content: 'a' }], {
        maxTokens: 256,
        temperature: 0,
      }),
    ).rejects.toBeInstanceOf(LlmHttpError);
  });

  it('Retry-After 헤더를 오류에 싣는다', async () => {
    jest.spyOn(global, 'fetch').mockResolvedValue({
      ok: false,
      status: 429,
      headers: { get: (k: string) => (k === 'retry-after' ? '12' : null) },
    } as unknown as Response);

    await expect(
      new LocalLlmProvider(config).complete([{ role: 'user', content: 'a' }], {
        maxTokens: 256,
        temperature: 0,
      }),
    ).rejects.toMatchObject({ status: 429, retryAfterSec: 12 });
  });
});
