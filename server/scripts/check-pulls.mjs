// PR 열람(11단계) 검증. 실제 서버 · 실제 DB 로 확인한다.
//
// 사전 조건은 check-browse.mjs 와 같다 — server/.env 에 GITHUB_CLIENT_ID ·
// GITHUB_CLIENT_SECRET · GITHUB_CALLBACK_URL · OAUTH_TOKEN_KEY 를 넣고,
// GITHUB_API_BASE 와 GITHUB_OAUTH_BASE 를 http://127.0.0.1:4599 로 둔 뒤
// 서버를 재시작한다(이 스크립트가 그 자리에 가짜 GitHub 을 띄운다).
//
// 사용: npm run check:pulls
//
// **check:browse 에 섞지 않는 이유**는 그쪽이 이미 56개이고 주제가 브랜치 ·
// 트리 · 파일 · 커밋이기 때문이다(설계 §5). PR 은 같은 열람 성격이지만 자기
// 라우트 파일(`pulls.controller.ts`)로 시작했으니 검증도 자기 스크립트로 시작한다.
import { createServer } from 'node:http';
import { createHmac } from 'node:crypto';

import { requireServer, abortUnless, PreflightAbort } from './lib/preflight.mjs';
import { BASE, stamp, api, signup } from './lib/api.mjs';
import { check, summary } from './lib/checks.mjs';
await requireServer(BASE);
const FAKE_PORT = 4599;


// ── 가짜 GitHub ────────────────────────────────────────
const REPO = {
  id: 9202,
  full_name: 'octocat/pulls-me',
  private: false,
  default_branch: 'main',
  pushed_at: '2026-08-30T00:00:00Z',
  permissions: { admin: true },
};

/** 열려 있는 PR. 목록(state=open)과 상세 양쪽에 쓴다. */
const PR_OPEN = {
  number: 12,
  title: '기능 X 를 더한다',
  state: 'open',
  draft: false,
  user: { login: 'octocat', avatar_url: 'https://example.invalid/a.png' },
  head: { ref: 'feature/x' },
  base: { ref: 'main' },
  html_url: 'https://github.com/octocat/pulls-me/pull/12',
  created_at: '2026-08-28T00:00:00Z',
  merged_at: null,
  closed_at: null,
  body: '이 PR 은 기능 X 를 더한다.',
  additions: 10,
  deletions: 3,
  changed_files: 2,
  // 이 값들이 우리 응답에 새는지 본다 — 토큰이 있어야 열리는 주소 · 내부 링크다.
  diff_url: 'https://example.invalid/diff/12',
  _links: { self: { href: 'https://example.invalid/self/12' } },
};

/** 머지된 PR — `state` 가 아니라 `merged_at` 으로 갈린다. */
const PR_MERGED = {
  number: 13,
  title: '머지된 PR',
  state: 'closed',
  draft: false,
  user: { login: 'octocat', avatar_url: null },
  head: { ref: 'feature/merged' },
  base: { ref: 'main' },
  html_url: 'https://github.com/octocat/pulls-me/pull/13',
  created_at: '2026-08-26T00:00:00Z',
  merged_at: '2026-08-27T00:00:00Z',
  closed_at: '2026-08-27T00:00:00Z',
  body: null,
  additions: 5,
  deletions: 1,
  changed_files: 1,
};

/** 머지 없이 닫힌 PR. */
const PR_CLOSED = {
  number: 14,
  title: '닫기만 한 PR',
  state: 'closed',
  draft: false,
  user: { login: 'octocat', avatar_url: null },
  head: { ref: 'feature/closed' },
  base: { ref: 'main' },
  html_url: 'https://github.com/octocat/pulls-me/pull/14',
  created_at: '2026-08-24T00:00:00Z',
  merged_at: null,
  closed_at: '2026-08-25T00:00:00Z',
  body: '',
  additions: 1,
  deletions: 1,
  changed_files: 1,
};

const PR_BY_NUMBER = { 12: PR_OPEN, 13: PR_MERGED, 14: PR_CLOSED };

/** 12 의 바뀐 파일 — renamed 하나를 섞어 previousPath 를 확인한다. */
const FILES_12 = [
  {
    filename: 'src/a.ts',
    status: 'modified',
    additions: 3,
    deletions: 1,
    // 이 값이 우리 응답에 새는지 본다 — diff 는 그리지 않기로 했다(10-3b).
    patch: '@@ -1 +1 @@\n-old\n+new',
  },
  {
    filename: 'src/new.ts',
    status: 'renamed',
    additions: 0,
    deletions: 0,
    previous_filename: 'old.ts',
    patch: '',
  },
];

/** 300개(3장 × 100개) — 상한에서 끊기고 truncated 가 되는지 확인한다. */
function fullFilePage(page) {
  return Array.from({ length: 100 }, (_, i) => ({
    filename: `gen/p${page}-${i}.ts`,
    status: 'modified',
    additions: 1,
    deletions: 0,
    patch: '@@ -1 +1 @@\n-a\n+b',
  }));
}

/** 12 의 리뷰 — 같은 사람이 변경 요청 뒤 승인했다. 접으면 approved 만 남는다. */
const REVIEWS = {
  12: [
    { user: { login: 'reviewer1' }, state: 'CHANGES_REQUESTED' },
    { user: { login: 'reviewer1' }, state: 'APPROVED' },
  ],
};

/** **가짜 GitHub 이 받은 요청 수.** "이벤트 조회는 GitHub 을 부르지 않는다"를 확인하는 데 쓴다. */
let apiHits = 0;

const fake = createServer((req, res) => {
  const url = new URL(req.url, `http://127.0.0.1:${FAKE_PORT}`);
  apiHits++;
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
    json(200, { id: 5252, login: 'octocat', avatar_url: 'https://example.invalid/a.png' });
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
    req.on('end', () => json(201, { id: 901 }));
    return;
  }

  // 순서가 중요하다 — 더 긴 경로(파일 · 리뷰)를 단건보다 먼저 본다.
  // 커밋에서 같은 함정을 겪었다(check-browse.mjs 162행 근처).
  const files = url.pathname.match(/^\/repos\/[^/]+\/[^/]+\/pulls\/(\d+)\/files$/);
  if (req.method === 'GET' && files) {
    const n = Number(files[1]);
    const page = Number(url.searchParams.get('page') ?? '1');
    if (n === 12 && page === 1) {
      json(200, FILES_12);
      return;
    }
    if (n === 99) {
      json(200, fullFilePage(page));
      return;
    }
    json(404, { message: 'Not Found' });
    return;
  }

  const reviews = url.pathname.match(/^\/repos\/[^/]+\/[^/]+\/pulls\/(\d+)\/reviews$/);
  if (req.method === 'GET' && reviews) {
    const n = Number(reviews[1]);
    json(200, REVIEWS[n] ?? []);
    return;
  }

  const one = url.pathname.match(/^\/repos\/[^/]+\/[^/]+\/pulls\/(\d+)$/);
  if (req.method === 'GET' && one) {
    const n = Number(one[1]);
    // 429 를 태우는 전용 번호 — check-browse.mjs 가 tree 에서 쓰는 토글 대신
    // 고정 번호를 쓴다. 이 번호로만 부르므로 다른 케이스와 섞이지 않는다.
    if (n === 429) {
      json(429, { message: 'API rate limit exceeded' }, { 'retry-after': '42' });
      return;
    }
    const pr = PR_BY_NUMBER[n];
    json(pr ? 200 : 404, pr ?? { message: 'Not Found' });
    return;
  }

  const list = url.pathname.match(/^\/repos\/[^/]+\/[^/]+\/pulls$/);
  if (req.method === 'GET' && list) {
    const state = url.searchParams.get('state') ?? 'open';
    json(200, state === 'closed' ? [PR_MERGED, PR_CLOSED] : [PR_OPEN]);
    return;
  }

  res.writeHead(404).end();
});

/** OAuth 연결을 마친다 — 열람은 토큰이 있어야 한다. */
async function connectGithub(token, seed) {
  const started = await api('POST', '/me/connections/github/start', { token });
  if (started.status === 503) return false;
  const state = new URL(started.json.authorizeUrl).searchParams.get('state');
  const query = new URLSearchParams({ code: `code-${stamp}-${seed}`, state });
  await fetch(`${BASE}/auth/github/callback?${query}`);
  return true;
}

/** 웹훅을 서명해 보낸다. 반환값은 응답 상태 코드. */
async function fireWebhook(event, payload, secret, repoId, seed) {
  const body = JSON.stringify(payload);
  const sig = 'sha256=' + createHmac('sha256', secret).update(body).digest('hex');
  const res = await fetch(`${BASE}/webhooks/github/${repoId}`, {
    method: 'POST',
    headers: {
      'content-type': 'application/json',
      'x-github-event': event,
      'x-github-delivery': `d-${stamp}-${seed}`,
      'x-hub-signature-256': sig,
    },
    body,
  });
  return res.status;
}

async function main() {
  console.log('\nPR 열람 검증 — 실서버 · 실DB (가짜 GitHub 4599)\n');

  const alice = await signup('pulls', 'a');
  const ok = await connectGithub(alice.token, 'a');
  if (!ok) {
    console.log('서버가 GitHub OAuth 미설정 상태다 — check-oauth.mjs 의 안내를 따를 것.\n');
    return;
  }
  const bob = await signup('pulls', 'x');
  // **스페이스 멤버이지만 GitHub 을 연결하지 않은 계정.** bob 은 스페이스
  // 멤버조차 아니라서 SpaceGuard 가 토큰 검사보다 먼저 404 로 끊는다 — 400
  // 을 태우려면 멤버여야 한다.
  const carol = await signup('pulls', 'c');

  const space = await api('POST', '/spaces', {
    token: alice.token,
    body: { name: `pulls${stamp}` },
  });
  const spaceId = space.json.id;
  const channels = await api('GET', `/spaces/${spaceId}/channels`, { token: alice.token });
  const channelId = channels.json?.[0]?.id;
  check('기본 채널 준비', !!channelId);

  const invite = await api('POST', `/spaces/${spaceId}/invites`, {
    token: alice.token,
    body: {},
  });
  const carolJoined = await api('POST', `/invites/${invite.json.code}/accept`, {
    token: carol.token,
  });
  check('carol 초대 수락', carolJoined.status === 200 || carolJoined.status === 201, String(carolJoined.status));

  const connected = await api('POST', `/spaces/${spaceId}/repos/connect`, {
    token: alice.token,
    body: { githubRepoId: REPO.id, linkedChannelId: channelId },
  });
  check('저장소 준비', connected.status === 201, JSON.stringify(connected.json));
  abortUnless(
    connected.status === 201,
    `저장소 준비 실패 (status=${connected.status})`,
    connected.json,
  );
  const repoId = connected.json.id;
  const at = (p, q = '') => `/spaces/${spaceId}/repos/${repoId}/${p}${q}`;

  // ── 1) 목록 ──────────────────────────────────────────
  const list = await api('GET', at('pulls'), { token: alice.token });
  check('열린 PR 목록이 온다', list.status === 200 && list.json?.pulls?.length === 1, String(list.status));
  check(
    '목록에 변경량이 없다 — GitHub 이 주지 않는다',
    list.json?.pulls?.[0]?.additions === undefined,
    JSON.stringify(list.json?.pulls?.[0]),
  );

  const bad = await api('GET', at('pulls', '?state=bogus'), { token: alice.token });
  check('state 가 이상하면 400', bad.status === 400, String(bad.status));

  // ── 2) 상세 ──────────────────────────────────────────
  const d12 = await api('GET', at('pulls/12'), { token: alice.token });
  check('PR 상세 200', d12.status === 200, String(d12.status));
  const d13 = await api('GET', at('pulls/13'), { token: alice.token });
  check('머지된 것은 closed 가 아니라 merged', d13.json?.state === 'merged', JSON.stringify(d13.json));
  const d14 = await api('GET', at('pulls/14'), { token: alice.token });
  check('머지 없이 닫힌 것은 closed', d14.json?.state === 'closed', JSON.stringify(d14.json));

  check('리뷰가 접혀서 온다 — 같은 사람의 마지막 것', d12.json?.review === 'approved', JSON.stringify(d12.json?.review));
  check('본문과 변경량이 온다', typeof d12.json?.additions === 'number', JSON.stringify(d12.json?.additions));
  check('htmlUrl 은 싣는다', typeof d12.json?.htmlUrl === 'string', JSON.stringify(d12.json?.htmlUrl));
  check(
    'diff_url · _links 는 싣지 않는다',
    d12.json?.diff_url === undefined && d12.json?._links === undefined,
    JSON.stringify(d12.json),
  );

  // ── 3) 파일 ──────────────────────────────────────────
  const f12 = await api('GET', at('pulls/12/files'), { token: alice.token });
  check('파일 목록 200', f12.status === 200, String(f12.status));
  check(
    'patch 가 응답에 없다',
    Array.isArray(f12.json?.files) && f12.json.files.every((f) => f.patch === undefined),
    JSON.stringify(f12.json?.files),
  );
  check(
    '경로 필드는 path 다 — 10-3b 의 ChangedFile 과 같다',
    typeof f12.json?.files?.[0]?.path === 'string',
    JSON.stringify(f12.json?.files?.[0]),
  );
  const renamed = f12.json?.files?.find((f) => f.status === 'renamed');
  check('renamed 파일이 목록에 있다', !!renamed, JSON.stringify(f12.json?.files));
  check('renamed 는 previousPath 를 싣는다', renamed?.previousPath === 'old.ts', JSON.stringify(renamed));

  const f99 = await api('GET', at('pulls/99/files'), { token: alice.token });
  check('상한을 넘으면 truncated 다', f99.json?.truncated === true, JSON.stringify(f99.json?.truncated));
  check('상한에서 끊는다', f99.json?.files?.length === 300, String(f99.json?.files?.length));

  // ── 4) 격리 · 실패 ───────────────────────────────────
  const other = await api('GET', at('pulls/12'), { token: bob.token });
  check('타 스페이스의 저장소는 404', other.status === 404, String(other.status));

  const noToken = await api('GET', at('pulls'), { token: carol.token });
  check(
    'GitHub 계정을 연결하지 않았으면 400 이다 — 목록이 아니라 안내로 떨어진다',
    noToken.status === 400,
    String(noToken.status),
  );
  // 서버에 GitHub 설정이 아예 없을 때의 503 은 이 스크립트가 태울 수 없다 —
  // .env 를 비우고 서버를 재시작해야 한다. check:oauth 와 같이 안내만 찍는다.
  console.log('  --  미설정 503 은 .env 의 GITHUB_CLIENT_ID 를 비우고 재시작해 확인한다');

  const missing = await api('GET', at('pulls/999'), { token: alice.token });
  check('없는 PR 번호는 404', missing.status === 404, String(missing.status));

  const rate = await api('GET', at('pulls/429'), { token: alice.token });
  check('429 는 Retry-After 를 헤더로 준다', rate.status === 429 && rate.headers?.get('retry-after') === '42', String(rate.status));

  // ── 5) 이벤트 진입 (Task 6) ──────────────────────────
  const secret = (await api('POST', at('secret'), { token: alice.token })).json?.webhookSecret;
  check('웹훅 시크릿 발급', typeof secret === 'string');

  async function latestMessage() {
    const res = await api('GET', `/spaces/${spaceId}/channels/${channelId}/messages`, {
      token: alice.token,
    });
    return res.json?.items?.[0];
  }

  const pushBody = {
    ref: 'refs/heads/main',
    before: 'aaa',
    after: 'bbb',
    pusher: { name: 'dbsrjs' },
    commits: [
      {
        id: 'c0ffee',
        message: 'fix: 무언가를 고친다',
        timestamp: '2026-08-30T00:00:00Z',
        author: { name: 'dbsrjs' },
        added: ['a.ts'],
        removed: [],
        modified: [],
      },
    ],
  };
  const pushStatus = await fireWebhook('push', pushBody, secret, repoId, 'push');
  check('push 웹훅 수신 200', pushStatus === 200, String(pushStatus));
  const pushMsg = await latestMessage();
  check('push 메시지에 repoEventId 가 실린다', !!pushMsg?.repoEventId, JSON.stringify(pushMsg));

  const prBody = {
    action: 'opened',
    number: 12,
    pull_request: { title: '기능 X 를 더한다', user: { login: 'octocat' }, merged: false },
  };
  const prStatus = await fireWebhook('pull_request', prBody, secret, repoId, 'pr');
  check('PR 웹훅 수신 200', prStatus === 200, String(prStatus));
  const prMsg = await latestMessage();
  check('PR 메시지에 repoEventId 가 실린다', !!prMsg?.repoEventId, JSON.stringify(prMsg));

  const issueBody = {
    action: 'opened',
    issue: { number: 55, title: '뭔가 고장났다', user: { login: 'octocat' } },
  };
  const issueStatus = await fireWebhook('issues', issueBody, secret, repoId, 'issue');
  check('이슈 웹훅 수신 200', issueStatus === 200, String(issueStatus));
  const issueMsg = await latestMessage();
  check('이슈 메시지에 repoEventId 가 실린다', !!issueMsg?.repoEventId, JSON.stringify(issueMsg));

  const evPush = await api('GET', `/spaces/${spaceId}/repo-events/${pushMsg?.repoEventId}`, {
    token: alice.token,
  });
  check('push 이벤트는 여전히 커밋을 준다', evPush.json?.kind === 'push', JSON.stringify(evPush.json));

  const hitsBefore = apiHits;
  const ev = await api('GET', `/spaces/${spaceId}/repo-events/${prMsg?.repoEventId}`, {
    token: alice.token,
  });
  check(
    'PR 이벤트는 kind:pr 과 번호를 준다',
    ev.json?.kind === 'pr' && ev.json?.number === 12,
    JSON.stringify(ev.json),
  );
  // **이 조각의 핵심 판단이라 말로만 두지 않는다** (10-3b 가 커밋에서 세운 규칙과 같다).
  check('이벤트 조회는 GitHub 을 부르지 않는다', apiHits === hitsBefore, `${hitsBefore} → ${apiHits}`);

  const evIssue = await api('GET', `/spaces/${spaceId}/repo-events/${issueMsg?.repoEventId}`, {
    token: alice.token,
  });
  check('이슈 이벤트는 other 다', evIssue.json?.kind === 'other', JSON.stringify(evIssue.json));
}

await new Promise((resolve) => fake.listen(FAKE_PORT, '127.0.0.1', resolve));

let crashed = null;
try {
  await main();
} catch (err) {
  crashed = err;
}
fake.close();

if (crashed instanceof PreflightAbort) {
  console.error('');
  console.error(`중단: ${crashed.reason}`);
  if (crashed.hint) {
    console.error('');
    console.error(crashed.hint);
  }
  console.error('');
  console.error('뒤의 케이스는 실패한 것이 아니라 검증하지 못한 것입니다.');
  console.error('');
  process.exitCode = 1;
} else if (crashed) {
  console.error('\n검증 중 예외:', crashed);
  process.exitCode = 1;
}

summary();
