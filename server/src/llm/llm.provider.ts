/**
 * 대화 한 줄. **멀티턴(13-3)부터 `assistant` 가 있다** — 앞 답을 역할로
 * 보내야 모델이 「앞 답」과 「자료」를 섞지 않는다. 툴 호출은 여전히 범위 밖이다.
 */
export interface LlmMessage {
  role: 'system' | 'user' | 'assistant';
  content: string;
}

export interface LlmResult {
  text: string;
  /**
   * **모르면 `0` 이 아니라 `null`.** 0 은 "안 썼다"로 읽힌다 (판단 #2).
   * provider 가 사용량을 주지 않는 경우가 실제로 있다.
   */
  promptTokens: number | null;
  completionTokens: number | null;
  /** 실제로 응답한 모델. 설정값이 아니다 — provider 가 다른 것으로 돌릴 수 있다. */
  model: string;
  /**
   * **출력 한도(`maxTokens`)에서 멈췄는지.** 잘린 답은 끝까지 쓴 답처럼 보이지만
   * 결론이 빠져 있다. 러너가 이것을 실패로 돌려 캐시에 굳지 않게 한다 (판단 #4).
   */
  truncated: boolean;
  /**
   * 주 모델 대신 **전환 모델**(`LLM_FALLBACK_MODEL`)이 답했는지. 어댑터는 늘
   * `false` 이고 `FallbackLlmProvider` 만 `true` 로 바꾼다. 러너가 기록하고,
   * 캐시가 그 행을 쓰지 않는다 — 주 모델이 풀린 뒤에도 가벼운 답이 굳지 않게.
   */
  fallback: boolean;
}

export interface LlmOptions {
  /**
   * 출력 상한. **생각(thinking) 토큰을 포함한다** — Gemini 3.x 는 생각 토큰도
   * 이 한도에서 쓴다(ai.google.dev/gemini-api/docs/thinking). 답 길이만의 상한이 아니다.
   */
  maxTokens: number;
  temperature: number;
  /** 구조화 출력. 13-2 이슈 초안에서만 쓴다. 어댑터 밖으로 새지 않는다. */
  json?: boolean;
}

export interface LlmProvider {
  /**
   * `provider:model`. **`promptHash` 에 섞는다** — 모델을 바꿨는데 캐시가 옛
   * 답을 주면 오류 없이 결과만 틀린다 (설계 §4).
   */
  readonly modelId: string;
  /**
   * `LLM_MAX_TOKENS`(`llm.config.ts` 의 `resolveLlm()`)에서 온 상한.
   * **러너가 이 값을 `complete()` 의 `options.maxTokens` 로 그대로 넘긴다** —
   * 러너가 자기 하드코딩 상수를 쓰면 이 설정이 아무 일도 하지 않게 된다
   * (최종 whole-branch 리뷰 Important ②).
   */
  readonly maxTokens: number;
  complete(messages: LlmMessage[], options: LlmOptions): Promise<LlmResult>;
}

/**
 * 주입 토큰. **`LlmProvider | null` 이 온다** — 설정이 없으면 `null` 이고,
 * 그때 서버는 정상 부팅하되 AI 만 503 이다 (`EMBEDDING_PROVIDER` 와 같은 규칙).
 */
export const LLM_PROVIDER = Symbol('LLM_PROVIDER');

/**
 * HTTP 로 온 실패. **상태 코드를 큐까지 들고 간다** — 429·5xx·4xx 의 재시도
 * 판정이 다르기 때문이다 (설계 §5).
 */
export class LlmHttpError extends Error {
  constructor(
    message: string,
    readonly status: number,
    readonly retryAfterSec?: number,
  ) {
    super(message);
    this.name = 'LlmHttpError';
  }
}
