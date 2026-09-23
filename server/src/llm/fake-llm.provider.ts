import { LlmMessage, LlmOptions, LlmProvider, LlmResult } from './llm.provider';
import { createHash } from 'node:crypto';

/**
 * 계약 검증용. **결정적이어야 한다** — 같은 입력에 같은 출력을 주지 않으면
 * `promptHash` 캐시 적중을 검증할 수 없다 (설계 §12).
 *
 * 내용은 쓸모없어도 된다. 이 어댑터로는 프롬프트가 실제로 쓸모 있는지 알 수
 * 없고, 그것은 실제 태우기가 볼 몫이다.
 */
export class FakeLlmProvider implements LlmProvider {
  readonly modelId = 'fake:fake';

  /**
   * 기본값 8192 는 `LLM_MAX_TOKENS` 미설정 시의 기본값(`llm.config.ts`)과
   * 맞춘 것뿐이다 — `LlmModule` 은 실제 설정값을 그대로 넘긴다.
   */
  constructor(readonly maxTokens: number = 8192) {}

  complete(messages: LlmMessage[], options: LlmOptions): Promise<LlmResult> {
    const joined = messages.map((m) => `${m.role}:${m.content}`).join('\n');
    const digest = createHash('sha256').update(joined).digest('hex').slice(0, 16);

    const text = options.json
      ? JSON.stringify({
          title: `가짜 제목 ${digest}`,
          description: joined.slice(0, 200),
          labelIds: [],
        })
      : `가짜 요약 ${digest}\n\n입력 ${messages.length}줄을 받았습니다.`;

    return Promise.resolve({
      text,
      // 센 척하지 않는다 (판단 #2).
      promptTokens: null,
      completionTokens: null,
      model: 'fake',
      truncated: false,
    });
  }
}
