// 답장/인용(7-3) 검증. 실제 서버 · 실제 DB · 실제 소켓으로 확인한다.
//
// 스레드와 **다른 축**임을 확인하는 것이 핵심이다 — 답장은 타임라인에 남고,
// 스레드 답글은 빠진다. 둘을 함께 쓸 수도 있어야 한다.
//
// 사전 조건: npm run db:up && npm run server:dev
// 사용: npm run check:quotes
import { io } from 'socket.io-client';

import { requireServer } from './lib/preflight.mjs';
const BASE = 'http://127.0.0.1:3000/api';
await requireServer(BASE);
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
      email: `quote-${tag}-${stamp}@example.com`,
      password: 'check-quotes-1234',
      name: `인용검증${tag}`,
      client: 'native',
    },
  });
  if (res.status !== 201) {
    console.error('가입 실패:', res.status, JSON.stringify(res.json));
    process.exit(1);
  }
  return { token: res.json.accessToken, userId: res.json.user.id };
}

console.log('\n답장(인용) 검증 — 실서버 · 실DB · 실소켓\n');

const alice = await signup('a');

const space = await api('POST', '/spaces', {
  token: alice.token,
  body: { name: `인용 검증 ${stamp}` },
});
const spaceId = space.json.id;
const channels = await api('GET', `/spaces/${spaceId}/channels`, {
  token: alice.token,
});
const channel = channels.json[0];
check('스페이스 · 채널 준비', space.status === 201 && !!channel);

const original = await api(
  'POST',
  `/spaces/${spaceId}/channels/${channel.id}/messages`,
  { token: alice.token, body: { body: '인용될 원본 메시지' } },
);
const originalId = original.json.id;
check('원본 전송', original.status === 201, `status=${original.status}`);

// ── 기본 ──────────────────────────────────────
console.log('\n[답장]');

const quoting = await api(
  'POST',
  `/spaces/${spaceId}/channels/${channel.id}/messages`,
  {
    token: alice.token,
    body: { body: '이건 답장입니다', quotedMessageId: originalId },
  },
);
check('답장 전송', quoting.status === 201, `status=${quoting.status}`);
check(
  '★ 전송 응답에 인용 요약이 실린다',
  quoting.json.quoted &&
    quoting.json.quoted.id === originalId &&
    quoting.json.quoted.body === '인용될 원본 메시지' &&
    quoting.json.quoted.authorName === '인용검증a',
  JSON.stringify(quoting.json.quoted),
);

const list = await api(
  'GET',
  `/spaces/${spaceId}/channels/${channel.id}/messages?limit=30`,
  { token: alice.token },
);
const bodies = list.json.items.map((m) => m.body);
check(
  '★ 답장은 타임라인에 남는다 — 스레드 답글과 다른 축이다',
  bodies.includes('이건 답장입니다') && bodies.includes('인용될 원본 메시지'),
  JSON.stringify(bodies),
);

const inList = list.json.items.find((m) => m.id === quoting.json.id);
check(
  '목록에도 인용 요약이 실린다',
  inList && inList.quoted && inList.quoted.id === originalId,
  JSON.stringify(inList?.quoted),
);
const originalInList = list.json.items.find((m) => m.id === originalId);
check(
  '인용하지 않은 메시지의 quoted 는 null',
  originalInList && originalInList.quoted === null,
  JSON.stringify(originalInList?.quoted),
);

// ── 한 겹만 ────────────────────────────────────
console.log('\n[한 겹만 펼친다]');

const nested = await api(
  'POST',
  `/spaces/${spaceId}/channels/${channel.id}/messages`,
  {
    token: alice.token,
    body: { body: '답장의 답장', quotedMessageId: quoting.json.id },
  },
);
check(
  '★ 인용의 인용도 가능하되 한 겹만 온다 — 계단이 되지 않는다',
  nested.status === 201 &&
    nested.json.quoted.id === quoting.json.id &&
    nested.json.quoted.quoted === undefined,
  JSON.stringify(nested.json.quoted),
);

// ── 스레드와 함께 ──────────────────────────────
console.log('\n[스레드와 함께 쓸 수 있다]');

const threadReply = await api(
  'POST',
  `/spaces/${spaceId}/channels/${channel.id}/messages`,
  {
    token: alice.token,
    body: {
      body: '스레드 안에서 인용',
      parentId: originalId,
      quotedMessageId: quoting.json.id,
    },
  },
);
check(
  '★ 스레드 답글이면서 인용일 수 있다 — 두 축은 서로를 막지 않는다',
  threadReply.status === 201 &&
    threadReply.json.parentId === originalId &&
    threadReply.json.quoted?.id === quoting.json.id,
  JSON.stringify({
    parentId: threadReply.json.parentId,
    quoted: threadReply.json.quoted?.id,
  }),
);

const replies = await api(
  'GET',
  `/spaces/${spaceId}/messages/${originalId}/replies`,
  { token: alice.token },
);
check(
  '답글 목록에도 인용이 실린다',
  replies.json.items[0]?.quoted?.id === quoting.json.id,
  JSON.stringify(replies.json.items[0]?.quoted),
);

// ── 삭제된 원본 ────────────────────────────────
console.log('\n[삭제된 원본]');

const doomed = await api(
  'POST',
  `/spaces/${spaceId}/channels/${channel.id}/messages`,
  { token: alice.token, body: { body: '곧 지울 원본' } },
);
const quotingDoomed = await api(
  'POST',
  `/spaces/${spaceId}/channels/${channel.id}/messages`,
  {
    token: alice.token,
    body: { body: '지워질 것을 인용', quotedMessageId: doomed.json.id },
  },
);
await api('DELETE', `/spaces/${spaceId}/messages/${doomed.json.id}`, {
  token: alice.token,
});

const afterDelete = await api(
  'GET',
  `/spaces/${spaceId}/channels/${channel.id}/messages?limit=30`,
  { token: alice.token },
);
const stillQuoting = afterDelete.json.items.find(
  (m) => m.id === quotingDoomed.json.id,
);
check(
  '★ 원본이 삭제돼도 인용 링크는 남는다 — 답장의 맥락은 그때도 필요하다',
  stillQuoting && stillQuoting.quoted && stillQuoting.quoted.deleted === true,
  JSON.stringify(stillQuoting?.quoted),
);
check(
  '★ 삭제된 원본의 본문은 인용에도 새지 않는다',
  stillQuoting && stillQuoting.quoted.body === '',
  JSON.stringify(stillQuoting?.quoted?.body),
);

// ── 규칙 ──────────────────────────────────────
console.log('\n[규칙]');

const otherChannel = await api('POST', `/spaces/${spaceId}/channels`, {
  token: alice.token,
  body: { name: '다른 채널' },
});
const crossChannel = await api(
  'POST',
  `/spaces/${spaceId}/channels/${otherChannel.json.id}/messages`,
  { token: alice.token, body: { body: 'x', quotedMessageId: originalId } },
);
check(
  '★ 다른 채널의 메시지는 인용할 수 없다 (404) — 못 보는 대화가 새면 안 된다',
  crossChannel.status === 404,
  `status=${crossChannel.status}`,
);

const missing = await api(
  'POST',
  `/spaces/${spaceId}/channels/${channel.id}/messages`,
  {
    token: alice.token,
    body: { body: 'x', quotedMessageId: '00000000-0000-4000-8000-000000000000' },
  },
);
check('없는 메시지 인용은 404', missing.status === 404, `status=${missing.status}`);

const badUuid = await api(
  'POST',
  `/spaces/${spaceId}/channels/${channel.id}/messages`,
  { token: alice.token, body: { body: 'x', quotedMessageId: 'nope' } },
);
check('형식이 틀리면 400', badUuid.status === 400, `status=${badUuid.status}`);

// ── 소켓 ──────────────────────────────────────
console.log('\n[소켓]');

const socket = await connect(alice.token);
check('소켓 연결', !!socket.on);
await new Promise((r) => setTimeout(r, 500));

const incoming = waitFor(socket, 'message:new');
await api('POST', `/spaces/${spaceId}/channels/${channel.id}/messages`, {
  token: alice.token,
  body: { body: '소켓으로 올 답장', quotedMessageId: originalId },
});
const event = await incoming;
check(
  '★ 소켓 페이로드에도 인용 요약이 실린다 — 받는 쪽이 다시 조회하지 않아도 된다',
  event && event.message.quoted && event.message.quoted.id === originalId,
  JSON.stringify(event?.message?.quoted),
);

if (socket.close) socket.close();

console.log(`\n통과 ${pass} · 실패 ${fail}\n`);
process.exit(fail === 0 ? 0 : 1);
