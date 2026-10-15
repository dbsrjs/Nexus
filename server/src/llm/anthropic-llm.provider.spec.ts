import { AnthropicLlmProvider } from './anthropic-llm.provider';
import { LlmHttpError } from './llm.provider';

const config = {
  model: 'claude-haiku-5-5',
  apiKey: 'a',
  maxTokens: 8192,
  timeoutMs: 60000,
  base: 'http://127.0.0.1:9',
};

function ok(body: unknown) {
  return jest.spyOn(global, 'fetch').mockResolvedValue({
    ok: true,
    json: async () => body,
  } as unknown as Response);
}

interface SentBody {
  model: string;
  max_tokens: number;
  system?: string;
  messages: Array<{ role: string; content: string }>;
  output_config: { effort: string };
  temperature?: unknown;
}

function sent(spy: jest.SpyInstance): { url: string; init: RequestInit; body: SentBody } {
  const [url, init] = spy.mock.calls[0] as [string, RequestInit];
  return { url, init, body: JSON.parse(init.body as string) as SentBody };
}

describe('AnthropicLlmProvider', () => {
  afterEach(() => jest.restoreAllMocks());

  it('modelId 는 anthropic:모델 이다', () => {
    expect(new AnthropicLlmProvider(config).modelId).toBe('anthropic:claude-haiku-5-5');
  });

  it('응답에서 text 블록만 모으고 토큰 수 · 모델을 꺼낸다', async () => {
    ok({
      content: [
        { type: 'thinking', thinking: '' },
        { type: 'text', text: '요약' },
        { type: 'text', text: '입니다' },
      ],
      stop_reason: 'end_turn',
      usage: { input_tokens: 12, output_tokens: 7 },
      model: 'claude-haiku-5-5',
    });

    const r = await new AnthropicLlmProvider(config).complete(
      [{ role: 'user', content: '안녕' }],
      { maxTokens: 8192, temperature: 0.2 },
    );
    expect(r).toEqual({
      text: '요약입니다',
      promptTokens: 12,
      completionTokens: 7,
      model: 'claude-haiku-5-5',
      truncated: false,
      fallback: false,
    });
  });

  it('★ 키 · 버전 헤더를 싣고 system 을 최상위로 옮긴다', async () => {
    const spy = ok({ content: [{ type: 'text', text: 'x' }], stop_reason: 'end_turn' });

    await new AnthropicLlmProvider(config).complete(
      [
        { role: 'system', content: '규칙' },
        { role: 'user', content: '질문' },
        { role: 'assistant', content: '앞 답' },
        { role: 'user', content: '이어서' },
      ],
      { maxTokens: 4096, temperature: 0.2 },
    );

    const { url, init, body } = sent(spy);
    expect(url).toBe('http://127.0.0.1:9/messages');
    const headers = init.headers as Record<string, string>;
    expect(headers['x-api-key']).toBe('a');
    expect(headers['anthropic-version']).toBe('2023-06-01');
    expect(body.model).toBe('claude-haiku-5-5');
    expect(body.max_tokens).toBe(4096);
    expect(body.system).toBe('규칙');
    // 멀티턴의 차례를 그대로 둔다.
    expect(body.messages).toEqual([
      { role: 'user', content: '질문' },
      { role: 'assistant', content: '앞 답' },
      { role: 'user', content: '이어서' },
    ]);
    expect(body.output_config).toEqual({ effort: 'low' });
  });

  it('★ temperature 를 보내지 않는다 - Haiku 5.5 는 기본값이 아니면 400 이다', async () => {
    const spy = ok({ content: [{ type: 'text', text: 'x' }], stop_reason: 'end_turn' });

    await new AnthropicLlmProvider(config).complete([{ role: 'user', content: 'a' }], {
      maxTokens: 8192,
      temperature: 0.2,
    });

    expect('temperature' in sent(spy).body).toBe(false);
  });

  it('json 이면 시스템 지시로 JSON 만 달라고 한다', async () => {
    const spy = ok({ content: [{ type: 'text', text: '{}' }], stop_reason: 'end_turn' });

    await new AnthropicLlmProvider(config).complete([{ role: 'user', content: 'a' }], {
      maxTokens: 8192,
      temperature: 0,
      json: true,
    });

    expect(sent(spy).body.system).toMatch(/JSON 객체 하나만/);
  });

  it('★ max_tokens 에서 멈췄으면 truncated 다', async () => {
    ok({ content: [{ type: 'text', text: '원인은' }], stop_reason: 'max_tokens' });

    const r = await new AnthropicLlmProvider(config).complete(
      [{ role: 'user', content: 'a' }],
      { maxTokens: 8192, temperature: 0 },
    );
    expect(r.truncated).toBe(true);
  });

  it('★ 거절(refusal)은 답으로 돌려주지 않고 던진다 - 캐시에 굳지 않게', async () => {
    ok({ content: [{ type: 'text', text: '앞부분' }], stop_reason: 'refusal' });

    await expect(
      new AnthropicLlmProvider(config).complete([{ role: 'user', content: 'a' }], {
        maxTokens: 8192,
        temperature: 0,
      }),
    ).rejects.toThrow(/거절/);
  });

  it.each([429, 529])(
    '★ %i 는 상태 코드와 Retry-After 를 실어 던진다',
    async (status) => {
      jest.spyOn(global, 'fetch').mockResolvedValue({
        ok: false,
        status,
        headers: { get: (k: string) => (k === 'retry-after' ? '7' : null) },
      } as unknown as Response);

      const err = await new AnthropicLlmProvider(config)
        .complete([{ role: 'user', content: 'a' }], { maxTokens: 8192, temperature: 0 })
        .catch((e: unknown) => e);
      expect(err).toBeInstanceOf(LlmHttpError);
      expect((err as LlmHttpError).status).toBe(status);
      expect((err as LlmHttpError).retryAfterSec).toBe(7);
    },
  );

  it('시간 초과는 504 로 던진다', async () => {
    jest
      .spyOn(global, 'fetch')
      .mockRejectedValue(Object.assign(new Error('t'), { name: 'TimeoutError' }));

    const err = await new AnthropicLlmProvider(config)
      .complete([{ role: 'user', content: 'a' }], { maxTokens: 8192, temperature: 0 })
      .catch((e: unknown) => e);
    expect((err as LlmHttpError).status).toBe(504);
  });
});
