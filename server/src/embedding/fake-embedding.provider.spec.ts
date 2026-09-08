import { FakeEmbeddingProvider } from './fake-embedding.provider';
import { EMBEDDING_DIMENSIONS } from './embedding.provider';

describe('FakeEmbeddingProvider', () => {
  const provider = new FakeEmbeddingProvider();

  it('차원은 언제나 768 이다 — 스키마와 HNSW 인덱스가 그 값이다', async () => {
    const [v] = await provider.embed(['안녕']);
    expect(v).toHaveLength(EMBEDDING_DIMENSIONS);
    expect(provider.dimensions).toBe(EMBEDDING_DIMENSIONS);
  });

  it('결정적이다 — 같은 글은 언제나 같은 벡터다', async () => {
    const [a] = await provider.embed(['socket reconnect handler']);
    const [b] = await provider.embed(['socket reconnect handler']);
    expect(a).toEqual(b);
  });

  it('단위 벡터다', async () => {
    const [v] = await provider.embed(['단위 길이 확인']);
    const norm = Math.sqrt(v.reduce((s, x) => s + x * x, 0));
    expect(norm).toBeCloseTo(1, 6);
  });

  it('낱말이 겹치면 더 가깝다 — 검증이 순위를 단언할 수 있어야 한다', async () => {
    const [target, near, far] = await provider.embed([
      'socket reconnect with fresh token',
      'reconnect the socket using a fresh token please',
      '고아 첨부를 한 시간마다 지운다',
    ]);
    const dot = (a: number[], b: number[]) => a.reduce((s, x, i) => s + x * b[i], 0);
    expect(dot(target, near)).toBeGreaterThan(dot(target, far));
  });

  it('빈 글도 768 차원을 준다 — 삽입이 터지면 안 된다', async () => {
    const [v] = await provider.embed(['']);
    expect(v).toHaveLength(EMBEDDING_DIMENSIONS);
  });

  it('넣은 순서대로 같은 개수를 돌려준다', async () => {
    const out = await provider.embed(['a', 'b', 'c']);
    expect(out).toHaveLength(3);
  });
});
