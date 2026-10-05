// DM(17-1) 검증 — 열기 · 유일성 · 가시성 · 구조 API 404 · 떠난 상대.
// 실제 서버 · 실제 DB · 실제 소켓으로 확인한다.
//
// 사전 조건: npm run db:up && npm run server:dev
// 사용: npm run check:dm
//
// 자체 계정 넷 — owner(ann) · member(ben) · admin(cid, DM 밖의 셋째) · 스페이스 밖(eve).
import { requireServer } from './lib/preflight.mjs';
import { BASE, api, signup, stamp } from './lib/api.mjs';
import { check, summary } from './lib/checks.mjs';
import { connect, waitFor } from './lib/socket.mjs';
await requireServer(BASE);

console.log('\nDM 검증 — 실서버 · 실DB · 실소켓\n');

const ann = await signup('dm', 'a', 'Dm A');
const ben = await signup('dm', 'b', 'Dm B');
const cid = await signup('dm', 'c', 'Dm C');
const eve = await signup('dm', 'e', 'Dm E');

const space = await api('POST', '/spaces', { token: ann.token, body: { name: `dm ${stamp}` } });
const spaceId = space.json?.id;
const join = async (who, role) => {
  const inv = await api('POST', `/spaces/${spaceId}/invites`, { token: ann.token, body: { role } });
  return api('POST', `/invites/${inv.json?.code}/accept`, { token: who.token });
};
const joinedB = await join(ben, 'member');
const joinedC = await join(cid, 'admin');
check('준비 (스페이스 · 멤버 셋)', !!spaceId && joinedB.status === 200 && joinedC.status === 200);

const openDm = (who, userId) => api('POST', `/spaces/${spaceId}/dms`, { token: who.token, body: { userId } });
const channelsOf = async (who) =>
  (await api('GET', `/spaces/${spaceId}/channels`, { token: who.token })).json ?? [];

// ── 열기 ───────────────────────────────────────
console.log('\n[열기]');

const benSocket = await connect(ben.token);
await benSocket.emitWithAck('rooms:sync');
const benRooms = waitFor(benSocket, 'rooms:invalidate');
const opened = await openDm(ann, ben.userId);
const dmId = opened.json?.id;
check('DM 을 연다(200)', opened.status === 200 && !!dmId, `status=${opened.status}`);
check(
  '응답은 채널 목록 한 줄 — kind=dm · 상대 · 비공개',
  opened.json?.kind === 'dm' && opened.json?.dmUserId === ben.userId && opened.json?.isPrivate === true,
  JSON.stringify({ kind: opened.json?.kind, dm: opened.json?.dmUserId }),
);
check('상대가 rooms:invalidate(dm.opened)를 받는다', (await benRooms)?.reason === 'dm.opened');

const again = await openDm(ann, ben.userId);
check('★ 다시 열면 같은 DM(멱등)', !!dmId && again.json?.id === dmId, `${again.json?.id} vs ${dmId}`);
const reverse = await openDm(ben, ann.userId);
check('★ 상대가 열어도 같은 DM', !!dmId && reverse.json?.id === dmId);
check('상대 쪽 응답의 dmUserId 는 나', reverse.json?.dmUserId === ann.userId);

// 같은 두 사람(ben · cid)이 동시에 연다 — key 유일성이 하나만 남긴다(D2).
const [r1, r2, r3] = await Promise.all([openDm(ben, cid.userId), openDm(cid, ben.userId), openDm(ben, cid.userId)]);
check(
  '★ 동시에 열어도 DM 은 하나',
  r1.status === 200 && r2.status === 200 && r3.status === 200 && r1.json?.id === r2.json?.id && r2.json?.id === r3.json?.id,
  `status=${r1.status},${r2.status},${r3.status}`,
);

const self = await openDm(ann, ann.userId);
check('자기 자신과는 400', self.status === 400, `status=${self.status}`);
const outsider = await openDm(ann, eve.userId);
check('스페이스 멤버가 아니면 404', outsider.status === 404, `status=${outsider.status}`);
const bad = await openDm(ann, 'not-a-uuid');
check('uuid 가 아니면 400', bad.status === 400, `status=${bad.status}`);
const eveOpens = await api('POST', `/spaces/${spaceId}/dms`, { token: eve.token, body: { userId: ann.userId } });
check('스페이스 밖의 사람은 404(SpaceGuard)', eveOpens.status === 404, `status=${eveOpens.status}`);

// ── 대화 · 목록 ─────────────────────────────────
console.log('\n[대화 · 목록]');

const annList0 = await channelsOf(ann);
const dmRow0 = annList0.find((c) => c.id === dmId);
check('목록에 DM 이 있다 — 아직 메시지 없음(lastMessageAt=null)', !!dmRow0 && dmRow0.lastMessageAt === null);
const general = annList0.find((c) => c.kind === 'text');
check('일반 채널은 kind=text · dmUserId=null', general?.dmUserId === null, JSON.stringify(general?.kind));

const msgEvent = waitFor(benSocket, 'message:new');
await benSocket.emitWithAck('rooms:sync');
const sent = await api('POST', `/spaces/${spaceId}/channels/${dmId}/messages`, {
  token: ann.token,
  body: { body: 'hello dm' },
});
check('DM 에 보낸다(201)', sent.status === 201, `status=${sent.status}`);
check('상대가 실시간으로 받는다', (await msgEvent)?.message?.body === 'hello dm');
const benRow = (await channelsOf(ben)).find((c) => c.id === dmId);
check('상대 목록: 안 읽음 1 · lastMessageAt 이 찬다', benRow?.unreadCount === 1 && !!benRow?.lastMessageAt, JSON.stringify(benRow));

// ── 셋째 사람 ──────────────────────────────────
console.log('\n[셋째 사람 — 관리자도 못 본다]');

const cidSocket = await connect(cid.token);
await cidSocket.emitWithAck('rooms:sync');
const leak = waitFor(cidSocket, 'message:new', 1200);
await api('POST', `/spaces/${spaceId}/channels/${dmId}/messages`, { token: ben.token, body: { body: 'secret' } });
check('★ 셋째 사람의 소켓은 DM 메시지를 받지 않는다', (await leak) === null);
check('★ 셋째 사람 목록에 남의 DM 이 없다', !(await channelsOf(cid)).some((c) => c.id === dmId));
const peek = await api('GET', `/spaces/${spaceId}/channels/${dmId}/messages`, { token: cid.token });
check('셋째 사람이 메시지를 읽으면 404', peek.status === 404, `status=${peek.status}`);
const peekOne = await api('GET', `/spaces/${spaceId}/channels/${dmId}`, { token: cid.token });
check('셋째 사람이 채널을 열면 404', peekOne.status === 404, `status=${peekOne.status}`);

// ── 구조 API 는 DM 을 모른다(D7) ─────────────────
console.log('\n[구조 API 404]');

const patch = await api('PATCH', `/spaces/${spaceId}/channels/${dmId}`, { token: ann.token, body: { name: 'x' } });
check('★ 이름 바꾸기 404(owner 이자 참여자라도)', patch.status === 404, `status=${patch.status}`);
const patchByAdmin = await api('PATCH', `/spaces/${spaceId}/channels/${dmId}`, { token: cid.token, body: { isPrivate: false } });
check('★ 관리자가 공개로 돌리기 404', patchByAdmin.status === 404, `status=${patchByAdmin.status}`);
const joinDm = await api('POST', `/spaces/${spaceId}/channels/${dmId}/join`, { token: ann.token });
check('참여(join) 404', joinDm.status === 404, `status=${joinDm.status}`);
const roster = await api('GET', `/spaces/${spaceId}/channels/${dmId}/members`, { token: ann.token });
check('명단 보기 404', roster.status === 404, `status=${roster.status}`);
const addThird = await api('POST', `/spaces/${spaceId}/channels/${dmId}/members`, {
  token: ann.token,
  body: { userIds: [cid.userId] },
});
check('★ 셋째를 들이기 404', addThird.status === 404, `status=${addThird.status}`);
const perms = await api('PUT', `/spaces/${spaceId}/channels/${dmId}/permissions/member`, {
  token: ann.token,
  body: { canView: true, canSend: false },
});
check('권한 바꾸기 404', perms.status === 404, `status=${perms.status}`);
const repo = await api('POST', `/spaces/${spaceId}/repos`, {
  token: ann.token,
  body: { provider: 'github', fullPath: `dm/check-${stamp}`, linkedChannelId: dmId },
});
check('저장소를 DM 에 잇기 404', repo.status === 404, `status=${repo.status}`);
const mute = await api('PUT', `/spaces/${spaceId}/channels/${dmId}/mute`, { token: ann.token, body: { muted: true } });
check('음소거는 된다(내 설정)', mute.status === 200, `status=${mute.status}`);

// ── 떠난 상대 ──────────────────────────────────
console.log('\n[떠난 상대 — 읽기 전용]');

const leave = await api('POST', `/spaces/${spaceId}/leave`, { token: ben.token });
check('상대가 스페이스를 나간다', leave.status === 204, `status=${leave.status}`);
const annRow = (await channelsOf(ann)).find((c) => c.id === dmId);
check('★ DM 은 남고 canSend=false(D8)', !!annRow && annRow.canSend === false, JSON.stringify(annRow?.canSend));
check('…상대 id 는 그대로(key 에서 읽는다)', annRow?.dmUserId === ben.userId);
const history = await api('GET', `/spaces/${spaceId}/channels/${dmId}/messages`, { token: ann.token });
check('대화는 읽힌다', history.status === 200 && (history.json?.items ?? history.json ?? []).length >= 2, `status=${history.status}`);
const blocked = await api('POST', `/spaces/${spaceId}/channels/${dmId}/messages`, {
  token: ann.token,
  body: { body: 'anyone?' },
});
check('★ 보내면 403', blocked.status === 403, `status=${blocked.status}`);
const reopenGone = await openDm(ann, ben.userId);
check('떠난 사람과 새로 열면 404', reopenGone.status === 404, `status=${reopenGone.status}`);

const back = await join(ben, 'member');
check('상대가 다시 들어온다', back.status === 200);
check('다시 들어온 사람 목록에는 아직 DM 이 없다(명단 행이 지워졌다)', !(await channelsOf(ben)).some((c) => c.id === dmId));
const annRow2 = (await channelsOf(ann)).find((c) => c.id === dmId);
check('…돌아오면 다시 보낼 수 있다', annRow2?.canSend === true);
const revive = await openDm(ben, ann.userId);
check('★ 다시 열면 같은 DM 이 살아난다(D4)', revive.json?.id === dmId, `${revive.json?.id}`);
const benHistory = await api('GET', `/spaces/${spaceId}/channels/${dmId}/messages`, { token: ben.token });
check('…지난 대화가 그대로 보인다', benHistory.status === 200, `status=${benHistory.status}`);

for (const s of [benSocket, cidSocket]) s?.close?.();
process.exit(summary() === 0 ? 0 : 1);
