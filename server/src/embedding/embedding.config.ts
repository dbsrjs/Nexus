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

function defaultModel(provider: EmbeddingProviderName): string {
  if (provider === 'gemini') return 'gemini-embedding-001';
  if (provider === 'local') return 'nomic-embed-text';
  return 'fake';
}
