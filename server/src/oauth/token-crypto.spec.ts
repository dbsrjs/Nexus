import { decryptToken, encryptToken } from './token-crypto';

const KEY = Buffer.alloc(32, 3);
const OTHER_KEY = Buffer.alloc(32, 9);
const TOKEN = 'gho_1234567890abcdefghijklmnopqrstuvwxyz';

describe('token-crypto', () => {
  it('암호화한 것을 그대로 되돌린다', () => {
    expect(decryptToken(encryptToken(TOKEN, KEY), KEY)).toBe(TOKEN);
  });

  it('평문이 결과 어디에도 남지 않는다', () => {
    expect(encryptToken(TOKEN, KEY)).not.toContain('gho_');
  });

  it('같은 값을 두 번 암호화하면 결과가 다르다', () => {
    // IV 를 매번 새로 뽑기 때문이다. 같으면 같은 토큰을 쓰는 두 사용자를
    // DB 만 보고 알 수 있다.
    expect(encryptToken(TOKEN, KEY)).not.toBe(encryptToken(TOKEN, KEY));
  });

  it('다른 키로는 못 읽는다 — null 이지 예외가 아니다', () => {
    // 키를 바꾸면 옛 토큰을 못 읽는다. 그때 500 을 내면 사용자가 할 수 있는
    // 일이 없다 — "다시 연결해 주세요"로 떨어뜨린다.
    expect(decryptToken(encryptToken(TOKEN, KEY), OTHER_KEY)).toBeNull();
  });

  it('한 글자만 변조해도 null 이다', () => {
    const packed = encryptToken(TOKEN, KEY);
    const tampered = packed.slice(0, -1) + (packed.endsWith('A') ? 'B' : 'A');

    expect(decryptToken(tampered, KEY)).toBeNull();
  });

  it('형식이 아니면 null 이다', () => {
    expect(decryptToken('', KEY)).toBeNull();
    expect(decryptToken('gho_평문이_그냥_들어온_경우', KEY)).toBeNull();
    expect(decryptToken('v2.a.b.c', KEY)).toBeNull();
  });
});
