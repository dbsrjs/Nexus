import { ConfigService } from '@nestjs/config';

export type LlmProviderName = 'gemini' | 'local' | 'fake';

export interface LlmConfig {
  provider: LlmProviderName;
  model: string;
  apiKey: string | null;
  /** provider 의 주소. 비우면 각 어댑터의 기본값을 쓴다. */
  base: string | null;
  maxTokens: number;
}

const NAMES: LlmProviderName[] = ['gemini', 'local', 'fake'];

/** 빈 문자열을 미설정으로 친다. `.env` 에 자리만 잡아 둔 경우가 있다. */
function trimmed(config: ConfigService, key: string): string | null {
  return config.get<string>(key)?.trim() || null;
}

/**
 * LLM 설정의 **유일한 해석 지점**. `embedding.config.ts` 와 같은 역할이다.
 *
 * **기본값을 두지 않는다.** `fake` 를 기본으로 하면 운영에서 아무도 모르게
 * 가짜 답이 나가고 **AI 가 돌긴 도는데 내용이 틀린다** (설계 §3).
 *
 * 미설정이면 `null` 이고 AI 만 멈춘다. **모르는 이름은 던져 부팅을 멈춘다.**
 */
export function resolveLlm(config: ConfigService): LlmConfig | null {
  const raw = trimmed(config, 'LLM_PROVIDER');
  if (!raw) return null;

  if (!NAMES.includes(raw as LlmProviderName)) {
    throw new Error(
      `LLM_PROVIDER 는 ${NAMES.join(' · ')} 중 하나여야 합니다 (지금 "${raw}").`,
    );
  }
  const provider = raw as LlmProviderName;

  const apiKey = trimmed(config, 'GEMINI_API_KEY');
  // 키가 없으면 부팅은 되고 AI 만 멈춘다. 던지지 않는다.
  if (provider === 'gemini' && !apiKey) return null;

  const rawMax = trimmed(config, 'LLM_MAX_TOKENS');
  const parsed = rawMax && /^\d+$/.test(rawMax) ? Number(rawMax) : 0;

  return {
    provider,
    model: trimmed(config, 'LLM_MODEL') ?? defaultModel(provider),
    apiKey,
    base: trimmed(config, 'LLM_BASE'),
    maxTokens: parsed > 0 ? parsed : 1024,
  };
}

/**
 * **이 값은 구현 시점(2026-09-20)에 문서를 보고 정한 것이다** (설계 §3).
 * 확인한 날짜를 남긴다 — 세대 교체가 잦아 오래된 기본값은 조용히 실패한다.
 *
 * 고를 때의 조건:
 * - `gemini` — 무료 티어가 있고 **한국어 요약**과 **JSON 구조화 출력**이 되는 것
 * - `local` — **Q4 기준 5GB 이하.** `embeddinggemma`(0.6GB)와 함께 12GB 에
 *   상주해야 질의마다 모델을 바꿔 끼우지 않는다
 *
 * **`gemini` 는 `embeddinggemma` 와 달리 특정 버전이 아니라 별칭을 쓴다.**
 * 임베딩은 차원이 스키마(`vector(768)`)에 박혀 있어 모델을 못 바꾸지만,
 * 생성 모델은 그 제약이 없다. Google 문서(ai.google.dev/gemini-api/docs/models)가
 * `gemini-flash-latest` 를 "2주 예고 뒤 최신 릴리스로 핫스왑" 되는 별칭으로
 * 못박아 두었다 — 세대 교체가 유독 잦은 이 자리에서는 특정 버전을 박아 두는
 * 것보다 이 별칭이 조용히 낡는 값을 만들지 않는다. Flash 계열은 무료 티어에
 * 남아 있고(Pro 계열만 유료 전용으로 옮겨졌다) 구조화 출력(`responseSchema`)과
 * 다국어(한국어 포함)를 지원한다.
 *
 * `local` 은 `qwen2.5-coder:7b`(Q4_K_M 기본 태그, 4.7GB) — Qwen2.5 계열의
 * 다국어(한국어 포함) 능력에 코드 특화 파인튜닝을 얹었다. 13-3 코드 질의가
 * 같은 provider 를 쓰므로 코드를 다루는 계열을 우선했다. Qwen3 계열에는 이
 * 체급의 dense 7B 가 없어(문서화된 것은 4B 아니면 MoE 30B) 후보에서 뺐다.
 */
function defaultModel(provider: LlmProviderName): string {
  if (provider === 'gemini') return 'gemini-flash-latest';
  if (provider === 'local') return 'qwen2.5-coder:7b';
  return 'fake';
}
