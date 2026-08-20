import { createHmac } from 'crypto';
import { signState, STATE_TTL_SECONDS, verifyState } from './oauth-state';

const SECRET = 'test-secret-at-least-32-characters-long!!';
const USER = '11111111-2222-3333-4444-555555555555';
const NOW = 1_760_000_000_000;

/** 서명은 진짜로 하되 payload 만 우리가 정한다. */
function forge(payload: object, secret = SECRET): string {
  const body = Buffer.from(JSON.stringify(payload), 'utf8').toString('base64url');
  const mac = createHmac('sha256', secret).update(body).digest('base64url');
  return `${body}.${mac}`;
}

describe('oauth-state', () => {
  it('서명한 state 에서 userId 를 되찾는다', () => {
    expect(verifyState(signState(USER, SECRET, NOW), SECRET, NOW)).toBe(USER);
  });

  it('두 번 만들면 값이 다르다', () => {
    // nonce 때문이다. 저장하지 않으므로 일회용을 강제하지는 않는다.
    expect(signState(USER, SECRET, NOW)).not.toBe(signState(USER, SECRET, NOW));
  });

  it('다른 시크릿으로 서명한 것을 거부한다', () => {
    expect(verifyState(signState(USER, 'another-secret-value-32-chars-min!!', NOW), SECRET, NOW)).toBeNull();
  });

  it('본문을 고치면 거부한다', () => {
    const state = signState(USER, SECRET, NOW);
    const [body, mac] = state.split('.');
    const swapped = Buffer.from(
      JSON.stringify({ u: 'victim', p: 'github_oauth', n: 'x', e: NOW / 1000 + 60 }),
      'utf8',
    ).toString('base64url');

    expect(verifyState(`${swapped}.${mac}`, SECRET, NOW)).toBeNull();
    expect(body.length).toBeGreaterThan(0);
  });

  it('만료된 state 를 거부한다', () => {
    const state = signState(USER, SECRET, NOW);
    const later = NOW + (STATE_TTL_SECONDS + 1) * 1000;

    expect(verifyState(state, SECRET, later)).toBeNull();
  });

  it('용도가 다른 토큰을 거부한다', () => {
    // purpose 를 안 보면, 같은 시크릿으로 서명된 다른 토큰을 state 자리에
    // 밀어 넣는 공격이 성립한다.
    const other = forge({ u: USER, p: 'password_reset', n: 'x', e: NOW / 1000 + 60 });

    expect(verifyState(other, SECRET, NOW)).toBeNull();
  });

  it('userId 가 비었으면 거부한다', () => {
    expect(verifyState(forge({ u: '', p: 'github_oauth', n: 'x', e: NOW / 1000 + 60 }), SECRET, NOW)).toBeNull();
  });

  it('빈 값 · 쓰레기 문자열을 거부한다', () => {
    expect(verifyState(null, SECRET, NOW)).toBeNull();
    expect(verifyState(undefined, SECRET, NOW)).toBeNull();
    expect(verifyState('', SECRET, NOW)).toBeNull();
    expect(verifyState('점이없는문자열', SECRET, NOW)).toBeNull();
  });
});
