import { LlmMessage } from '../../llm/llm.provider';

const SYSTEM = [
  '너는 개발 팀의 대화를 요약하는 조수다.',
  '주어진 대화에서 다음 셋을 뽑아 **한국어 마크다운**으로 답한다.',
  '',
  '1. **정해진 것** — 결론이 난 사항',
  '2. **맡은 사람** — 누가 무엇을 하기로 했는가',
  '3. **남은 질문** — 결론이 나지 않은 것',
  '',
  '규칙:',
  '- 대화에 없는 내용을 지어내지 않는다. 해당 항목이 없으면 "없음" 이라고 쓴다.',
  '- 사람 이름은 대화에 나온 그대로 쓴다.',
  '- 인사말·잡담은 싣지 않는다.',
  '- 머리말이나 맺음말 없이 위 세 항목만 쓴다.',
].join('\n');

/**
 * 요약 프롬프트를 조립한다. **순수 함수다** — 이 결과가 그대로 `promptHash`
 * 의 입력이라, 실행 때마다 달라지는 값(시각 · 난수)을 넣으면 캐시가 영영
 * 맞지 않는다.
 */
export function summarizePrompt(transcript: string): LlmMessage[] {
  return [
    { role: 'system', content: SYSTEM },
    { role: 'user', content: `다음 대화를 요약해 줘.\n\n${transcript}` },
  ];
}
