import { AiRunKind, Prisma } from '@prisma/client';
import { AskPreset } from './ask-request';
import type { StoredAskInput } from './ai.service';

/**
 * AI 기록(19)의 순수 함수. 목록 · 사슬이 `ai_runs.input` · `result` 를 화면에 보이는
 * 모양으로 옮긴다 — 단위 테스트가 실 DB 없이 이것만 본다.
 */

/** 목록 미리보기 길이. 원문(마크다운)을 자르고 평문화는 앱이 한다(19 설계 D9). */
export const PREVIEW_MAX = 200;

/**
 * 뿌리 문답의 요청. **적재(워커의 프롬프트 재조립)와 기록이 같은 판정을 쓴다.**
 * 13-1 에서 적재된 행은 `{channelId, messageIds}` 뿐이다 — 요약으로 읽는다.
 */
export function rootRequestOf(input: StoredAskInput): {
  instruction: string | null;
  preset: AskPreset | null;
} {
  return {
    instruction: input.instruction ?? null,
    preset: input.preset ?? (input.instruction === undefined ? 'summary' : null),
  };
}

/** 목록 · 사슬에서 뿌리 질문을 보이는 모양. 프리셋이면 질문은 null 이다. */
export function rootQuestionOf(input: StoredAskInput): {
  question: string | null;
  preset: AskPreset | null;
} {
  const { instruction, preset } = rootRequestOf(input);
  return { question: instruction, preset };
}

/** 끝 답의 앞부분. 이슈 초안은 제목이다. 없으면 빈 문자열 — 지어내지 않는다. */
export function previewOf(kind: AiRunKind, result: Prisma.JsonValue): string {
  const r = (result ?? {}) as { markdown?: unknown; title?: unknown };
  const text = kind === AiRunKind.draft_issue ? r.title : r.markdown;
  return typeof text === 'string' ? text.slice(0, PREVIEW_MAX) : '';
}

/**
 * 목록의 근거. **id 만 싣는다** — 이름은 앱이 이미 가진 목록에서 찾는다(설계 D10).
 */
export function listContextOf(input: StoredAskInput) {
  return {
    channelId: input.channelId ?? null,
    messageCount: input.messageIds?.length ?? null,
    repoId: input.repoId ?? null,
  };
}

/** 사슬의 근거. 앱이 칩을 되살리도록 메시지 id 까지 싣는다(설계 D11). */
export function threadContextOf(input: StoredAskInput) {
  return {
    channelId: input.channelId ?? null,
    messageIds: input.messageIds ?? null,
    repoId: input.repoId ?? null,
  };
}
