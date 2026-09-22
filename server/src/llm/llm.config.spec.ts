import { ConfigService } from '@nestjs/config';
import { resolveLlm } from './llm.config';

/** `.env` 를 흉내 내는 최소 ConfigService. */
function cfg(values: Record<string, string>): ConfigService {
  return { get: (key: string) => values[key] } as unknown as ConfigService;
}

describe('resolveLlm', () => {
  it('LLM_PROVIDER 가 없으면 null 이다 — 서버는 뜨고 AI 만 꺼진다', () => {
    expect(resolveLlm(cfg({}))).toBeNull();
  });

  it('빈 문자열을 미설정으로 친다 — .env 에 자리만 잡아 둔 경우', () => {
    expect(resolveLlm(cfg({ LLM_PROVIDER: '   ' }))).toBeNull();
  });

  it('모르는 이름은 던져 부팅을 멈춘다 — 없는 것과 잘못된 것은 다르다', () => {
    expect(() => resolveLlm(cfg({ LLM_PROVIDER: 'openai' }))).toThrow(
      /gemini · local · fake/,
    );
  });

  it('gemini 인데 키가 없으면 null 이다 — 던지지 않는다', () => {
    expect(resolveLlm(cfg({ LLM_PROVIDER: 'gemini' }))).toBeNull();
  });

  it('gemini 는 키가 있으면 해석된다', () => {
    const r = resolveLlm(cfg({ LLM_PROVIDER: 'gemini', GEMINI_API_KEY: 'k' }));
    expect(r?.provider).toBe('gemini');
    expect(r?.apiKey).toBe('k');
  });

  it('local 은 키 없이 해석된다', () => {
    expect(resolveLlm(cfg({ LLM_PROVIDER: 'local' }))?.provider).toBe('local');
  });

  it('LLM_MAX_TOKENS 가 숫자가 아니면 기본값 2048 을 쓴다', () => {
    const r = resolveLlm(cfg({ LLM_PROVIDER: 'fake', LLM_MAX_TOKENS: 'many' }));
    expect(r?.maxTokens).toBe(2048);
  });

  it('LLM_MAX_TOKENS 가 0 이하면 기본값을 쓴다', () => {
    const r = resolveLlm(cfg({ LLM_PROVIDER: 'fake', LLM_MAX_TOKENS: '0' }));
    expect(r?.maxTokens).toBe(2048);
  });

  it('LLM_MODEL 을 주면 그대로 쓴다', () => {
    const r = resolveLlm(cfg({ LLM_PROVIDER: 'local', LLM_MODEL: 'my-model' }));
    expect(r?.model).toBe('my-model');
  });
});
