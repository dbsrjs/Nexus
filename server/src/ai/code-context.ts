import { ChunkHit } from '../repos/indexing/index-chunks.repository';

/**
 * 결과의 인용 한 줄. **LLM 이 아니라 우리가 채운다** — LLM 이 지어낸 경로가
 * 링크가 되는 일을 원천 차단한다(13 설계 §7.3 · 13-2 설계 §2).
 * `n` 은 프롬프트의 `[n]` 과 같은 번호다.
 */
export interface Citation {
  n: number;
  path: string;
  startLine: number;
  endLine: number;
  commitSha: string;
}

/** 본문 안의 가장 긴 백틱 열보다 길게 — 청크가 코드 블록을 닫아 절을 깨뜨리지 않게. */
function fenceFor(content: string): string {
  const longest = Math.max(0, ...(content.match(/`+/g) ?? []).map((run) => run.length));
  return '`'.repeat(Math.max(3, longest + 1));
}

/**
 * 청크를 프롬프트의 `## 코드` 절 본문으로 만든다. **순수 함수다** — 결과가
 * 그대로 `promptHash` 의 입력이다. 청크가 없으면 빈 문자열(절을 싣지 않는다).
 */
export function codeSection(chunks: ChunkHit[]): string {
  return chunks
    .map((c, i) => {
      const fence = fenceFor(c.content);
      return `[${i + 1}] ${c.path}:${c.startLine}-${c.endLine}\n${fence}${c.lang ?? ''}\n${c.content}\n${fence}`;
    })
    .join('\n\n');
}

export function citationsOf(chunks: ChunkHit[]): Citation[] {
  return chunks.map((c, i) => ({
    n: i + 1,
    path: c.path,
    startLine: c.startLine,
    endLine: c.endLine,
    commitSha: c.commitSha,
  }));
}
