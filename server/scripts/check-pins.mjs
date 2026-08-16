// 핀(7-5) 검증. 실제 서버 · 실제 DB · 실제 소켓으로 확인한다.
//
// 사전 조건: npm run db:up && npm run server:dev
// 사용: npm run check:pins
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
      email: `pin-${tag}-${stamp}@example.com`,
      password: 'check-pins-1234',
      name: `핀검증${tag}`,
      client: 'native',
    },
  });
  if (res.status !== 201) {
    console.error('가입 실패:', res.status, JSON.stringify(res.json));
    process.exit(1);
  }
  return { token: res.json.accessToken, userId: res.json.user.id };
}

console.log('\n핀 검증 — 실서버 · 실DB · 실소켓\n');

const alice = await signup('a');
const outsider = await signup('x');

const space = await api('POST', '/spaces', {
  token: alice.token,
  body: { name: `핀 검증 ${stamp}` },
});
const spaceId = space.json.id;
const channels = await api('GET', `/spaces/${spaceId}/channels`, {
  token: alice.token,
});
const channel = channels.json[0];
check('스페이스 · 채널 준비', !!channel);

const send = (body) =>
  api('POST', `/spaces/${spaceId}/channels/${channel.id}/messages`, {
    token: alice.token,
    body,
  });

const first = await send({ body: '고정할 메시지' });
const second = await send({ body: '두 번째로 고정할 메시지' });
const plain = await send({ body: '고정하지 않을 메시지' });

// ── 고정 ──────────────────────────────────────
console.log('\n[고정 · 해제]');

const pinned = await api('POST', `/spaces/${spaceId}/messages/${first.json.id}/pin`, {
  token: alice.token,
});
check('고정', pinned.status === 201, `status=${pinned.status}`);
check('응답에 pinned=true 가 실린다', pinned.json.pinned === true, JSON.stringify(pinned.json.pinned));

const again = await api('POST', `/spaces/${spaceId}/messages/${first.json.id}/pin`, {
  token: alice.token,
});
check(
  '★ 이미 고정된 것을 다시 고정해도 오류가 아니다 (멱등)',
  again.status === 201 && again.json.pinned === true,
  `status=${again.status}`,
);

await api('POST', `/spaces/${spaceId}/messages/${second.json.id}/pin`, {
  token: alice.token,
});

const pins = await api('GET', `/spaces/${spaceId}/channels/${channel.id}/pins`, {
  token: alice.token,
});
check('핀 목록 200', pins.status === 200, `status=${pins.status}`);
check(
  '★ 고정한 것만 나온다',
  pins.json.length === 2 &&
    !pins.json.some((m) => m.id === plain.json.id),
  JSON.stringify(pins.json.map((m) => m.body)),
);
check(
  '최신순이다',
  pins.json[0].body === '두 번째로 고정할 메시지',
  JSON.stringify(pins.json.map((m) => m.body)),
);
check(
  '핀 목록에도 리액션 · 인용 · 멘션이 실린다',
  Array.isArray(pins.json[0].reactions) &&
    Array.isArray(pins.json[0].mentions) &&
    'quoted' in pins.json[0],
  JSON.stringify(Object.keys(pins.json[0])),
);

const unpinned = await api(
  'DELETE',
  `/spaces/${spaceId}/messages/${first.json.id}/pin`,
  { token: alice.token },
);
check('해제', unpinned.status === 200 && unpinned.json.pinned === false, `status=${unpinned.status}`);

const unpinAgain = await api(
  'DELETE',
  `/spaces/${spaceId}/messages/${first.json.id}/pin`,
  { token: alice.token },
);
check(
  '★ 고정되지 않은 것을 해제해도 오류가 아니다 (멱등)',
  unpinAgain.status === 200,
  `status=${unpinAgain.status}`,
);

const afterUnpin = await api(
  'GET',
  `/spaces/${spaceId}/channels/${channel.id}/pins`,
  { token: alice.token },
);
check('해제하면 목록에서 빠진다', afterUnpin.json.length === 1, `${afterUnpin.json.length}`);

// ── 목록에 pinned 가 실린다 ────────────────────
const list = await api(
  'GET',
  `/spaces/${spaceId}/channels/${channel.id}/messages?limit=10`,
  { token: alice.token },
);
check(
  '★ 채널 목록에도 pinned 가 실린다 - 메시지 옆에 표시하려면 필요하다',
  list.json.items.find((m) => m.id === second.json.id)?.pinned === true,
  JSON.stringify(list.json.items.map((m) => ({ b: m.body, p: m.pinned }))),
);

// ── 규칙 ──────────────────────────────────────
console.log('\n[규칙]');

const reply = await send({ body: '답글', parentId: second.json.id });
const pinReply = await api(
  'POST',
  `/spaces/${spaceId}/messages/${reply.json.id}/pin`,
  { token: alice.token },
);
check(
  '★ 답글은 고정할 수 없다 (400) - 상단 목록에서 맥락 없이 뜬다',
  pinReply.status === 400,
  `status=${pinReply.status}`,
);

const doomed = await send({ body: '곧 지울 메시지' });
await api('DELETE', `/spaces/${spaceId}/messages/${doomed.json.id}`, {
  token: alice.token,
});
const pinDeleted = await api(
  'POST',
  `/spaces/${spaceId}/messages/${doomed.json.id}/pin`,
  { token: alice.token },
);
check(
  '삭제된 메시지는 고정할 수 없다 (400)',
  pinDeleted.status === 400,
  `status=${pinDeleted.status}`,
);

const byOutsider = await api(
  'POST',
  `/spaces/${spaceId}/messages/${second.json.id}/pin`,
  { token: outsider.token },
);
check(
  '★ 비멤버는 404 - 403 이 아니다',
  byOutsider.status === 404,
  `status=${byOutsider.status}`,
);

// 고정한 메시지를 지우면 목록에서 빠진다
const pinnedThenDeleted = await send({ body: '고정했다 지울 메시지' });
await api('POST', `/spaces/${spaceId}/messages/${pinnedThenDeleted.json.id}/pin`, {
  token: alice.token,
});
await api('DELETE', `/spaces/${spaceId}/messages/${pinnedThenDeleted.json.id}`, {
  token: alice.token,
});
const afterDelete = await api(
  'GET',
  `/spaces/${spaceId}/channels/${channel.id}/pins`,
  { token: alice.token },
);
check(
  '★ 고정한 메시지를 지우면 핀 목록에서 빠진다',
  !afterDelete.json.some((m) => m.id === pinnedThenDeleted.json.id),
  JSON.stringify(afterDelete.json.map((m) => m.body)),
);

// ── 소켓 ──────────────────────────────────────
console.log('\n[소켓]');

const socket = await connect(alice.token);
const outsiderSocket = await connect(outsider.token);
check('소켓 연결', !!socket.on && !!outsiderSocket.on);
await new Promise((r) => setTimeout(r, 500));

const event = waitFor(socket, 'pin:changed');
const leak = waitFor(outsiderSocket, 'pin:changed', 1500);

await api('POST', `/spaces/${spaceId}/messages/${first.json.id}/pin`, {
  token: alice.token,
});

const payload = await event;
check(
  '★ pin:changed 가 채널 룸으로 온다',
  payload && payload.messageId === first.json.id && payload.pinned === true,
  JSON.stringify(payload),
);
check('★ 비멤버에게는 가지 않는다', (await leak) === null, '비멤버가 받았다');

const unpinEvent = waitFor(socket, 'pin:changed');
await api('DELETE', `/spaces/${spaceId}/messages/${first.json.id}/pin`, {
  token: alice.token,
});
check(
  '해제도 브로드캐스트된다',
  (await unpinEvent)?.pinned === false,
  '해제 이벤트가 오지 않았다',
);

for (const s of [socket, outsiderSocket]) {
  if (s.close) s.close();
}

console.log(`\n통과 ${pass} · 실패 ${fail}\n`);
process.exit(fail === 0 ? 0 : 1);
