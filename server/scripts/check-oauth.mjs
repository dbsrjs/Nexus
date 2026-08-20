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
//
// **미설정 503 은 서버가 지금 미설정 상태여야만 태울 수 있다.** 이 스크립트가
// 서버를 대신 죽였다 켜지는 않는다 — 대신 시작할 때 현재 상태를 스스로
// 감지해 두 갈래로 나뉜다.
//   · 미설정이면 503 분기만 확인하고 안내를 찍은 뒤 끝난다.
//   · 설정돼 있으면 나머지 전부를 확인하고, 503 은 이 실행에서 태울 수
//     없다는 것을 화면에 명확히 알린다(조용히 건너뛰지 않는다).
// 둘 다 보려면 이 스크립트를 두 번 돌려야 한다 — 한 번은 GITHUB_CLIENT_ID
// 등을 비운 채, 한 번은 채운 채로.
import { createServer } from 'node:http';

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
    throw new Error(`가입 실패: ${res.status} ${JSON.stringify(res.json)}`);
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
  return {
    status: res.status,
    contentType: res.headers.get('content-type') ?? '',
    html: await res.text(),
  };
}

const SUCCESS = 'GitHub 을 연결했습니다';

// 실패 HTML 에 절대 새면 안 되는 내부 사정. 이 자리에서 실제로 버그 둘을
// 잡았다 — 잘못 설정된 서버가 OAUTH_TOKEN_KEY 의 길이를, DB 장애가
// 호스트·포트를 인증 없이(콜백은 @Public 이다) 흘렸다.
const LEAK_PATTERNS = [/oauth_token_key/i, /\b5432\b/, /database/i, /prisma/i];
function leaksOf(html) {
  return LEAK_PATTERNS.filter((re) => re.test(html)).map((re) => re.source);
}

/**
 * 실패로 끝나야 하는 콜백 하나를 세 각도로 확인한다:
 *   1) 성공 문구가 없다
 *   2) 그래도 200 + text/html 이다 (실패 종류를 상태 코드로 흘리지 않는다)
 *   3) 본문에 내부 설정 · DB 사정이 안 샌다
 */
async function expectFailure(label, code, state) {
  const r = await callback(code, state);
  check(`${label} — 실패 페이지`, !r.html.includes(SUCCESS));
  check(
    `${label} — 실패해도 200 HTML`,
    r.status === 200 && r.contentType.toLowerCase().includes('text/html'),
    `status=${r.status} content-type=${r.contentType}`,
  );
  const leaked = leaksOf(r.html);
  check(`${label} — 내부 정보가 새지 않는다`, leaked.length === 0, `누출: ${leaked}`);
  return r;
}

async function main() {
  console.log('\nGitHub 계정 연결 검증 — 실서버 · 실DB (가짜 GitHub 4599)\n');

  const alice = await signup('a');

  // ── 0. 지금 서버가 설정돼 있는지 스스로 감지한다 ─────
  // 이 요청이 브리프의 "1. 시작" 절이 쓰는 첫 start 호출이기도 하다 —
  // 설정돼 있으면 그대로 재사용한다.
  const probe = await api('POST', '/me/connections/github/start', { token: alice.token });

  if (probe.status === 503) {
    console.log('서버가 GitHub OAuth 미설정 상태다 (GITHUB_CLIENT_ID 등이 비어 있음).\n');
    check('설정이 없으면 start 는 503', probe.status === 503, String(probe.status));

    console.log('\n이 상태에서는 503 분기만 확인할 수 있다. 나머지 케이스를 보려면:');
    console.log('  1) server/.env 에 GITHUB_CLIENT_ID · GITHUB_CLIENT_SECRET ·');
    console.log('     GITHUB_CALLBACK_URL · GITHUB_OAUTH_BASE · GITHUB_API_BASE ·');
    console.log('     OAUTH_TOKEN_KEY 를 채운다 (이 파일 상단 주석 참고)');
    console.log('  2) npm run server:dev 를 재시작한다');
    console.log('  3) npm run check:oauth 를 다시 돌린다\n');
    return;
  }

  console.log('서버가 GitHub OAuth 로 설정돼 있다 — 이 실행에서는 503(미설정) 분기를');
  console.log('태우지 않는다. 그 분기를 보려면 위 값들을 비우고 서버를 재시작한 뒤');
  console.log('이 스크립트를 다시 돌려라.\n');

  const bob = await signup('b');

  // ── 1. 시작 ──────────────────────────────────────────
  const started = probe;
  check('start 200', started.status === 201 || started.status === 200, String(started.status));
  const authorizeUrl = started.json?.authorizeUrl ?? '';
  check(
    'authorizeUrl 이 설정된 base 를 쓴다',
    authorizeUrl.startsWith(`http://127.0.0.1:${FAKE_PORT}/login/oauth/authorize`),
    authorizeUrl,
  );
  check('client_id 가 실린다', authorizeUrl.includes('client_id=check-oauth-client'));
  check('scope=repo 가 실린다', new URL(authorizeUrl).searchParams.get('scope') === 'repo');
  check('state 가 실린다', !!stateOf(authorizeUrl));

  const second = await api('POST', '/me/connections/github/start', { token: alice.token });
  check(
    '두 번 시작하면 state 가 다르다',
    stateOf(second.json.authorizeUrl) !== stateOf(authorizeUrl),
  );

  check(
    '토큰 없이 start 는 401',
    (await api('POST', '/me/connections/github/start')).status === 401,
  );

  // ── 2. state 거부 ────────────────────────────────────
  await expectFailure('state 없이 콜백', 'c1', null);
  await expectFailure('위조 state', 'c2', 'forged.signature');

  const tampered = (() => {
    const s = stateOf(second.json.authorizeUrl);
    const [body, mac] = s.split('.');
    return `${body}.${mac.slice(0, -1)}${mac.endsWith('A') ? 'B' : 'A'}`;
  })();
  await expectFailure('서명 한 글자를 고친 state', 'c3', tampered);
  await expectFailure('code 없이', null, stateOf(second.json.authorizeUrl));

  // ── 3. 연결 ──────────────────────────────────────────
  const done = await callback(`code-${stamp}`, stateOf(authorizeUrl));
  check(
    '콜백이 200 HTML 을 준다',
    done.status === 200 && done.contentType.toLowerCase().includes('text/html'),
    `status=${done.status} content-type=${done.contentType}`,
  );
  check('성공 페이지가 그려진다', done.html.includes(SUCCESS));
  check(
    '성공 페이지에도 내부 정보가 없다',
    leaksOf(done.html).length === 0,
    `누출: ${leaksOf(done.html)}`,
  );

  const list = await api('GET', '/me/connections', { token: alice.token });
  check('연결 목록 200', list.status === 200);
  check('연결이 하나 보인다', Array.isArray(list.json) && list.json.length === 1, JSON.stringify(list.json));
  check('login 이 보인다', list.json?.[0]?.login === 'octocat');
  check('avatarUrl 이 보인다', typeof list.json?.[0]?.avatarUrl === 'string');
  check('connectedAt 이 있다', !!list.json?.[0]?.connectedAt);

  const serialized = JSON.stringify(list.json);
  check('응답에 액세스 토큰이 없다', !serialized.includes('gho_'));
  check('응답에 accessToken 필드가 없다', !serialized.includes('accessToken'));

  // ── 4. code 재사용 ───────────────────────────────────
  // 같은 state 를 다시 써도 무상태 서명이라 그 자체는 통과한다 — 가짜
  // GitHub 이 같은 code 를 거부해야 진짜로 실패한다(oauth-state.ts 의 설계
  // 그대로다).
  await expectFailure('같은 code 재사용', `code-${stamp}`, stateOf(authorizeUrl));

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
  check(
    '해제 후 목록이 빈다',
    (await api('GET', '/me/connections', { token: alice.token })).json?.length === 0,
  );
  check(
    '없는 연결을 또 해제해도 204 (멱등)',
    (await api('DELETE', '/me/connections/github', { token: alice.token })).status === 204,
  );
}

await new Promise((resolve) => fake.listen(FAKE_PORT, '127.0.0.1', resolve));

let crashed = null;
try {
  await main();
} catch (err) {
  crashed = err;
  console.error('예외로 중단:', err);
}

console.log(`\n통과 ${pass} · 실패 ${fail}\n`);

// **`close()` 직후 바로 `process.exit()` 하면 Windows 에서 아직 정리 중인
// 소켓 핸들과 경합해 libuv 단언(`UV_HANDLE_CLOSING`)으로 죽는다.** `close()`
// 콜백을 기다린 뒤 강제 종료 대신 `exitCode` 만 세팅해 이벤트 루프가 스스로
// 비워지게 둔다.
await new Promise((resolve) => fake.close(() => resolve()));
process.exitCode = crashed || fail > 0 ? 1 : 0;
