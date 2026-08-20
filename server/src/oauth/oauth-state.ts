import { createHmac, randomBytes, timingSafeEqual } from 'crypto';

/**
 * CSRF 방어용 `state`. **저장하지 않고 서명한다**
 * (docs/superpowers/specs/2026-08-20-github-oauth-design.md §3).
 *
 * Redis 가 없고, DB 에 5분짜리 행을 만들면 청소가 숙제로 남는다. 콜백은
 * `@Public()` 이라 요청자가 누구인지 알 방법이 이 값 말고는 없다.
 *
 * 대가: 무상태라 일회용을 강제하지 못한다. 다만 `code` 와 함께 와야 하고
 * GitHub 이 `code` 재사용을 거부하므로 두 번째는 토큰 교환에서 실패한다.
 */
export const STATE_TTL_SECONDS = 300;

/** 이 값이 없으면 같은 시크릿으로 서명된 다른 토큰이 state 로 통한다. */
const PURPOSE = 'github_oauth';

interface StatePayload {
  u: string;
  p: string;
  n: string;
  /** 만료 (epoch 초) */
  e: number;
}

export function signState(userId: string, secret: string, now = Date.now()): string {
  const payload: StatePayload = {
    u: userId,
    p: PURPOSE,
    // 같은 사용자가 연달아 시작해도 값이 겹치지 않게 한다. 저장하지 않으므로
    // 일회용을 강제하는 장치는 아니다.
    n: randomBytes(9).toString('base64url'),
    e: Math.floor(now / 1000) + STATE_TTL_SECONDS,
  };

  const body = Buffer.from(JSON.stringify(payload), 'utf8').toString('base64url');
  return `${body}.${mac(body, secret)}`;
}

/** 성공하면 `userId`, 아니면 `null`. 왜 실패했는지는 밖으로 내지 않는다. */
export function verifyState(
  state: string | null | undefined,
  secret: string,
  now = Date.now(),
): string | null {
  if (!state) return null;

  const [body, signature] = state.split('.');
  if (!body || !signature) return null;

  const expected = Buffer.from(mac(body, secret), 'utf8');
  const received = Buffer.from(signature, 'utf8');
  // timingSafeEqual 은 길이가 다르면 던진다.
  if (expected.length !== received.length) return null;
  if (!timingSafeEqual(expected, received)) return null;

  let payload: StatePayload;
  try {
    payload = JSON.parse(Buffer.from(body, 'base64url').toString('utf8')) as StatePayload;
  } catch {
    return null;
  }

  if (payload.p !== PURPOSE) return null;
  if (typeof payload.u !== 'string' || !payload.u) return null;
  if (typeof payload.e !== 'number' || payload.e * 1000 <= now) return null;

  return payload.u;
}

function mac(body: string, secret: string): string {
  return createHmac('sha256', secret).update(body).digest('base64url');
}
