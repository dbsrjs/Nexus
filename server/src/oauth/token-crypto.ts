import { createCipheriv, createDecipheriv, randomBytes } from 'crypto';

/**
 * provider 토큰을 애플리케이션 레벨에서 암호화한다 (schema.prisma 의
 * `oauth_accounts.access_token` 주석 · 백엔드 설계 §7.3).
 *
 * DB 덤프 하나가 곧 남의 저장소 접근권이 되지 않게 하는 것이 목적이다.
 */
const VERSION = 'v1';
const IV_BYTES = 12; // GCM 권장값
const ALGORITHM = 'aes-256-gcm';

export function encryptToken(plain: string, key: Buffer): string {
  const iv = randomBytes(IV_BYTES);
  const cipher = createCipheriv(ALGORITHM, key, iv);
  const ciphertext = Buffer.concat([cipher.update(plain, 'utf8'), cipher.final()]);

  return [
    VERSION,
    iv.toString('base64url'),
    cipher.getAuthTag().toString('base64url'),
    ciphertext.toString('base64url'),
  ].join('.');
}

/**
 * **실패하면 던지지 않고 `null` 을 준다.** 키 교체 · 변조 · 형식 불일치가
 * 전부 같은 결론으로 모인다 — 그 토큰은 못 쓴다. 호출부는 이것을
 * "연결이 없다"로 취급한다.
 */
export function decryptToken(packed: string, key: Buffer): string | null {
  const parts = packed.split('.');
  if (parts.length !== 4 || parts[0] !== VERSION) return null;

  const [, iv, tag, ciphertext] = parts;
  try {
    const decipher = createDecipheriv(ALGORITHM, key, Buffer.from(iv, 'base64url'));
    const decrypted = Buffer.concat([
      decipher.update(Buffer.from(ciphertext, 'base64url')),
    ]);
    decipher.setAuthTag(Buffer.from(tag, 'base64url'));
    const final = decipher.final();

    return Buffer.concat([decrypted, final]).toString('utf8');
  } catch {
    // GCM 태그가 안 맞으면 final() 이 던진다. 그것이 곧 "못 읽는다"다.
    return null;
  }
}
