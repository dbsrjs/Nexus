import { LocalEmbeddingProvider, prefixesFor } from './local-embedding.provider';
import { EMBEDDING_DIMENSIONS } from './embedding.provider';

const CFG = {
  provider: 'local' as const,
  model: 'embeddinggemma',
  apiKey: null,
  base: null,
  batchSize: 32,
};

function vector(fill: number): number[] {
  return new Array(EMBEDDING_DIMENSIONS).fill(fill);
}

describe('LocalEmbeddingProvider', () => {
  const original = global.fetch;
  afterEach(() => {
    global.fetch = original;
  });

  // ── task 접두사 ────────────────────────────────────────────
  // 모델 카드가 접두사를 **요구한다**(embeddinggemma · nomic 계열 모두).
  // 처음 구현에는 접두사가 아예 없었고, **빼도 200 이 오고 벡터도 나오므로
  // 오류가 아니라 순위만 나빠졌다** — 테스트로 고정해 둔다.
  it.each([
    ['document' as const, 'title: none | text: '],
    ['query' as const, 'task: search result | query: '],
  ])('embeddinggemma 의 %s 는 "%s" 접두사를 붙인다', async (task, prefix) => {
    let body: any = null;
    global.fetch = (async (_url: string, init: any) => {
      body = JSON.parse(init.body);
      return { ok: true, status: 200, json: async () => ({ embeddings: [vector(1)] }) };
    }) as any;

    await new LocalEmbeddingProvider(CFG).embed(['소켓 재연결'], task);
    expect(body.input).toEqual([`${prefix}소켓 재연결`]);
  });

  it('접두사를 붙여도 모델 이름은 그대로 보낸다', async () => {
    let body: any = null;
    global.fetch = (async (_url: string, init: any) => {
      body = JSON.parse(init.body);
      return { ok: true, status: 200, json: async () => ({ embeddings: [vector(1)] }) };
    }) as any;

    await new LocalEmbeddingProvider(CFG).embed(['a'], 'document');
    expect(body.model).toBe('embeddinggemma');
  });

  it('기본 주소는 Ollama 데몬이다', async () => {
    let url = '';
    global.fetch = (async (u: string) => {
      url = u;
      return { ok: true, status: 200, json: async () => ({ embeddings: [vector(1)] }) };
    }) as any;

    await new LocalEmbeddingProvider(CFG).embed(['a'], 'document');
    expect(url).toBe('http://127.0.0.1:11434/api/embed');
  });

  it('정규화해서 돌려준다', async () => {
    global.fetch = (async () => ({
      ok: true,
      status: 200,
      json: async () => ({ embeddings: [vector(2)] }),
    })) as any;

    const [v] = await new LocalEmbeddingProvider(CFG).embed(['a'], 'document');
    const norm = Math.sqrt(v.reduce((s, x) => s + x * x, 0));
    expect(norm).toBeCloseTo(1, 6);
  });

  it('차원이 다르면 던진다 — 그냥 넣으면 pgvector 가 알아보기 어렵게 실패한다', async () => {
    global.fetch = (async () => ({
      ok: true,
      status: 200,
      json: async () => ({ embeddings: [[1, 2, 3]] }),
    })) as any;

    await expect(new LocalEmbeddingProvider(CFG).embed(['a'], 'document')).rejects.toThrow(
      /768/,
    );
  });

  it('실패는 status 를 들고 던진다 — 워커가 429 를 다르게 다룬다', async () => {
    global.fetch = (async () => ({ ok: false, status: 503, headers: { get: () => null } })) as any;

    await expect(new LocalEmbeddingProvider(CFG).embed(['a'], 'document')).rejects.toMatchObject({
      status: 503,
    });
  });
});

describe('prefixesFor — 접두사는 provider 가 아니라 모델의 것이다', () => {
  it('embeddinggemma 는 gemma 형식을 쓴다', () => {
    expect(prefixesFor('embeddinggemma')).toEqual({
      document: 'title: none | text: ',
      query: 'task: search result | query: ',
    });
  });

  it('nomic 계열은 search_ 형식을 쓴다 — 같은 Ollama 뒤인데 형식이 다르다', () => {
    const nomic = { document: 'search_document: ', query: 'search_query: ' };
    expect(prefixesFor('nomic-embed-text')).toEqual(nomic);
    expect(prefixesFor('nomic-embed-text-v2-moe')).toEqual(nomic);
  });

  it('태그가 붙어도 알아본다 — Ollama 는 `모델:latest` 로 부른다', () => {
    expect(prefixesFor('embeddinggemma:latest').document).toBe('title: none | text: ');
  });

  // **틀린 접두사는 없는 접두사보다 나쁘다** — 그 낱말이 벡터에 섞여 문서와
  // 질의를 서로 밀어낸다. 모르는 모델에는 아무것도 붙이지 않는다.
  it('모르는 모델에는 접두사를 붙이지 않는다', () => {
    expect(prefixesFor('mxbai-embed-large')).toEqual({ document: '', query: '' });
  });
});
