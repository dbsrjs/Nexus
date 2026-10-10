// 음성 채널(20단계) 검증 — 실서버 · 실DB · 실소켓 · **실제 LiveKit**.
//
// 사전 조건: npm run db:up && npm run server:dev, 그리고 LiveKit
//   docker compose -f server/docker-compose.yml --profile voice up -d livekit
//   (server/.env 에 LIVEKIT_URL · LIVEKIT_API_KEY · LIVEKIT_API_SECRET — .env.example 의 개발값)
// 사용: npm run check:voice
//
// **미디어는 보내지 않는다.** 시그널 WebSocket 만 붙여도 LiveKit 은 참가자를 JOINED 로 세고
// 웹훅 · 참가자 목록 · 내보내기가 실제처럼 돈다(2026-10-10 v1.9.1 에서 확인). 소리가 실제로
// 오가는지는 이 검증이 보지 않는다 — 앱을 두 창 띄워 사람이 듣는다.
//
// 자체 계정 넷 — owner(ann) · member(ben) · member(cat) · 다른 스페이스의 eve.
import { createHash, createHmac } from 'node:crypto';
import { requireServer } from './lib/preflight.mjs';
import { BASE, api, signup, stamp } from './lib/api.mjs';
import { check, summary } from './lib/checks.mjs';
import { connect } from './lib/socket.mjs';
await requireServer(BASE);

console.log('\n음성 채널 검증 — 실서버 · 실소켓 · 실제 LiveKit\n');

if (!process.env.LIVEKIT_API_SECRET) {
  try {
    process.loadEnvFile(new URL('../.env', import.meta.url));
  } catch {
    // 없으면 아래 준비 단계가 알린다.
  }
}
const LK_KEY = process.env.LIVEKIT_API_KEY ?? '';
const LK_SECRET = process.env.LIVEKIT_API_SECRET ?? '';
const LK_API = (process.env.LIVEKIT_API_URL || process.env.LIVEKIT_URL || '').replace(/^ws/, 'http');

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
const b64 = (obj) => Buffer.from(JSON.stringify(obj)).toString('base64url');
/** LiveKit 과 같은 방식의 HS256 JWT(웹훅 위조 · 서버 API 확인용). */
function lkJwt(payload, secret = LK_SECRET) {
  const now = Math.floor(Date.now() / 1000);
  const head = `${b64({ alg: 'HS256', typ: 'JWT' })}.${b64({ iss: LK_KEY, nbf: now, exp: now + 60, ...payload })}`;
  return `${head}.${createHmac('sha256', secret).update(head).digest('base64url')}`;
}
const decode = (jwt) => JSON.parse(Buffer.from(jwt.split('.')[1] ?? '', 'base64url').toString());

/** 검증이 LiveKit 에 직접 묻는다 — 서버가 말하는 것이 아니라 실제 룸의 상태를 본다. */
async function lkParticipants(room) {
  const res = await fetch(`${LK_API}/twirp/livekit.RoomService/ListParticipants`, {
    method: 'POST',
    headers: { 'content-type': 'application/json', authorization: `Bearer ${lkJwt({ video: { roomAdmin: true, room } })}` },
    body: JSON.stringify({ room }),
  });
  return res.ok ? ((await res.json()).participants ?? []) : null;
}

/** 시그널만 붙는 참가자. 닫히면 `closed` 가 풀린다. */
function joinSignal({ url, token }) {
  const ws = new WebSocket(`${url}/rtc?access_token=${token}&protocol=16&sdk=js&version=2.0.0&auto_subscribe=1`);
  const opened = new Promise((resolve) => {
    ws.onopen = () => resolve(true);
    ws.onerror = () => resolve(false);
  });
  const closed = new Promise((resolve) => ws.addEventListener('close', () => resolve(true)));
  return { ws, opened, closed };
}

/** `voice:state` 중 그 채널에서 조건이 맞는 것을 기다린다. */
function stateWhere(socket, channelId, pred, ms = 5000) {
  return new Promise((resolve) => {
    const timer = setTimeout(() => {
      socket.off('voice:state', handler);
      resolve(null);
    }, ms);
    const handler = (p) => {
      if (p?.channelId !== channelId || !pred(p.userIds ?? [])) return;
      clearTimeout(timer);
      socket.off('voice:state', handler);
      resolve(p);
    };
    socket.on('voice:state', handler);
  });
}
const within = (p, ms) => Promise.race([p, sleep(ms).then(() => false)]);

// ── 준비 ───────────────────────────────────────
const status = await api('GET', '/voice', { token: (await signup('voice', 'probe')).token });
check('준비 — 서버의 통화가 켜져 있다(LIVEKIT_*)', status.json?.enabled === true, JSON.stringify(status.json));
check('준비 — 검증이 LiveKit 키를 안다', !!LK_KEY && !!LK_SECRET && !!LK_API);
if (status.json?.enabled !== true || !LK_SECRET) {
  summary();
  process.exit(1);
}

const ann = await signup('voice', 'a', 'Voice A');
const ben = await signup('voice', 'b', 'Voice B');
const cat = await signup('voice', 'c', 'Voice C');
const eve = await signup('voice', 'e', 'Voice E');
const space = await api('POST', '/spaces', { token: ann.token, body: { name: `voice ${stamp}` } });
const spaceId = space.json?.id;
for (const who of [ben, cat]) {
  const inv = await api('POST', `/spaces/${spaceId}/invites`, { token: ann.token, body: { role: 'member' } });
  await api('POST', `/invites/${inv.json?.code}/accept`, { token: who.token });
}
const eveSpace = (await api('POST', '/spaces', { token: eve.token, body: { name: `voice other ${stamp}` } })).json;
const ch = (path = '') => `/spaces/${spaceId}/channels${path}`;
const text = (await api('GET', ch(), { token: ann.token })).json?.[0];
check('준비 (스페이스 · 멤버 · 글 채널)', !!spaceId && !!text?.id && !!eveSpace?.id);

// ── 만들기 ─────────────────────────────────────
console.log('\n[만들기]');
const made = await api('POST', ch(), { token: ann.token, body: { name: 'Lounge', kind: 'voice' } });
const lounge = made.json;
check('음성 채널을 만든다', made.status === 201 && lounge?.kind === 'voice', `status=${made.status} kind=${lounge?.kind}`);
const listed = (await api('GET', ch(), { token: ben.token })).json?.find((c) => c.id === lounge?.id);
check('목록에 kind=voice 로 보인다', listed?.kind === 'voice');
const dmKind = await api('POST', ch(), { token: ann.token, body: { name: 'x', kind: 'dm' } });
check('kind=dm 은 이 경로로 못 만든다(400)', dmKind.status === 400, `status=${dmKind.status}`);
const memberMakes = await api('POST', ch(), { token: ben.token, body: { name: 'y', kind: 'voice' } });
check('member 는 채널을 못 만든다(403 — 채널 만들기와 같은 규칙)', memberMakes.status === 403, `status=${memberMakes.status}`);
const priv = (await api('POST', ch(), { token: ann.token, body: { name: 'Secret', kind: 'voice', isPrivate: true } })).json;
check('비공개 음성 채널', priv?.kind === 'voice' && priv?.isPrivate === true);
const voiceMsg = await api('POST', ch(`/${lounge?.id}/messages`), { token: ann.token, body: { body: 'hello' } });
check('★ 음성 채널에는 메시지를 못 보낸다(400 — 보일 곳이 없다)', !!lounge?.id && voiceMsg.status === 400, `status=${voiceMsg.status}`);
const textMsg = await api('POST', ch(`/${text?.id}/messages`), { token: ann.token, body: { body: 'hello' } });
check('글 채널은 그대로 보낸다', textMsg.status === 201, `status=${textMsg.status}`);

// ── 토큰 ───────────────────────────────────────
console.log('\n[토큰]');
const tokenOf = (who, channelId, sid = spaceId) =>
  api('POST', `/spaces/${sid}/channels/${channelId}/voice/token`, { token: who.token });
const benTok = await tokenOf(ben, lounge?.id);
const claims = benTok.json?.token ? decode(benTok.json.token) : null;
check('토큰을 준다', benTok.status === 200 && !!benTok.json?.url && !!claims, `status=${benTok.status}`);
check('★ 룸은 <spaceId>:<channelId>', claims?.video?.room === `${spaceId}:${lounge?.id}`, claims?.video?.room);
check('identity 는 사용자 id', claims?.sub === ben.userId);
check('표시 이름이 실린다', claims?.name === 'Voice B');
check('말할 수 있다(canSpeak · canPublish)', benTok.json?.canSpeak === true && claims?.video?.canPublish === true);
check(
  '★ 카메라는 토큰에 없다 — 마이크 · 화면 공유만',
  JSON.stringify(claims?.video?.canPublishSources) === JSON.stringify(['microphone', 'screen_share', 'screen_share_audio']),
  JSON.stringify(claims?.video?.canPublishSources),
);
check('데이터 채널 · 메타데이터는 닫혀 있다', claims?.video?.canPublishData === false && claims?.video?.canUpdateOwnMetadata === false);
check('수명이 짧다(15분 이하)', claims && claims.exp - claims.nbf <= 15 * 60 && claims.exp > Date.now() / 1000);
check('LiveKit 키로 서명했다(iss)', claims?.iss === LK_KEY);

const textTok = await tokenOf(ben, text?.id);
check('글 채널이면 400', textTok.status === 400, `status=${textTok.status}`);
const eveTok = await tokenOf(eve, lounge?.id);
check('★ 스페이스 밖 사람은 404', eveTok.status === 404, `status=${eveTok.status}`);
const eveCross = await tokenOf(eve, lounge?.id, eveSpace?.id);
check('★ 자기 스페이스 경로로 남의 채널을 물어도 404', eveCross.status === 404, `status=${eveCross.status}`);
const catPriv = await tokenOf(cat, priv?.id);
check('★ 비공개 채널 명단 밖이면 404', catPriv.status === 404, `status=${catPriv.status}`);
const annPriv = await tokenOf(ann, priv?.id);
check('명단에 있으면 받는다', annPriv.status === 200);
const noAuth = await api('POST', `/spaces/${spaceId}/channels/${lounge?.id}/voice/token`);
check('로그인 없이는 401', noAuth.status === 401, `status=${noAuth.status}`);

// ── 웹훅 ───────────────────────────────────────
console.log('\n[웹훅]');
const hookBody = JSON.stringify({ event: 'room_started', room: { name: `${spaceId}:${lounge?.id}` }, id: 'EV_check', createdAt: '0' });
const hook = (auth, body = hookBody) =>
  fetch(`${BASE}/voice/webhook`, {
    method: 'POST',
    headers: { 'content-type': 'application/webhook+json', ...(auth ? { authorization: auth } : {}) },
    body,
  }).then((r) => r.status);
const sha = (b) => createHash('sha256').update(b).digest('base64');
check('서명이 맞으면 200', (await hook(lkJwt({ sha256: sha(hookBody) }))) === 200);
check('★ 서명이 없으면 401', (await hook(null)) === 401);
check('★ 다른 시크릿으로 서명하면 401', (await hook(lkJwt({ sha256: sha(hookBody) }, 'x'.repeat(40)))) === 401);
check('★ 본문을 바꾸면 401(원문 해시)', (await hook(lkJwt({ sha256: sha(hookBody) }), hookBody.replace('room_started', 'room_finished'))) === 401);
check('만료가 없는 토큰은 401', (await hook((() => {
  const head = `${b64({ alg: 'HS256', typ: 'JWT' })}.${b64({ iss: LK_KEY, sha256: sha(hookBody) })}`;
  return `${head}.${createHmac('sha256', LK_SECRET).update(head).digest('base64url')}`;
})())) === 401);

// ── 들어가기 · 상태 ─────────────────────────────
console.log('\n[들어가기 · 상태]');
const annSocket = await connect(ann.token);
await annSocket.emitWithAck('rooms:sync');
const eveSocket = await connect(eve.token);
await eveSocket.emitWithAck('rooms:sync');

const room = `${spaceId}:${lounge?.id}`;
const annSees = stateWhere(annSocket, lounge?.id, (ids) => ids.includes(ben.userId));
const eveHears = stateWhere(eveSocket, lounge?.id, () => true, 2000);
const benSignal = joinSignal(benTok.json);
check('LiveKit 에 붙는다(토큰이 통한다)', await benSignal.opened);
check('★ 같은 채널을 보는 사람이 voice:state 를 받는다', !!(await annSees));
check('★ 스페이스 밖 사람은 받지 않는다', (await eveHears) === null);
const snap = await api('GET', `/spaces/${spaceId}/voice`, { token: cat.token });
check('처음 값에 들어 있다', snap.json?.channels?.[lounge?.id]?.includes(ben.userId), JSON.stringify(snap.json));
const eveSnap = await api('GET', `/spaces/${spaceId}/voice`, { token: eve.token });
check('남의 스페이스 처음 값은 404', eveSnap.status === 404, `status=${eveSnap.status}`);

// 비공개 채널의 통화는 명단 밖 사람의 처음 값에 없다.
const annPrivSignal = joinSignal(annPriv.json);
await annPrivSignal.opened;
await sleep(1000);
const catSnap = (await api('GET', `/spaces/${spaceId}/voice`, { token: cat.token })).json?.channels ?? {};
const annSnap = (await api('GET', `/spaces/${spaceId}/voice`, { token: ann.token })).json?.channels ?? {};
check('비공개 채널 통화는 명단에 있는 사람에게 보인다', annSnap[priv?.id]?.includes(ann.userId), JSON.stringify(annSnap));
check('★ 명단 밖 사람의 처음 값에는 없다', !(priv?.id in catSnap), JSON.stringify(catSnap));
annPrivSignal.ws.close();

// ── 권한이 바뀌면 ────────────────────────────────
console.log('\n[권한이 바뀌면]');
await api('PUT', ch(`/${lounge?.id}/permissions/member`), { token: ann.token, body: { canView: true, canSend: false } });
let muted = false;
for (let i = 0; i < 20 && !muted; i++) {
  await sleep(250);
  const p = (await lkParticipants(room))?.find((x) => x.identity === ben.userId);
  muted = p?.permission?.can_publish === false;
}
check('★ 읽기 전용이 되면 통화 중에도 말하기가 꺼진다(LiveKit 에서 확인)', muted);
const roTok = await tokenOf(ben, lounge?.id);
check('읽기 전용이면 듣기만 하는 토큰', roTok.json?.canSpeak === false && decode(roTok.json.token)?.video?.canPublish === false);
await api('DELETE', ch(`/${lounge?.id}/permissions/member`), { token: ann.token });
let unmuted = false;
for (let i = 0; i < 20 && !unmuted; i++) {
  await sleep(250);
  const p = (await lkParticipants(room))?.find((x) => x.identity === ben.userId);
  unmuted = p?.permission?.can_publish === true;
}
check('되돌리면 다시 말할 수 있다', unmuted);

// ── 볼 수 없게 되면 ─────────────────────────────
console.log('\n[볼 수 없게 되면]');
const leftSees = stateWhere(annSocket, lounge?.id, (ids) => !ids.includes(ben.userId), 8000);
const kicked = await api('DELETE', `/spaces/${spaceId}/members/${ben.userId}`, { token: ann.token });
check('ben 을 내보낸다', kicked.status === 204 || kicked.status === 200, `status=${kicked.status}`);
check('★ 내보내면 LiveKit 연결이 끊긴다', await within(benSignal.closed, 8000));
check('★ 남은 사람에게 빠졌다고 알린다', !!(await leftSees));
const gone = (await lkParticipants(room)) ?? [];
check('LiveKit 룸에도 남지 않는다', !gone.some((p) => p.identity === ben.userId), JSON.stringify(gone.map((p) => p.identity)));

// 공개 → 비공개 전환 — 명단 밖 사람(cat)이 통화 중이면 끊긴다.
const catTok = await tokenOf(cat, lounge?.id);
const catSignal = joinSignal(catTok.json);
await catSignal.opened;
await stateWhere(annSocket, lounge?.id, (ids) => ids.includes(cat.userId));
await api('PATCH', ch(`/${lounge?.id}`), { token: ann.token, body: { isPrivate: true } });
check('★ 비공개로 바꾸면 명단 밖 참가자가 끊긴다', await within(catSignal.closed, 8000));

annSocket.close();
eveSocket.close();
process.exit(summary() === 0 ? 0 : 1);
