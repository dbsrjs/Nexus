import { createHmac, timingSafeEqual } from 'crypto';

const PREFIX = 'sha256=';

/**
 * GitHub 이 `X-Hub-Signature-256` 에 넣는 형식으로 서명한다.
 *
 * 검증 스크립트가 GitHub 없이 요청을 만들 때도 쓴다 — 서명을 우리가 만들 수
 * 있으므로 웹훅 전체를 로컬에서 검증할 수 있다.
 */
export function signPayload(body: Buffer, secret: string): string {
  return PREFIX + createHmac('sha256', secret).update(body).digest('hex');
}

/**
 * 웹훅 서명을 검증한다. **여기가 곧 인증이다** — 부르는 쪽이 GitHub 이라
 * JWT 를 요구할 수 없다. 뚫리면 아무나 채널에 메시지를 넣을 수 있다.
 *
 * `body` 는 **원문 바이트**여야 한다. 파싱된 객체를 다시 직렬화해 계산하면
 * 키 순서 · 공백 · 유니코드 이스케이프가 달라져 멀쩡한 요청이 위조로 판정된다.
 */
export function verifySignature(
  body: Buffer,
  signature: string | null | undefined,
  secret: string,
): boolean {
  if (!signature || !signature.toLowerCase().startsWith(PREFIX)) return false;

  const expected = Buffer.from(signPayload(body, secret), 'utf8');
  const received = Buffer.from(signature.toLowerCase(), 'utf8');

  // timingSafeEqual 은 길이가 다르면 던진다. 그 예외가 500 이 되면 길이가
  // 응답으로 새 나가고, 무엇보다 서버 로그가 시끄러워진다.
  if (expected.length !== received.length) return false;

  // 문자열 `===` 는 앞에서 몇 글자가 맞았는지가 비교 시간으로 새 나간다.
  return timingSafeEqual(expected, received);
}
