import { LlmMessage } from '../../llm/llm.provider';

/** 이슈 제목 상한. 이슈 테이블의 컬럼 상한(9-1)과 같다. */
export const MAX_ISSUE_TITLE = 200;

const SYSTEM = [
  '너는 개발 팀의 대화를 읽고 이슈 초안을 쓰는 조수다.',
  '대화에서 해야 할 일 하나를 뽑아 다음 JSON 하나로만 답한다.',
  '',
  '{"title": "짧은 한국어 제목", "description": "한국어 마크다운 본문"}',
  '',
  '규칙:',
  '- title 은 무엇을 할지 한 줄로. 80자 안쪽.',
  '- description 에는 배경 · 할 일 · 확인할 것을 대화에 나온 만큼만 쓴다.',
  '- 대화에 없는 내용을 지어내지 않는다.',
  '- 코드가 주어지면 관련 위치를 [n] 으로 가리킨다.',
  '- JSON 밖에 아무것도 쓰지 않는다.',
].join('\n');

/** 이슈 초안 프롬프트. **순수 함수다**(`promptHash` 의 입력). */
export function issuePrompt(transcript: string, code: string): LlmMessage[] {
  const user = `다음 대화로 이슈 초안을 써 줘.\n\n## 대화\n${transcript}`;
  return [
    { role: 'system', content: SYSTEM },
    { role: 'user', content: code ? `${user}\n\n## 코드\n${code}` : user },
  ];
}

export interface IssueDraft {
  title: string;
  description: string;
}

/**
 * 모델 응답을 초안으로 읽는다. **못 읽으면 던진다** — 러너의
 * `classifyFailure` 가 그 밖의 오류를 fatal 로 친다. 같은 프롬프트에 같은
 * 모양이 다시 올 것이라 재시도로 낫지 않는다(13 설계 §5).
 *
 * 제목이 상한을 넘으면 자른다. 사람이 생성 시트에서 확인하는 초안이라, 넘긴
 * 채 두면 생성이 400 이 되어 초안 전체를 잃는다(판단 #4 의 「사람이 쓴 본문」
 * 예외와 같은 성격).
 */
export function parseIssueDraft(text: string): IssueDraft {
  // 모델이 JSON 을 코드펜스로 감싸 주는 일이 있다 — 벗긴다.
  const bare = text
    .trim()
    .replace(/^```[a-zA-Z]*\s*\n?/, '')
    .replace(/\n?```$/, '')
    .trim();

  let parsed: unknown;
  try {
    parsed = JSON.parse(bare);
  } catch {
    throw new Error('이슈 초안이 JSON 이 아닙니다.');
  }
  const { title, description } = (parsed ?? {}) as Record<string, unknown>;
  if (typeof title !== 'string' || title.trim().length === 0) {
    throw new Error('이슈 초안에 제목이 없습니다.');
  }
  if (typeof description !== 'string') {
    throw new Error('이슈 초안의 본문이 문자열이 아닙니다.');
  }
  return { title: title.trim().slice(0, MAX_ISSUE_TITLE), description: description.trim() };
}
