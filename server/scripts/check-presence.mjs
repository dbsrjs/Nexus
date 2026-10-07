// 프레즌스 · 타이핑(17-2) 검증 — 실서버 · 실소켓.
//
// 사전 조건: npm run db:up && npm run server:dev
// 사용: npm run check:presence
//
// 오프라인 유예(5초)를 실제로 기다리므로 스크립트가 30초쯤 걸린다.
// 자체 계정 넷 — owner(ann) · member(ben) · member(cat) · 함께 쓰는 스페이스가 없는 eve.
import { requireServer } from './lib/preflight.mjs';
import { BASE, api, signup, stamp } from './lib/api.mjs';
import { check, summary } from './lib/checks.mjs';
import { connect, waitFor } from './lib/socket.mjs';
await requireServer(BASE);

console.log('\n프레즌스 · 타이핑 검증 — 실서버 · 실소켓\n');

const GRACE = 5000;
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

const ann = await signup('presence', 'a', 'Presence A');
const ben = await signup('presence', 'b', 'Presence B');
const cat = await signup('presence', 'c', 'Presence C');
const eve = await signup('presence', 'e', 'Presence E');

const space = await api('POST', '/spaces', { token: ann.token, body: { name: `presence ${stamp}` } });
const spaceId = space.json?.id;
for (const who of [ben, cat]) {
  const inv = await api('POST', `/spaces/${spaceId}/invites`, { token: ann.token, body: { role: 'member' } });
  await api('POST', `/invites/${inv.json?.code}/accept`, { token: who.token });
}
await api('POST', '/spaces', { token: eve.token, body: { name: `presence other ${stamp}` } });
const general = (await api('GET', `/spaces/${spaceId}/channels`, { token: ann.token })).json?.[0]?.id;
check('준비 (스페이스 · 멤버 · 채널)', !!spaceId && !!general);

/** `presence:changed` 중 그 사람 것만 기다린다. */
function presenceOf(socket, userId, ms = 3000) {
  return new Promise((resolve) => {
    const timer = setTimeout(() => {
      socket.off('presence:changed', handler);
      resolve(null);
    }, ms);
    const handler = (p) => {
      if (p?.userId !== userId) return;
      clearTimeout(timer);
      socket.off('presence:changed', handler);
      resolve(p.status);
    };
    socket.on('presence:changed', handler);
  });
}
const snapshot = async (who = ann) =>
  (await api('GET', `/spaces/${spaceId}/presence`, { token: who.token })).json?.users ?? {};
const ready = async (socket) => {
  await socket.emitWithAck('rooms:sync');
  return socket;
};

// ── 프레즌스 ───────────────────────────────────
console.log('\n[프레즌스]');

const annSocket = await ready(await connect(ann.token));
const eveSocket = await ready(await connect(eve.token));
const annSees = presenceOf(annSocket, ben.userId);
const eveSees = presenceOf(eveSocket, ben.userId, 1500);
const ben1 = await ready(await connect(ben.token));
check('함께 쓰는 사람이 온라인을 받는다', (await annSees) === 'online');
check('★ 함께 쓰는 스페이스가 없는 사람은 받지 않는다(D18)', (await eveSees) === null);
check('처음 값 — 온라인', (await snapshot())[ben.userId] === 'online');
check('처음 값에 나도 있다', (await snapshot())[ann.userId] === 'online');
const evePeek = await api('GET', `/spaces/${spaceId}/presence`, { token: eve.token });
check('남의 스페이스 처음 값은 404', evePeek.status === 404, `status=${evePeek.status}`);

const ben2 = await ready(await connect(ben.token));
const quiet = presenceOf(annSocket, ben.userId, 1200);
const away1 = await ben1.emitWithAck('presence:set', { status: 'away' });
check('presence:set 을 받는다', away1?.ok === true, JSON.stringify(away1));
check('★ 다른 소켓이 온라인이면 그대로 온라인(D15)', (await quiet) === null && (await snapshot())[ben.userId] === 'online');
const awaySees = presenceOf(annSocket, ben.userId);
await ben2.emitWithAck('presence:set', { status: 'away' });
check('모든 소켓이 away 면 자리비움', (await awaySees) === 'away');
check('처음 값 — 자리비움', (await snapshot())[ben.userId] === 'away');
const backSees = presenceOf(annSocket, ben.userId);
await ben2.emitWithAck('presence:set', { status: 'online' });
check('돌아오면 온라인', (await backSees) === 'online');
const badStatus = await ben2.emitWithAck('presence:set', { status: 'offline' });
check('offline 은 보낼 수 없다(끊는 것으로 알린다)', badStatus?.ok === false, JSON.stringify(badStatus));

// 두 소켓을 온라인으로 맞춘 뒤 끊는다. ben1 이 away 로 남아 있으면 서버가 끊김을 받는
// 순서에 따라(ben2 가 먼저면) 남은 ben1 때문에 오프라인 전에 'away' 가 한 번 나간다 —
// 서버로서는 맞는 전이라 검증 쪽 순서 경합이다(CI 에서 간헐 실패).
await ben1.emitWithAck('presence:set', { status: 'online' });
const offlineSees = presenceOf(annSocket, ben.userId, GRACE + 3000);
const t0 = Date.now();
ben1.close();
ben2.close();
const offline = await offlineSees;
const waited = Date.now() - t0;
check('★ 모두 끊기면 오프라인 — 유예 뒤에(D17)', offline === 'offline' && waited >= GRACE - 200, `${offline} after ${waited}ms`);
check('처음 값에서 빠진다', !((await snapshot()) ?? {})[ben.userId]);

const onAgain = presenceOf(annSocket, ben.userId);
let ben3 = await ready(await connect(ben.token));
check('다시 붙으면 온라인', (await onAgain) === 'online');
const flicker = presenceOf(annSocket, ben.userId, GRACE + 2000);
ben3.close();
await sleep(500);
ben3 = await ready(await connect(ben.token));
check('★ 유예 안에 다시 붙으면 아무것도 알리지 않는다', (await flicker) === null);
check('…그대로 온라인', (await snapshot())[ben.userId] === 'online');

// ── 타이핑 ─────────────────────────────────────
console.log('\n[타이핑]');

const ben4 = await ready(await connect(ben.token));
const catSocket = await ready(await connect(cat.token));
const annTyping = waitFor(annSocket, 'typing');
const selfTyping = waitFor(ben3, 'typing', 1200);
const sentOk = await ben3.emitWithAck('typing', { spaceId, channelId: general });
check('typing 을 받는다', sentOk?.ok === true, JSON.stringify(sentOk));
const got = await annTyping;
check(
  '같은 채널 사람이 받는다 — 보낸 사람 · 스레드 아님',
  got?.userId === ben.userId && got?.channelId === general && got?.parentId === null,
  JSON.stringify(got),
);
check('★ 보낸 소켓은 받지 않는다', (await selfTyping) === null);

await sleep(1100);
const [firstOk, tooFast] = await Promise.all([
  ben3.emitWithAck('typing', { spaceId, channelId: general }),
  ben3.emitWithAck('typing', { spaceId, channelId: general }),
]);
check('…간격이 지나면 다시 받는다', firstOk?.ok === true, JSON.stringify(firstOk));
check('★ 1초 안의 반복은 버린다(D22)', tooFast?.ok === false && tooFast?.error === 'too_fast', JSON.stringify(tooFast));
await sleep(1100);
const parentId = '00000000-0000-4000-8000-000000000001';
const threadTyping = waitFor(annSocket, 'typing');
await ben3.emitWithAck('typing', { spaceId, channelId: general, parentId });
check('스레드는 parentId 를 싣는다', (await threadTyping)?.parentId === parentId);

const priv = await api('POST', `/spaces/${spaceId}/channels`, {
  token: ann.token,
  body: { name: `secret ${stamp}`, isPrivate: true },
});
const privId = priv.json?.id;
await api('POST', `/spaces/${spaceId}/channels/${privId}/members`, { token: ann.token, body: { userIds: [ben.userId] } });
for (const s of [annSocket, ben4, catSocket]) await s.emitWithAck('rooms:sync');
const catLeak = waitFor(catSocket, 'typing', 1200);
const benPriv = waitFor(ben4, 'typing');
await annSocket.emitWithAck('typing', { spaceId, channelId: privId });
check('비공개 채널 명단은 받는다', (await benPriv)?.channelId === privId);
check('★ 명단 밖 사람은 받지 않는다', (await catLeak) === null);
const catTries = await catSocket.emitWithAck('typing', { spaceId, channelId: privId });
check('★ 볼 수 없는 채널에 보내면 거부', catTries?.ok === false && catTries?.error === 'not_allowed', JSON.stringify(catTries));
const eveTries = await eveSocket.emitWithAck('typing', { spaceId, channelId: general });
check('★ 스페이스 밖 사람이 보내면 거부', eveTries?.ok === false && eveTries?.error === 'not_allowed', JSON.stringify(eveTries));

await api('PUT', `/spaces/${spaceId}/channels/${general}/permissions/member`, {
  token: ann.token,
  body: { canView: true, canSend: false },
});
await sleep(1100);
const readOnly = await ben4.emitWithAck('typing', { spaceId, channelId: general });
check('★ 읽기 전용 채널에서는 거부(D22)', readOnly?.ok === false && readOnly?.error === 'not_allowed', JSON.stringify(readOnly));
const ownerOk = await annSocket.emitWithAck('typing', { spaceId, channelId: general });
check('…보낼 수 있는 사람은 그대로', ownerOk?.ok === true, JSON.stringify(ownerOk));
const bad = await annSocket.emitWithAck('typing', { spaceId, channelId: 'nope' });
check('잘못된 페이로드는 거부 — 연결은 산다', bad?.error === 'invalid_payload' && annSocket.connected, JSON.stringify(bad));

for (const s of [annSocket, eveSocket, ben3, ben4, catSocket]) s?.close?.();
process.exit(summary() === 0 ? 0 : 1);
