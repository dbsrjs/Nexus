import { AiRunKind } from '@prisma/client';
import { LlmMessage } from '../../llm/llm.provider';
import { AskRequest } from '../ask-request';
import { ASK_SYSTEM } from './ask';
import { AskMaterial, BuiltPrompt, buildAskPrompt } from './build';

/** 사슬 상한 — 첫 문답 + 후속 9 (13-3 설계 D5). 앱도 같은 값이다. */
export const MAX_THREAD_TURNS = 10;

export interface ThreadTurn {
  question: string;
  answer: string;
}

/** 사슬. 첫 문답은 자료를 들고, 뒤 문답은 지시문과 답만 든다. */
export interface FollowUpThread {
  root: Pick<AskRequest, 'instruction' | 'preset'>;
  rootAnswer: string;
  /** 첫 문답 뒤의 문답들 — 오래된 것부터. */
  later: ThreadTurn[];
}

/**
 * 이어 묻기 프롬프트 (13-3 설계 §3). **순수 함수다** — 적재(해시)와 워커가
 * 같은 것을 부른다. 둘이 따로 조립하면 캐시 키와 실제로 보낸 프롬프트가 어긋난다.
 *
 * 첫 user 는 13-2 의 `buildAskPrompt` 가 만든 그대로다(자료 + 첫 요청). system 은
 * **언제나 ask 의 것** — 요약 system 은 세 항목 양식을 강제해 후속 답까지 굳힌다.
 * 요약의 user 는 「다음 대화를 요약해 줘」를 담고 있어 system 을 바꿔도 첫 문답이
 * 그대로 읽힌다.
 */
export function buildFollowUpPrompt(
  thread: FollowUpThread,
  material: AskMaterial,
  instruction: string,
): BuiltPrompt {
  // 이슈 초안(JSON)에 이어 물으면 「이슈 만들기」로 이어지지 않는다(D6).
  if (thread.root.preset === 'issue') {
    throw new Error('이슈 초안에는 이어 묻지 않습니다.');
  }
  const first = buildAskPrompt(thread.root, material);
  const firstUser = first.messages.find((m) => m.role === 'user');
  if (!firstUser) throw new Error('첫 문답에 user 가 없습니다.');

  const messages: LlmMessage[] = [
    { role: 'system', content: ASK_SYSTEM },
    firstUser,
    { role: 'assistant', content: thread.rootAnswer },
  ];
  for (const turn of thread.later) {
    messages.push({ role: 'user', content: turn.question });
    messages.push({ role: 'assistant', content: turn.answer });
  }
  messages.push({ role: 'user', content: instruction });
  return { kind: AiRunKind.ask, messages, json: false };
}
