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
 * **`gemini` 는 처음에 `gemini-flash-latest` 별칭을 골랐지만 13-1 실제
 * 태우기(2026-09-22)에서 뒤집혔다.** Google 문서(ai.google.dev/gemini-api/docs/models)는
 * `-latest` 를 "새 출시마다 핫스왑" 되는 별칭이라 부르면서도 **"대부분의
 * 프로덕션 앱은 특정 안정화 모델을 써야 한다"** 고 적어 두었다 — 가장 새
 * 모델은 곧 가장 붐비는 모델이라, 별칭을 쓰면 그 부하를 그대로 맞는다.
 * 실측이 이를 뒷받침한다(같은 요약 프롬프트, 548 프롬프트 토큰):
 *
 * | 모델 | 결과 |
 * |---|---|
 * | `gemini-flash-latest`(별칭, 옛 기본값) | **503 매번** |
 * | `gemini-3.5-flash` | 503 |
 * | `gemini-2.5-flash` | 404 (2.5 계열은 기존 사용자로만 접근 허용) |
 * | `gemini-3.6-flash` | 타임아웃 |
 * | `gemini-flash-lite-latest`(별칭) | 200, 14.3초 — 성공했지만 별칭이라 탈락 |
 * | `gemini-3.5-flash-lite` | 성공하지만 7.1~85.2초로 널뛰고 503 도 2회 |
 * | **`gemini-3.1-flash-lite`** | **1.2~5.9초, 6회 중 1회만 503** |
 *
 * **`gemini-3.1-flash-lite` 로 고정한다.** `gemini-flash-lite-latest` 는
 * 유일하게 성공한 다른 후보였지만 **① `-latest` 별칭이라 위와 같은 핫스왑
 * 부하 문제를 그대로 안고, ② 14.3초로 `gemini-3.1-flash-lite`(1.2~5.9초)보다
 * 느렸다** — 별칭이 아닌 후보 중 가장 빠르고 안정적이었다. Flash 계열은
 * 무료 티어에 남아 있고(Pro 계열만 유료 전용으로 옮겨졌다) JSON 구조화
 * 출력(`responseSchema`, 13-2 가 쓸 것)도 3/3 파싱에 성공했다. **503 은
 * 특정 모델만의 문제가 아니라 산발적으로 온다** — 큐의 5xx 재시도(최대
 * 3회)가 이미 처리하는 종류이니 이 값이 503 을 완전히 없애 주지는 않는다.
 *
 * `local` 은 `qwen2.5-coder:7b`(Q4_K_M 기본 태그, 4.7GB) — Qwen2.5 계열의
 * 다국어(한국어 포함) 능력에 코드 특화 파인튜닝을 얹었다. 13-3 코드 질의가
 * 같은 provider 를 쓰므로 코드를 다루는 계열을 우선했다. Qwen3 계열에는 이
 * 체급의 dense 7B 가 없어(문서화된 것은 4B 아니면 MoE 30B) 후보에서 뺐다.
 * **이 값은 13-1 에서 실측하지 못했다** — 이 PC 에 Ollama 가 설치돼 있지
 * 않다. `local` 경로를 쓰기 전에 먼저 실제로 태워 볼 것.
 */
function defaultModel(provider: LlmProviderName): string {
  if (provider === 'gemini') return 'gemini-3.1-flash-lite';
  if (provider === 'local') return 'qwen2.5-coder:7b';
  return 'fake';
}
