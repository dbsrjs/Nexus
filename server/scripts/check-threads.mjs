// 스레드(7-2) 검증. 실제 서버 · 실제 DB · 실제 소켓으로 확인한다.
//
// 사전 조건:
//   npm run db:up && npm run server:dev   (다른 터미널)
//
// 사용: npm run check:threads
//
// check-reactions.mjs 와 같이 자체 계정 · 자체 스페이스를 만들어 쓴다.
import { io } from 'socket.io-client';

const BASE = 'http://127.0.0.1:3000/api';
const WS = 'http://127.0.0.1:3000';

let pass = 0;
let fail = 0;

function check(name, ok, detail = '') {
  if (ok) {
    pass++;
    console.log(`  ✅ ${name}`);
  } else {
    fail++;
    console.log(`  ❌ ${name} ${detail}`);
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
      email: `thread-${tag}-${stamp}@example.com`,
      password: 'check-threads-1234',
      name: `스레드검증${tag}`,
      client: 'native',
    },
  });
  if (res.status !== 201) {
    console.error('가입 실패:', res.status, JSON.stringify(res.json));
    process.exit(1);
  }
  return { token: res.json.accessToken, userId: res.json.user.id };
}

console.log('\n스레드 검증 — 실서버 · 실DB · 실소켓\n');

const alice = await signup('a');
const outsider = await signup('x');

const space = await api('POST', '/spaces', {
  token: alice.token,
  body: { name: `스레드 검증 ${stamp}` },
});
const spaceId = space.json.id;
const channels = await api('GET', `/spaces/${spaceId}/channels`, {
  token: alice.token,
});
const channel = channels.json[0];
check('스페이스 · 채널 준비', space.status === 201 && !!channel);

const root = await api('POST', `/spaces/${spaceId}/channels/${channel.id}/messages`, {
  token: alice.token,
  body: { body: '스레드의 뿌리가 될 메시지' },
});
check('최상위 메시지 전송', root.status === 201, `status=${root.status}`);
const rootId = root.json.id;

// ── 답글 전송 ──────────────────────────────────
console.log('\n[답글]');

const reply1 = await api('POST', `/spaces/${spaceId}/channels/${channel.id}/messages`, {
  token: alice.token,
  body: { body: '첫 번째 답글', parentId: rootId },
});
check('답글 전송', reply1.status === 201, `status=${reply1.status}`);
check(
  '답글에 parentId 가 실려 온다',
  reply1.json.parentId === rootId,
  JSON.stringify(reply1.json.parentId),
);

await api('POST', `/spaces/${spaceId}/channels/${channel.id}/messages`, {
  token: alice.token,
  body: { body: '두 번째 답글', parentId: rootId },
});

// ── 채널 목록에 섞이지 않는다 ────────────────────
console.log('\n[채널 타임라인과의 분리]');

const list = await api(
  'GET',
  `/spaces/${spaceId}/channels/${channel.id}/messages?limit=30`,
  { token: alice.token },
);
const bodies = list.json.items.map((m) => m.body);
check(
  '★ 답글은 채널 타임라인에 섞이지 않는다',
  !bodies.includes('첫 번째 답글') && !bodies.includes('두 번째 답글'),
  JSON.stringify(bodies),
);

const rootInList = list.json.items.find((m) => m.id === rootId);
check(
  '★ 부모의 replyCount 가 2 로 올라간다',
  rootInList && rootInList.replyCount === 2,
  JSON.stringify(rootInList?.replyCount),
);
check(
  'lastReplyAt 이 찍힌다',
  rootInList && rootInList.lastReplyAt !== null,
  JSON.stringify(rootInList?.lastReplyAt),
);

// ── 답글 목록 ──────────────────────────────────
console.log('\n[답글 목록]');

const replies = await api('GET', `/spaces/${spaceId}/messages/${rootId}/replies`, {
  token: alice.token,
});
check('답글 목록 200', replies.status === 200, `status=${replies.status}`);
check(
  '★ 부모를 함께 준다 — 스레드 화면은 부모부터 그린다',
  replies.json.parent && replies.json.parent.id === rootId,
  JSON.stringify(replies.json.parent?.id),
);
check(
  '★ 채널 목록과 같은 방향(최신순)이다',
  replies.json.items.length === 2 &&
    replies.json.items[0].body === '두 번째 답글',
  JSON.stringify(replies.json.items.map((m) => m.body)),
);
check(
  '답글에도 리액션 요약이 실린다',
  Array.isArray(replies.json.items[0].reactions),
  JSON.stringify(replies.json.items[0]?.reactions),
);

// 커서 페이지네이션
const firstPage = await api(
  'GET',
  `/spaces/${spaceId}/messages/${rootId}/replies?limit=1`,
  { token: alice.token },
);
check(
  '커서가 돌아온다',
  firstPage.json.items.length === 1 && firstPage.json.nextCursor !== null,
  JSON.stringify(firstPage.json.nextCursor),
);
const secondPage = await api(
  'GET',
  `/spaces/${spaceId}/messages/${rootId}/replies?limit=1&cursor=${firstPage.json.nextCursor}`,
  { token: alice.token },
);
check(
  '★ 다음 페이지가 겹치지 않는다',
  secondPage.json.items.length === 1 &&
    secondPage.json.items[0].id !== firstPage.json.items[0].id,
  JSON.stringify(secondPage.json.items.map((m) => m.body)),
);

// ── 규칙 ──────────────────────────────────────
console.log('\n[규칙]');

const nested = await api('POST', `/spaces/${spaceId}/channels/${channel.id}/messages`, {
  token: alice.token,
  body: { body: '답글의 답글', parentId: reply1.json.id },
});
check(
  '★ 답글에는 답글을 달 수 없다 (400)',
  nested.status === 400,
  `status=${nested.status}`,
);

const onReply = await api(
  'GET',
  `/spaces/${spaceId}/messages/${reply1.json.id}/replies`,
  { token: alice.token },
);
check(
  '★ 답글에는 스레드가 없다 (400)',
  onReply.status === 400,
  `status=${onReply.status}`,
);

const badParent = await api(
  'POST',
  `/spaces/${spaceId}/channels/${channel.id}/messages`,
  {
    token: alice.token,
    body: { body: 'x', parentId: '00000000-0000-4000-8000-000000000000' },
  },
);
check('없는 부모는 404', badParent.status === 404, `status=${badParent.status}`);

const notUuid = await api(
  'POST',
  `/spaces/${spaceId}/channels/${channel.id}/messages`,
  { token: alice.token, body: { body: 'x', parentId: 'not-a-uuid' } },
);
check('parentId 형식이 틀리면 400', notUuid.status === 400, `status=${notUuid.status}`);

// 다른 채널의 메시지를 부모로 삼을 수 없다
const other = await api('POST', `/spaces/${spaceId}/channels`, {
  token: alice.token,
  body: { name: '다른 채널' },
});
const crossChannel = await api(
  'POST',
  `/spaces/${spaceId}/channels/${other.json.id}/messages`,
  { token: alice.token, body: { body: 'x', parentId: rootId } },
);
check(
  '★ 스레드가 채널 경계를 넘지 않는다 (404)',
  crossChannel.status === 404,
  `status=${crossChannel.status}`,
);

// 삭제된 메시지
const doomed = await api('POST', `/spaces/${spaceId}/channels/${channel.id}/messages`, {
  token: alice.token,
  body: { body: '곧 지울 메시지' },
});
await api('DELETE', `/spaces/${spaceId}/messages/${doomed.json.id}`, {
  token: alice.token,
});
const onDeleted = await api(
  'POST',
  `/spaces/${spaceId}/channels/${channel.id}/messages`,
  { token: alice.token, body: { body: 'x', parentId: doomed.json.id } },
);
check(
  '삭제된 메시지에는 답글을 달 수 없다 (400)',
  onDeleted.status === 400,
  `status=${onDeleted.status}`,
);

const byOutsider = await api(
  'GET',
  `/spaces/${spaceId}/messages/${rootId}/replies`,
  { token: outsider.token },
);
check(
  '★ 비멤버는 404 — 403 이 아니다',
  byOutsider.status === 404,
  `status=${byOutsider.status}`,
);

// ── 소켓 ──────────────────────────────────────
console.log('\n[소켓]');

const aliceSocket = await connect(alice.token);
const outsiderSocket = await connect(outsider.token);
check('소켓 연결', !!aliceSocket.on && !!outsiderSocket.on);
await new Promise((r) => setTimeout(r, 500));

const threadEvent = waitFor(aliceSocket, 'thread:reply');
const timelineEvent = waitFor(aliceSocket, 'message:new', 1500);
const leak = waitFor(outsiderSocket, 'thread:reply', 1500);

await api('POST', `/spaces/${spaceId}/channels/${channel.id}/messages`, {
  token: alice.token,
  body: { body: '소켓으로 올 답글', parentId: rootId },
});

const event = await threadEvent;
check(
  '★ thread:reply 가 채널 룸으로 온다',
  event && event.parentId === rootId && event.message.body === '소켓으로 올 답글',
  JSON.stringify(event?.parentId),
);
check(
  '★ 갱신된 replyCount 가 함께 온다 — 채널 화면이 다시 조회하지 않아도 된다',
  event && event.replyCount === 3,
  JSON.stringify(event?.replyCount),
);
check(
  '★ 답글은 message:new 로 오지 않는다 — 타임라인에 끼면 안 된다',
  (await timelineEvent) === null,
  '답글이 message:new 로 왔다',
);
check('★ 비멤버에게는 가지 않는다', (await leak) === null, '비멤버가 받았다');

for (const s of [aliceSocket, outsiderSocket]) {
  if (s.close) s.close();
}

console.log(`\n통과 ${pass} · 실패 ${fail}\n`);
process.exit(fail === 0 ? 0 : 1);
