/**
 * 파일 본문을 내려보낼지 정한다.
 *
 * **세 가지 생략을 구분하는 이유는 사용자가 할 수 있는 일이 다르기 때문이다**
 * (설계 §2) — 바이너리는 영영 못 보고, 큰 파일은 GitHub 에서 열면 되고,
 * `unavailable` 은 나중에 폴백을 붙이면 풀린다.
 */
export type OmitReason = 'binary' | 'too_large' | 'unavailable';

export interface BlobBody {
  content: string | null;
  omitted: OmitReason | null;
}

/**
 * 우리 임계값. GitHub 의 1MB 보다 낮은 이유는 그만한 텍스트를 앱이 받아
 * 그리는 것이 이미 무의미하기 때문이다 — 등폭으로 그리면 만 줄이 넘는다.
 */
export const MAX_BLOB_BYTES = 512 * 1024;

export function resolveBlobBody(base64: string | null, size: number): BlobBody {
  // **우리가 자른 것을 GitHub 탓으로 돌리지 않는다.** 둘 다 해당하면
  // too_large 가 먼저다.
  if (size > MAX_BLOB_BYTES) return { content: null, omitted: 'too_large' };
  if (base64 === null) return { content: null, omitted: 'unavailable' };

  const bytes = Buffer.from(base64, 'base64');

  // 디코딩 결과가 임계값을 넘는 경우도 막는다 — `size` 는 GitHub 이 준 값이라
  // 어긋날 수 있고, 믿을 것은 실제로 받은 바이트다.
  if (bytes.byteLength > MAX_BLOB_BYTES) {
    return { content: null, omitted: 'too_large' };
  }

  // **확장자로 판별하지 않는다.** 목록은 유지 비용이 끝없이 늘고, 목록에 없는
  // 것이 나올 때마다 고쳐야 한다 (설계 §2).
  if (bytes.includes(0)) return { content: null, omitted: 'binary' };

  const text = bytes.toString('utf8');
  // 치환 문자가 생겼다면 UTF-8 이 아니다. 원문에 U+FFFD 가 있었을 수도 있지만
  // 그건 텍스트 파일에서 사실상 없는 일이고, 있어도 결과는 "못 읽는다"로 같다.
  if (text.includes('�')) return { content: null, omitted: 'binary' };

  return { content: text, omitted: null };
}
