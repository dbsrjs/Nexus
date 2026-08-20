import { ConfigService } from '@nestjs/config';
import { resolveGithubOauth, resolveOauthTokenKey } from './oauth.config';

function fakeConfig(values: Record<string, string>): ConfigService {
  return { get: (key: string) => values[key] } as unknown as ConfigService;
}

const KEY_32 = Buffer.alloc(32, 7).toString('base64url');

const FULL = {
  GITHUB_CLIENT_ID: 'Iv1.abc',
  GITHUB_CLIENT_SECRET: 'secret',
  GITHUB_CALLBACK_URL: 'http://localhost:3000/api/auth/github/callback',
};

describe('resolveGithubOauth', () => {
  it('값이 다 있으면 설정을 준다', () => {
    expect(resolveGithubOauth(fakeConfig(FULL))).toEqual({
      ...{ clientId: 'Iv1.abc', clientSecret: 'secret' },
      callbackUrl: 'http://localhost:3000/api/auth/github/callback',
      oauthBase: 'https://github.com',
      apiBase: 'https://api.github.com',
    });
  });

  it('base 를 덮어쓸 수 있다 — 검증이 가짜 GitHub 을 물린다', () => {
    const cfg = resolveGithubOauth(
      fakeConfig({
        ...FULL,
        GITHUB_OAUTH_BASE: 'http://127.0.0.1:4599',
        GITHUB_API_BASE: 'http://127.0.0.1:4599/api',
      }),
    );

    expect(cfg?.oauthBase).toBe('http://127.0.0.1:4599');
    expect(cfg?.apiBase).toBe('http://127.0.0.1:4599/api');
  });

  it('하나라도 없으면 null 이다 — 부팅을 막지 않는다', () => {
    expect(resolveGithubOauth(fakeConfig({}))).toBeNull();
    const { GITHUB_CLIENT_SECRET: _drop, ...missing } = FULL;
    expect(resolveGithubOauth(fakeConfig(missing))).toBeNull();
  });

  it('빈 문자열을 미설정으로 친다', () => {
    // .env 에 자리만 잡아 둔 경우다. 8-1 에서 STORAGE_LOCAL_DIR= 로 겪었다.
    expect(resolveGithubOauth(fakeConfig({ ...FULL, GITHUB_CLIENT_ID: '  ' }))).toBeNull();
  });
});

describe('resolveOauthTokenKey', () => {
  it('32바이트 base64url 을 Buffer 로 준다', () => {
    expect(resolveOauthTokenKey(fakeConfig({ OAUTH_TOKEN_KEY: KEY_32 }))?.length).toBe(32);
  });

  it('없으면 null 이다 — 저장소를 안 쓰는 사람까지 부팅을 막을 이유가 없다', () => {
    expect(resolveOauthTokenKey(fakeConfig({}))).toBeNull();
    expect(resolveOauthTokenKey(fakeConfig({ OAUTH_TOKEN_KEY: '' }))).toBeNull();
  });

  it('길이가 틀리면 던진다 — 없는 것과 잘못된 것은 다르다', () => {
    const short = Buffer.alloc(16, 1).toString('base64url');
    expect(() => resolveOauthTokenKey(fakeConfig({ OAUTH_TOKEN_KEY: short }))).toThrow(
      /32바이트/,
    );
  });
});
