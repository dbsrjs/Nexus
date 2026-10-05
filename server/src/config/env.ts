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
