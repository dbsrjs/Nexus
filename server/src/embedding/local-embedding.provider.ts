import { Logger } from '@nestjs/common';
import { EmbeddingConfig } from './embedding.config';
import {
  EMBEDDING_DIMENSIONS,
  EmbeddingProvider,
  assertDimensions,
  normalize,
} from './embedding.provider';
import { EmbeddingHttpError } from './gemini-embedding.provider';

const DEFAULT_BASE = 'http://127.0.0.1:11434';

/**
 * Ollama 로컬 임베딩(`nomic-embed-text` 는 정확히 768 차원이다).
 *
 * **키가 필요 없고 한도가 없다.** 대가는 Ollama 데몬이 개발 PC 마다 하나 더
 * 필요하다는 것이다 — 그래서 기본이 아니라 선택지다 (설계 §6).
 */
export class LocalEmbeddingProvider implements EmbeddingProvider {
  private readonly logger = new Logger(LocalEmbeddingProvider.name);
  readonly dimensions = EMBEDDING_DIMENSIONS;

  constructor(private readonly config: EmbeddingConfig) {}

  async embed(texts: string[]): Promise<number[][]> {
    const base = this.config.base ?? DEFAULT_BASE;

    const res = await fetch(`${base}/api/embed`, {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify({ model: this.config.model, input: texts }),
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
