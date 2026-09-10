import { Logger } from '@nestjs/common';
import { EmbeddingConfig } from './embedding.config';
import {
  EMBEDDING_DIMENSIONS,
  EmbeddingProvider,
  EmbeddingTask,
  assertDimensions,
  normalize,
} from './embedding.provider';
import { EmbeddingHttpError } from './gemini-embedding.provider';

const DEFAULT_BASE = 'http://127.0.0.1:11434';

/**
 * **접두사는 provider 속성이 아니라 모델 속성이다.**
 *
 * 처음에는 nomic 것 하나를 어댑터에 박아 뒀는데, `embeddinggemma` 를 붙이며
 * **형식이 아예 다르다는 것**이 드러났다. 같은 Ollama 뒤에 있어도 모델이
 * 다르면 다른 문자열을 요구한다 — provider 하나에 접두사 하나라는 가정이
 * 틀렸다.
 *
 * 모델 카드가 요구하는 그대로 적는다 (2026-09-10 확인):
 * - `embeddinggemma` — 문서 `title: {title | "none"} | text: {content}` ·
 *   질의 `task: search result | query: {content}`
 * - `nomic-embed-text` 계열 — "the text prompt _must_ include a _task
 *   instruction prefix_"
 */
const PREFIX_RULES: Array<{
  match: RegExp;
  prefixes: Record<EmbeddingTask, string>;
}> = [
  {
    match: /^embeddinggemma/i,
    // 제목이 없으므로 문서 쪽은 `none` 이다 — 모델 카드가 그 자리를 그렇게 쓴다.
    prefixes: {
      document: 'title: none | text: ',
      query: 'task: search result | query: ',
    },
  },
  {
    match: /^nomic-embed-text/i,
    prefixes: { document: 'search_document: ', query: 'search_query: ' },
  },
];

/**
 * 모르는 모델에는 **접두사를 붙이지 않는다.** 틀린 접두사는 없는 접두사보다
 * 나쁘다 — 그 낱말이 벡터에 섞여 문서와 질의를 서로 밀어낸다.
 */
const NO_PREFIX: Record<EmbeddingTask, string> = { document: '', query: '' };

export function prefixesFor(model: string): Record<EmbeddingTask, string> {
  return PREFIX_RULES.find((r) => r.match.test(model))?.prefixes ?? NO_PREFIX;
}

/**
 * Ollama 로컬 임베딩. 기본 모델은 `embeddinggemma`(768차원 · 2,048 토큰 ·
 * 다국어) 다 — 고른 과정은 `embedding.config.ts` 의 `defaultModel()`.
 *
 * **키가 필요 없고 한도가 없다.** 대가는 Ollama 데몬이 개발 PC 마다 하나 더
 * 필요하다는 것이다.
 *
 * **모델을 바꿀 때는 컨텍스트 길이를 반드시 확인할 것.** 넘치면 Ollama 는
 * 오류를 주지 않고 **뒤를 조용히 버린다** — v2-moe(512 토큰)에서 실제로
 * 겪었다. 재는 법은 설계 §6 「2026-09-10」 ①.
 */
export class LocalEmbeddingProvider implements EmbeddingProvider {
  private readonly logger = new Logger(LocalEmbeddingProvider.name);
  readonly dimensions = EMBEDDING_DIMENSIONS;

  constructor(private readonly config: EmbeddingConfig) {}

  async embed(texts: string[], task: EmbeddingTask): Promise<number[][]> {
    const base = this.config.base ?? DEFAULT_BASE;
    const prefix = prefixesFor(this.config.model)[task];

    const res = await fetch(`${base}/api/embed`, {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify({
        model: this.config.model,
        input: texts.map((text) => prefix + text),
      }),
    });

    if (!res.ok) {
      this.logger.warn(`로컬 임베딩 호출 실패: ${res.status}`);
      throw new EmbeddingHttpError(
        `로컬 임베딩이 ${res.status} 를 주었습니다.`,
        res.status,
      );
    }

    const body = (await res.json()) as { embeddings?: number[][] };
    const vectors = body.embeddings ?? [];
    assertDimensions(vectors);
    return vectors.map(normalize);
  }
}
