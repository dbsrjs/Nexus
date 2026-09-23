import { GeminiLlmProvider } from './gemini-llm.provider';
import { LlmHttpError } from './llm.provider';

const config = {
  provider: 'gemini' as const,
  model: 'gemini-test',
  apiKey: 'k',
  base: 'http://127.0.0.1:9',
  maxTokens: 8192,
  fallbackModel: null,
};

function ok(body: unknown) {
  return jest.spyOn(global, 'fetch').mockResolvedValue({
    ok: true,
    json: async () => body,
  } as unknown as Response);
}

interface SentBody {
  systemInstruction?: unknown;
  contents?: unknown;
  generationConfig: Record<string, unknown>;
}

function sentBody(spy: jest.SpyInstance): SentBody {
  const init = spy.mock.calls[0][1] as RequestInit;
  return JSON.parse(init.body as string) as SentBody;
}

describe('GeminiLlmProvider', () => {
  afterEach(() => jest.restoreAllMocks());

  it('응답 본문에서 text · 토큰 수 · 모델을 꺼낸다', async () => {
    ok({
      candidates: [{ content: { parts: [{ text: '요약' }, { text: '입니다' }] }, finishReason: 'STOP' }],
      usageMetadata: { promptTokenCount: 12, candidatesTokenCount: 7 },
      modelVersion: 'gemini-test-001',
    });

    const r = await new GeminiLlmProvider(config).complete(
      [{ role: 'user', content: '안녕' }],
      { maxTokens: 8192, temperature: 0 },
    );
    expect(r).toEqual({
      text: '요약입니다',
      promptTokens: 12,
      completionTokens: 7,
      model: 'gemini-test-001',
      truncated: false,
      fallback: false,
    });
  });

  it('★ 출력 한도에서 멈췄으면 truncated 다 - 러너가 잘린 답을 캐시에 굳히지 않는다', async () => {
    ok({
      candidates: [{ content: { parts: [{ text: '원인은 두 가지' }] }, finishReason: 'MAX_TOKENS' }],
    });

    const r = await new GeminiLlmProvider(config).complete(
      [{ role: 'user', content: 'a' }],
      { maxTokens: 8192, temperature: 0 },
    );
    expect(r.truncated).toBe(true);
  });

  it('★ 생각 수준을 low 로 보낸다 - 생각 토큰이 출력 한도를 나눠 쓰기 때문이다', async () => {
    const spy = ok({ candidates: [{ content: { parts: [{ text: 'x' }] }, finishReason: 'STOP' }] });

    await new GeminiLlmProvider(config).complete([{ role: 'user', content: 'a' }], {
      maxTokens: 8192,
      temperature: 0.2,
    });

    const body = sentBody(spy);
    expect(body.generationConfig).toEqual({
      temperature: 0.2,
      maxOutputTokens: 8192,
      thinkingConfig: { thinkingLevel: 'low' },
    });
  });

  it('★ assistant 는 model 로, 메시지마다 content 하나로 옮긴다 - 멀티턴 순서를 지킨다', async () => {
    const spy = ok({ candidates: [{ content: { parts: [{ text: 'x' }] }, finishReason: 'STOP' }] });

    await new GeminiLlmProvider(config).complete(
      [
        { role: 'system', content: '규칙' },
        { role: 'user', content: '첫 질문' },
        { role: 'assistant', content: '첫 답' },
        { role: 'user', content: '이어서' },
      ],
      { maxTokens: 8192, temperature: 0 },
    );

    expect(sentBody(spy).contents).toEqual([
      { role: 'user', parts: [{ text: '첫 질문' }] },
      { role: 'model', parts: [{ text: '첫 답' }] },
      { role: 'user', parts: [{ text: '이어서' }] },
    ]);
  });

  it('system 은 systemInstruction 으로, json 은 responseMimeType 으로 옮긴다', async () => {
    const spy = ok({ candidates: [{ content: { parts: [{ text: '{}' }] }, finishReason: 'STOP' }] });

    await new GeminiLlmProvider(config).complete(
      [
        { role: 'system', content: '규칙' },
        { role: 'user', content: '질문' },
      ],
      { maxTokens: 8192, temperature: 0, json: true },
    );

    const body = sentBody(spy);
    expect(body.systemInstruction).toEqual({ parts: [{ text: '규칙' }] });
    expect(body.contents).toEqual([{ role: 'user', parts: [{ text: '질문' }] }]);
    expect(body.generationConfig.responseMimeType).toBe('application/json');
  });

  it('실패 상태는 Retry-After 와 함께 LlmHttpError 로 던진다', async () => {
    jest.spyOn(global, 'fetch').mockResolvedValue({
      ok: false,
      status: 429,
      headers: { get: (k: string) => (k === 'retry-after' ? '30' : null) },
    } as unknown as Response);

    const p = new GeminiLlmProvider(config).complete([{ role: 'user', content: 'a' }], {
      maxTokens: 8192,
      temperature: 0,
    });
    await expect(p).rejects.toBeInstanceOf(LlmHttpError);
    await expect(p).rejects.toMatchObject({ status: 429, retryAfterSec: 30 });
  });
});
