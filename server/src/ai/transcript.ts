/**
 * 메시지를 프롬프트에 넣을 텍스트로 바꾼다. **순수 함수다** — DB 도 설정도
 * 보지 않아 단위 테스트가 전부를 덮는다 (설계 §6).
 *
 * 13-1 요약과 13-2 이슈 초안이 이것 하나를 함께 쓴다.
 */

/** 메시지 상한. 넘으면 400 이다 — 조용히 자르지 않는다 (판단 #4). */
export const MAX_TRANSCRIPT_MESSAGES = 200;

export interface TranscriptMessage {
  body: string;
  /** null 이 아니면 소프트 삭제. 본문을 싣지 않는다 (판단 #5). */
  deletedAt: Date | null;
  createdAt: Date;
  authorName: string;
  /** 파일명만. 바이트를 LLM 에 보내지 않는다. */
  attachmentNames: string[];
}

/** `<@uuid>` — 저장 형식 그대로다 (판단 #12). */
const MENTION = /<@([^>]+)>/g;

function hhmm(at: Date): string {
  const h = String(at.getUTCHours()).padStart(2, '0');
  const m = String(at.getUTCMinutes()).padStart(2, '0');
  return `${h}:${m}`;
}

/**
 * **`<@userId>` 를 표시 이름으로 되돌린다.** 저장 형식 그대로 주면 LLM 이
 * UUID 를 읽는다. 모르는 id 는 `@(알 수 없음)` 으로 둔다 — 하나 때문에
 * 원문을 잃게 하지 않는다.
 */
function withNames(body: string, names: Map<string, string>): string {
  return body.replace(MENTION, (_, id: string) => `@${names.get(id) ?? '(알 수 없음)'}`);
}

export function buildTranscript(
  messages: TranscriptMessage[],
  names: Map<string, string>,
): string {
  return messages
    .map((m) => {
      const head = `[${hhmm(m.createdAt)}] ${m.authorName}: `;
      if (m.deletedAt) return head + '(삭제된 메시지)';

      const body = withNames(m.body, names);
      const files =
        m.attachmentNames.length > 0
          ? `(첨부: ${m.attachmentNames.join(', ')})`
          : '';

      return head + [body, files].filter((s) => s.length > 0).join(' ');
    })
    .join('\n');
}
