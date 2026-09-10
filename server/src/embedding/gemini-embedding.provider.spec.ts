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

    await new GeminiEmbeddingProvider(CFG).embed(['a'], 'document');
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

    const out = await new GeminiEmbeddingProvider(CFG).embed(['a', 'b', 'c'], 'document');
    expect(calls).toBe(2);
    expect(out).toHaveLength(3);
  });

  it('정규화해서 돌려준다', async () => {
    global.fetch = (async () => ({
      ok: true,
      status: 200,
      json: async () => ({ embeddings: [{ values: vector(2) }] }),
    })) as any;

    const [v] = await new GeminiEmbeddingProvider(CFG).embed(['a'], 'document');
    const norm = Math.sqrt(v.reduce((s, x) => s + x * x, 0));
    expect(norm).toBeCloseTo(1, 6);
  });

  it('차원이 다르면 던진다 — 조용히 넣으면 pgvector 가 알아보기 어렵게 실패한다', async () => {
    global.fetch = (async () => ({
      ok: true,
      status: 200,
      json: async () => ({ embeddings: [{ values: [1, 2, 3] }] }),
    })) as any;

    await expect(new GeminiEmbeddingProvider(CFG).embed(['a'], 'document')).rejects.toThrow(/768/);
  });

  // 429 는 provider 안에서 먼저 삼킨다(지수 백오프). 밖으로 던지면 작업
  // 전체가 접히는데 전체 재인덱싱은 이어받지 못해 처음부터 다시 시작한다.
  // **테스트가 느려지지 않게 retry-after 를 0 으로 준다** — 대기 계산이
  // 헤더를 우선하므로 실제 sleep 이 0 이 된다.
  it('429 를 여러 번 다시 시도한 뒤에야 던진다', async () => {
    let calls = 0;
    global.fetch = (async () => {
      calls++;
      return {
        ok: false,
        status: 429,
        headers: { get: (k: string) => (k === 'retry-after' ? '0' : null) },
      };
    }) as any;

    await expect(new GeminiEmbeddingProvider(CFG).embed(['a'], 'document')).rejects.toMatchObject({
      status: 429,
    });
    // 최초 1회 + RATE_LIMIT_RETRIES(20)
    expect(calls).toBe(21);
  });

  it('429 가 아닌 실패는 곧바로 던진다 — 기다려도 낫지 않는다', async () => {
    let calls = 0;
    global.fetch = (async () => {
      calls++;
      return { ok: false, status: 500, headers: { get: () => null } };
    }) as any;

    await expect(new GeminiEmbeddingProvider(CFG).embed(['a'], 'document')).rejects.toMatchObject({
      status: 500,
    });
    expect(calls).toBe(1);
  });
  it('API 키를 URL 이 아니라 헤더에 싣는다 — 주소는 로그에 남는다', async () => {
    let seen: any = null;
    global.fetch = (async (url: string, init: any) => {
      seen = { url, headers: init.headers };
      return { ok: true, status: 200, json: async () => ({ embeddings: [{ values: vector(1) }] }) };
    }) as any;

    await new GeminiEmbeddingProvider(CFG).embed(['a'], 'document');
    expect(seen.url).not.toContain('test-key');
    expect(seen.headers['x-goog-api-key']).toBe('test-key');
  });
  // ── taskType ──────────────────────────────────────────────
  // **문서가 이 짝을 직접 지정한다**: "Use CODE_RETRIEVAL_QUERY for queries;
  // RETRIEVAL_DOCUMENT for code blocks to be retrieved."
  // 처음 구현에는 taskType 자체가 없었다. 빠뜨려도 200 이 오고 벡터도
  // 나오므로 **오류가 아니라 순위만 나빠진다** — 테스트로 고정해 둔다.
  it.each([
    ['document' as const, 'RETRIEVAL_DOCUMENT'],
    ['query' as const, 'CODE_RETRIEVAL_QUERY'],
  ])('%s 는 taskType 을 %s 로 보낸다', async (task, expected) => {
    let body: any = null;
    global.fetch = (async (_url: string, init: any) => {
      body = JSON.parse(init.body);
      return {
        ok: true,
        status: 200,
        json: async () => ({ embeddings: [{ values: vector(1) }] }),
      };
    }) as any;

    await new GeminiEmbeddingProvider(CFG).embed(['a'], task);
    expect(body.requests[0].taskType).toBe(expected);
  });
});
