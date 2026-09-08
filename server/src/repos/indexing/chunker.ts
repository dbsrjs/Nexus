/**
 * 청크 하나. 줄 번호는 **1부터, 양끝 포함**이다 — `repo_index_chunks` 의
 * `start_line` · `end_line` 이 그 뜻이다.
 */
export interface Chunk {
  startLine: number;
  endLine: number;
  content: string;
}

/**
 * 한 청크의 줄 수.
 *
 * 이 코드베이스에서 함수 하나에 앞뒤 맥락이 붙는 크기이고, 긴 줄을 감안해도
 * `gemini-embedding-001` 의 **2,048 토큰 한도 아래**로 들어온다. 약한 쪽에
 * 맞춰야 provider 를 갈아탈 때 청크 크기를 다시 정하지 않는다 (설계 §5).
 */
export const CHUNK_LINES = 60;

/**
 * 겹치는 줄 수. 겹침이 없으면 경계에 걸친 코드가 **어느 청크에서도 완결되지
 * 않는다.** 이 값이 그것을 막는 최소값이다.
 */
export const CHUNK_OVERLAP = 10;

/**
 * 줄 수와 **별도로** 두는 문자 상한. 압축된 파일은 200KB 짜리 한 줄이 나온다 —
 * 줄 수만으로 자르면 그런 파일이 토큰 한도를 통째로 넘긴다.
 */
export const CHUNK_MAX_CHARS = 4000;

/** 빈 줄을 찾아볼 범위. 이보다 멀리 당기면 청크가 들쭉날쭉해진다. */
const SNAP_WINDOW = 5;

export function chunkText(text: string): Chunk[] {
  if (text.trim() === '') return [];

  // **CRLF 를 먼저 턴다.** GitHub 이 주는 본문에 CRLF 가 섞여 있고, 남겨 두면
  // 청크 내용 끝마다 \r 이 붙어 임베딩과 표시가 함께 지저분해진다.
  const lines = text.replace(/\r\n?/g, '\n').split('\n');

  const chunks: Chunk[] = [];
  let i = 0;

  while (i < lines.length) {
    // 한 줄이 혼자 상한을 넘으면 그 줄 안에서 자른다. 그런 줄은 사람이 쓴
    // 코드가 아니지만, 그렇다고 내용을 버릴 이유는 없다.
    if (lines[i].length > CHUNK_MAX_CHARS) {
      for (let at = 0; at < lines[i].length; at += CHUNK_MAX_CHARS) {
        chunks.push({
          startLine: i + 1,
          endLine: i + 1,
          content: lines[i].slice(at, at + CHUNK_MAX_CHARS),
        });
      }
      i += 1;
      continue;
    }

    // end 는 **제외 인덱스**다.
    let end = Math.min(i + CHUNK_LINES, lines.length);

    // 문자 상한. 줄 수가 남아도 여기서 끊는다.
    let chars = 0;
    for (let k = i; k < end; k++) {
      // +1 은 줄바꿈. 첫 줄은 앞에 줄바꿈이 없다.
      const next = chars + lines[k].length + (k > i ? 1 : 0);
      if (next > CHUNK_MAX_CHARS && k > i) {
        end = k;
        break;
      }
      chars = next;
    }

    // 빈 줄이 경계 근처에 있으면 거기서 끊는다. **파서가 아니라 보정이다** —
    // 문장 중간에서 잘리는 것을 자주 막아 주고, 못 찾으면 그냥 넘어간다.
    if (end < lines.length) {
      for (let k = end - 1; k >= Math.max(i + 1, end - SNAP_WINDOW); k--) {
        if (lines[k].trim() === '') {
          end = k;
          break;
        }
      }
    }

    const content = lines.slice(i, end).join('\n');
    // 공백뿐인 청크는 임베딩할 값이 없다.
    if (content.trim() !== '') {
      chunks.push({ startLine: i + 1, endLine: end, content });
    }

    if (end >= lines.length) break;
    // **반드시 전진한다.** 겹침이 청크 길이보다 커지는 경우(문자 상한으로 짧게
    // 끊긴 청크)에 i 가 제자리에 머물면 무한 루프가 된다.
    i = Math.max(i + 1, end - CHUNK_OVERLAP);
  }

  return chunks;
}
