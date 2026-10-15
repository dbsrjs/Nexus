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

  it('LLM_MAX_TOKENS 가 숫자가 아니면 기본값 8192 를 쓴다', () => {
    const r = resolveLlm(cfg({ LLM_PROVIDER: 'fake', LLM_MAX_TOKENS: 'many' }));
    expect(r?.maxTokens).toBe(8192);
  });

  it('LLM_MAX_TOKENS 가 0 이하면 기본값을 쓴다', () => {
    const r = resolveLlm(cfg({ LLM_PROVIDER: 'fake', LLM_MAX_TOKENS: '0' }));
    expect(r?.maxTokens).toBe(8192);
  });

  it('gemini 의 기본 모델은 gemini-3.5-flash 다(2026-09-23 재측정)', () => {
    const r = resolveLlm(cfg({ LLM_PROVIDER: 'gemini', GEMINI_API_KEY: 'k' }));
    expect(r?.model).toBe('gemini-3.5-flash');
  });

  it('★ gemini 의 전환 모델 기본값은 gemini-3.1-flash-lite 다(하루 500회)', () => {
    const r = resolveLlm(cfg({ LLM_PROVIDER: 'gemini', GEMINI_API_KEY: 'k' }));
    expect(r?.fallback).toEqual({
      provider: 'gemini',
      model: 'gemini-3.1-flash-lite',
      apiKey: 'k',
    });
  });

  it('LLM_FALLBACK_MODEL 을 주면 그대로 쓰고, none 이면 끈다', () => {
    const base = { LLM_PROVIDER: 'gemini', GEMINI_API_KEY: 'k' };
    expect(resolveLlm(cfg({ ...base, LLM_FALLBACK_MODEL: 'x' }))?.fallback?.model).toBe(
      'x',
    );
    expect(resolveLlm(cfg({ ...base, LLM_FALLBACK_MODEL: 'none' }))?.fallback).toBeNull();
  });

  it('전환 모델이 주 모델과 같으면 전환하지 않는다', () => {
    const r = resolveLlm(
      cfg({
        LLM_PROVIDER: 'gemini',
        GEMINI_API_KEY: 'k',
        LLM_MODEL: 'gemini-3.1-flash-lite',
      }),
    );
    expect(r?.fallback).toBeNull();
  });

  it('local · fake 에는 전환 모델이 없다', () => {
    expect(resolveLlm(cfg({ LLM_PROVIDER: 'local' }))?.fallback).toBeNull();
    expect(resolveLlm(cfg({ LLM_PROVIDER: 'fake' }))?.fallback).toBeNull();
  });

  describe('LLM_FALLBACK_PROVIDER=anthropic', () => {
    const base = {
      LLM_PROVIDER: 'gemini',
      GEMINI_API_KEY: 'g',
      LLM_FALLBACK_PROVIDER: 'anthropic',
    };

    it('★ 기본 모델은 claude-haiku-5-5 이고 ANTHROPIC_API_KEY 를 쓴다', () => {
      const r = resolveLlm(cfg({ ...base, ANTHROPIC_API_KEY: 'a' }));
      expect(r?.fallback).toEqual({
        provider: 'anthropic',
        model: 'claude-haiku-5-5',
        apiKey: 'a',
      });
      // 주 모델의 키는 그대로다.
      expect(r?.apiKey).toBe('g');
    });

    it('LLM_FALLBACK_MODEL 을 주면 그 Claude 모델을 쓰고, none 이면 끈다', () => {
      const withKey = { ...base, ANTHROPIC_API_KEY: 'a' };
      expect(
        resolveLlm(cfg({ ...withKey, LLM_FALLBACK_MODEL: 'claude-sonnet-5-5' }))?.fallback
          ?.model,
      ).toBe('claude-sonnet-5-5');
      expect(
        resolveLlm(cfg({ ...withKey, LLM_FALLBACK_MODEL: 'none' }))?.fallback,
      ).toBeNull();
    });

    it('★ 키가 없으면 던진다 - 고르고 안 채운 것은 조용히 끄지 않는다', () => {
      expect(() => resolveLlm(cfg(base))).toThrow(/ANTHROPIC_API_KEY/);
    });

    it('none 이면 키가 없어도 던지지 않는다', () => {
      expect(
        resolveLlm(cfg({ ...base, LLM_FALLBACK_MODEL: 'none' }))?.fallback,
      ).toBeNull();
    });
  });

  it('모르는 전환 provider 는 던진다', () => {
    expect(() =>
      resolveLlm(
        cfg({
          LLM_PROVIDER: 'gemini',
          GEMINI_API_KEY: 'k',
          LLM_FALLBACK_PROVIDER: 'openai',
        }),
      ),
    ).toThrow(/gemini · anthropic/);
  });

  it('★ gemini 호출 시간 제한 기본값은 60초다 - 255초짜리 응답을 기다리지 않는다', () => {
    const r = resolveLlm(cfg({ LLM_PROVIDER: 'gemini', GEMINI_API_KEY: 'k' }));
    expect(r?.timeoutMs).toBe(60000);
  });

  it('LLM_TIMEOUT_SEC 를 주면 그 값을 쓰고, 숫자가 아니거나 0 이하면 기본값', () => {
    const base = { LLM_PROVIDER: 'gemini', GEMINI_API_KEY: 'k' };
    expect(resolveLlm(cfg({ ...base, LLM_TIMEOUT_SEC: '30' }))?.timeoutMs).toBe(30000);
    expect(resolveLlm(cfg({ ...base, LLM_TIMEOUT_SEC: 'soon' }))?.timeoutMs).toBe(60000);
    expect(resolveLlm(cfg({ ...base, LLM_TIMEOUT_SEC: '0' }))?.timeoutMs).toBe(60000);
  });

  it('local 은 기본으로 시간 제한이 없다 - CPU 추론은 원래 느리다', () => {
    expect(resolveLlm(cfg({ LLM_PROVIDER: 'local' }))?.timeoutMs).toBeNull();
    expect(
      resolveLlm(cfg({ LLM_PROVIDER: 'local', LLM_TIMEOUT_SEC: '300' }))?.timeoutMs,
    ).toBe(300000);
  });

  it('LLM_MODEL 을 주면 그대로 쓴다', () => {
    const r = resolveLlm(cfg({ LLM_PROVIDER: 'local', LLM_MODEL: 'my-model' }));
    expect(r?.model).toBe('my-model');
  });
});
