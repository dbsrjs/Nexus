import { LlmMessage } from '../../llm/llm.provider';

export const ASK_SYSTEM = [
  '너는 개발 팀의 조수다. 아래 요청에 답한다.',
  '',
  '규칙:',
  '- 한국어 마크다운으로 답한다. 요청이 다른 언어를 원하면 그 언어로 답한다.',
  '- 주어진 자료(대화 · 코드)만 근거로 답한다. 자료에 없으면 없다고 말한다.',
  '- 기한 · 담당자 · 수치는 대화에서 그 일에 직접 붙은 것만 쓴다. 한 일의 기한을 다른 일로 넓히지 않는다.',
  '- 코드를 근거로 말할 때는 그 코드의 번호를 [n] 으로 붙인다.',
  '- 요청이 양식을 정하면 그 양식을 따른다. 정하지 않으면 짧고 바로 쓸 수 있게 쓴다.',
].join('\n');

/**
 * 자유 지시문 프롬프트 (13-2 설계 §3). **순수 함수다**(`promptHash` 의 입력).
 * 없는 절은 싣지 않는다.
 */
export function askPrompt(input: {
  transcript: string | null;
  code: string;
  instruction: string;
}): LlmMessage[] {
  const sections: string[] = [];
  if (input.transcript) sections.push(`## 대화\n${input.transcript}`);
  if (input.code) sections.push(`## 코드\n${input.code}`);
  sections.push(`## 요청\n${input.instruction}`);
  return [
    { role: 'system', content: ASK_SYSTEM },
    { role: 'user', content: sections.join('\n\n') },
  ];
}
