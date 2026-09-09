// 저장소 인덱싱(12단계) 검증. 실제 서버 · 실제 DB 로 확인한다.
//
// 사전 조건은 check-browse.mjs 와 같고 **하나가 더 있다** —
// server/.env 에 EMBEDDING_PROVIDER=fake 를 넣고 서버를 재시작해야 한다.
// 진짜 provider 를 부르면 CI 가 외부 API 키에 묶인다 (설계 §8).
//
// 사용: npm run check:indexing
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
  full_name: 'octocat/index-me',
  private: false,
  default_branch: 'main',
  permissions: { admin: true },
};

const HEAD_SHA = 'head1111111111111111111111111111111111ab';

/**
 * 저장소 내용. sha → { path, size, base64 }.
 *
 * **거르는 갈래를 하나씩 심어 둔다** — 바이너리 · 대용량 · 생성 파일.
 * 문구는 물어볼 질문("reconnect socket with fresh token")과 낱말이 겹치도록
 * 골랐다 — `fake` provider 는 낱말 해싱이라 겹치는 낱말이 있어야 1위 단언이
 * 우연이 아니라 근거로 성립한다.
 */
const SOCKET_FILE = [
  'class SocketController {',
  '  Future<void> reconnectWithFreshToken() async {',
  '    final token = await api.refreshAccessToken();',
  '    socket.connect(token);',
  '  }',
  '}',
].join('\n');

const BLOBS = {
  sha_socket: { path: 'lib/socket.dart', text: SOCKET_FILE },
  sha_orphan: {
    path: 'src/orphan.ts',
    text: 'export function cleanupOrphans() {\n  // 고아 첨부를 지운다\n}\n',
  },
  sha_generated: {
    path: 'lib/model.freezed.dart',
    text: '// GENERATED CODE - DO NOT MODIFY BY HAND\nclass _Model {}\n',
  },
  sha_binary: { path: 'logo.png', bytes: Buffer.from([0x89, 0x50, 0x00, 0x01]) },
  sha_big: { path: 'huge.txt', text: 'a'.repeat(300 * 1024) },
};

function entryFor(sha) {
  const b = BLOBS[sha];
  const bytes = b.bytes ?? Buffer.from(b.text);
  return { path: b.path, type: 'blob', sha, size: bytes.byteLength };
}

const TREE = { sha: HEAD_SHA, truncated: false, tree: Object.keys(BLOBS).map(entryFor) };

const NEXT_SHA = 'next2222222222222222222222222222222222cd';

/** 두 번째 커밋의 내용. socket 을 고치고, orphan 을 지우고, 새 파일을 더한다. */
const NEXT_BLOBS = {
  sha_socket2: {
    path: 'lib/socket.dart',
    text: SOCKET_FILE.replace('reconnectWithFreshToken', 'reconnectWithRotatedToken'),
  },
  sha_added: { path: 'src/added.ts', text: 'export const added = true;\n' },
};

/** 지금 어느 커밋을 서비스하나. 검증이 이 값을 바꿔 두 번째 push 를 흉내 낸다. */
let serving = 'first';

const ALL_BLOBS = { ...BLOBS, ...NEXT_BLOBS };

function entryForAll(sha) {
  const b = ALL_BLOBS[sha];
  const bytes = b.bytes ?? Buffer.from(b.text);
  return { path: b.path, type: 'blob', sha, size: bytes.byteLength };
}

/** 가짜 GitHub 이 받은 요청 수. 예산 단언(다시 태우면 다시 부른다)에 쓴다. */
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
      json(200, code ? { access_token: `gho_${code}`, scope: 'repo' } : { error: 'bad' });
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

  // **blob 을 트리보다 먼저 본다.** 순서를 뒤집으면 트리 분기가 blob 요청까지
  // 삼킨다(check-browse 가 /commits/:sha 에서 겪은 것과 같다).
  const blob = url.pathname.match(/^\/repos\/[^/]+\/[^/]+\/git\/blobs\/(.+)$/);
  if (req.method === 'GET' && blob) {
    const found = ALL_BLOBS[decodeURIComponent(blob[1])];
    if (!found) {
      json(404, { message: 'Not Found' });
      return;
    }
    const bytes = found.bytes ?? Buffer.from(found.text);
    json(200, {
      content: bytes.toString('base64'),
      encoding: 'base64',
      size: bytes.byteLength,
    });
    return;
  }

  const tree = url.pathname.match(/^\/repos\/[^/]+\/[^/]+\/git\/trees\/(.+)$/);
  if (req.method === 'GET' && tree) {
    if (serving === 'second') {
      // socket 은 새 sha 로, orphan 은 빠지고, added 가 들어온다.
      const shas = ['sha_socket2', 'sha_generated', 'sha_binary', 'sha_big', 'sha_added'];
      json(200, { sha: NEXT_SHA, truncated: false, tree: shas.map(entryForAll) });
      return;
    }
    json(200, TREE);
    return;
  }

  const compare = url.pathname.match(/^\/repos\/[^/]+\/[^/]+\/compare\/(.+)\.\.\.(.+)$/);
  if (req.method === 'GET' && compare) {
    const base = decodeURIComponent(compare[1]);
    // base 가 우리가 아는 커밋이 아니면 404 — force-push 를 흉내 낸다.
    if (base !== HEAD_SHA) {
      json(404, { message: 'Not Found' });
      return;
    }
    json(200, {
      files: [
        { filename: 'lib/socket.dart', status: 'modified' },
        { filename: 'src/orphan.ts', status: 'removed' },
        { filename: 'src/added.ts', status: 'added' },
      ],
    });
    return;
  }

  const branch = url.pathname.match(/^\/repos\/[^/]+\/[^/]+\/branches\/(.+)$/);
  if (req.method === 'GET' && branch) {
    json(200, { name: decodeURIComponent(branch[1]), commit: { sha: HEAD_SHA } });
    return;
  }

  res.writeHead(404).end();
});

/** OAuth 연결을 마친다 — 인덱싱은 스페이스 멤버 중 아무나의 토큰을 쓴다. */
async function connectGithub(token, seed) {
  const started = await api('POST', '/me/connections/github/start', { token });
  if (started.status === 503) return false;
  const state = new URL(started.json.authorizeUrl).searchParams.get('state');
  const query = new URLSearchParams({ code: `code-${stamp}-${seed}`, state });
  await fetch(`${BASE}/auth/github/callback?${query}`);
  return true;
}

/** 인덱싱이 끝날 때까지 기다린다. 연결 · 다시 태우기 모두 kick() 이 있어 보통 곧바로 끝난다. */
async function waitForIndex(token, spaceId, repoId, want = 'done', tries = 60) {
  for (let i = 0; i < tries; i++) {
    const res = await api('GET', `/spaces/${spaceId}/repos/${repoId}/index`, { token });
    if (res.json?.state === want) return res.json;
    if (res.json?.state === 'failed' && want !== 'failed') return res.json;
    await new Promise((r) => setTimeout(r, 500));
  }
  return null;
}

async function main() {
  console.log('\n저장소 인덱싱 검증 — 실서버 · 실DB (가짜 GitHub 4599)\n');

  const owner = await signup('index', 'owner');
  const space = await api('POST', '/spaces', {
    token: owner.token,
    // **영문으로 짓는다** — slug 는 한글을 떨어뜨려 한글 이름 둘이 같은 slug 를
    // 요구한다(10-2b 에서 겪었다).
    body: { name: `IndexSpace ${stamp}` },
  });
  abortUnless(space.status === 201, '스페이스 생성 실패', space.json);
  const spaceId = space.json.id;

  const connected = await connectGithub(owner.token, 'a');
  abortUnless(
    connected,
    'GitHub 연결이 설정되지 않았습니다. .env 의 GITHUB_* 와 OAUTH_TOKEN_KEY 를 채우고 서버를 재시작하세요.',
    null,
  );

  const channel = await api('POST', `/spaces/${spaceId}/channels`, {
    token: owner.token,
    body: { name: 'dev' },
  });

  // 필드 이름은 `dto/connect-repo.dto.ts` 그대로다. 전역 파이프가
  // `forbidNonWhitelisted` 라 다른 이름을 쓰면 400 이다.
  const linked = await api('POST', `/spaces/${spaceId}/repos/connect`, {
    token: owner.token,
    body: { githubRepoId: REPO.id, linkedChannelId: channel.json.id },
  });
  abortUnless(linked.status === 201, '저장소 연결 실패', linked.json);
  const repoId = linked.json.id;

  // ── 적재와 완주 ────────────────────────────────
  const state = await waitForIndex(owner.token, spaceId, repoId);
  check('연결하면 인덱싱이 끝난다', state?.state === 'done', JSON.stringify(state));
  check('인덱싱한 커밋을 기록한다', state?.indexedCommitSha === HEAD_SHA);
  check('청크가 쌓였다', (state?.chunkCount ?? 0) > 0);
  check('트리가 잘리지 않았다고 말한다', state?.truncated === false);

  // ── 거르기 ────────────────────────────────────
  const hits = await api('POST', `/spaces/${spaceId}/repos/${repoId}/index/search`, {
    token: owner.token,
    body: { query: 'reconnect socket with fresh token', topK: 20 },
  });
  check('검색이 200/201 이다', hits.status === 201 || hits.status === 200, String(hits.status));
  const chunks = hits.json?.chunks ?? [];
  const paths = new Set(chunks.map((c) => c.path));
  check('사람이 쓴 파일이 인덱싱됐다', paths.has('lib/socket.dart'));
  // 검색이 완전히 깨져 chunks 가 비면 paths 가 빈 Set 이 되어 아래 부정
  // 단언들이 전부 자동으로 참이 된다 — "빠졌다"는 "있는데 그 안에 없다"는
  // 뜻이라, 결과 자체가 없으면 그 단언은 아무것도 증명하지 못한다.
  abortUnless(
    chunks.length > 0,
    '검색 결과가 비어 있어 거르기 단언을 확인할 수 없습니다',
    hits.json,
  );
  check('바이너리는 빠졌다', !paths.has('logo.png'));
  check('256KB 를 넘는 파일은 빠졌다', !paths.has('huge.txt'));
  check('생성 파일은 빠졌다', !paths.has('lib/model.freezed.dart'));

  // ── 순위 ──────────────────────────────────────
  const top = hits.json?.chunks?.[0];
  check('물어본 내용을 담은 청크가 1위다', top?.path === 'lib/socket.dart', top?.path);
  check('줄 번호가 1부터다', top?.startLine === 1);
  check('그 시점 커밋을 함께 준다', top?.commitSha === HEAD_SHA);

  // ── 테넌트 격리 ────────────────────────────────
  const outsider = await signup('index', 'out');
  const outsiderSpace = await api('POST', '/spaces', {
    token: outsider.token,
    body: { name: `OtherSpace ${stamp}` },
  });
  const leak = await api(
    'POST',
    `/spaces/${outsiderSpace.json.id}/repos/${repoId}/index/search`,
    { token: outsider.token, body: { query: 'socket' } },
  );
  check('남의 스페이스에서는 404 다 (403 이 아니다)', leak.status === 404, String(leak.status));

  const stranger = await api('GET', `/spaces/${spaceId}/repos/${repoId}/index`, {
    token: outsider.token,
  });
  check('비멤버는 스페이스 자체가 404 다', stranger.status === 404, String(stranger.status));

  // ── 입력 검증 ──────────────────────────────────
  const bad = await api('POST', `/spaces/${spaceId}/repos/${repoId}/index/search`, {
    token: owner.token,
    body: { query: 'a', topK: 999 },
  });
  check('topK 상한을 넘으면 400 이다', bad.status === 400, String(bad.status));

  const extra = await api('POST', `/spaces/${spaceId}/repos/${repoId}/index/search`, {
    token: owner.token,
    body: { query: 'a', nope: 1 },
  });
  check('DTO 밖 필드는 400 이다', extra.status === 400, String(extra.status));

  // ── 다시 태우기 ────────────────────────────────
  const before = apiHits;
  const again = await api('POST', `/spaces/${spaceId}/repos/${repoId}/index`, {
    token: owner.token,
  });
  check('다시 태우기가 받아들여진다', again.status === 201 || again.status === 200);
  const redone = await waitForIndex(owner.token, spaceId, repoId);
  check('다시 태워도 끝난다', redone?.state === 'done');
  check('GitHub 을 실제로 다시 불렀다', apiHits > before);
  // 둘 다 폴링이 타임아웃하면 `chunkCount` 가 둘 다 undefined 가 되어
  // `===` 비교만으로는 "같다"로 거짓 통과한다(10-2b 에서 겪은 사고).
  // 숫자인 것부터 확인해야 "늘지 않았다"는 비교가 뜻을 가진다.
  check(
    '청크 수가 그대로다 — 지우고 다시 쌓아도 늘지 않는다',
    typeof state?.chunkCount === 'number' &&
      typeof redone?.chunkCount === 'number' &&
      redone.chunkCount === state.chunkCount,
    `${state?.chunkCount} → ${redone?.chunkCount}`,
  );

  // ── 증분 재인덱싱 ──────────────────────────────
  //
  // **다시 태우기(manual)로는 증분을 태울 수 없다** — 그쪽은 baseSha 를 비워
  // 언제나 전체다. 증분은 push 웹훅이 깨우므로 서명된 요청을 직접 보낸다.
  //
  // **자동 등록 응답에는 webhookSecret 이 없다**(설계상 등록·재발급 응답에만
  // 실린다). 재발급으로 받아 온다 — 그 순간부터 옛 시크릿은 무효지만 이
  // 저장소는 우리만 쓴다.
  serving = 'second';
  const beforeIncremental = apiHits;

  const reissued = await api('POST', `/spaces/${spaceId}/repos/${repoId}/secret`, {
    token: owner.token,
  });
  abortUnless(
    typeof reissued.json?.webhookSecret === 'string',
    '웹훅 시크릿 재발급 실패',
    reissued.json,
  );

  const body = JSON.stringify({
    ref: 'refs/heads/main',
    after: NEXT_SHA,
    commits: [{ id: NEXT_SHA, message: '두 번째', author: { name: 'octocat' } }],
    repository: { full_name: REPO.full_name },
    pusher: { name: 'octocat' },
  });
  const sig =
    'sha256=' +
    createHmac('sha256', reissued.json.webhookSecret).update(body).digest('hex');
  const hook = await fetch(`${BASE}/webhooks/github/${repoId}`, {
    method: 'POST',
    headers: {
      'content-type': 'application/json',
      'x-github-event': 'push',
      'x-github-delivery': `d-${stamp}-2`,
      'x-hub-signature-256': sig,
    },
    body,
  });
  check('push 웹훅이 200 이다', hook.status === 200, String(hook.status));

  const after2 = await waitForIndex(owner.token, spaceId, repoId);
  check('두 번째 인덱싱이 끝난다', after2?.state === 'done', JSON.stringify(after2));
  check('새 커밋을 기록한다', after2?.indexedCommitSha === NEXT_SHA);

  const hits2 = await api('POST', `/spaces/${spaceId}/repos/${repoId}/index/search`, {
    token: owner.token,
    body: { query: 'reconnect socket rotated token cleanup orphans added', topK: 20 },
  });
  const paths2 = new Set((hits2.json?.chunks ?? []).map((c) => c.path));
  check('지워진 파일의 청크가 사라졌다', !paths2.has('src/orphan.ts'));
  check('새 파일이 인덱싱됐다', paths2.has('src/added.ts'));

  const socketChunk = (hits2.json?.chunks ?? []).find((c) => c.path === 'lib/socket.dart');
  check('바뀐 파일은 새 커밋 sha 를 갖는다', socketChunk?.commitSha === NEXT_SHA);

  // **핵심 단언** — 증분이면 바뀐 파일만 받는다. 전체(5개)보다 적어야 한다.
  const spent = apiHits - beforeIncremental;
  check('증분은 전체보다 적은 요청을 쓴다', spent < 8, `요청 ${spent}회`);

  // ── base 가 사라지면 전체로 떨어진다 ────────────
  //
  // 가짜 GitHub 은 base 가 HEAD_SHA 가 아니면 404 를 준다 = force-push.
  // 지금 indexedCommitSha 는 NEXT_SHA 라 다음 push 의 compare 가 404 가 되고,
  // 그래도 인덱싱은 끝나야 한다 — 여기서 던지면 force-push 한 번에 인덱스가
  // 영영 낡는다.
  const body3 = JSON.stringify({
    ref: 'refs/heads/main',
    after: NEXT_SHA,
    commits: [{ id: NEXT_SHA, message: '세 번째', author: { name: 'octocat' } }],
    repository: { full_name: REPO.full_name },
    pusher: { name: 'octocat' },
  });
  const sig3 =
    'sha256=' +
    createHmac('sha256', reissued.json.webhookSecret).update(body3).digest('hex');
  await fetch(`${BASE}/webhooks/github/${repoId}`, {
    method: 'POST',
    headers: {
      'content-type': 'application/json',
      'x-github-event': 'push',
      'x-github-delivery': `d-${stamp}-3`,
      'x-hub-signature-256': sig3,
    },
    body: body3,
  });
  const after3 = await waitForIndex(owner.token, spaceId, repoId);
  check(
    'compare 가 404 여도 전체 재인덱싱으로 끝난다',
    after3?.state === 'done',
    JSON.stringify(after3),
  );

  // ── 다른 브랜치는 아무 일도 없다 ───────────────
  const before4 = apiHits;
  const body4 = JSON.stringify({
    ref: 'refs/heads/feature/whatever',
    after: 'feature999999999999999999999999999999999a',
    commits: [],
    repository: { full_name: REPO.full_name },
    pusher: { name: 'octocat' },
  });
  const sig4 =
    'sha256=' +
    createHmac('sha256', reissued.json.webhookSecret).update(body4).digest('hex');
  const hook4 = await fetch(`${BASE}/webhooks/github/${repoId}`, {
    method: 'POST',
    headers: {
      'content-type': 'application/json',
      'x-github-event': 'push',
      'x-github-delivery': `d-${stamp}-4`,
      'x-hub-signature-256': sig4,
    },
    body: body4,
  });
  check('기능 브랜치 push 도 200 이다', hook4.status === 200);
  // 워커가 깨어날 시간을 준다. 깨어나면 안 되는 것이 이 케이스의 주제다.
  await new Promise((r) => setTimeout(r, 1500));
  const idle = await api('GET', `/spaces/${spaceId}/repos/${repoId}/index`, {
    token: owner.token,
  });
  check('default 브랜치가 아니면 인덱싱하지 않는다', idle.json?.state === 'done');
  check('GitHub 을 부르지도 않았다', apiHits === before4, `${before4} → ${apiHits}`);
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
