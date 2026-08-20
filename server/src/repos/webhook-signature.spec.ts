import { createHmac } from 'crypto';
import { signPayload, verifySignature } from './webhook-signature';

const SECRET = 'whsec_test_1234567890';
const BODY = Buffer.from('{"zen":"Non-blocking is better than blocking."}');

/**
 * 서명이 곧 인증이다 — 부르는 쪽이 GitHub 이라 JWT 를 요구할 수 없다.
 * 여기가 뚫리면 아무나 채널에 메시지를 넣을 수 있다.
 */
describe('verifySignature', () => {
  it('제대로 서명한 요청을 통과시킨다', () => {
    expect(verifySignature(BODY, signPayload(BODY, SECRET), SECRET)).toBe(true);
  });

  it('본문이 한 글자만 달라도 거부한다', () => {
    const signature = signPayload(BODY, SECRET);
    const tampered = Buffer.from('{"zen":"Blocking is better than blocking."}');

    expect(verifySignature(tampered, signature, SECRET)).toBe(false);
  });

  it('다른 시크릿으로 서명한 것을 거부한다', () => {
    // 저장소마다 시크릿이 다르다. 하나가 새도 다른 저장소는 안전해야 한다.
    const signature = signPayload(BODY, 'whsec_other_secret');

    expect(verifySignature(BODY, signature, SECRET)).toBe(false);
  });

  it('서명이 없으면 거부한다', () => {
    expect(verifySignature(BODY, null, SECRET)).toBe(false);
    expect(verifySignature(BODY, '', SECRET)).toBe(false);
    expect(verifySignature(BODY, undefined, SECRET)).toBe(false);
  });

  it('sha256= 접두사가 없으면 거부한다', () => {
    const raw = createHmac('sha256', SECRET).update(BODY).digest('hex');

    expect(verifySignature(BODY, raw, SECRET)).toBe(false);
  });

  it('길이가 다른 값에 던지지 않고 false 를 준다', () => {
    // timingSafeEqual 은 길이가 다르면 예외를 던진다. 그것이 500 이 되면
    // 공격자가 길이를 알아낼 수 있고, 무엇보다 서버가 시끄러워진다.
    expect(verifySignature(BODY, 'sha256=abc', SECRET)).toBe(false);
    expect(verifySignature(BODY, 'sha256=', SECRET)).toBe(false);
  });

  it('16진수가 아닌 값에도 던지지 않는다', () => {
    expect(verifySignature(BODY, `sha256=${'z'.repeat(64)}`, SECRET)).toBe(false);
  });

  it('대소문자가 달라도 같은 서명으로 본다', () => {
    // GitHub 은 소문자로 보내지만, 손으로 붙여 넣는 사람도 있다.
    const signature = signPayload(BODY, SECRET).toUpperCase();

    expect(verifySignature(BODY, signature, SECRET)).toBe(true);
  });
});

describe('signPayload', () => {
  it('GitHub 형식(sha256=…)으로 만든다', () => {
    expect(signPayload(BODY, SECRET)).toMatch(/^sha256=[0-9a-f]{64}$/);
  });
});
