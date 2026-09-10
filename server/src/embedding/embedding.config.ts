import { ConfigService } from '@nestjs/config';

export type EmbeddingProviderName = 'gemini' | 'local' | 'fake';

export interface EmbeddingConfig {
  provider: EmbeddingProviderName;
  model: string;
  apiKey: string | null;
  /** provider 의 주소. 비우면 각 어댑터의 기본값을 쓴다. */
  base: string | null;
  batchSize: number;
}

const NAMES: EmbeddingProviderName[] = ['gemini', 'local', 'fake'];

/** 빈 문자열을 미설정으로 친다. `.env` 에 자리만 잡아 둔 경우가 있다. */
function trimmed(config: ConfigService, key: string): string | null {
  return config.get<string>(key)?.trim() || null;
}

/**
 * 임베딩 설정의 **유일한 해석 지점**. `oauth.config.ts` 와 같은 역할이다.
 *
 * **기본값을 두지 않는다.** `fake` 를 기본으로 하면 운영에서 아무도 모르게
 * 해시 벡터가 들어가고 **검색이 돌긴 도는데 결과가 틀린다** — 가장 나쁜
 * 실패다 (설계 §6).
 *
 * 미설정이면 `null` 이고 인덱싱만 멈춘다. **모르는 이름은 던져 부팅을 멈춘다** —
 * 없는 것("이 기능을 안 쓴다")과 잘못된 것(설정 실수)은 다르다.
 */
export function resolveEmbedding(config: ConfigService): EmbeddingConfig | null {
  const raw = trimmed(config, 'EMBEDDING_PROVIDER');
  if (!raw) return null;

  if (!NAMES.includes(raw as EmbeddingProviderName)) {
    throw new Error(
      `EMBEDDING_PROVIDER 는 ${NAMES.join(' · ')} 중 하나여야 합니다 (지금 "${raw}").`,
    );
  }
  const provider = raw as EmbeddingProviderName;

  const apiKey = trimmed(config, 'GEMINI_API_KEY');
  // 키가 없으면 부팅은 되고 인덱싱만 멈춘다. 던지지 않는다.
  if (provider === 'gemini' && !apiKey) return null;

  const batchRaw = trimmed(config, 'EMBEDDING_BATCH_SIZE');
  const batchSize = batchRaw && /^\d+$/.test(batchRaw) ? Number(batchRaw) : 32;

  return {
    provider,
    model: trimmed(config, 'EMBEDDING_MODEL') ?? defaultModel(provider),
    apiKey,
    base: trimmed(config, 'EMBEDDING_BASE'),
    // 배치 한도가 문서에 명시돼 있지 않다. **모르는 값에 붙어 있지 않도록**
    // 낮게 잡고 설정으로 뺀다 (설계 §6).
    batchSize: batchSize > 0 ? batchSize : 32,
  };
}

/**
 * **`local` 의 기본은 `embeddinggemma` 다.** 두 번 바꿔서 여기까지 왔고,
 * 두 번 다 실측이 뒤집었다 (2026-09-10).
 *
 * | 모델 | 왜 탈락했나 |
 * |---|---|
 * | `nomic-embed-text`(v1.5) | **한국어를 못 한다.** 전체 인덱싱 뒤 재니 한국어 질의 5개가 0/5 였고, **서로 다른 다섯 질의의 1위가 모두 같은 청크**였다 — 한국어가 벡터 공간의 한 자리로 뭉개진다 |
 * | `nomic-embed-text-v2-moe` | 다국어는 되는데 **컨텍스트가 512 토큰**이다. 약 1,000자를 넘으면 **오류 없이 뒤를 통째로 버린다**(잘린 앞부분만 임베딩된다). 60줄 청크가 안 들어간다 |
 *
 * `embeddinggemma`(300M)는 셋을 동시에 만족한다 — **768차원 네이티브**(잘라
 * 쓰지 않으니 재정규화도 불필요) · **2,048 토큰**(우리 청크 상한이 들어간다) ·
 * 100개 이상 언어. 한국어 질의 4개로 재니 4/4 였고 정답과 오답의 간격도 컸다
 * (0.52~0.62 vs 0.13~0.27).
 *
 * **차원이 768 인 것이 이 선택의 조건이다** — `vector(768)` 이 스키마와 HNSW
 * 인덱스에 박혀 있어, 바꾸면 전체 재인덱싱을 강제한다.
 */
function defaultModel(provider: EmbeddingProviderName): string {
  if (provider === 'gemini') return 'gemini-embedding-001';
  if (provider === 'local') return 'embeddinggemma';
  return 'fake';
}
