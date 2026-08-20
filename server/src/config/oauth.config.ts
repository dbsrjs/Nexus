import { ConfigService } from '@nestjs/config';

/**
 * GitHub OAuth 설정의 **유일한 해석 지점**. `jwt.config.ts` 와 같은 역할이다
 * (docs/superpowers/specs/2026-08-20-github-oauth-design.md §8).
 */
export interface GithubOauthConfig {
  clientId: string;
  clientSecret: string;
  /** 브라우저가 돌아오는 주소. localhost 로 둬도 된다. */
  callbackUrl: string;
  /** authorize · token 교환. 검증에서 가짜 GitHub 으로 돌린다. */
  oauthBase: string;
  /** REST API. GHE 를 위해 GitHub 자신이 가진 개념이다. */
  apiBase: string;
}

const KEY_BYTES = 32;

/** 빈 문자열을 미설정으로 친다. `.env` 에 자리만 잡아 둔 경우가 있다. */
function trimmed(config: ConfigService, key: string): string | null {
  return config.get<string>(key)?.trim() || null;
}

export function resolveGithubOauth(
  config: ConfigService,
): GithubOauthConfig | null {
  const clientId = trimmed(config, 'GITHUB_CLIENT_ID');
  const clientSecret = trimmed(config, 'GITHUB_CLIENT_SECRET');
  const callbackUrl = trimmed(config, 'GITHUB_CALLBACK_URL');

  // 하나라도 없으면 연결 기능만 꺼진다. 부팅은 막지 않는다 — OAuth 가 없어도
  // 대화 · 이슈 · 첨부는 전부 돈다.
  if (!clientId || !clientSecret || !callbackUrl) return null;

  return {
    clientId,
    clientSecret,
    callbackUrl,
    oauthBase: trimmed(config, 'GITHUB_OAUTH_BASE') ?? 'https://github.com',
    apiBase: trimmed(config, 'GITHUB_API_BASE') ?? 'https://api.github.com',
  };
}

/**
 * 토큰 암호화 키. 없으면 `null` 이고 연결 시도만 503 이 된다.
 *
 * **길이가 틀리면 던진다.** 없는 것은 "이 기능을 안 쓴다"이지만 잘못된 것은
 * 설정 실수라, 조용히 넘기면 연결이 되는 줄 알고 쓰다가 나중에 깨진다.
 */
export function resolveOauthTokenKey(config: ConfigService): Buffer | null {
  const raw = trimmed(config, 'OAUTH_TOKEN_KEY');
  if (!raw) return null;

  const key = Buffer.from(raw, 'base64url');
  if (key.length !== KEY_BYTES) {
    throw new Error(
      `OAUTH_TOKEN_KEY 는 base64url 로 인코딩한 ${KEY_BYTES}바이트여야 합니다 (지금 ${key.length}바이트).\n` +
        '  생성: node -e "console.log(require(\'crypto\').randomBytes(32).toString(\'base64url\'))"',
    );
  }
  return key;
}
