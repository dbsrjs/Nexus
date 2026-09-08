import { ConfigService } from '@nestjs/config';
import { resolveEmbedding } from './embedding.config';

function cfg(values: Record<string, string>): ConfigService {
  return { get: (k: string) => values[k] } as unknown as ConfigService;
}

describe('resolveEmbedding', () => {
  it('기본값을 두지 않는다 — 비어 있으면 null 이다', () => {
    expect(resolveEmbedding(cfg({}))).toBeNull();
    expect(resolveEmbedding(cfg({ EMBEDDING_PROVIDER: '   ' }))).toBeNull();
  });

  it('모르는 이름은 던진다 — 설정 실수는 조용히 넘기지 않는다', () => {
    expect(() => resolveEmbedding(cfg({ EMBEDDING_PROVIDER: 'openai' }))).toThrow(
      /EMBEDDING_PROVIDER/,
    );
  });

  it('gemini 인데 키가 없으면 null 이다 — 없는 것과 잘못된 것은 다르다', () => {
    expect(resolveEmbedding(cfg({ EMBEDDING_PROVIDER: 'gemini' }))).toBeNull();
  });

  it('fake 는 키가 필요 없다', () => {
    const resolved = resolveEmbedding(cfg({ EMBEDDING_PROVIDER: 'fake' }));
    expect(resolved?.provider).toBe('fake');
  });

  it('gemini 는 키가 있으면 풀린다', () => {
    const resolved = resolveEmbedding(
      cfg({ EMBEDDING_PROVIDER: 'gemini', GEMINI_API_KEY: 'k' }),
    );
    expect(resolved).toEqual({
      provider: 'gemini',
      model: 'gemini-embedding-001',
      apiKey: 'k',
      base: null,
      batchSize: 32,
    });
  });

  it('local 은 키가 필요 없고 base 를 받는다', () => {
    const resolved = resolveEmbedding(
      cfg({ EMBEDDING_PROVIDER: 'local', EMBEDDING_BASE: 'http://127.0.0.1:11434' }),
    );
    expect(resolved?.provider).toBe('local');
    expect(resolved?.base).toBe('http://127.0.0.1:11434');
  });
});
