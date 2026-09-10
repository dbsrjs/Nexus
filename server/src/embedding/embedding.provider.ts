/**
 * 벡터 차원. **스키마(`vector(768)`)와 HNSW 인덱스에 박혀 있어 고정이다.**
 * 바꾸는 것은 인덱스 재생성을 뜻한다 (설계 §6).
 */
export const EMBEDDING_DIMENSIONS = 768;

/**
 * 이 텍스트가 **검색되는 쪽인지 검색하는 쪽인지.**
 *
 * **모델이 둘을 다르게 다룬다.** `gemini-embedding-001` 은 `taskType` 을,
 * `nomic-embed-text` 는 `search_document:` · `search_query:` 접두사를 받는데
 * 둘 다 **문서가 요구하는 것이지 선택지가 아니다** — 안 주면 검색 품질이
 * 떨어진다. 처음에는 이 구분 없이 `embed(texts)` 하나였고, 그래서 두 어댑터가
 * 나란히 그 신호를 빠뜨리고 있었다.
 */
export type EmbeddingTask = 'document' | 'query';

export interface EmbeddingProvider {
  readonly dimensions: number;
  /** 넣은 순서 그대로, 같은 개수를 돌려준다. */
  embed(texts: string[], task: EmbeddingTask): Promise<number[][]>;
}

/**
 * 주입 토큰. **`EmbeddingProvider | null` 이 온다** — 설정이 없으면 `null` 이고,
 * 그때 서버는 정상 부팅하되 인덱싱만 멈춘다(10-2a 의 `OAUTH_TOKEN_KEY` 규칙).
 */
export const EMBEDDING_PROVIDER = Symbol('EMBEDDING_PROVIDER');

/**
 * 차원을 지키게 한다. **그냥 넣으면 pgvector 가 알아보기 어려운 메시지로
 * 던진다** — provider 를 갈아탈 때 가장 먼저 어긋나는 것이 이 값이다.
 */
export function assertDimensions(vectors: number[][]): void {
  for (const v of vectors) {
    if (v.length !== EMBEDDING_DIMENSIONS) {
      throw new Error(
        `임베딩 차원이 ${EMBEDDING_DIMENSIONS} 이어야 하는데 ${v.length} 입니다. ` +
          'EMBEDDING_MODEL 과 출력 차원 설정을 확인하세요.',
      );
    }
  }
}

/**
 * L2 정규화.
 *
 * `vector_cosine_ops` 는 크기에 영향받지 않아 없어도 되지만,
 * `gemini-embedding-001` 은 768 로 자르면 단위 벡터가 아니게 되고(문서가 직접
 * 정규화를 요구한다), 넣어 두면 나중에 내적 연산으로 바꿀 여지가 남는다.
 */
export function normalize(v: number[]): number[] {
  let sum = 0;
  for (const x of v) sum += x * x;
  const norm = Math.sqrt(sum);
  // 영벡터는 나눌 수 없다. 그대로 둔다 — 어떤 것과도 가깝지 않게 된다.
  if (norm === 0) return v;
  return v.map((x) => x / norm);
}
