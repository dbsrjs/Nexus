import { chunkText, CHUNK_LINES, CHUNK_OVERLAP, CHUNK_MAX_CHARS } from './chunker';

/** n 줄짜리 텍스트. 각 줄이 자기 번호를 담아 경계를 눈으로 확인할 수 있다. */
function lines(n: number, width = 10): string {
  return Array.from({ length: n }, (_, i) => `L${i + 1}`.padEnd(width, 'x')).join('\n');
}

describe('chunkText', () => {
  it('빈 글과 공백뿐인 글은 청크를 만들지 않는다', () => {
    expect(chunkText('')).toEqual([]);
    expect(chunkText('   \n\n  \n')).toEqual([]);
  });

  it('한 청크에 들어가면 통째로 하나다', () => {
    const result = chunkText(lines(10));
    expect(result).toHaveLength(1);
    expect(result[0].startLine).toBe(1);
    expect(result[0].endLine).toBe(10);
  });

  it('줄 번호는 1부터 시작하고 양끝을 포함한다', () => {
    const [first] = chunkText(lines(200));
    expect(first.startLine).toBe(1);
    expect(first.endLine).toBe(CHUNK_LINES);
    expect(first.content.split('\n')).toHaveLength(CHUNK_LINES);
  });

  it('청크가 겹친다 — 경계에 걸린 코드가 한쪽에는 온전히 들어가야 한다', () => {
    const [first, second] = chunkText(lines(200));
    expect(second.startLine).toBe(first.endLine - CHUNK_OVERLAP + 1);
  });

  it('마지막 줄까지 빠짐없이 덮는다', () => {
    const result = chunkText(lines(137));
    expect(result[result.length - 1].endLine).toBe(137);
  });

  it('빈 줄이 경계 근처에 있으면 거기서 끊는다', () => {
    // 58번째 줄을 비워 둔다. 상한(60) 앞 5줄 안이라 여기로 당겨져야 한다.
    const src = Array.from({ length: 200 }, (_, i) => (i === 57 ? '' : `L${i + 1}`)).join('\n');
    const [first] = chunkText(src);
    expect(first.endLine).toBe(57);
  });

  it('문자 상한을 넘으면 줄 수가 남아도 끊는다', () => {
    // 한 줄이 500자. 8줄이면 4000자를 넘는다.
    const wide = Array.from({ length: 40 }, () => 'a'.repeat(500)).join('\n');
    const [first] = chunkText(wide);
    expect(first.content.length).toBeLessThanOrEqual(CHUNK_MAX_CHARS);
    expect(first.endLine).toBeLessThan(CHUNK_LINES);
  });

  it('한 줄이 혼자 상한을 넘으면 그 줄 안에서 자르고 내용을 버리지 않는다', () => {
    const monster = 'z'.repeat(CHUNK_MAX_CHARS * 2 + 7);
    const result = chunkText(monster);
    expect(result.length).toBeGreaterThan(1);
    // 줄이 하나뿐이므로 모든 조각의 줄 번호가 같다.
    expect(result.every((c) => c.startLine === 1 && c.endLine === 1)).toBe(true);
    expect(result.map((c) => c.content).join('')).toBe(monster);
  });

  it('CRLF 를 LF 와 같게 다룬다 — GitHub 본문에 CRLF 가 온다', () => {
    const result = chunkText('a\r\nb\r\nc');
    expect(result[0].content).toBe('a\nb\nc');
    expect(result[0].endLine).toBe(3);
  });

  it('공백뿐인 청크는 버린다', () => {
    // 앞 5줄만 내용이 있고 나머지 300줄이 빈 파일.
    const src = ['a', 'b', 'c', 'd', 'e', ...Array(300).fill('')].join('\n');
    const result = chunkText(src);
    expect(result).toHaveLength(1);
  });
});
