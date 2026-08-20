# 10-2a GitHub OAuth 연결 구현 계획

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 로그인한 사용자가 자기 계정에 GitHub 을 연결하고, 저장소 화면 상단에 "GitHub 연결됨 @계정" 이 보이게 한다.

**Architecture:** 앱은 시스템 브라우저를 열기만 한다. GitHub 은 서버 콜백(`@Public()`)으로 돌아오고, 서버가 `state` 를 검증해 토큰을 교환·암호화 저장한 뒤 소켓 개인 룸(`user:{userId}`)으로 `oauth:connected` 를 쏜다. 브라우저에는 "닫아도 됩니다" HTML 한 장만 그린다.

**Tech Stack:** NestJS · Prisma · Node `crypto`(AES-256-GCM · HMAC) · Socket.IO · Flutter(Riverpod · go_router · dio · url_launcher)

## Global Constraints

- **설계 스펙은 `docs/superpowers/specs/2026-08-20-github-oauth-design.md`.** 여기서 갈라지면 스펙을 먼저 고친다.
- **주석 · 커밋 메시지 · 문서는 한국어.** 커밋에 `Co-Authored-By: Claude` 를 넣지 않는다.
- **테넌트 격리:** 이 조각의 자원(`oauth_accounts`)은 **사용자 단위**라 `spaceId` 가 없다. 스페이스 밑 라우트를 만들지 않는다.
- **토큰은 어떤 응답에도 실리지 않는다.** 연결 목록은 `provider · login · avatarUrl · connectedAt` 만 준다.
- **`OAUTH_TOKEN_KEY` 가 없으면 부팅은 되고 연결 시도만 503.** 다만 **길이가 틀리면 부팅을 중단**한다 — 없는 것과 잘못된 것은 다르다.
- **빈 문자열은 미설정으로 친다**(`||`, `??` 아님). 8-1 에서 `STORAGE_LOCAL_DIR=` 로 겪었다.
- **새 npm 의존성을 넣지 않는다.** `state` 서명은 Node `crypto` HMAC 으로 직접 만든다(`webhook-signature.ts` 와 같은 idiom).
- **앱 새 의존성은 `url_launcher` 하나.**
- **모델을 고치면 `cd app && dart run build_runner build`** 를 돌리고 `.freezed.dart` · `.g.dart` 를 커밋한다.
- **마이그레이션 없음.** 10-2a 는 스키마를 건드리지 않는다(`webhook_external_id` 는 10-2b).

**검증 명령**

| | |
|---|---|
| 서버 단위 테스트 | `npm --prefix server run test` |
| 한 파일만 | `npm --prefix server run test -- oauth-state` |
| 타입 검사 | `npm --prefix server run typecheck` |
| 린트 | `npm run server:lint` |
| 계약 검증 | `npm run check:oauth` (Task 6 에서 만든다) |
| 앱 | `cd app && flutter analyze && flutter test` |

---

## File Structure

**서버 — 새 모듈 `server/src/oauth/`**

| 파일 | 책임 |
|---|---|
| `src/config/oauth.config.ts` | env 해석의 **유일한 지점**(`jwt.config.ts` 와 같은 역할) |
| `src/oauth/token-crypto.ts` | AES-256-GCM 암복호. 순수 함수 |
| `src/oauth/oauth-state.ts` | `state` 서명·검증. 순수 함수 |
| `src/oauth/github-oauth.client.ts` | GitHub 으로 나가는 HTTP 호출만 |
| `src/oauth/callback-page.ts` | 브라우저에 그릴 HTML 두 장 |
| `src/oauth/oauth.service.ts` | 위 넷을 엮어 DB 에 쓰고 소켓을 쏜다 |
| `src/oauth/oauth.controller.ts` | `/api/me/connections/*` (인증 필요) |
| `src/oauth/oauth-callback.controller.ts` | `/api/auth/github/callback` (`@Public()`) |
| `src/oauth/oauth.module.ts` | 배선 |

컨트롤러를 둘로 나누는 이유는 `repos` 모듈과 같다 — **한쪽은 인증을 지나고 한쪽은 지나지 않는다.** 한 컨트롤러에 섞으면 어느 라우트가 공개인지 읽어서 알 수 없다.

**앱**

| 파일 | 책임 |
|---|---|
| `lib/domain/models/connection.dart` | `GithubConnection`(freezed) |
| `lib/data/api/connections_api.dart` | `start` · `list` · `disconnect` |
| `lib/features/repo/repos_screen.dart` | 저장소 화면 — 10-2a 는 상단 연결 영역만 |
| `lib/features/repo/connection_controller.dart` | 연결 상태 provider + 대기 상태 |

---

## Task 1: 설정 해석 — `OAUTH_TOKEN_KEY` · GitHub OAuth 값

**Files:**
- Create: `server/src/config/oauth.config.ts`
- Test: `server/src/config/oauth.config.spec.ts`
- Modify: `server/.env.example`

**Interfaces:**
- Consumes: `ConfigService` (`@nestjs/config`)
- Produces:
  - `interface GithubOauthConfig { clientId: string; clientSecret: string; callbackUrl: string; oauthBase: string; apiBase: string }`
  - `resolveGithubOauth(config: ConfigService): GithubOauthConfig | null`
  - `resolveOauthTokenKey(config: ConfigService): Buffer | null` — 길이가 틀리면 `throw`

- [ ] **Step 1: 실패하는 테스트를 쓴다**

`server/src/config/oauth.config.spec.ts`:

```ts
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
```

- [ ] **Step 2: 실패를 확인한다**

```bash
npm --prefix server run test -- oauth.config
```

Expected: FAIL — `Cannot find module './oauth.config'`

- [ ] **Step 3: 최소 구현을 쓴다**

`server/src/config/oauth.config.ts`:

```ts
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
```

- [ ] **Step 4: 통과를 확인한다**

```bash
npm --prefix server run test -- oauth.config
```

Expected: PASS (8 tests)

- [ ] **Step 5: `.env.example` 을 갱신한다**

`server/.env.example` 의 `GITHUB_CALLBACK_URL=` 줄 **아래**에 붙인다:

```
# 토큰 암호화 키 (32바이트 base64url). 비우면 GitHub 연결만 503 이 된다.
#   node -e "console.log(require('crypto').randomBytes(32).toString('base64url'))"
OAUTH_TOKEN_KEY=

# 검증 전용. 비우면 진짜 GitHub 을 쓴다 — npm run check:oauth 가 가짜 서버를 물린다.
GITHUB_OAUTH_BASE=
GITHUB_API_BASE=
```

`GITHUB_CALLBACK_URL` 위의 주석에 한 줄 더한다:

```
# 브라우저가 돌아오는 주소다. 웹훅용 PUBLIC_BASE_URL 과 다르다 — 이쪽은 localhost 로 충분하다.
```

- [ ] **Step 6: 커밋**

```bash
git add server/src/config/oauth.config.ts server/src/config/oauth.config.spec.ts server/.env.example
git commit -m "feat(server): OAuth 설정 해석 — 10-2a"
```

---

## Task 2: 토큰 암복호 (AES-256-GCM)

**Files:**
- Create: `server/src/oauth/token-crypto.ts`
- Test: `server/src/oauth/token-crypto.spec.ts`

**Interfaces:**
- Consumes: Task 1 의 `resolveOauthTokenKey` 가 주는 `Buffer`
- Produces:
  - `encryptToken(plain: string, key: Buffer): string` — `v1.{iv}.{tag}.{ct}` (각 부분 base64url)
  - `decryptToken(packed: string, key: Buffer): string | null` — **실패하면 던지지 않고 `null`**

- [ ] **Step 1: 실패하는 테스트를 쓴다**

`server/src/oauth/token-crypto.spec.ts`:

```ts
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
```

- [ ] **Step 2: 실패를 확인한다**

```bash
npm --prefix server run test -- token-crypto
```

Expected: FAIL — `Cannot find module './token-crypto'`

- [ ] **Step 3: 최소 구현을 쓴다**

`server/src/oauth/token-crypto.ts`:

```ts
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
    decipher.setAuthTag(Buffer.from(tag, 'base64url'));

    return Buffer.concat([
      decipher.update(Buffer.from(ciphertext, 'base64url')),
      decipher.final(),
    ]).toString('utf8');
  } catch {
    // GCM 태그가 안 맞으면 final() 이 던진다. 그것이 곧 "못 읽는다"다.
    return null;
  }
}
```

- [ ] **Step 4: 통과를 확인한다**

```bash
npm --prefix server run test -- token-crypto
```

Expected: PASS (6 tests)

- [ ] **Step 5: 커밋**

```bash
git add server/src/oauth/token-crypto.ts server/src/oauth/token-crypto.spec.ts
git commit -m "feat(server): OAuth 토큰 암복호 — 10-2a"
```

---

## Task 3: `state` 서명 · 검증

**Files:**
- Create: `server/src/oauth/oauth-state.ts`
- Test: `server/src/oauth/oauth-state.spec.ts`

**Interfaces:**
- Consumes: `JwtSecrets.accessSecret`(`src/config/jwt.config.ts`)를 서명 비밀로 받는다
- Produces:
  - `signState(userId: string, secret: string, now?: number): string`
  - `verifyState(state: string | null | undefined, secret: string, now?: number): string | null` — 성공하면 `userId`
  - `STATE_TTL_SECONDS: number` (= 300)

`now` 를 인자로 받는 이유는 만료를 테스트에서 시간 조작 없이 태우기 위함이다.

- [ ] **Step 1: 실패하는 테스트를 쓴다**

`server/src/oauth/oauth-state.spec.ts`:

```ts
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
```

- [ ] **Step 2: 실패를 확인한다**

```bash
npm --prefix server run test -- oauth-state
```

Expected: FAIL — `Cannot find module './oauth-state'`

- [ ] **Step 3: 최소 구현을 쓴다**

`server/src/oauth/oauth-state.ts`:

```ts
import { createHmac, randomBytes, timingSafeEqual } from 'crypto';

/**
 * CSRF 방어용 `state`. **저장하지 않고 서명한다**
 * (docs/superpowers/specs/2026-08-20-github-oauth-design.md §3).
 *
 * Redis 가 없고, DB 에 5분짜리 행을 만들면 청소가 숙제로 남는다. 콜백은
 * `@Public()` 이라 요청자가 누구인지 알 방법이 이 값 말고는 없다.
 *
 * 대가: 무상태라 일회용을 강제하지 못한다. 다만 `code` 와 함께 와야 하고
 * GitHub 이 `code` 재사용을 거부하므로 두 번째는 토큰 교환에서 실패한다.
 */
export const STATE_TTL_SECONDS = 300;

/** 이 값이 없으면 같은 시크릿으로 서명된 다른 토큰이 state 로 통한다. */
const PURPOSE = 'github_oauth';

interface StatePayload {
  u: string;
  p: string;
  n: string;
  /** 만료 (epoch 초) */
  e: number;
}

export function signState(userId: string, secret: string, now = Date.now()): string {
  const payload: StatePayload = {
    u: userId,
    p: PURPOSE,
    // 같은 사용자가 연달아 시작해도 값이 겹치지 않게 한다. 저장하지 않으므로
    // 일회용을 강제하는 장치는 아니다.
    n: randomBytes(9).toString('base64url'),
    e: Math.floor(now / 1000) + STATE_TTL_SECONDS,
  };

  const body = Buffer.from(JSON.stringify(payload), 'utf8').toString('base64url');
  return `${body}.${mac(body, secret)}`;
}

/** 성공하면 `userId`, 아니면 `null`. 왜 실패했는지는 밖으로 내지 않는다. */
export function verifyState(
  state: string | null | undefined,
  secret: string,
  now = Date.now(),
): string | null {
  if (!state) return null;

  const [body, signature] = state.split('.');
  if (!body || !signature) return null;

  const expected = Buffer.from(mac(body, secret), 'utf8');
  const received = Buffer.from(signature, 'utf8');
  // timingSafeEqual 은 길이가 다르면 던진다.
  if (expected.length !== received.length) return null;
  if (!timingSafeEqual(expected, received)) return null;

  let payload: StatePayload;
  try {
    payload = JSON.parse(Buffer.from(body, 'base64url').toString('utf8')) as StatePayload;
  } catch {
    return null;
  }

  if (payload.p !== PURPOSE) return null;
  if (typeof payload.u !== 'string' || !payload.u) return null;
  if (typeof payload.e !== 'number' || payload.e * 1000 <= now) return null;

  return payload.u;
}

function mac(body: string, secret: string): string {
  return createHmac('sha256', secret).update(body).digest('base64url');
}
```

- [ ] **Step 4: 통과를 확인한다**

```bash
npm --prefix server run test -- oauth-state
```

Expected: PASS (8 tests)

- [ ] **Step 5: 커밋**

```bash
git add server/src/oauth/oauth-state.ts server/src/oauth/oauth-state.spec.ts
git commit -m "feat(server): OAuth state 서명·검증 — 10-2a"
```

---

## Task 4: GitHub 으로 나가는 호출

**Files:**
- Create: `server/src/oauth/github-oauth.client.ts`

**Interfaces:**
- Consumes: Task 1 의 `GithubOauthConfig`
- Produces (모두 `GithubOauthClient` 의 메서드):
  - `authorizeUrl(cfg: GithubOauthConfig, state: string): string`
  - `exchangeCode(cfg: GithubOauthConfig, code: string): Promise<{ accessToken: string; scope: string | null } | null>`
  - `fetchUser(cfg: GithubOauthConfig, accessToken: string): Promise<{ id: number; login: string; avatarUrl: string | null } | null>`

**단위 테스트를 두지 않는다.** 전부 네트워크 호출이라 스텁으로 덮으면 §6 의 실수를 반복한다 — 이 갈래는 Task 6 의 가짜 GitHub 으로 실제 HTTP 를 태워 검증한다.

- [ ] **Step 1: 구현을 쓴다**

`server/src/oauth/github-oauth.client.ts`:

```ts
import { Injectable, Logger } from '@nestjs/common';
import type { GithubOauthConfig } from '../config/oauth.config';

export interface GithubToken {
  accessToken: string;
  scope: string | null;
}

export interface GithubUser {
  id: number;
  login: string;
  avatarUrl: string | null;
}

/**
 * GitHub 으로 나가는 HTTP 호출만 한다. DB 도 소켓도 모른다.
 *
 * 주소를 `GithubOauthConfig` 에서 받는 이유는 검증 때문이다 — 가짜 GitHub 을
 * 물려야 `check:oauth` 가 진짜 GitHub 없이 돈다 (설계 §10).
 *
 * **실패는 던지지 않고 `null` 로 준다.** 호출부(콜백)가 할 수 있는 일이
 * 오류 페이지를 그리는 것뿐이라, 실패 종류를 나눠도 쓰이지 않는다.
 */
@Injectable()
export class GithubOauthClient {
  private readonly logger = new Logger(GithubOauthClient.name);

  authorizeUrl(cfg: GithubOauthConfig, state: string): string {
    const query = new URLSearchParams({
      client_id: cfg.clientId,
      redirect_uri: cfg.callbackUrl,
      // 비공개 저장소 조회와 웹훅 관리(admin:repo_hook)가 여기 포함된다 (설계 §1).
      scope: 'repo',
      state,
    });

    return `${cfg.oauthBase}/login/oauth/authorize?${query.toString()}`;
  }

  async exchangeCode(cfg: GithubOauthConfig, code: string): Promise<GithubToken | null> {
    try {
      const res = await fetch(`${cfg.oauthBase}/login/oauth/access_token`, {
        method: 'POST',
        headers: {
          'content-type': 'application/json',
          // 없으면 GitHub 이 form 인코딩으로 답한다.
          accept: 'application/json',
        },
        body: JSON.stringify({
          client_id: cfg.clientId,
          client_secret: cfg.clientSecret,
          code,
          redirect_uri: cfg.callbackUrl,
        }),
      });

      const json = (await res.json()) as {
        access_token?: string;
        scope?: string;
        error?: string;
      };

      // GitHub 은 code 재사용·만료에도 **200** 을 주고 body 에 error 를 담는다.
      if (!res.ok || !json.access_token) {
        this.logger.warn(`토큰 교환 실패: ${res.status} ${json.error ?? ''}`);
        return null;
      }

      return { accessToken: json.access_token, scope: json.scope ?? null };
    } catch (err) {
      this.logger.error('토큰 교환 중 오류', err as Error);
      return null;
    }
  }

  async fetchUser(cfg: GithubOauthConfig, accessToken: string): Promise<GithubUser | null> {
    try {
      const res = await fetch(`${cfg.apiBase}/user`, {
        headers: {
          authorization: `Bearer ${accessToken}`,
          accept: 'application/vnd.github+json',
        },
      });

      if (!res.ok) {
        this.logger.warn(`사용자 조회 실패: ${res.status}`);
        return null;
      }

      const json = (await res.json()) as {
        id?: number;
        login?: string;
        avatar_url?: string;
      };
      if (typeof json.id !== 'number' || !json.login) return null;

      return { id: json.id, login: json.login, avatarUrl: json.avatar_url ?? null };
    } catch (err) {
      this.logger.error('사용자 조회 중 오류', err as Error);
      return null;
    }
  }
}
```

- [ ] **Step 2: 타입 검사로 확인한다**

```bash
npm --prefix server run typecheck
```

Expected: 오류 없음 (출력 없이 종료)

- [ ] **Step 3: 커밋**

```bash
git add server/src/oauth/github-oauth.client.ts
git commit -m "feat(server): GitHub OAuth 클라이언트 — 10-2a"
```

---

## Task 5: 서비스 · 컨트롤러 · 콜백 페이지 · 배선

**Files:**
- Create: `server/src/oauth/callback-page.ts`
- Create: `server/src/oauth/oauth.service.ts`
- Create: `server/src/oauth/oauth.controller.ts`
- Create: `server/src/oauth/oauth-callback.controller.ts`
- Create: `server/src/oauth/oauth.module.ts`
- Modify: `server/src/app.module.ts` (imports 에 `OauthModule` 추가)

**Interfaces:**
- Consumes: Task 1~4 전부 · `PrismaService` · `RealtimeEmitter`(`toUser`) · `resolveJwtSecrets`
- Produces:
  - `OauthService.start(userId): Promise<{ authorizeUrl: string }>`
  - `OauthService.completeGithub(code, state): Promise<boolean>`
  - `OauthService.list(userId): Promise<ConnectionView[]>` — `{ provider, login, avatarUrl, connectedAt }`
  - `OauthService.disconnect(userId): Promise<void>`
  - `OauthService.githubTokenFor(userId): Promise<string | null>` — **10-2b 가 쓴다.** 복호화 실패는 `null`
  - 소켓 이벤트 `oauth:connected` → `{ provider: 'github', login: string }`

- [ ] **Step 1: 콜백 페이지를 쓴다**

`server/src/oauth/callback-page.ts`:

```ts
/**
 * 브라우저에 그릴 페이지 두 장. 템플릿 엔진을 들이지 않는다 — 페이지가 둘뿐이다.
 *
 * 앱은 이 화면을 보지 않는다. 연결 성공은 소켓(`oauth:connected`)으로 알고,
 * 실패는 아무것도 오지 않는 것으로 안다 (설계 §2).
 */
function page(title: string, message: string, accent: string): string {
  return `<!doctype html>
<html lang="ko">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>${title} · Nexus</title>
<style>
  body { margin:0; min-height:100vh; display:grid; place-items:center;
         background:#0f1115; color:#e6e8ec;
         font-family:'Pretendard','Segoe UI',system-ui,sans-serif; }
  main { text-align:center; padding:32px; }
  h1 { font-size:20px; margin:0 0 8px; color:${accent}; }
  p  { margin:0; font-size:14px; color:#9aa1ad; }
</style>
</head>
<body><main><h1>${title}</h1><p>${message}</p></main></body>
</html>`;
}

export const CALLBACK_SUCCESS_HTML = page(
  'GitHub 을 연결했습니다',
  '이 창을 닫고 Nexus 로 돌아가세요.',
  '#7dd3a0',
);

export const CALLBACK_FAILURE_HTML = page(
  '연결하지 못했습니다',
  '이 창을 닫고 Nexus 에서 다시 시도해 주세요.',
  '#f2777a',
);
```

- [ ] **Step 2: 서비스를 쓴다**

`server/src/oauth/oauth.service.ts`:

```ts
import {
  Injectable,
  Logger,
  ServiceUnavailableException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { OauthProvider } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { RealtimeEmitter } from '../realtime/realtime-emitter';
import { resolveJwtSecrets } from '../config/jwt.config';
import {
  GithubOauthConfig,
  resolveGithubOauth,
  resolveOauthTokenKey,
} from '../config/oauth.config';
import { GithubOauthClient } from './github-oauth.client';
import { signState, verifyState } from './oauth-state';
import { decryptToken, encryptToken } from './token-crypto';

export interface ConnectionView {
  provider: OauthProvider;
  login: string;
  avatarUrl: string | null;
  connectedAt: Date;
}

/**
 * GitHub 계정 연결 (설계 스펙 §2~§5).
 *
 * **토큰은 이 클래스 밖으로 나가지 않는다.** 유일한 예외가
 * `githubTokenFor()` 인데, 그것도 서버 안(10-2b 의 저장소 서비스)에서만 쓴다.
 */
@Injectable()
export class OauthService {
  private readonly logger = new Logger(OauthService.name);
  private readonly stateSecret: string;

  constructor(
    private readonly prisma: PrismaService,
    private readonly config: ConfigService,
    private readonly github: GithubOauthClient,
    private readonly realtime: RealtimeEmitter,
  ) {
    // JWT 시크릿을 state 서명에 재사용한다. 토큰 암호화 키와 달리 이쪽은
    // 회전해도 잃을 것이 5분짜리 진행 중 연결뿐이다.
    this.stateSecret = resolveJwtSecrets(config).accessSecret;
  }

  /** 연결을 시작한다. 설정이 없으면 **503** 이다 — 400 은 요청 탓이라는 뜻이다. */
  start(userId: string): { authorizeUrl: string } {
    const cfg = this.requireConfig();
    const state = signState(userId, this.stateSecret);

    return { authorizeUrl: this.github.authorizeUrl(cfg, state) };
  }

  /**
   * 콜백을 끝낸다. **성공 여부만 돌려준다** — 실패 종류를 브라우저에
   * 알려 줄 이유가 없다(공격자에게 힌트가 된다).
   */
  async completeGithub(code: string | undefined, state: string | undefined): Promise<boolean> {
    const cfg = resolveGithubOauth(this.config);
    const key = resolveOauthTokenKey(this.config);
    if (!cfg || !key || !code) return false;

    const userId = verifyState(state, this.stateSecret);
    if (!userId) return false;

    const token = await this.github.exchangeCode(cfg, code);
    if (!token) return false;

    const user = await this.github.fetchUser(cfg, token.accessToken);
    if (!user) return false;

    // 같은 GitHub 계정을 다시 연결하면 갈아 끼운다. providerUserId 가
    // 유니크라 다른 Nexus 계정이 같은 GitHub 을 잡고 있으면 그쪽에서 옮겨 온다.
    await this.prisma.oauthAccount.upsert({
      where: {
        provider_providerUserId: {
          provider: OauthProvider.github,
          providerUserId: String(user.id),
        },
      },
      create: {
        userId,
        provider: OauthProvider.github,
        providerUserId: String(user.id),
        accessToken: encryptToken(token.accessToken, key),
        scope: token.scope,
      },
      update: {
        userId,
        accessToken: encryptToken(token.accessToken, key),
        scope: token.scope,
      },
    });

    this.realtime.toUser(userId, 'oauth:connected', {
      provider: 'github',
      login: user.login,
    });

    this.logger.log(`GitHub 연결: user=${userId} login=${user.login}`);
    return true;
  }

  /**
   * 연결 목록. **토큰은 실리지 않는다** (설계 §4).
   *
   * `login` 은 DB 에 없다 — `oauth_accounts` 에 컬럼이 없어서다. 지금은
   * 토큰으로 GitHub 에 물어본다. 실패하면 그 연결은 목록에서 빠진다:
   * 화면에는 "연결 안 됨"으로 보이고, 다시 연결하면 회복된다.
   */
  async list(userId: string): Promise<ConnectionView[]> {
    const rows = await this.prisma.oauthAccount.findMany({
      where: { userId },
      orderBy: { createdAt: 'asc' },
    });

    const cfg = resolveGithubOauth(this.config);
    const key = resolveOauthTokenKey(this.config);
    if (!cfg || !key) return [];

    const views: ConnectionView[] = [];
    for (const row of rows) {
      const token = row.accessToken ? decryptToken(row.accessToken, key) : null;
      // 복호화 실패(키 교체)를 "연결 없음"으로 취급한다.
      if (!token) continue;

      const user = await this.github.fetchUser(cfg, token);
      if (!user) continue;

      views.push({
        provider: row.provider,
        login: user.login,
        avatarUrl: user.avatarUrl,
        connectedAt: row.createdAt,
      });
    }
    return views;
  }

  /**
   * 연결을 끊는다. **이미 걸린 웹훅은 건드리지 않는다** (설계 §5) —
   * 채널에 커밋이 안 뜨는 것이 "계정 연결을 해제했다"의 결과여서는 안 된다.
   */
  async disconnect(userId: string): Promise<void> {
    await this.prisma.oauthAccount.deleteMany({
      where: { userId, provider: OauthProvider.github },
    });
  }

  /** 서버 안에서만 쓴다. 10-2b 의 저장소 서비스가 이것으로 GitHub 을 부른다. */
  async githubTokenFor(userId: string): Promise<string | null> {
    const key = resolveOauthTokenKey(this.config);
    if (!key) return null;

    const row = await this.prisma.oauthAccount.findFirst({
      where: { userId, provider: OauthProvider.github },
    });
    if (!row?.accessToken) return null;

    return decryptToken(row.accessToken, key);
  }

  private requireConfig(): GithubOauthConfig {
    const cfg = resolveGithubOauth(this.config);
    const key = resolveOauthTokenKey(this.config);

    if (!cfg || !key) {
      throw new ServiceUnavailableException(
        'GitHub 연결이 설정되지 않았습니다. 서버 관리자가 .env 를 채워야 합니다.',
      );
    }
    return cfg;
  }
}
```

- [ ] **Step 3: 컨트롤러 둘을 쓴다**

`server/src/oauth/oauth.controller.ts`:

```ts
import { Controller, Delete, Get, HttpCode, HttpStatus, Post } from '@nestjs/common';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { OauthService } from './oauth.service';

/**
 *   POST   /api/me/connections/github/start
 *   GET    /api/me/connections
 *   DELETE /api/me/connections/github
 *
 * 사용자 단위라 스페이스 밑이 아니다 — `SpaceGuard` 를 걸 자리가 없다.
 * 빈 @Controller() 라 라우트가 /api 루트에 붙는다(UsersController 와 같다).
 */
@Controller()
export class OauthController {
  constructor(private readonly oauth: OauthService) {}

  @Post('me/connections/github/start')
  start(@CurrentUser('id') userId: string) {
    return this.oauth.start(userId);
  }

  /** 토큰은 실리지 않는다. */
  @Get('me/connections')
  list(@CurrentUser('id') userId: string) {
    return this.oauth.list(userId);
  }

  /** 내 토큰을 지우는 일이지 연동을 끝내는 일이 아니다 — 웹훅은 남는다. */
  @Delete('me/connections/github')
  @HttpCode(HttpStatus.NO_CONTENT)
  disconnect(@CurrentUser('id') userId: string) {
    return this.oauth.disconnect(userId);
  }
}
```

`server/src/oauth/oauth-callback.controller.ts`:

```ts
import { Controller, Get, Header, Query } from '@nestjs/common';
import { Public } from '../common/decorators/public.decorator';
import { OauthService } from './oauth.service';
import { CALLBACK_FAILURE_HTML, CALLBACK_SUCCESS_HTML } from './callback-page';

/**
 * GET /api/auth/github/callback — **브라우저가 온다.**
 *
 * `@Public()` 인 이유는 GitHub 이 리다이렉트로 보낸 브라우저에 우리 JWT 가
 * 실릴 수 없어서다. 요청자가 누구인지는 `state` 서명이 말해 준다 (설계 §3).
 *
 * 주소를 `/api/auth/github/callback` 으로 둔 것은 `.env.example` 이 이미
 * 그렇게 적고 있기 때문이다.
 */
@Controller('auth/github')
export class OauthCallbackController {
  constructor(private readonly oauth: OauthService) {}

  @Public()
  @Get('callback')
  @Header('content-type', 'text/html; charset=utf-8')
  async callback(
    @Query('code') code?: string,
    @Query('state') state?: string,
  ): Promise<string> {
    const ok = await this.oauth.completeGithub(code, state);

    // 실패해도 상태 코드는 200 이다. 이 응답을 읽는 것은 사람의 브라우저이고,
    // 왜 실패했는지를 나눠 알려 주면 공격자에게 힌트가 된다.
    return ok ? CALLBACK_SUCCESS_HTML : CALLBACK_FAILURE_HTML;
  }
}
```

- [ ] **Step 4: 모듈을 배선한다**

`server/src/oauth/oauth.module.ts`:

```ts
import { Module } from '@nestjs/common';
import { RealtimeEmitterModule } from '../realtime/realtime-emitter.module';
import { GithubOauthClient } from './github-oauth.client';
import { OauthService } from './oauth.service';
import { OauthController } from './oauth.controller';
import { OauthCallbackController } from './oauth-callback.controller';

/**
 * 컨트롤러가 둘인 이유는 repos 모듈과 같다 — **한쪽은 인증을 지나고 한쪽은
 * 지나지 않는다.** 섞으면 어느 라우트가 공개인지 읽어서 알 수 없다.
 *
 * `OauthService` 를 export 하는 것은 10-2b 가 `githubTokenFor()` 를 쓰기 때문이다.
 */
@Module({
  imports: [RealtimeEmitterModule],
  controllers: [OauthController, OauthCallbackController],
  providers: [OauthService, GithubOauthClient],
  exports: [OauthService],
})
export class OauthModule {}
```

`server/src/app.module.ts` — `import` 줄을 `ReposModule` 아래에 더하고:

```ts
import { OauthModule } from './oauth/oauth.module';
```

`imports` 배열의 `ReposModule` **아래**에 `OauthModule,` 을 더한다.

- [ ] **Step 5: 타입 검사 · 린트 · 전체 테스트로 확인한다**

```bash
npm --prefix server run typecheck && npm run server:lint && npm --prefix server run test
```

Expected: typecheck 무출력, lint 오류 0, 테스트 전부 PASS (기존 115 + 이번 22 = 137)

- [ ] **Step 6: 서버를 띄워 라우트가 붙었는지 본다**

```bash
npm run server:dev
```

Expected: 부팅 로그에 `Mapped {/api/me/connections, GET}` 과 `Mapped {/api/auth/github/callback, GET}` 이 보인다. **`OAUTH_TOKEN_KEY` 가 비어 있어도 부팅된다**는 것이 여기서 확인해야 할 핵심이다.

- [ ] **Step 7: 커밋**

```bash
git add server/src/oauth server/src/app.module.ts
git commit -m "feat(server): GitHub 계정 연결 API — 10-2a"
```

---

## Task 6: 계약 검증 — 가짜 GitHub 을 띄운다

**Files:**
- Create: `server/scripts/check-oauth.mjs`
- Modify: `package.json` (루트) — `check:oauth` 스크립트
- Modify: `CLAUDE.md` — 명령 표에 한 줄

**Interfaces:**
- Consumes: Task 5 의 REST 계약 전부
- Produces: `npm run check:oauth`

**사전 조건이 다른 check 스크립트보다 하나 많다.** 서버가 가짜 GitHub 을 보도록 `.env` 에 아래를 넣고 `server:dev` 를 **재시작**해야 한다. 스크립트가 첫 줄에 이 사실을 찍는다.

```
GITHUB_CLIENT_ID=check-oauth-client
GITHUB_CLIENT_SECRET=check-oauth-secret
GITHUB_CALLBACK_URL=http://127.0.0.1:3000/api/auth/github/callback
GITHUB_OAUTH_BASE=http://127.0.0.1:4599
GITHUB_API_BASE=http://127.0.0.1:4599
OAUTH_TOKEN_KEY=<32바이트 base64url>
```

- [ ] **Step 1: 스크립트를 쓴다**

`server/scripts/check-oauth.mjs`:

```js
// GitHub 계정 연결(10-2a) 검증. 실제 서버 · 실제 DB 로 확인한다.
//
// 사전 조건:
//   1) npm run db:up
//   2) server/.env 에 아래를 넣는다
//        GITHUB_CLIENT_ID=check-oauth-client
//        GITHUB_CLIENT_SECRET=check-oauth-secret
//        GITHUB_CALLBACK_URL=http://127.0.0.1:3000/api/auth/github/callback
//        GITHUB_OAUTH_BASE=http://127.0.0.1:4599
//        GITHUB_API_BASE=http://127.0.0.1:4599
//        OAUTH_TOKEN_KEY=<32바이트 base64url>
//   3) npm run server:dev   (위 값을 넣은 뒤 재시작해야 한다)
//
// 사용: npm run check:oauth
//
// **진짜 GitHub 없이 돈다.** 이 스크립트가 4599 포트에 가짜 GitHub 을 띄우고,
// 서버는 GITHUB_*_BASE 로 그쪽을 본다 (설계 §10).
import { createServer } from 'node:http';
import { createHmac } from 'node:crypto';

const BASE = 'http://127.0.0.1:3000/api';
const FAKE_PORT = 4599;
const stamp = Date.now().toString(36);

let pass = 0;
let fail = 0;

function check(name, ok, detail = '') {
  if (ok) {
    pass++;
    console.log(`  OK  ${name}`);
  } else {
    fail++;
    console.log(`FAIL  ${name} ${detail}`);
  }
}

async function api(method, path, { token, body } = {}) {
  const res = await fetch(BASE + path, {
    method,
    headers: {
      'content-type': 'application/json',
      ...(token ? { authorization: `Bearer ${token}` } : {}),
    },
    ...(body ? { body: JSON.stringify(body) } : {}),
  });
  let json = null;
  try {
    json = await res.json();
  } catch {
    /* 본문 없음 */
  }
  return { status: res.status, json };
}

// ── 가짜 GitHub ────────────────────────────────────────
// code 하나당 한 번만 토큰을 내준다 — 진짜 GitHub 이 code 재사용을 거부하는
// 것과 같게 만들어, state 를 두 번 써도 두 번째가 실패하는 것을 볼 수 있다.
const usedCodes = new Set();
let userLogin = 'octocat';

const fake = createServer((req, res) => {
  const url = new URL(req.url, `http://127.0.0.1:${FAKE_PORT}`);

  if (req.method === 'POST' && url.pathname === '/login/oauth/access_token') {
    let raw = '';
    req.on('data', (c) => (raw += c));
    req.on('end', () => {
      const { code } = JSON.parse(raw || '{}');
      res.writeHead(200, { 'content-type': 'application/json' });
      if (!code || usedCodes.has(code)) {
        // 진짜 GitHub 도 이 경우 200 + error 본문을 준다.
        res.end(JSON.stringify({ error: 'bad_verification_code' }));
        return;
      }
      usedCodes.add(code);
      res.end(JSON.stringify({ access_token: `gho_${code}`, scope: 'repo' }));
    });
    return;
  }

  if (req.method === 'GET' && url.pathname === '/user') {
    const auth = req.headers.authorization ?? '';
    if (!auth.startsWith('Bearer gho_')) {
      res.writeHead(401, { 'content-type': 'application/json' });
      res.end(JSON.stringify({ message: 'Bad credentials' }));
      return;
    }
    res.writeHead(200, { 'content-type': 'application/json' });
    res.end(
      JSON.stringify({
        id: 4242,
        login: userLogin,
        avatar_url: 'https://example.invalid/a.png',
      }),
    );
    return;
  }

  res.writeHead(404).end();
});

await new Promise((resolve) => fake.listen(FAKE_PORT, '127.0.0.1', resolve));

async function signup(tag) {
  const res = await api('POST', '/auth/signup', {
    body: {
      email: `oauth-${tag}-${stamp}@example.com`,
      password: 'check-oauth-1234',
      name: `연결검증${tag}`,
      client: 'native',
    },
  });
  if (res.status !== 201) {
    console.error('가입 실패:', res.status, JSON.stringify(res.json));
    process.exit(1);
  }
  return { token: res.json.accessToken, userId: res.json.user.id };
}

/** authorizeUrl 에서 state 만 뽑는다. */
function stateOf(authorizeUrl) {
  return new URL(authorizeUrl).searchParams.get('state');
}

async function callback(code, state) {
  const query = new URLSearchParams();
  if (code !== null) query.set('code', code);
  if (state !== null) query.set('state', state);
  const res = await fetch(`${BASE}/auth/github/callback?${query.toString()}`);
  return { status: res.status, html: await res.text() };
}

const SUCCESS = 'GitHub 을 연결했습니다';

console.log('\nGitHub 계정 연결 검증 — 실서버 · 실DB (가짜 GitHub 4599)\n');

const alice = await signup('a');
const bob = await signup('b');

// ── 1. 시작 ──────────────────────────────────────────
const started = await api('POST', '/me/connections/github/start', { token: alice.token });
check('start 200', started.status === 201 || started.status === 200, String(started.status));
const authorizeUrl = started.json?.authorizeUrl ?? '';
check('authorizeUrl 이 설정된 base 를 쓴다', authorizeUrl.startsWith(`http://127.0.0.1:${FAKE_PORT}/login/oauth/authorize`), authorizeUrl);
check('client_id 가 실린다', authorizeUrl.includes('client_id=check-oauth-client'));
check('scope=repo 가 실린다', new URL(authorizeUrl).searchParams.get('scope') === 'repo');
check('state 가 실린다', !!stateOf(authorizeUrl));

const second = await api('POST', '/me/connections/github/start', { token: alice.token });
check('두 번 시작하면 state 가 다르다', stateOf(second.json.authorizeUrl) !== stateOf(authorizeUrl));

check('토큰 없이 start 는 401', (await api('POST', '/me/connections/github/start')).status === 401);

// ── 2. state 거부 ────────────────────────────────────
check('state 없이 콜백하면 실패 페이지', !(await callback('c1', null)).html.includes(SUCCESS));
check('위조 state 를 거부한다', !(await callback('c2', 'forged.signature')).html.includes(SUCCESS));

const tampered = (() => {
  const s = stateOf(second.json.authorizeUrl);
  const [body, mac] = s.split('.');
  return `${body}.${mac.slice(0, -1)}${mac.endsWith('A') ? 'B' : 'A'}`;
})();
check('서명 한 글자를 고치면 거부한다', !(await callback('c3', tampered)).html.includes(SUCCESS));
check('code 없이 오면 실패 페이지', !(await callback(null, stateOf(second.json.authorizeUrl))).html.includes(SUCCESS));

// ── 3. 연결 ──────────────────────────────────────────
const done = await callback(`code-${stamp}`, stateOf(authorizeUrl));
check('콜백이 200 HTML 을 준다', done.status === 200);
check('성공 페이지가 그려진다', done.html.includes(SUCCESS));

const list = await api('GET', '/me/connections', { token: alice.token });
check('연결 목록 200', list.status === 200);
check('연결이 하나 보인다', Array.isArray(list.json) && list.json.length === 1, JSON.stringify(list.json));
check('login 이 보인다', list.json?.[0]?.login === 'octocat');
check('avatarUrl 이 보인다', typeof list.json?.[0]?.avatarUrl === 'string');
check('connectedAt 이 있다', !!list.json?.[0]?.connectedAt);

const serialized = JSON.stringify(list.json);
check('응답에 액세스 토큰이 없다', !serialized.includes('gho_'));
check('응답에 accessToken 필드가 없다', !serialized.includes('accessToken'));

// ── 4. state 재사용 ──────────────────────────────────
const replay = await callback(`code-${stamp}`, stateOf(authorizeUrl));
check('같은 code 를 다시 쓰면 실패한다', !replay.html.includes(SUCCESS));

// ── 5. 남의 연결이 보이지 않는다 ─────────────────────
const bobList = await api('GET', '/me/connections', { token: bob.token });
check('남의 연결은 내 목록에 없다', Array.isArray(bobList.json) && bobList.json.length === 0);

// ── 6. 재연결(upsert) ────────────────────────────────
userLogin = 'octocat-renamed';
const again = await api('POST', '/me/connections/github/start', { token: alice.token });
await callback(`code-again-${stamp}`, stateOf(again.json.authorizeUrl));
const relisted = await api('GET', '/me/connections', { token: alice.token });
check('다시 연결해도 행이 늘지 않는다', relisted.json?.length === 1, JSON.stringify(relisted.json));
check('바뀐 login 이 반영된다', relisted.json?.[0]?.login === 'octocat-renamed');

// ── 7. 해제 ──────────────────────────────────────────
const removed = await api('DELETE', '/me/connections/github', { token: alice.token });
check('해제 204', removed.status === 204, String(removed.status));
check('해제 후 목록이 빈다', (await api('GET', '/me/connections', { token: alice.token })).json?.length === 0);
check('없는 연결을 또 해제해도 204 (멱등)', (await api('DELETE', '/me/connections/github', { token: alice.token })).status === 204);

fake.close();
console.log(`\n통과 ${pass} · 실패 ${fail}\n`);
process.exit(fail === 0 ? 0 : 1);
```

- [ ] **Step 2: 스크립트를 등록한다**

루트 `package.json` 의 `"check:repos"` **아래**에 더한다:

```json
    "check:oauth": "node server/scripts/check-oauth.mjs",
```

- [ ] **Step 3: `.env` 를 채우고 서버를 재시작한다**

```bash
node -e "console.log(require('crypto').randomBytes(32).toString('base64url'))"
```

출력값을 `server/.env` 의 `OAUTH_TOKEN_KEY=` 에 넣고, 위 사전 조건의 나머지 5줄도 넣은 뒤 `npm run server:dev` 를 다시 띄운다.

- [ ] **Step 4: 검증을 돌린다**

```bash
npm run check:oauth
```

Expected: `통과 27 · 실패 0`

- [ ] **Step 5: `CLAUDE.md` 명령 표에 한 줄 더한다**

`| npm run check:repos | ... |` 줄 **아래**에:

```
| `npm run check:oauth` | GitHub 계정 연결 계약 검증(27개). **가짜 GitHub(4599)을 스스로 띄운다** — `.env` 에 `GITHUB_*_BASE` 를 넣고 서버를 재시작해야 한다 |
```

- [ ] **Step 6: 커밋**

```bash
git add server/scripts/check-oauth.mjs package.json CLAUDE.md
git commit -m "test(server): GitHub 계정 연결 계약 검증 — 10-2a"
```

---

## Task 7: 앱 — 연결 모델과 API

**Files:**
- Create: `app/lib/domain/models/connection.dart`
- Create: `app/lib/data/api/connections_api.dart`
- Modify: `app/pubspec.yaml` (`url_launcher` 추가)

**Interfaces:**
- Consumes: Task 5 의 REST 계약
- Produces:
  - `class GithubConnection { String provider; String login; String? avatarUrl; DateTime connectedAt }` (freezed)
  - `ConnectionsApi.startGithub(): Future<String>` — authorizeUrl
  - `ConnectionsApi.list(): Future<List<GithubConnection>>`
  - `ConnectionsApi.disconnectGithub(): Future<void>`

- [ ] **Step 1: 모델을 쓴다**

`app/lib/domain/models/connection.dart`:

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'connection.freezed.dart';
part 'connection.g.dart';

/// `GET /api/me/connections` 의 한 항목.
///
/// **토큰은 여기 없다.** 서버가 어떤 응답에도 싣지 않는다
/// (docs/superpowers/specs/2026-08-20-github-oauth-design.md §4).
@freezed
abstract class GithubConnection with _$GithubConnection {
  const factory GithubConnection({
    required String provider,
    required String login,
    String? avatarUrl,
    required DateTime connectedAt,
  }) = _GithubConnection;

  factory GithubConnection.fromJson(Map<String, dynamic> json) =>
      _$GithubConnectionFromJson(json);
}
```

- [ ] **Step 2: 코드 생성을 돌린다**

```bash
cd app && dart run build_runner build --delete-conflicting-outputs
```

Expected: `Succeeded after ...` 와 `connection.freezed.dart` · `connection.g.dart` 생성

- [ ] **Step 3: API 를 쓴다**

`app/lib/data/api/connections_api.dart`:

```dart
import 'package:dio/dio.dart';

import '../../domain/models/connection.dart';
import 'api_client.dart';
import 'api_failure.dart';

/// GitHub 계정 연결. **스페이스가 아니라 사용자 단위**라 경로에 spaceId 가 없다.
class ConnectionsApi {
  ConnectionsApi(this._client);

  final ApiClient _client;

  /// POST /api/me/connections/github/start → 브라우저로 열 주소.
  ///
  /// 서버 설정이 없으면 503 이다 — 앱이 고칠 수 있는 문제가 아니라
  /// `ApiFailure` 로 분류해 자기 문구를 쓴다.
  Future<String> startGithub() async {
    try {
      final res = await _client.dio.post<Map<String, dynamic>>(
        '/me/connections/github/start',
      );
      return res.data?['authorizeUrl'] as String? ?? '';
    } on DioException catch (e) {
      throw ApiException(classifyDioException(e));
    }
  }

  /// GET /api/me/connections — 비어 있으면 "연결 안 됨"이다.
  Future<List<GithubConnection>> list() async {
    try {
      final res = await _client.dio.get<List<dynamic>>('/me/connections');
      return (res.data ?? const [])
          .cast<Map<String, dynamic>>()
          .map(GithubConnection.fromJson)
          .toList(growable: false);
    } on DioException catch (e) {
      throw ApiException(classifyDioException(e));
    }
  }

  /// DELETE /api/me/connections/github — 이미 걸린 웹훅은 남는다.
  Future<void> disconnectGithub() async {
    try {
      await _client.dio.delete<void>('/me/connections/github');
    } on DioException catch (e) {
      throw ApiException(classifyDioException(e));
    }
  }
}
```

- [ ] **Step 4: `url_launcher` 를 더한다**

`app/pubspec.yaml` 의 `dependencies:` 에서 `file_picker: ^12.0.0` 아래에:

```yaml
  # OAuth 는 시스템 브라우저에서 진행한다. 앱 안 웹뷰를 쓰지 않는 것은
  # GitHub 이 임베디드 웹뷰 로그인을 막기 때문이기도 하다.
  url_launcher: ^6.3.1
```

```bash
cd app && flutter pub get
```

**`pubspec.lock` 은 커밋하지 않는다** — PC 마다 Flutter SDK 가 달라 뒤집힌다(CLAUDE.md §1). 새 패키지가 들어간 이번에는 lock 이 바뀌는 것이 정상이지만, `git restore app/pubspec.lock` 로 되돌린 뒤 커밋한다.

- [ ] **Step 5: 정적 분석으로 확인한다**

```bash
cd app && flutter analyze
```

Expected: `No issues found!`

- [ ] **Step 6: 커밋**

```bash
git add app/lib/domain/models/connection.dart app/lib/domain/models/connection.freezed.dart app/lib/domain/models/connection.g.dart app/lib/data/api/connections_api.dart app/pubspec.yaml
git restore app/pubspec.lock
git commit -m "feat(app): 연결 모델과 API — 10-2a"
```

---

## Task 8: 앱 — 소켓 `oauth:connected`

**Files:**
- Modify: `app/lib/data/socket/socket_event.dart`
- Modify: `app/lib/data/socket/socket_client.dart`
- Test: `app/test/oauth_connection_test.dart`

**Interfaces:**
- Consumes: 서버가 `room.user(userId)` 로 쏘는 `oauth:connected` → `{ provider, login }`
- Produces: `class OauthConnected extends SocketEvent { final String provider; final String login; }`

- [ ] **Step 1: 실패하는 테스트를 쓴다**

`app/test/oauth_connection_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_app/data/socket/socket_event.dart';

void main() {
  group('OauthConnected', () {
    test('provider 와 login 을 담는다', () {
      const event = OauthConnected(provider: 'github', login: 'octocat');

      expect(event.provider, 'github');
      expect(event.login, 'octocat');
    });

    test('SocketEvent 의 한 갈래다', () {
      // sealed 라 화면이 switch 로 받을 때 빠뜨리면 컴파일이 막힌다.
      const SocketEvent event = OauthConnected(provider: 'github', login: 'octocat');

      expect(event, isA<SocketEvent>());
    });
  });
}
```

- [ ] **Step 2: 실패를 확인한다**

```bash
cd app && flutter test test/oauth_connection_test.dart
```

Expected: FAIL — `Undefined name 'OauthConnected'`

- [ ] **Step 3: 이벤트를 더한다**

`app/lib/data/socket/socket_event.dart` 의 `SocketUnauthorized` 클래스 **아래**에:

```dart
/// GitHub 계정 연결이 끝났다. **콜백은 브라우저가 받고 앱은 이것으로 안다**
/// (docs/superpowers/specs/2026-08-20-github-oauth-design.md §2).
///
/// 개인 룸(`user:{userId}`)으로만 온다 — 남의 연결이 내게 오지 않는다.
class OauthConnected extends SocketEvent {
  const OauthConnected({required this.provider, required this.login});

  final String provider;
  final String login;
}
```

- [ ] **Step 4: 소켓 클라이언트에 배선한다**

`app/lib/data/socket/socket_client.dart` 의 `..on('rooms:invalidate', _onRoomsInvalidate);` **바로 위**에:

```dart
      ..on('oauth:connected', _onOauthConnected)
```

그리고 `_onRoomsInvalidate` 메서드 **위**에 핸들러를 더한다:

```dart
  void _onOauthConnected(dynamic data) {
    final map = _asMap(data);
    final provider = map?['provider'];
    final login = map?['login'];
    if (provider is! String || login is! String) return;

    _emit(OauthConnected(provider: provider, login: login));
  }
```

- [ ] **Step 5: 통과를 확인한다**

```bash
cd app && flutter test test/oauth_connection_test.dart && flutter analyze
```

Expected: `All tests passed!` · `No issues found!`

- [ ] **Step 6: 커밋**

```bash
git add app/lib/data/socket app/test/oauth_connection_test.dart
git commit -m "feat(app): oauth:connected 소켓 이벤트 — 10-2a"
```

---

## Task 9: 앱 — 저장소 화면(연결 영역) · 라우트 · 진입점

**Files:**
- Create: `app/lib/features/repo/connection_controller.dart`
- Create: `app/lib/features/repo/repos_screen.dart`
- Test: `app/test/repos_screen_test.dart`
- Modify: `app/lib/core/router.dart`
- Modify: `app/lib/features/shell/channel_pane.dart`

**Interfaces:**
- Consumes: Task 7 의 `ConnectionsApi`, Task 8 의 `OauthConnected`
- Produces:
  - `connectionsProvider` — `FutureProvider<List<GithubConnection>>`
  - `githubConnectionProvider` — `Provider<GithubConnection?>` (없으면 `null`)
  - 라우트 `/s/:spaceId/repos`

**캐시하지 않는다.** 파일 목록 · 이슈 댓글과 같은 판단이다(설계 §9). drift 를 건드리지 않으므로 `schemaVersion` 도 그대로다.

- [ ] **Step 1: 실패하는 위젯 테스트를 쓴다**

`app/test/repos_screen_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_app/domain/models/connection.dart';
import 'package:nexus_app/features/repo/connection_controller.dart';
import 'package:nexus_app/features/repo/repos_screen.dart';

/// 9-3 에서 서버만 만들고 화면을 빠뜨린 채 완료로 보고한 일이 있었다.
/// 이 테스트는 그 구멍을 막는 자리다.
Widget harness(List<Override> overrides) {
  return ProviderScope(
    overrides: overrides,
    child: const MaterialApp(home: ReposScreen(spaceId: 'space-1')),
  );
}

void main() {
  testWidgets('연결 전에는 연결 버튼을 보여 준다', (tester) async {
    await tester.pumpWidget(harness([
      connectionsProvider.overrideWith((ref) async => const <GithubConnection>[]),
    ]));
    await tester.pumpAndSettle();

    expect(find.text('GitHub 연결'), findsOneWidget);
    expect(find.textContaining('@'), findsNothing);
  });

  testWidgets('연결되면 계정과 해제 버튼을 보여 준다', (tester) async {
    await tester.pumpWidget(harness([
      connectionsProvider.overrideWith((ref) async => [
            GithubConnection(
              provider: 'github',
              login: 'octocat',
              avatarUrl: null,
              connectedAt: DateTime.utc(2026, 8, 20),
            ),
          ]),
    ]));
    await tester.pumpAndSettle();

    expect(find.text('@octocat'), findsOneWidget);
    expect(find.text('연결 해제'), findsOneWidget);
    expect(find.text('GitHub 연결'), findsNothing);
  });

  testWidgets('불러오지 못하면 다시 시도할 길을 남긴다', (tester) async {
    await tester.pumpWidget(harness([
      connectionsProvider.overrideWith((ref) async => throw Exception('offline')),
    ]));
    await tester.pumpAndSettle();

    // 조용히 빈 화면을 그리면 "연결 안 됨"과 구분되지 않는다.
    expect(find.text('다시 확인'), findsOneWidget);
  });
}
```

- [ ] **Step 2: 실패를 확인한다**

```bash
cd app && flutter test test/repos_screen_test.dart
```

Expected: FAIL — `Target of URI doesn't exist: 'package:nexus_app/features/repo/repos_screen.dart'`

- [ ] **Step 3: 컨트롤러를 쓴다**

`app/lib/features/repo/connection_controller.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/api/connections_api.dart';
import '../../domain/models/connection.dart';
import '../auth/auth_controller.dart';

// apiClientProvider 는 features/auth/auth_controller.dart:32 에 있다.
// 다른 API provider(channelsApiProvider 등)도 전부 여기서 가져다 쓴다.
final connectionsApiProvider = Provider<ConnectionsApi>(
  (ref) => ConnectionsApi(ref.watch(apiClientProvider)),
);

/// 연결 상태. **캐시하지 않는다** — 오프라인에서 볼 이유가 약하고, 캐시하면
/// GitHub 쪽 변화와 어긋난 채로 굳는다 (설계 §9).
final connectionsProvider = FutureProvider<List<GithubConnection>>(
  (ref) => ref.watch(connectionsApiProvider).list(),
);

/// 없으면 `null`. 화면은 이 하나로 분기한다.
final githubConnectionProvider = Provider<GithubConnection?>((ref) {
  final list = ref.watch(connectionsProvider).valueOrNull;
  if (list == null || list.isEmpty) return null;

  return list.firstWhere(
    (c) => c.provider == 'github',
    orElse: () => list.first,
  );
});
```

- [ ] **Step 4: 화면을 쓴다**

`app/lib/features/repo/repos_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/socket/socket_event.dart';
import '../../domain/models/connection.dart';
import '../realtime/socket_controller.dart';
import 'connection_controller.dart';

/// 저장소 화면. **10-2a 는 상단 연결 영역만 채운다** — 저장소 목록과
/// 붙이기는 10-2b 다.
class ReposScreen extends ConsumerStatefulWidget {
  const ReposScreen({super.key, required this.spaceId});

  final String spaceId;

  @override
  ConsumerState<ReposScreen> createState() => _ReposScreenState();
}

class _ReposScreenState extends ConsumerState<ReposScreen> {
  /// 브라우저를 열어 둔 상태. **타임아웃을 두지 않는다** — 사람이 GitHub
  /// 로그인부터 해야 할 수도 있어 얼마가 걸릴지 알 수 없다 (설계 §9).
  bool _waiting = false;

  Future<void> _connect() async {
    setState(() => _waiting = true);
    try {
      final url = await ref.read(connectionsApiProvider).startGithub();
      final ok = url.isEmpty
          ? false
          : await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      if (!ok && mounted) {
        setState(() => _waiting = false);
        _toast('브라우저를 열지 못했습니다');
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _waiting = false);
      _toast('연결을 시작하지 못했습니다');
    }
  }

  Future<void> _disconnect() async {
    try {
      await ref.read(connectionsApiProvider).disconnectGithub();
    } catch (_) {
      if (mounted) _toast('해제하지 못했습니다');
    }
    ref.invalidate(connectionsProvider);
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    // 콜백은 브라우저가 받는다. 앱은 이 이벤트로 연결을 안다.
    // socketEventsProvider 는 features/realtime/socket_controller.dart:34 다.
    ref.listen<AsyncValue<SocketEvent>>(socketEventsProvider, (_, next) {
      if (next.value is! OauthConnected) return;
      if (mounted) setState(() => _waiting = false);
      ref.invalidate(connectionsProvider);
    });

    final connections = ref.watch(connectionsProvider);
    final github = ref.watch(githubConnectionProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('저장소')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          switch (connections) {
            AsyncError() => _Retry(onRetry: () => ref.invalidate(connectionsProvider)),
            AsyncLoading() => const Center(child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              )),
            _ => github == null
                ? _Disconnected(waiting: _waiting, onConnect: _connect)
                : _Connected(connection: github, onDisconnect: _disconnect),
          },
        ],
      ),
    );
  }
}

class _Disconnected extends StatelessWidget {
  const _Disconnected({required this.waiting, required this.onConnect});

  final bool waiting;
  final VoidCallback onConnect;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('GitHub 을 연결하면 커밋과 PR 이 채널로 들어옵니다',
                style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 12),
            if (waiting)
              const Text('브라우저에서 계속하세요…')
            else
              FilledButton.icon(
                onPressed: onConnect,
                icon: const Icon(Icons.link, size: 18),
                label: const Text('GitHub 연결'),
              ),
          ],
        ),
      ),
    );
  }
}

class _Connected extends StatelessWidget {
  const _Connected({required this.connection, required this.onDisconnect});

  final GithubConnection connection;
  final VoidCallback onDisconnect;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: connection.avatarUrl == null
              ? null
              : NetworkImage(connection.avatarUrl!),
          child: connection.avatarUrl == null ? const Icon(Icons.person) : null,
        ),
        title: Text('@${connection.login}'),
        subtitle: const Text('GitHub 연결됨'),
        trailing: TextButton(onPressed: onDisconnect, child: const Text('연결 해제')),
      ),
    );
  }
}

/// 조용히 빈 화면을 그리면 "연결 안 됨"과 구분되지 않는다.
class _Retry extends StatelessWidget {
  const _Retry({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text('연결 상태를 불러오지 못했습니다'),
        const SizedBox(height: 8),
        OutlinedButton(onPressed: onRetry, child: const Text('다시 확인')),
      ],
    );
  }
}
```

- [ ] **Step 5: 통과를 확인한다**

```bash
cd app && flutter test test/repos_screen_test.dart
```

Expected: `All tests passed!` (3 tests)

- [ ] **Step 6: 라우트를 더한다**

`app/lib/core/router.dart` — `files` 라우트 **아래**에:

```dart
          // 저장소. 파일 목록과 같이 셸 위에 덮어서 연다.
          GoRoute(
            path: 'repos',
            builder: (_, state) =>
                ReposScreen(spaceId: state.pathParameters['spaceId']!),
          ),
```

파일 맨 위 import 에 `import '../features/repo/repos_screen.dart';` 를 더한다.

- [ ] **Step 7: 진입점을 더한다**

`app/lib/features/shell/channel_pane.dart` — '보드' `IconButton` **아래**에:

```dart
                IconButton(
                  tooltip: '저장소',
                  icon: const Icon(Icons.hub_outlined, size: 18),
                  onPressed: space == null
                      ? null
                      : () => context.push('/s/${space.id}/repos'),
                ),
```

- [ ] **Step 8: 전체 검사**

```bash
cd app && flutter analyze && flutter test
```

Expected: `No issues found!` · 기존 129 + 이번 5 = **134개 통과**

- [ ] **Step 9: Windows 데스크톱으로 눈으로 확인한다**

```bash
cd app && flutter run -d windows --dart-define=API_BASE=http://127.0.0.1:3000
```

**사람이 직접 봐야 한다** — 개발 빌드는 시작 메뉴에 없어 데스크톱 자동화 도구가 창을 잡지 못한다(9-1 에서 확인했다).

확인할 것:
1. 채널 목록 헤더의 저장소 아이콘 → 저장소 화면이 열린다
2. "GitHub 연결" 을 누르면 **시스템 브라우저가 열린다**
3. 브라우저에서 승인하면 "GitHub 을 연결했습니다" 페이지가 뜬다
4. **앱을 건드리지 않아도** 화면이 `@계정` 으로 바뀐다 ← 소켓 경로의 핵심
5. "연결 해제" 를 누르면 다시 연결 버튼으로 돌아간다

3~4 에는 진짜 GitHub OAuth App(Client ID · Secret)이 필요하다. **없으면 여기까지가 이 조각의 끝이고**, 1·2·5 와 `check:oauth` 27개로 확인한 것을 완료 보고에 그대로 적는다 — 확인한 것과 확인하지 못한 것을 나눠서 쓴다(CLAUDE.md §6).

- [ ] **Step 10: 커밋**

```bash
git add app/lib/features/repo app/lib/core/router.dart app/lib/features/shell/channel_pane.dart app/test/repos_screen_test.dart
git commit -m "feat(app): 저장소 화면과 GitHub 연결 — 10-2a"
```

---

## Task 10: 문서 갱신

**Files:**
- Modify: `CLAUDE.md` (§4 에 10-2a 항목 · §5 표)
- Modify: `docs/전환-계획.md` (§4 의 10-2 체크박스)

- [ ] **Step 1: `docs/전환-계획.md` 를 고친다**

`- [ ] **10-2 GitHub OAuth** — ...` 줄을 둘로 나눈다:

```
- [x] **10-2a GitHub 계정 연결** — OAuth 시작 · 콜백 · 토큰 암호화 저장 ·
      `oauth:connected` · 앱 저장소 화면(연결 영역)
- [ ] **10-2b 저장소 목록 · 웹훅 자동 등록** — `GET /me/github/repos` ·
      `POST /repos/connect` · 훅 재등록 · 수동 등록 행 승격
```

- [ ] **Step 2: `CLAUDE.md` §4 에 절을 더한다**

"### 10-1 완료 …" 절 **아래**에 `### 10-2a 완료 (GitHub 계정 연결)` 절을 쓴다. **실제로 확인한 것만** 적고, 진짜 GitHub 종단 확인을 하지 못했으면 "확인하지 못한 것"에 명시한다.

- [ ] **Step 3: `CLAUDE.md` §5 표를 고친다**

`| 10-2 | **GitHub OAuth** ... | |` 줄을 두 줄로 나누고 10-2a 에 ✅ 를 넣는다.

- [ ] **Step 4: 커밋**

```bash
git add CLAUDE.md docs/전환-계획.md
git commit -m "docs: 10-2a 완료를 반영한다"
```

---

## 자체 점검 결과

계획을 스펙과 대조해 확인한 것:

| 스펙 절 | 덮는 Task |
|---|---|
| §2 콜백 흐름 · 실패 HTML | Task 5 |
| §3 `state` 무상태 서명 · purpose | Task 3 |
| §4 토큰 암호화 · 키 없으면 503 · 복호화 실패는 "연결 없음" | Task 1 · 2 · 5 |
| §5 해제해도 웹훅은 남긴다 | Task 5 (`disconnect` 가 `oauth_accounts` 만 지운다) |
| §8 env · 마이그레이션 없음 | Task 1 |
| §9 앱 화면 · 캐시하지 않음 · 타임아웃 없음 | Task 7 · 8 · 9 |
| §10 가짜 GitHub 계약 검증 | Task 6 |

**10-2b 로 미룬 것**(이 계획에 없는 것이 맞다): §6 저장소 목록, §7 웹훅 자동 등록 · 승격 · 재등록, `webhook_external_id` 마이그레이션, `PUBLIC_BASE_URL`.

**`login` 을 DB 에 두지 않아 목록 조회가 매번 GitHub 을 부른다.** 스펙이 정하지 않은 지점이라 여기서 정했다 — `oauth_accounts` 에 컬럼이 없고, 컬럼을 더하면 마이그레이션이 생겨 "10-2a 는 스키마를 안 건드린다"가 깨진다. 10-2b 에서 저장소 목록을 부를 때 같은 호출이 필요하므로, 그때 캐시할지 함께 정한다.
