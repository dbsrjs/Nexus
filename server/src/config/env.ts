import { ConfigService } from '@nestjs/config';

/**
 * 환경변수 읽기의 공용 조각. 설정 파일마다(`oauth` · `llm` · `embedding` · CORS) 같은 함수를
 * 따로 들고 있었다 — 한 곳만 고치면 나머지가 옛 규칙으로 남는다.
 */

/**
 * 빈 문자열을 미설정으로 친다. `.env` 에 `X=` 로 자리만 잡아 둔 경우가 있다.
 * **`??` 로 기본값을 붙이면 안 된다** — 빈 문자열이 그대로 통과한다(CLAUDE.md §2).
 */
export function envTrimmed(config: ConfigService, key: string): string | null {
  return config.get<string>(key)?.trim() || null;
}

/** 0 이상의 정수. 없거나 숫자가 아니면 `null` — 기본값은 부르는 쪽이 정한다. */
export function envUint(config: ConfigService, key: string): number | null {
  const raw = envTrimmed(config, key);
  return raw && /^\d+$/.test(raw) ? Number(raw) : null;
}

/** `CORS_ORIGINS` — 쉼표로 나눈 오리진 목록. REST(`main.ts`)와 소켓 어댑터가 같이 쓴다. */
export function resolveCorsOrigins(config: ConfigService): string[] {
  return (envTrimmed(config, 'CORS_ORIGINS') ?? '')
    .split(',')
    .map((o) => o.trim())
    .filter(Boolean);
}

/**
 * `TRUST_PROXY` — Express 의 `trust proxy` 값. 비우면 끈다(직접 받는 개발 서버).
 *
 * 리버스 프록시(Cloudflare Tunnel 의 cloudflared · nginx) 뒤에서 이것을 켜지 않으면
 * `req.ip` 가 언제나 프록시 주소다 — 로그인 시도 제한(IP + 이메일)이 **모든 사람을 한
 * IP 로** 세어, 한 사람의 오타가 남의 로그인을 막는다.
 *
 * **`true` 는 받지 않는다.** 모든 홉을 믿으면 직접 닿은 사람이 `X-Forwarded-For` 를 지어내
 * 시도 제한을 피한다. 홉 수(`1`)나 신뢰할 주소 목록(`loopback` · `uniquelocal` · CIDR)을 쓴다.
 */
export function resolveTrustProxy(config: ConfigService): number | string | null {
  const raw = envTrimmed(config, 'TRUST_PROXY');
  if (!raw) return null;
  if (/^\d+$/.test(raw)) return Number(raw);
  if (raw === 'true' || raw === '*') {
    throw new Error(
      'TRUST_PROXY=true 는 받지 않습니다 — 홉 수(1)나 주소 목록(loopback, uniquelocal)을 쓰십시오',
    );
  }
  return raw;
}
