import { FakeLlmProvider } from './fake-llm.provider';
import { LlmHttpError } from './llm.provider';

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

  describe('실패 주입 지시문 — 계약 검증이 큐의 실패 갈래를 태운다', () => {
    const ask = (p: FakeLlmProvider, content: string) =>
      p.complete([{ role: 'user', content }], opts);

    it('status=503;times=2 면 두 번 503 을 던지고 세 번째에 성공한다', async () => {
      const p = new FakeLlmProvider();
      const content = '요약 [[fake-llm:status=503;times=2]]';
      for (let i = 0; i < 2; i++) {
        await expect(ask(p, content)).rejects.toMatchObject({ status: 503 });
      }
      await expect(ask(p, content)).resolves.toMatchObject({ truncated: false });
    });

    it('times 가 없으면 매번 던진다', async () => {
      const p = new FakeLlmProvider();
      for (let i = 0; i < 7; i++) {
        await expect(ask(p, '[[fake-llm:status=503]]')).rejects.toBeInstanceOf(
          LlmHttpError,
        );
      }
    });

    it('★ retry-after 는 0 도 살려 싣는다 - 0 을 없음으로 읽으면 1분을 기다린다', async () => {
      const p = new FakeLlmProvider();
      await expect(ask(p, '[[fake-llm:status=429;retry-after=0]]')).rejects.toMatchObject(
        {
          status: 429,
          retryAfterSec: 0,
        },
      );
    });

    it('횟수는 프롬프트마다 따로 센다', async () => {
      const p = new FakeLlmProvider();
      await expect(ask(p, 'ㄱ [[fake-llm:status=503;times=1]]')).rejects.toBeDefined();
      await expect(ask(p, 'ㄴ [[fake-llm:status=503;times=1]]')).rejects.toBeDefined();
      await expect(ask(p, 'ㄱ [[fake-llm:status=503;times=1]]')).resolves.toBeDefined();
    });

    it('empty 는 빈 답, truncated 는 잘린 답을 준다 - 러너가 둘 다 실패로 돌린다', async () => {
      const p = new FakeLlmProvider();
      await expect(ask(p, '[[fake-llm:empty]]')).resolves.toMatchObject({ text: '' });
      await expect(ask(p, '[[fake-llm:truncated]]')).resolves.toMatchObject({
        truncated: true,
      });
    });

    it('모르는 지시는 던진다 - 오타가 성공으로 보이면 검증이 거짓으로 통과한다', async () => {
      const p = new FakeLlmProvider();
      await expect(ask(p, '[[fake-llm:stauts=503]]')).rejects.toThrow(/fake-llm/);
    });

    it('지시문이 없으면 그대로 성공한다', async () => {
      await expect(ask(new FakeLlmProvider(), '평범한 요청')).resolves.toMatchObject({
        truncated: false,
      });
    });
  });
});
