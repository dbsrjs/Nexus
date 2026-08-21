// 리액션(7-1) 검증. 실제 서버 · 실제 DB · 실제 소켓으로 확인한다.
//
// 스키마와 쿼리가 걸린 변경은 스텁으로 증명할 수 없다 — 그렇게 22개를 통과시킨
// 코드에서 실 DB 를 붙이자마자 버그 두 개가 나왔다(docs/전환-계획.md §6).
//
// 사전 조건:
//   npm run db:up && npm run server:dev   (다른 터미널)
//
// 사용: npm run check:reactions
//
// 시드 비밀번호를 받지 않는다. **자체 계정 · 자체 스페이스를 만들어 쓰므로**
// 기존 데이터를 건드리지 않고, 시드를 다시 돌린 뒤에도 그대로 동작한다.
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
      email: `reaction-${tag}-${stamp}@example.com`,
      password: 'check-reactions-1234',
      name: `리액션검증${tag}`,
      client: 'native',
    },
  });
  if (res.status !== 201) {
    console.error('가입 실패:', res.status, JSON.stringify(res.json));
    process.exit(1);
  }
  return { token: res.json.accessToken, userId: res.json.user.id };
}

console.log('\n리액션 검증 — 실서버 · 실DB · 실소켓\n');

const alice = await signup('a');
const bob = await signup('b');
const outsider = await signup('x');

const space = await api('POST', '/spaces', {
  token: alice.token,
  body: { name: `리액션 검증 ${stamp}` },
});
check('스페이스 생성', space.status === 201, `status=${space.status}`);
const spaceId = space.json.id;

const channels = await api('GET', `/spaces/${spaceId}/channels`, {
  token: alice.token,
});
const channel = channels.json[0];
check('기본 채널이 있다', !!channel);

const sent = await api('POST', `/spaces/${spaceId}/channels/${channel.id}/messages`, {
  token: alice.token,
  body: { body: '리액션을 달아 볼 메시지' },
});
check('메시지 전송', sent.status === 201, `status=${sent.status}`);
const messageId = sent.json.id;

// ── REST ──────────────────────────────────────
console.log('\n[REST]');

const added = await api('POST', `/spaces/${spaceId}/messages/${messageId}/reactions`, {
  token: alice.token,
  body: { emoji: '👍' },
});
check(
  '추가하면 요약이 돌아온다 — count 1 · mine true',
  added.status === 201 &&
    added.json.length === 1 &&
    added.json[0].emoji === '👍' &&
    added.json[0].count === 1 &&
    added.json[0].mine === true,
  JSON.stringify(added.json),
);

const again = await api('POST', `/spaces/${spaceId}/messages/${messageId}/reactions`, {
  token: alice.token,
  body: { emoji: '👍' },
});
check(
  '★ 같은 이모지를 다시 눌러도 오류가 아니고 count 가 늘지 않는다 (멱등)',
  again.status === 201 && again.json[0].count === 1,
  JSON.stringify(again.json),
);

await api('POST', `/spaces/${spaceId}/messages/${messageId}/reactions`, {
  token: alice.token,
  body: { emoji: '🎉' },
});
const combined = await api(
  'POST',
  `/spaces/${spaceId}/messages/${messageId}/reactions`,
  { token: alice.token, body: { emoji: '👩‍💻' } },
);
check(
  '★ 결합 이모지(👩‍💻)도 받는다',
  combined.status === 201 && combined.json.some((r) => r.emoji === '👩‍💻'),
  JSON.stringify(combined.json),
);

const list = await api(
  'GET',
  `/spaces/${spaceId}/channels/${channel.id}/messages?limit=5`,
  { token: alice.token },
);
const inList = list.json.items.find((m) => m.id === messageId);
check(
  '★ 목록에 리액션이 실려 온다 — 처음 눌린 순서를 유지한다',
  inList &&
    inList.reactions.length === 3 &&
    inList.reactions[0].emoji === '👍' &&
    inList.reactions[1].emoji === '🎉',
  JSON.stringify(inList?.reactions),
);

const removed = await api(
  'DELETE',
  `/spaces/${spaceId}/messages/${messageId}/reactions/${encodeURIComponent('👍')}`,
  { token: alice.token },
);
check(
  '제거하면 그 이모지가 빠진다',
  removed.status === 200 && !removed.json.some((r) => r.emoji === '👍'),
  JSON.stringify(removed.json),
);

const removeAgain = await api(
  'DELETE',
  `/spaces/${spaceId}/messages/${messageId}/reactions/${encodeURIComponent('👍')}`,
  { token: alice.token },
);
check(
  '★ 없는 것을 지워도 오류가 아니다 (멱등)',
  removeAgain.status === 200,
  `status=${removeAgain.status}`,
);

// ── 입력 검증 ──────────────────────────────────
console.log('\n[입력 검증]');

const tooLong = await api('POST', `/spaces/${spaceId}/messages/${messageId}/reactions`, {
  token: alice.token,
  body: { emoji: '이건이모지가아니라아주긴문자열입니다정말로깁니다' },
});
check('긴 문자열은 400', tooLong.status === 400, `status=${tooLong.status}`);

const withSpace = await api(
  'POST',
  `/spaces/${spaceId}/messages/${messageId}/reactions`,
  { token: alice.token, body: { emoji: 'a b' } },
);
check('공백이 든 값은 400', withSpace.status === 400, `status=${withSpace.status}`);

const extraField = await api(
  'POST',
  `/spaces/${spaceId}/messages/${messageId}/reactions`,
  { token: alice.token, body: { emoji: '👍', spaceId: 'x' } },
);
check(
  'DTO 밖 필드는 400 — 조용히 지우지 않는다',
  extraField.status === 400,
  `status=${extraField.status}`,
);

// ── 테넌트 격리 ────────────────────────────────
console.log('\n[테넌트 격리]');

const bogus = await api(
  'POST',
  `/spaces/${spaceId}/messages/00000000-0000-4000-8000-000000000000/reactions`,
  { token: alice.token, body: { emoji: '👍' } },
);
check('없는 메시지는 404', bogus.status === 404, `status=${bogus.status}`);

const byOutsider = await api(
  'POST',
  `/spaces/${spaceId}/messages/${messageId}/reactions`,
  { token: outsider.token, body: { emoji: '👍' } },
);
check(
  '★ 비멤버는 404 — 403 이 아니다(리소스 존재 자체를 숨긴다)',
  byOutsider.status === 404,
  `status=${byOutsider.status}`,
);

const doomed = await api('POST', `/spaces/${spaceId}/channels/${channel.id}/messages`, {
  token: alice.token,
  body: { body: '곧 지울 메시지' },
});
await api('DELETE', `/spaces/${spaceId}/messages/${doomed.json.id}`, {
  token: alice.token,
});
const onDeleted = await api(
  'POST',
  `/spaces/${spaceId}/messages/${doomed.json.id}/reactions`,
  { token: alice.token, body: { emoji: '👍' } },
);
check(
  '★ 삭제된 메시지에는 리액션을 달 수 없다',
  onDeleted.status === 404,
  `status=${onDeleted.status}`,
);

// ── 여럿이 누를 때 ──────────────────────────────
console.log('\n[여럿이 누를 때]');

const invite = await api('POST', `/spaces/${spaceId}/invites`, {
  token: alice.token,
  body: { role: 'member' },
});
const accepted = await api('POST', `/invites/${invite.json.code}/accept`, {
  token: bob.token,
});
check(
  '초대 수락',
  accepted.status === 200 || accepted.status === 201,
  `status=${accepted.status}`,
);

const byBob = await api('POST', `/spaces/${spaceId}/messages/${messageId}/reactions`, {
  token: bob.token,
  body: { emoji: '🎉' },
});
const bobRow = byBob.json.find((r) => r.emoji === '🎉');
check(
  '★ 같은 이모지를 둘이 누르면 count 2',
  bobRow && bobRow.count === 2 && bobRow.mine === true,
  JSON.stringify(byBob.json),
);

const aliceView = await api(
  'GET',
  `/spaces/${spaceId}/channels/${channel.id}/messages?limit=5`,
  { token: alice.token },
);
const aliceOnly = aliceView.json.items
  .find((m) => m.id === messageId)
  ?.reactions.find((r) => r.emoji === '👩‍💻');
check(
  '★ mine 은 보는 사람마다 다르게 계산된다',
  aliceOnly && aliceOnly.mine === true,
  JSON.stringify(aliceOnly),
);

// ── 소켓 ──────────────────────────────────────
console.log('\n[소켓]');

const aliceSocket = await connect(alice.token);
const bobSocket = await connect(bob.token);
const outsiderSocket = await connect(outsider.token);
check(
  '소켓 3개 연결',
  aliceSocket.on && bobSocket.on && outsiderSocket.on,
  '연결 실패',
);

// 룸 조인이 끝나기를 기다린다.
await new Promise((r) => setTimeout(r, 500));

const bobGets = waitFor(bobSocket, 'reaction:changed');
const outsiderShouldNotGet = waitFor(outsiderSocket, 'reaction:changed', 1500);

await api('POST', `/spaces/${spaceId}/messages/${messageId}/reactions`, {
  token: alice.token,
  body: { emoji: '🔥' },
});

const event = await bobGets;
check(
  '★ 같은 채널의 다른 사람에게 reaction:changed 가 간다',
  event && event.messageId === messageId,
  JSON.stringify(event),
);
check(
  '이벤트에 채널·스페이스가 실려 있다',
  event && event.spaceId === spaceId && event.channelId === channel.id,
  JSON.stringify(event),
);
check(
  '★ 페이로드에 mine 이 없다 — 받는 사람마다 답이 달라 브로드캐스트에 실을 수 없다',
  event &&
    Array.isArray(event.reactions) &&
    event.reactions.every((r) => !('mine' in r) && 'userId' in r),
  JSON.stringify(event?.reactions),
);
check(
  '★ 비멤버에게는 가지 않는다',
  (await outsiderShouldNotGet) === null,
  '비멤버가 이벤트를 받았다',
);

const removeEvent = waitFor(bobSocket, 'reaction:changed');
await api(
  'DELETE',
  `/spaces/${spaceId}/messages/${messageId}/reactions/${encodeURIComponent('🔥')}`,
  { token: alice.token },
);
const afterRemove = await removeEvent;
check(
  '제거도 브로드캐스트된다',
  afterRemove && !afterRemove.reactions.some((r) => r.emoji === '🔥'),
  JSON.stringify(afterRemove?.reactions),
);

for (const s of [aliceSocket, bobSocket, outsiderSocket]) {
  if (s.close) s.close();
}

console.log(`\n통과 ${pass} · 실패 ${fail}\n`);
process.exit(fail === 0 ? 0 : 1);
