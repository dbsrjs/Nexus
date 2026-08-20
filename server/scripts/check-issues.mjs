// 이슈 보드(9-1) 검증. 실제 서버 · 실제 DB · 실제 소켓으로 확인한다.
//
// 사전 조건: npm run db:up && npm run server:dev
// 사용: npm run check:issues
//
// 자체 계정 · 스페이스를 만들어 쓰므로 시드 비밀번호가 필요 없다.
import { io } from 'socket.io-client';

const BASE = 'http://127.0.0.1:3000/api';
const WS = 'http://127.0.0.1:3000';

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

function connect(token) {
  return new Promise((resolve) => {
    const socket = io(WS, {
      auth: { token },
      transports: ['websocket'],
      reconnection: false,
      timeout: 5000,
    });
    socket.once('connect', () => resolve(socket));
    socket.once('connect_error', (err) => resolve(err));
  });
}

function waitFor(socket, event, ms = 3000) {
  return new Promise((resolve) => {
    const timer = setTimeout(() => {
      socket.off(event, handler);
      resolve(null);
    }, ms);
    const handler = (payload) => {
      clearTimeout(timer);
      resolve(payload);
    };
    socket.once(event, handler);
  });
}

const stamp = Date.now();

async function signup(tag) {
  const res = await api('POST', '/auth/signup', {
    body: {
      email: `issue-${tag}-${stamp}@example.com`,
      password: 'check-issues-1234',
      name: `이슈검증${tag}`,
      client: 'native',
    },
  });
  if (res.status !== 201) {
    console.error('가입 실패:', res.status, JSON.stringify(res.json));
    process.exit(1);
  }
  return { token: res.json.accessToken, userId: res.json.user.id };
}

console.log('\n이슈 보드 검증 — 실서버 · 실DB · 실소켓\n');

const alice = await signup('a');
const guest = await signup('g');
const outsider = await signup('x');

// ── 준비 ─────────────────────────────────────────────
// slug 를 예측할 수 있도록 영문 이름으로 만든다(한글 이름은 폴백 slug 가 된다).
const space = await api('POST', '/spaces', {
  token: alice.token,
  body: { name: `board${stamp}` },
});
const spaceId = space.json.id;
const slug = space.json.slug;
check('스페이스 준비', !!spaceId, JSON.stringify(space.json));

// 접두사 규칙: slug 의 앞 마디들을 3자 이상이 될 때까지 이어 붙여 6자로 자른다.
const prefix = slug
  .toUpperCase()
  .split(/[^A-Z0-9]+/)
  .filter(Boolean)
  .reduce((acc, part) => (acc.length >= 3 ? acc : acc + part), '')
  .slice(0, 6);

// guest 를 초대로 넣는다.
const invite = await api('POST', `/spaces/${spaceId}/invites`, {
  token: alice.token,
  body: { role: 'guest' },
});
await api('POST', `/invites/${invite.json.code}/accept`, { token: guest.token });

// 남의 스페이스(비교용)
const otherSpace = await api('POST', '/spaces', {
  token: outsider.token,
  body: { name: `other${stamp}` },
});
const otherIssue = await api('POST', `/spaces/${otherSpace.json.id}/issues`, {
  token: outsider.token,
  body: { title: '남의 이슈' },
});

const createIssue = (body, token = alice.token) =>
  api('POST', `/spaces/${spaceId}/issues`, { token, body });

const listIssues = (query = '', token = alice.token) =>
  api('GET', `/spaces/${spaceId}/issues${query}`, { token });

// ── 1. 테넌트 격리 ───────────────────────────────────
const foreign = await api(
  `GET`,
  `/spaces/${spaceId}/issues/${otherIssue.json.id}`,
  { token: alice.token },
);
check('타 스페이스 이슈 조회는 404', foreign.status === 404, `status=${foreign.status}`);

const foreignPatch = await api(
  'PATCH',
  `/spaces/${spaceId}/issues/${otherIssue.json.id}`,
  { token: alice.token, body: { title: '남의 것을 고친다' } },
);
check(
  '타 스페이스 이슈 수정도 404',
  foreignPatch.status === 404,
  `status=${foreignPatch.status}`,
);

const asOutsider = await listIssues('', outsider.token);
check('비멤버의 목록 조회는 404', asOutsider.status === 404, `status=${asOutsider.status}`);

// ── 2. 채번 ──────────────────────────────────────────
const burst = await Promise.all(
  Array.from({ length: 10 }, (_, i) => createIssue({ title: `동시 ${i}` })),
);
const keys = burst.map((r) => r.json?.key);
check('동시 생성 10건이 모두 201', burst.every((r) => r.status === 201));
check('동시 생성 10건의 키가 모두 다르다', new Set(keys).size === 10, keys.join(','));
check(
  `키가 slug 접두사(${prefix})를 쓴다`,
  keys.every((k) => typeof k === 'string' && k.startsWith(`${prefix}-`)),
  keys[0],
);

// ── 3. position — 사이 삽입 ──────────────────────────
const first = (await createIssue({ title: '첫째' })).json;
const second = (await createIssue({ title: '둘째' })).json;
const third = (await createIssue({ title: '셋째' })).json;

// 새 이슈는 맨 위에 놓이므로 지금 순서는 셋째 · 둘째 · 첫째다.
const beforeMove = (await listIssues('?status=backlog')).json.issues.map((i) => i.id);
check(
  '새 이슈는 컬럼 맨 위에 놓인다',
  beforeMove.indexOf(third.id) < beforeMove.indexOf(second.id) &&
    beforeMove.indexOf(second.id) < beforeMove.indexOf(first.id),
  beforeMove.slice(0, 3).join(','),
);

const moved = await api('PUT', `/spaces/${spaceId}/issues/${third.id}/position`, {
  token: alice.token,
  body: { status: 'backlog', afterId: second.id, beforeId: first.id },
});
check('사이로 옮기면 200', moved.status === 200, JSON.stringify(moved.json));

const order = (await listIssues('?status=backlog')).json.issues.map((i) => i.id);
check(
  '목록 순서가 둘째 · 셋째 · 첫째 다',
  order.indexOf(second.id) < order.indexOf(third.id) &&
    order.indexOf(third.id) < order.indexOf(first.id),
  order.slice(0, 3).join(','),
);

// ── 4. 이웃 검증 ─────────────────────────────────────
const cross = await api('PUT', `/spaces/${spaceId}/issues/${third.id}/position`, {
  token: alice.token,
  body: { status: 'doing', afterId: first.id },
});
check('다른 컬럼 카드를 기준으로 옮기면 400', cross.status === 400, `status=${cross.status}`);

const reversed = await api('PUT', `/spaces/${spaceId}/issues/${third.id}/position`, {
  token: alice.token,
  body: { status: 'backlog', afterId: first.id, beforeId: second.id },
});
check('이웃 순서가 뒤바뀌면 400', reversed.status === 400, `status=${reversed.status}`);

const foreignNeighbour = await api(
  'PUT',
  `/spaces/${spaceId}/issues/${third.id}/position`,
  { token: alice.token, body: { status: 'backlog', afterId: otherIssue.json.id } },
);
check(
  '타 스페이스 카드를 기준으로 옮기면 404',
  foreignNeighbour.status === 404,
  `status=${foreignNeighbour.status}`,
);

// ── 5. 권한 ──────────────────────────────────────────
const guestList = await listIssues('', guest.token);
check('guest 열람 허용', guestList.status === 200, `status=${guestList.status}`);

const guestCreate = await createIssue({ title: 'guest 가 만든다' }, guest.token);
check('guest 생성 거부', guestCreate.status === 403, `status=${guestCreate.status}`);

const guestMove = await api('PUT', `/spaces/${spaceId}/issues/${first.id}/position`, {
  token: guest.token,
  body: { status: 'doing' },
});
check('guest 이동 거부', guestMove.status === 403, `status=${guestMove.status}`);

// ── 6. closedAt ──────────────────────────────────────
const toDone = await api('PATCH', `/spaces/${spaceId}/issues/${first.id}`, {
  token: alice.token,
  body: { status: 'done' },
});
check('done 으로 옮기면 closedAt 이 찍힌다', !!toDone.json?.closedAt, JSON.stringify(toDone.json?.closedAt));

const withinDone = await api('PUT', `/spaces/${spaceId}/issues/${first.id}/position`, {
  token: alice.token,
  body: { status: 'done' },
});
check(
  'done 안에서 자리만 옮기면 closedAt 이 그대로다',
  withinDone.json?.closedAt === toDone.json?.closedAt,
  `${withinDone.json?.closedAt} vs ${toDone.json?.closedAt}`,
);

const fromDone = await api('PATCH', `/spaces/${spaceId}/issues/${first.id}`, {
  token: alice.token,
  body: { status: 'doing' },
});
check('done 에서 나오면 closedAt 이 비워진다', fromDone.json?.closedAt === null, JSON.stringify(fromDone.json?.closedAt));

// PATCH 로 컬럼을 옮기면 대상 컬럼 맨 위로 간다.
const doingTop = (await listIssues('?status=doing')).json.issues;
check(
  'PATCH 로 옮긴 카드가 대상 컬럼 맨 위에 있다',
  doingTop[0]?.id === first.id,
  doingTop.map((i) => i.id).join(','),
);

// ── 7. 에픽은 한 단계 ────────────────────────────────
const epic = (await createIssue({ title: '에픽' })).json;
const story = await createIssue({ title: '스토리', parentId: epic.id });
check('에픽 아래 스토리는 만들어진다', story.status === 201, `status=${story.status}`);

const grandchild = await createIssue({ title: '손자', parentId: story.json.id });
check('에픽의 에픽은 400', grandchild.status === 400, `status=${grandchild.status}`);

// ── 8. 소켓 ──────────────────────────────────────────
const socket = await connect(alice.token);
const outsiderSocket = await connect(outsider.token);
check('소켓 연결', !!socket.id && !!outsiderSocket.id);

const createdEvent = waitFor(socket, 'issue:created');
const outsiderEvent = waitFor(outsiderSocket, 'issue:created', 1500);
const made = await createIssue({ title: '소켓으로 올 이슈' });
const arrived = await createdEvent;
check('issue:created 가 도착한다', arrived?.key === made.json.key, JSON.stringify(arrived?.key));
check('비멤버에게는 가지 않는다', (await outsiderEvent) === null);

const updatedEvent = waitFor(socket, 'issue:updated');
await api('PATCH', `/spaces/${spaceId}/issues/${made.json.id}`, {
  token: alice.token,
  body: { status: 'review' },
});
check('issue:updated 가 도착한다', (await updatedEvent)?.status === 'review');

// ── 9. 컬럼 상한 ─────────────────────────────────────
// 채번이 스페이스 행을 잠그므로 200건을 한꺼번에 던지면 잠금 대기로 느려진다.
// 20건씩 끊어 보낸다.
const already = (await listIssues('?status=backlog')).json.issues.length;
const need = 201 - already;
for (let i = 0; i < need; i += 20) {
  await Promise.all(
    Array.from({ length: Math.min(20, need - i) }, (_, j) =>
      createIssue({ title: `상한 ${i + j}` }),
    ),
  );
}
const big = await listIssues('?status=backlog');
check(
  '상한을 넘기면 truncated 에 담긴다',
  big.json.truncated.includes('backlog'),
  JSON.stringify(big.json.truncated),
);
check('상한만큼만 준다', big.json.issues.length === 200, `${big.json.issues.length}건`);

for (const s of [socket, outsiderSocket]) {
  if (s.close) s.close();
}

console.log(`\n통과 ${pass} · 실패 ${fail}\n`);
process.exit(fail === 0 ? 0 : 1);
