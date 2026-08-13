import { ConfigService } from '@nestjs/config';

/**
 * JWT 시크릿·수명의 **유일한 해석 지점**.
 *
 * 이전 구조는 auth.module · jwt.strategy · realtime.gateway 세 곳이 각자
 * `config.get('JWT_SECRET') ?? 'dev-insecure-secret'` 식으로 시크릿을 읽었다.
 * 폴백 문자열이 서로 달라, JWT_SECRET 을 설정하지 않으면 REST 는 뜨는데
 * 소켓만 전부 인증 실패하는 상태가 만들어졌다 (docs/전환-계획.md §3.5-1).
 *
 * 해석을 여기 하나로 모으고 **하드코딩 폴백을 없앤다.** 미설정이면 부팅을
 * 중단시킨다 — 조용히 약한 키로 뜨는 것보다 낫다 (docs/백엔드-설계.md §6).
 */
export interface JwtSecrets {
  accessSecret: string;
  refreshSecret: string;
  accessTtl: string;
  refreshTtl: string;
}

const MIN_SECRET_LENGTH = 32;

export function resolveJwtSecrets(config: ConfigService): JwtSecrets {
  const accessSecret = config.get<string>('JWT_SECRET')?.trim();

  if (!accessSecret) {
    throw new Error(
      'JWT_SECRET 이 설정되지 않았습니다. .env.example 을 참고해 값을 채우십시오.\n' +
        '  생성: node -e "console.log(require(\'crypto\').randomBytes(48).toString(\'base64url\'))"',
    );
  }

  if (accessSecret.length < MIN_SECRET_LENGTH) {
    throw new Error(
      `JWT_SECRET 이 너무 짧습니다 (${accessSecret.length}자). ${MIN_SECRET_LENGTH}자 이상을 쓰십시오.`,
    );
  }

  // 리프레시 시크릿을 분리하면 액세스 토큰 시크릿이 유출돼도 리프레시 토큰까지
  // 위조되지는 않는다. 미설정 시에는 액세스 시크릿을 재사용한다(폴백 상수가 아니다).
  const refreshSecret =
    config.get<string>('JWT_REFRESH_SECRET')?.trim() || accessSecret;

  return {
    accessSecret,
    refreshSecret,
    accessTtl: config.get<string>('JWT_EXPIRES_IN')?.trim() || '15m',
    refreshTtl: config.get<string>('JWT_REFRESH_EXPIRES_IN')?.trim() || '7d',
  };
}
