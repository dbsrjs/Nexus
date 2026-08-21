import { MAX_BLOB_BYTES, resolveBlobBody } from './blob-content';

/** GitHub 이 주는 모양대로 base64 로 만든다. */
function b64(input: string | Buffer): string {
  return Buffer.from(input).toString('base64');
}

describe('resolveBlobBody', () => {
  it('텍스트는 본문을 그대로 준다', () => {
    const result = resolveBlobBody(b64('const a = 1;\n'), 13);

    expect(result.content).toBe('const a = 1;\n');
    expect(result.omitted).toBeNull();
  });

  it('빈 파일도 본문이다 — 생략이 아니다', () => {
    // 0바이트 파일은 "볼 수 없는 것"이 아니라 "비어 있는 것"이다.
    const result = resolveBlobBody(b64(''), 0);

    expect(result.content).toBe('');
    expect(result.omitted).toBeNull();
  });

  it('NUL 이 있으면 바이너리다', () => {
    const result = resolveBlobBody(b64(Buffer.from([0x89, 0x50, 0x00, 0x01])), 4);

    expect(result.content).toBeNull();
    expect(result.omitted).toBe('binary');
  });

  it('UTF-8 로 읽히지 않으면 바이너리다', () => {
    // 0xFF 는 UTF-8 에 나올 수 없는 바이트다.
    const result = resolveBlobBody(b64(Buffer.from([0xff, 0xfe, 0x41])), 3);

    expect(result.omitted).toBe('binary');
  });

  it('한글은 바이너리가 아니다', () => {
    // UTF-8 다바이트 문자를 바이너리로 오인하면 한국어 문서를 못 연다.
    const result = resolveBlobBody(b64('안녕하세요\n'), 16);

    expect(result.content).toBe('안녕하세요\n');
    expect(result.omitted).toBeNull();
  });

  it('임계값을 넘으면 too_large — 본문이 와도 싣지 않는다', () => {
    const big = 'a'.repeat(MAX_BLOB_BYTES + 1);
    const result = resolveBlobBody(b64(big), big.length);

    expect(result.content).toBeNull();
    expect(result.omitted).toBe('too_large');
  });

  it('임계값과 같으면 통과한다 — 경계는 넘을 때만 자른다', () => {
    const edge = 'a'.repeat(MAX_BLOB_BYTES);
    const result = resolveBlobBody(b64(edge), edge.length);

    expect(result.omitted).toBeNull();
  });

  it('임계값 안인데 본문이 없으면 unavailable', () => {
    // **1MB 초과는 여기로 오지 않는다** — 우리 임계값(512KB)에 먼저 걸려
    // too_large 가 된다. 이 갈래는 GitHub 이 작은 파일의 본문을 생략하는
    // 예상 밖의 경우를 위한 방어다. 없으면 화면이 "빈 파일"로 오해한다.
    const result = resolveBlobBody(null, 1000);

    expect(result.content).toBeNull();
    expect(result.omitted).toBe('unavailable');
  });

  it('임계값 초과가 unavailable 보다 먼저다', () => {
    // 둘 다 해당할 때, 우리가 자른 것을 GitHub 탓으로 돌리지 않는다.
    const result = resolveBlobBody(null, MAX_BLOB_BYTES + 1);

    expect(result.omitted).toBe('too_large');
  });

  it('size 가 작다고 해도 실제 바이트가 크면 자른다', () => {
    // size 는 GitHub 이 준 값이라 어긋날 수 있다. 믿을 것은 받은 바이트다.
    const big = 'a'.repeat(MAX_BLOB_BYTES + 1);
    const result = resolveBlobBody(b64(big), 10);

    expect(result.omitted).toBe('too_large');
  });
});
