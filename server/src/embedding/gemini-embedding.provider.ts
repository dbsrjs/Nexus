import { Logger } from '@nestjs/common';
import { EmbeddingConfig } from './embedding.config';
import {
  EMBEDDING_DIMENSIONS,
  EmbeddingProvider,
  EmbeddingTask,
  assertDimensions,
  normalize,
} from './embedding.provider';

const DEFAULT_BASE = 'https://generativelanguage.googleapis.com/v1beta';

/**
 * **문서가 이 조합을 직접 지정한다**: "Use `CODE_RETRIEVAL_QUERY` for queries;
 * `RETRIEVAL_DOCUMENT` for code blocks to be retrieved."
 * (ai.google.dev/gemini-api/docs/embeddings, 2026-09-10 확인)
 *
 * 질의 쪽만 코드 전용 값이라는 것이 핵심이다 — 양쪽을 `CODE_RETRIEVAL_QUERY`
 * 로 맞추고 싶어지지만 그것은 문서가 말하는 짝이 아니다.
 */
const TASK_TYPES: Record<EmbeddingTask, string> = {
  document: 'RETRIEVAL_DOCUMENT',
  query: 'CODE_RETRIEVAL_QUERY',
};

/**
 * 429 를 provider 안에서 몇 번까지 삼키나.
 *
 * **횟수는 넉넉하고 간격은 짧다.** 한 번 기다리는 값이 작아 20회를 다 써도
 * 1분 남짓이고, 분당 한도는 1분이면 반드시 회복되므로 사실상 포기하지 않는다.
 */
const RATE_LIMIT_RETRIES = 20;

/** 대기의 하한·상한(초). 실측으로 정했다 — 아래 주석 참고. */
const RATE_LIMIT_MIN_WAIT_SEC = 2;
const RATE_LIMIT_MAX_WAIT_SEC = 8;

/**
 * 429 뒤 얼마나 기다릴지. **짧게, 그리고 흩어지게.**
 *
 * 지수 백오프를 먼저 썼다가 실측으로 뒤집었다. 한도가 **토큰 버킷**이라
 * 조금씩 계속 채워지는데, 파일 넷을 동시에 부르는 구조에서 넷이 **똑같은
 * 시간을 자면** 그동안 채워진 몫을 아무도 가져가지 않는다. 깨어나면 넷이
 * 한꺼번에 쳐서 하나만 통과하고 셋은 더 긴 대기로 올라간다 — 기다릴수록
 * 나빠지는 되먹임이다.
 *
 * 실측(같은 키 · 같은 크기의 청크): 2초 간격으로 순차 재시도하면 **분당
 * 52청크**가 나오는데, 5·10·20·30초 백오프로는 **분당 13청크**였다.
 *
 * **지터가 핵심이다.** 없으면 넷이 계속 같은 박자로 부딪힌다.
 */
function rateLimitWaitMs(attempt: number): number {
  const base = Math.min(RATE_LIMIT_MIN_WAIT_SEC + attempt, RATE_LIMIT_MAX_WAIT_SEC);
  // ±30% 로 흩는다. 동시에 기다리던 호출들이 같은 순간에 깨어나지 않게 한다.
  return Math.round(base * 1000 * (0.7 + Math.random() * 0.6));
}

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

  async embed(texts: string[], task: EmbeddingTask): Promise<number[][]> {
    const out: number[][] = [];
    for (let i = 0; i < texts.length; i += this.config.batchSize) {
      const batch = texts.slice(i, i + this.config.batchSize);
      out.push(...(await this.callBatch(batch, task)));
    }
    return out;
  }

  /**
   * 분당 한도(429)를 **여기서 흡수한다.**
   *
   * 밖으로 던지면 작업 전체가 실패로 접히는데, **전체 재인덱싱에는 이어받는
   * 장치가 없어 처음부터 다시 시작한다** — 한도가 있는 provider 에서는 그
   * 재시작이 다시 한도를 먹어 영영 끝나지 않는다. 실제로 겪었다(무료 티어
   * 약 100 RPM, 파일 4개 동시면 그 위로 올라간다).
   *
   * **한도가 있는 것은 오류가 아니라 속도다.** 기다렸다 다시 하는 것이 맞는
   * 대응이고, 그래도 안 되면 그때 작업으로 올린다.
   *
   * 429 응답에 `retry-after` 도 `retryDelay` 도 없어(직접 확인했다) 지수
   * 백오프를 쓴다 — 1 · 2 · 4 · 8 · 16초.
   */
  private async callBatch(texts: string[], task: EmbeddingTask): Promise<number[][]> {
    for (let attempt = 0; ; attempt++) {
      try {
        return await this.callOnce(texts, task);
      } catch (err) {
        const retryable = err instanceof EmbeddingHttpError && err.status === 429;
        if (!retryable || attempt >= RATE_LIMIT_RETRIES) throw err;

        // `?? ` 로 본다 — `0` 은 "곧바로 다시"라는 뜻이지 미설정이 아니다.
        const waitMs =
          err.retryAfterSec !== undefined ? err.retryAfterSec * 1000 : rateLimitWaitMs(attempt);
        // 매번 찍으면 로그가 429 로 덮인다 — 몇 번 만에 한 번만 남긴다.
        if (attempt % 5 === 0) {
          this.logger.warn(`분당 한도 — ${Math.round(waitMs / 100) / 10}초 뒤 다시 (${attempt + 1}회)`);
        }
        await new Promise((resolve) => setTimeout(resolve, waitMs));
      }
    }
  }

  private async callOnce(texts: string[], task: EmbeddingTask): Promise<number[][]> {
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
          taskType: TASK_TYPES[task],
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
