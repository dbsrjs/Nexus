import { Logger } from '@nestjs/common';
import { EmbeddingConfig } from './embedding.config';
import {
  EMBEDDING_DIMENSIONS,
  EmbeddingProvider,
  assertDimensions,
  normalize,
} from './embedding.provider';

const DEFAULT_BASE = 'https://generativelanguage.googleapis.com/v1beta';

/**
 * provider 쪽 실패. **`status` 와 `retryAfterSec` 를 들고 간다** — 워커가
 * 429 를 "시도 횟수로 세지 않고 미룬다"로 다루려면 그 구분이 필요하다.
 */
export class EmbeddingHttpError extends Error {
  constructor(
    message: string,
    readonly status: number,
    readonly retryAfterSec?: number,
  ) {
    super(message);
  }
}

/**
 * Gemini 임베딩.
 *
 * **`outputDimensionality` 를 반드시 보낸다.** 기본이 3,072 라 안 보내면
 * `vector(768)` 삽입이 터진다. 768 은 문서가 권장하는 값 셋(768 · 1,536 ·
 * 3,072) 중 하나다 (설계 §6).
 *
 * **정규화해서 돌려준다.** `gemini-embedding-001` 은 3,072 미만으로 자르면
 * 단위 벡터가 아니게 되고 문서가 직접 정규화를 요구한다.
 */
export class GeminiEmbeddingProvider implements EmbeddingProvider {
  private readonly logger = new Logger(GeminiEmbeddingProvider.name);
  readonly dimensions = EMBEDDING_DIMENSIONS;

  constructor(private readonly config: EmbeddingConfig) {}

  async embed(texts: string[]): Promise<number[][]> {
    const out: number[][] = [];
    for (let i = 0; i < texts.length; i += this.config.batchSize) {
      const batch = texts.slice(i, i + this.config.batchSize);
      out.push(...(await this.callBatch(batch)));
    }
    return out;
  }

  private async callBatch(texts: string[]): Promise<number[][]> {
    const base = this.config.base ?? DEFAULT_BASE;
    const model = `models/${this.config.model}`;

    const res = await fetch(`${base}/${model}:batchEmbedContents`, {
      method: 'POST',
      headers: {
        'content-type': 'application/json',
        // **키를 URL 에 싣지 않는다.** 주소는 로그와 오류 메시지에 남는다.
        'x-goog-api-key': this.config.apiKey ?? '',
      },
      body: JSON.stringify({
        requests: texts.map((text) => ({
          model,
          content: { parts: [{ text }] },
          outputDimensionality: EMBEDDING_DIMENSIONS,
        })),
      }),
    });

    if (!res.ok) {
      const raw = res.headers?.get?.('retry-after');
      const retryAfterSec = raw && /^\d+$/.test(raw) ? Number(raw) : undefined;
      this.logger.warn(`임베딩 호출 실패: ${res.status}`);
      throw new EmbeddingHttpError(
        `임베딩 provider 가 ${res.status} 를 주었습니다.`,
        res.status,
        retryAfterSec,
      );
    }

    const body = (await res.json()) as { embeddings?: Array<{ values?: number[] }> };
    const vectors = (body.embeddings ?? []).map((e) => e.values ?? []);
    // 차원이 다르면 여기서 멈춘다. 그냥 넣으면 pgvector 가 알아보기 어렵게 실패한다.
    assertDimensions(vectors);
    return vectors.map(normalize);
  }
}
