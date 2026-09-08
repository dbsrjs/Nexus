import { createHash } from 'node:crypto';
import {
  EMBEDDING_DIMENSIONS,
  EmbeddingProvider,
  normalize,
} from './embedding.provider';

/**
 * 검증 전용 임베딩. **편의가 아니라 요구 조건이다** — 없으면 CI 가 외부 API
 * 키에 묶인다 (설계 §6 · §8).
 *
 * **낱말 해싱(feature hashing)** 을 쓴다. 순수 해시로 만들면 정확히 같은 글만
 * 가까워지는데, 그러면 "질문을 던지면 그 청크가 1위로 나온다"를 확인할 수
 * 없다. 낱말이 겹치면 벡터도 겹치게 해 두어야 순위를 단언할 수 있다.
 *
 * 의미를 모르는 것은 당연하다 — 이것으로 검색 품질을 재지 않는다.
 */
export class FakeEmbeddingProvider implements EmbeddingProvider {
  readonly dimensions = EMBEDDING_DIMENSIONS;

  async embed(texts: string[]): Promise<number[][]> {
    return texts.map((text) => this.one(text));
  }

  private one(text: string): number[] {
    const vector = new Array<number>(EMBEDDING_DIMENSIONS).fill(0);
    // 한글·영문·숫자를 낱말로 본다. 그 밖의 문자는 구분자다.
    const tokens = text.toLowerCase().split(/[^\p{L}\p{N}_]+/u);

    for (const token of tokens) {
      if (!token) continue;
      const digest = createHash('sha256').update(token).digest();
      // 앞 4바이트로 자리를, 그다음 1바이트로 부호를 정한다. 부호를 섞어야
      // 흔한 낱말이 모든 벡터를 같은 방향으로 밀지 않는다.
      const slot = digest.readUInt32BE(0) % EMBEDDING_DIMENSIONS;
      vector[slot] += digest[4] % 2 === 0 ? 1 : -1;
    }

    return normalize(vector);
  }
}
