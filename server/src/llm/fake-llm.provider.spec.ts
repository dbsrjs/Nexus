import { FakeLlmProvider } from './fake-llm.provider';

describe('FakeLlmProvider', () => {
  const provider = new FakeLlmProvider();
  const opts = { maxTokens: 1024, temperature: 0 };

  it('같은 입력에 같은 출력을 준다 — 캐시 검증이 이것에 기댄다', async () => {
    const msgs = [{ role: 'user' as const, content: '안녕' }];
    const a = await provider.complete(msgs, opts);
    const b = await provider.complete(msgs, opts);
    expect(a.text).toBe(b.text);
  });

  it('입력이 다르면 출력도 다르다 — 캐시가 잘못 맞는 것을 잡는다', async () => {
    const a = await provider.complete([{ role: 'user', content: 'ㄱ' }], opts);
    const b = await provider.complete([{ role: 'user', content: 'ㄴ' }], opts);
    expect(a.text).not.toBe(b.text);
  });

  it('modelId 가 fake:fake 다', () => {
    expect(provider.modelId).toBe('fake:fake');
  });

  it('json 옵션이면 파싱 가능한 JSON 을 준다', async () => {
    const r = await provider.complete([{ role: 'user', content: 'x' }], {
      ...opts,
      json: true,
    });
    expect(() => JSON.parse(r.text)).not.toThrow();
  });

  it('토큰 수를 센 척하지 않는다 — null 이다', async () => {
    const r = await provider.complete([{ role: 'user', content: 'x' }], opts);
    expect(r.promptTokens).toBeNull();
    expect(r.completionTokens).toBeNull();
  });
});
