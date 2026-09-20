/** 대화 한 줄. 툴 호출·멀티턴은 범위 밖이라 역할이 둘뿐이다 (설계 §13). */
export interface LlmMessage {
  role: 'system' | 'user';
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
}

export interface LlmOptions {
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
