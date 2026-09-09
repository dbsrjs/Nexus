import { GeminiEmbeddingProvider } from './gemini-embedding.provider';
import { EMBEDDING_DIMENSIONS } from './embedding.provider';

const CFG = {
  provider: 'gemini' as const,
  model: 'gemini-embedding-001',
  apiKey: 'test-key',
  base: null,
  batchSize: 2,
};

function vector(fill: number): number[] {
  return new Array(EMBEDDING_DIMENSIONS).fill(fill);
}

describe('GeminiEmbeddingProvider', () => {
  const original = global.fetch;
  afterEach(() => {
    global.fetch = original;
  });

  it('768 을 달라고 요청한다 — 기본값 3072 로 오면 삽입이 터진다', async () => {
    let body: any = null;
    global.fetch = (async (_url: string, init: any) => {
      body = JSON.parse(init.body);
      return {
        ok: true,
        status: 200,
        json: async () => ({ embeddings: [{ values: vector(1) }] }),
      };
    }) as any;

    await new GeminiEmbeddingProvider(CFG).embed(['a']);
    expect(body.requests[0].outputDimensionality).toBe(EMBEDDING_DIMENSIONS);
  });

  it('배치 크기대로 나눠 부른다', async () => {
    let calls = 0;
    global.fetch = (async (_url: string, init: any) => {
      calls++;
      const n = JSON.parse(init.body).requests.length;
      return {
        ok: true,
        status: 200,
        json: async () => ({ embeddings: Array.from({ length: n }, () => ({ values: vector(1) })) }),
      };
    }) as any;

    const out = await new GeminiEmbeddingProvider(CFG).embed(['a', 'b', 'c']);
    expect(calls).toBe(2);
    expect(out).toHaveLength(3);
  });

  it('정규화해서 돌려준다', async () => {
    global.fetch = (async () => ({
      ok: true,
      status: 200,
      json: async () => ({ embeddings: [{ values: vector(2) }] }),
    })) as any;

    const [v] = await new GeminiEmbeddingProvider(CFG).embed(['a']);
    const norm = Math.sqrt(v.reduce((s, x) => s + x * x, 0));
    expect(norm).toBeCloseTo(1, 6);
  });

  it('차원이 다르면 던진다 — 조용히 넣으면 pgvector 가 알아보기 어렵게 실패한다', async () => {
    global.fetch = (async () => ({
      ok: true,
      status: 200,
      json: async () => ({ embeddings: [{ values: [1, 2, 3] }] }),
    })) as any;

    await expect(new GeminiEmbeddingProvider(CFG).embed(['a'])).rejects.toThrow(/768/);
  });

  it('429 는 retryAfter 를 실어 던진다', async () => {
    global.fetch = (async () => ({
      ok: false,
      status: 429,
      headers: { get: (k: string) => (k === 'retry-after' ? '17' : null) },
      text: async () => 'rate limited',
    })) as any;

    await expect(new GeminiEmbeddingProvider(CFG).embed(['a'])).rejects.toMatchObject({
      status: 429,
      retryAfterSec: 17,
    });
  });

  it('API 키를 URL 이 아니라 헤더에 싣는다 — 주소는 로그에 남는다', async () => {
    let seen: any = null;
    global.fetch = (async (url: string, init: any) => {
      seen = { url, headers: init.headers };
      return { ok: true, status: 200, json: async () => ({ embeddings: [{ values: vector(1) }] }) };
    }) as any;

    await new GeminiEmbeddingProvider(CFG).embed(['a']);
    expect(seen.url).not.toContain('test-key');
    expect(seen.headers['x-goog-api-key']).toBe('test-key');
  });
});
