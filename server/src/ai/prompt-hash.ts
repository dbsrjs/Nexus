import { createHash } from 'node:crypto';
import { LlmMessage } from '../llm/llm.provider';

/**
 * 같은 질문에 두 번 돈을 쓰지 않기 위한 캐시 키 (설계 §4).
 *
 * **모델 ID 를 반드시 섞는다.** 모델을 바꿨는데 캐시가 옛 답을 주면 오류 없이
 * 결과만 틀린다 — 임베딩에서 이미 겪은 종류의 실패다(2026-09-17 빚 정리).
 *
 * **`spaceId` 는 넣지 않는다.** 테넌트 격리는 해시 충돌이 아니라 조회
 * `WHERE` 로 지킨다.
 *
 * 역할까지 함께 해시한다 — 내용만 이어 붙이면 system 과 user 가 뒤바뀐
 * 프롬프트가 같은 키를 갖는다.
 *
 * **구분자는 공백이 아니라 NUL(`\u0000`) 문자다.** `content` 는
 * `buildTranscript` 가 만든 대화 원문이라 공백을 얼마든지 담을 수 있는
 * 사용자 통제 값이다 — 공백으로 이으면 메시지 경계가 사라져 서로 다른
 * 두 대화가 같은 해시를 가질 수 있다. NUL 문자는 일반 문자열에 나타날 수
 * 없으므로 경계가 보장된다.
 */
export function promptHash(
  kind: string,
  modelId: string,
  messages: LlmMessage[],
): string {
  const body = messages
    .map((m) => `${m.role}\u0000${m.content}`)
    .join('\u0000');
  return createHash('sha256')
    .update([kind, modelId, body].join('\u0000'))
    .digest('hex');
}
