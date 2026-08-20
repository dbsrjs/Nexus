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

  describe('한 글자만 변조해도 null 이다', () => {
    // 각 파트의 "마지막 글자"를 바꾸는 방식은 쓰지 않는다. base64url 은
    // 3바이트씩 묶어 4글자로 인코딩하는데, 원문 바이트 수를 3으로 나눈
    // 나머지가 1이면(IV 12바이트는 나머지 0이라 안전하지만, GCM 태그
    // 16바이트와 이 테스트의 40바이트 토큰이 만드는 암호문은 나머지가 1이다)
    // 마지막 글자는 유효 비트가 2개뿐이고 나머지 4비트는 항상 0으로 채우는
    // 패딩이다. 그 결과 마지막 글자로 나올 수 있는 값은 base64url 알파벳
    // 64개 중 'A' · 'Q' · 'g' · 'w' 넷뿐이고, 그중 'A' 는 패딩 비트가 전부
    // 0인 값이라 'A' → 'B' 로 바꿔도 디코더가 패딩 비트를 무시해 원래
    // 바이트와 완전히 같게 디코딩된다(`Buffer.from('AAAAA','base64url')
    // .equals(Buffer.from('AAAAB','base64url'))` 가 `true`). 그래서 마지막
    // 글자가 'A' 로 끝나는 25% 의 경우 변조가 일어나지 않아 이 테스트가
    // 흔들렸다(8회 중 2회 실패 재현됨). **첫 글자는 이런 패딩 문제가 없다**
    // — 언제나 그 3바이트(또는 나머지) 묶음의 최상위 6비트를 그대로 담으므로,
    // 다른 글자로 바꾸면 반드시 다른 바이트가 된다. 그래서 아래는 전부
    // 각 파트의 첫 글자를 결정론적으로 바꾼다.
    function tamperFirstChar(value: string): string {
      return (value[0] === 'A' ? 'B' : 'A') + value.slice(1);
    }

    it('암호문을 변조하면 null 이다', () => {
      const packed = encryptToken(TOKEN, KEY);
      const [version, iv, tag, ciphertext] = packed.split('.');
      const tampered = [version, iv, tag, tamperFirstChar(ciphertext)].join('.');

      expect(decryptToken(tampered, KEY)).toBeNull();
    });

    it('인증 태그를 변조하면 null 이다', () => {
      const packed = encryptToken(TOKEN, KEY);
      const [version, iv, tag, ciphertext] = packed.split('.');
      const tampered = [version, iv, tamperFirstChar(tag), ciphertext].join('.');

      expect(decryptToken(tampered, KEY)).toBeNull();
    });

    it('IV 를 변조하면 null 이다', () => {
      const packed = encryptToken(TOKEN, KEY);
      const [version, iv, tag, ciphertext] = packed.split('.');
      const tampered = [version, tamperFirstChar(iv), tag, ciphertext].join('.');

      expect(decryptToken(tampered, KEY)).toBeNull();
    });
  });

  it('형식이 아니면 null 이다', () => {
    expect(decryptToken('', KEY)).toBeNull();
    expect(decryptToken('gho_평문이_그냥_들어온_경우', KEY)).toBeNull();
    expect(decryptToken('v2.a.b.c', KEY)).toBeNull();
  });
});
