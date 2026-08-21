// 저장소 열람(10-3a) 검증. 실제 서버 · 실제 DB 로 확인한다.
//
// 사전 조건은 check-oauth.mjs 와 같다 — server/.env 에 GITHUB_CLIENT_ID ·
// GITHUB_CLIENT_SECRET · GITHUB_CALLBACK_URL · OAUTH_TOKEN_KEY 를 넣고,
// GITHUB_API_BASE 와 GITHUB_OAUTH_BASE 를 http://127.0.0.1:4599 로 둔 뒤
// 서버를 재시작한다(이 스크립트가 그 자리에 가짜 GitHub 을 띄운다).
//
// 사용: npm run check:browse
//
// **check:oauth 에 섞지 않는 이유**는 그쪽이 이미 76개이고 주제가 연결 ·
// 등록이기 때문이다. 열람은 읽기 전용이라 섞을 이유가 없다 (설계 §5).
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
  return { status: res.status, json, headers: res.headers };
}

// ── 가짜 GitHub ────────────────────────────────────────
const REPO = {
  id: 9101,
  full_name: 'octocat/browse-me',
  private: false,
  default_branch: 'main',
  pushed_at: '2026-08-21T00:00:00Z',
  permissions: { admin: true },
};

const b64 = (input) => Buffer.from(input).toString('base64');

/** 경로별 응답. 배열이면 디렉터리, 객체면 파일이다. */
const CONTENTS = {
  '': [
    { name: 'src', path: 'src', type: 'dir' },
    { name: 'README.md', path: 'README.md', type: 'file', size: 12 },
    { name: 'logo.png', path: 'logo.png', type: 'file', size: 4 },
  ],
  // 이름순 정렬을 확인하려고 일부러 뒤섞어 둔다.
  src: [
    { name: 'zebra.ts', path: 'src/zebra.ts', type: 'file', size: 5 },
    { name: 'main.ts', path: 'src/main.ts', type: 'file', size: 13 },
    { name: 'app', path: 'src/app', type: 'dir' },
  ],
  'README.md': {
    type: 'file',
    name: 'README.md',
    path: 'README.md',
    size: 12,
    content: b64('hello world\n'),
    // 이 값이 우리 응답에 새는지 본다 — 토큰이 있어야 열리는 주소다.
    download_url: 'https://example.invalid/raw/README.md',
  },
  'logo.png': {
    type: 'file',
    name: 'logo.png',
    path: 'logo.png',
    size: 4,
    content: b64(Buffer.from([0x89, 0x50, 0x00, 0x01])),
  },
  'big.txt': {
    type: 'file',
    name: 'big.txt',
    path: 'big.txt',
    size: 600 * 1024,
    content: b64('a'.repeat(600 * 1024)),
  },
  // **임계값 안인데 본문이 없는 경우.** 1MB 초과는 우리 임계값(512KB)에
  // 먼저 걸려 too_large 가 되므로, unavailable 을 태우려면 작아야 한다.
  'empty-body.txt': {
    type: 'file',
    name: 'empty-body.txt',
    path: 'empty-body.txt',
    size: 1000,
    content: '',
  },
  '한글 폴더': [
    { name: '메모.md', path: '한글 폴더/메모.md', type: 'file', size: 7 },
  ],
  '한글 폴더/메모.md': {
    type: 'file',
    name: '메모.md',
    path: '한글 폴더/메모.md',
    size: 7,
    content: b64('안녕\n'),
  },
};

let rateLimited = false;

const fake = createServer((req, res) => {
  const url = new URL(req.url, `http://127.0.0.1:${FAKE_PORT}`);
  const json = (code, body, headers = {}) => {
    res.writeHead(code, { 'content-type': 'application/json', ...headers });
    res.end(JSON.stringify(body));
  };

  if (req.method === 'POST' && url.pathname === '/login/oauth/access_token') {
    let raw = '';
    req.on('data', (c) => (raw += c));
    req.on('end', () => {
      const { code } = JSON.parse(raw || '{}');
      json(
        200,
        code ? { access_token: `gho_${code}`, scope: 'repo' } : { error: 'bad_verification_code' },
      );
    });
    return;
  }

  if (req.method === 'GET' && url.pathname === '/user') {
    json(200, { id: 4242, login: 'octocat', avatar_url: 'https://example.invalid/a.png' });
    return;
  }

  if (req.method === 'GET' && url.pathname === '/user/repos') {
    json(200, [REPO]);
    return;
  }

  const single = url.pathname.match(/^\/repositories\/(\d+)$/);
  if (req.method === 'GET' && single) {
    const hit = Number(single[1]) === REPO.id;
    json(hit ? 200 : 404, hit ? REPO : { message: 'Not Found' });
    return;
  }

  if (req.method === 'POST' && url.pathname.endsWith('/hooks')) {
    let raw = '';
    req.on('data', (c) => (raw += c));
    req.on('end', () => json(201, { id: 900 }));
    return;
  }

  if (req.method === 'GET' && url.pathname === `/repos/${REPO.full_name}/branches`) {
    json(200, [
      { name: 'main', protected: true },
      { name: 'dev', protected: false },
    ]);
    return;
  }

  const contents = url.pathname.match(/^\/repos\/([^/]+\/[^/]+)\/contents\/(.*)$/);
  if (req.method === 'GET' && contents) {
    // rate limit 갈래는 한 번만 태운다.
    if (rateLimited) {
      rateLimited = false;
      json(429, { message: 'API rate limit exceeded' }, { 'retry-after': '42' });
      return;
    }
    const ref = url.searchParams.get('ref');
    if (ref && ref !== 'main' && ref !== 'dev') {
      json(404, { message: 'No commit found for the ref' });
      return;
    }
    const path = decodeURIComponent(contents[2]);
    const found = CONTENTS[path];
    if (found === undefined) {
      json(404, { message: 'Not Found' });
      return;
    }
    json(200, found);
    return;
  }

  res.writeHead(404).end();
});

async function signup(tag) {
  const res = await api('POST', '/auth/signup', {
    body: {
      email: `browse-${tag}-${stamp}@example.com`,
      password: 'check-browse-1234',
      name: `열람검증${tag}`,
      client: 'native',
    },
  });
  if (res.status !== 201) throw new Error(`가입 실패: ${res.status}`);
  return { token: res.json.accessToken, userId: res.json.user.id };
}

/** OAuth 연결을 마친다 — 열람은 토큰이 있어야 한다. */
async function connect(token, seed) {
  const started = await api('POST', '/me/connections/github/start', { token });
  if (started.status === 503) return false;
  const state = new URL(started.json.authorizeUrl).searchParams.get('state');
  const query = new URLSearchParams({ code: `code-${stamp}-${seed}`, state });
  await fetch(`${BASE}/auth/github/callback?${query}`);
  return true;
}

async function main() {
  console.log('\n저장소 열람 검증 — 실서버 · 실DB (가짜 GitHub 4599)\n');

  const alice = await signup('a');
  const ok = await connect(alice.token, 'a');
  if (!ok) {
    console.log('서버가 GitHub OAuth 미설정 상태다 — check-oauth.mjs 의 안내를 따를 것.\n');
    return;
  }
  const bob = await signup('x');

  const space = await api('POST', '/spaces', {
    token: alice.token,
    body: { name: `browse${stamp}` },
  });
  const spaceId = space.json.id;
  const connected = await api('POST', `/spaces/${spaceId}/repos/connect`, {
    token: alice.token,
    body: { githubRepoId: REPO.id },
  });
  check('저장소 준비', connected.status === 201, JSON.stringify(connected.json));
  const repoId = connected.json.id;
  const at = (p, q = '') => `/spaces/${spaceId}/repos/${repoId}/${p}${q}`;

  // ── 브랜치 ───────────────────────────────────────────
  const branches = await api('GET', at('branches'), { token: alice.token });
  check('브랜치 200', branches.status === 200, String(branches.status));
  check('두 건이 온다', branches.json?.branches?.length === 2);
  check('protected 가 실린다', branches.json?.branches?.[0]?.protected === true);
  check('defaultBranch 가 온다', branches.json?.defaultBranch === 'main');

  // ── 트리 ─────────────────────────────────────────────
  const root = await api('GET', at('tree'), { token: alice.token });
  check('루트 트리 200', root.status === 200, String(root.status));
  check('ref 를 비우면 기본 브랜치다', root.json?.ref === 'main', JSON.stringify(root.json?.ref));
  check('항목 셋', root.json?.entries?.length === 3);
  check('폴더가 먼저다', root.json?.entries?.[0]?.type === 'dir');
  check(
    '파일에는 size 가 있다',
    root.json?.entries?.find((e) => e.name === 'README.md')?.size === 12,
    JSON.stringify(root.json?.entries),
  );

  const sub = await api('GET', at('tree', '?path=src'), { token: alice.token });
  check('하위 트리 200', sub.status === 200);
  check(
    '폴더 먼저 · 그 안에서 이름순',
    JSON.stringify(sub.json?.entries?.map((e) => e.name)) ===
      JSON.stringify(['app', 'main.ts', 'zebra.ts']),
    JSON.stringify(sub.json?.entries?.map((e) => e.name)),
  );

  const korean = await api('GET', at('tree', '?path=' + encodeURIComponent('한글 폴더')), {
    token: alice.token,
  });
  check('한글·공백 경로가 통한다', korean.status === 200, JSON.stringify(korean.json));

  const badRef = await api('GET', at('tree', '?ref=nope'), { token: alice.token });
  check('없는 ref 는 404', badRef.status === 404, String(badRef.status));
  const badPath = await api('GET', at('tree', '?path=nope'), { token: alice.token });
  check('없는 경로는 404', badPath.status === 404, String(badPath.status));
  const fileAsTree = await api('GET', at('tree', '?path=README.md'), { token: alice.token });
  check('파일을 트리로 열면 400', fileAsTree.status === 400, String(fileAsTree.status));

  // ── 파일 ─────────────────────────────────────────────
  const readme = await api('GET', at('blob', '?path=README.md'), { token: alice.token });
  check('파일 200', readme.status === 200, String(readme.status));
  check('본문이 온다', readme.json?.content === 'hello world\n');
  check('omitted 는 null', readme.json?.omitted === null);
  check(
    '원본의 download_url 이 새지 않는다',
    !JSON.stringify(readme.json).includes('download_url') &&
      !JSON.stringify(readme.json).includes('example.invalid'),
    JSON.stringify(readme.json),
  );

  const koreanFile = await api(
    'GET',
    at('blob', '?path=' + encodeURIComponent('한글 폴더/메모.md')),
    { token: alice.token },
  );
  check('한글 본문이 깨지지 않는다', koreanFile.json?.content === '안녕\n', JSON.stringify(koreanFile.json));

  const noPath = await api('GET', at('blob'), { token: alice.token });
  check('path 없이 부르면 400', noPath.status === 400, String(noPath.status));
  const dirAsBlob = await api('GET', at('blob', '?path=src'), { token: alice.token });
  check('디렉터리를 파일로 열면 400', dirAsBlob.status === 400, String(dirAsBlob.status));

  // ── 생략 셋 ──────────────────────────────────────────
  const png = await api('GET', at('blob', '?path=logo.png'), { token: alice.token });
  check('바이너리는 binary', png.json?.omitted === 'binary', JSON.stringify(png.json));
  check('바이너리는 본문이 없다', png.json?.content === null);

  const big = await api('GET', at('blob', '?path=big.txt'), { token: alice.token });
  check('임계값 초과는 too_large', big.json?.omitted === 'too_large', JSON.stringify(big.json));

  const noBody = await api('GET', at('blob', '?path=empty-body.txt'), { token: alice.token });
  check(
    '임계값 안인데 본문이 없으면 unavailable',
    noBody.json?.omitted === 'unavailable',
    JSON.stringify(noBody.json),
  );

  // ── 429 ──────────────────────────────────────────────
  rateLimited = true;
  const limited = await api('GET', at('tree'), { token: alice.token });
  check('429 를 그대로 전달한다', limited.status === 429, String(limited.status));
  // **본문이 아니라 헤더다.** 전역 예외 필터가 본문을 일정한 봉투로 다시
  // 빚으므로 커스텀 필드는 살아남지 못한다 — Retry-After 는 HTTP 표준 헤더다.
  check(
    'Retry-After 를 헤더로 준다',
    limited.headers?.get('retry-after') === '42',
    String(limited.headers?.get('retry-after')),
  );

  // ── 격리 ─────────────────────────────────────────────
  check(
    '남의 저장소 브랜치는 404',
    (await api('GET', at('branches'), { token: bob.token })).status === 404,
  );
  check('남의 저장소 트리는 404', (await api('GET', at('tree'), { token: bob.token })).status === 404);
  check(
    '남의 저장소 파일은 404',
    (await api('GET', at('blob', '?path=README.md'), { token: bob.token })).status === 404,
  );

  // ── 연결하지 않은 사용자 ─────────────────────────────
  const space2 = await api('POST', '/spaces', {
    token: bob.token,
    body: { name: `browse2${stamp}` },
  });
  const own = await api('POST', `/spaces/${space2.json.id}/repos`, {
    token: bob.token,
    body: { provider: 'github', fullPath: REPO.full_name },
  });
  const noToken = await api('GET', `/spaces/${space2.json.id}/repos/${own.json.id}/branches`, {
    token: bob.token,
  });
  check('연결 없이 열람하면 400', noToken.status === 400, String(noToken.status));
}

await new Promise((resolve) => fake.listen(FAKE_PORT, '127.0.0.1', resolve));

let crashed = null;
try {
  await main();
} catch (err) {
  crashed = err;
}
fake.close();

if (crashed) {
  console.error('\n검증 중 예외:', crashed);
  process.exitCode = 1;
}

console.log(`\n통과 ${pass} · 실패 ${fail}\n`);
if (fail > 0) process.exitCode = 1;
