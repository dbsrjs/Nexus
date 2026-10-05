// 인앱 알림(18단계) 검증 — 만들기 · 고르기 · 음소거 · 스위치 · 가시성 · 읽음 · 소켓.
// 실제 서버 · 실제 DB · 실제 소켓으로 확인한다.
//
// 사전 조건: npm run db:up && npm run server:dev
// 사용: npm run check:notifications
//
// 자체 계정 넷 — owner(ann) · member(ben) · member(cid) · 스페이스 밖(eve).
import { requireServer } from './lib/preflight.mjs';
import { BASE, api, signup, stamp } from './lib/api.mjs';
import { check, summary } from './lib/checks.mjs';
import { connect, waitFor } from './lib/socket.mjs';
await requireServer(BASE);

console.log('\n인앱 알림 검증 — 실서버 · 실DB · 실소켓\n');

const ann = await signup('noti', 'a', 'Noti A');
const ben = await signup('noti', 'b', 'Noti B');
const cid = await signup('noti', 'c', 'Noti C');
const eve = await signup('noti', 'e', 'Noti E');

const space = await api('POST', '/spaces', { token: ann.token, body: { name: `noti ${stamp}` } });
const spaceId = space.json?.id;
const join = async (who, role) => {
  const inv = await api('POST', `/spaces/${spaceId}/invites`, { token: ann.token, body: { role } });
  return api('POST', `/invites/${inv.json?.code}/accept`, { token: who.token });
};
const joinedB = await join(ben, 'member');
const joinedC = await join(cid, 'member');
const general = ((await api('GET', `/spaces/${spaceId}/channels`, { token: ann.token })).json ?? []).find(
  (c) => c.kind === 'text' && !c.isPrivate,
);
check('준비 (스페이스 · 멤버 둘 · 공개 채널)', !!spaceId && joinedB.status === 200 && joinedC.status === 200 && !!general);
const generalId = general?.id;

const send = async (who, channelId, body, parentId) => {
  const res = await api('POST', `/spaces/${spaceId}/channels/${channelId}/messages`, {
    token: who.token,
    body: { body, ...(parentId ? { parentId } : {}) },
  });
  return res.json?.id;
};
const notesOf = async (who, query = '?limit=100') =>
  (await api('GET', `/spaces/${spaceId}/notifications${query}`, { token: who.token })).json?.items ?? [];
const noteFor = async (who, messageId) => (await notesOf(who)).filter((n) => n.messageId === messageId);
const unread = async (who) =>
  (await api('GET', `/spaces/${spaceId}/notifications/unread-count`, { token: who.token })).json?.count;

// ── 종류 넷 ─────────────────────────────────────
console.log('\n[종류 — 멘션 · @everyone · DM · 답글]');

const benSocket = await connect(ben.token);
const benSocket2 = await connect(ben.token);
const cidSocket = await connect(cid.token);

const benNew = waitFor(benSocket, 'notification:new');
const cidLeak = waitFor(cidSocket, 'notification:new', 1200);
const m1 = await send(ann, generalId, `hi <@${ben.userId}>`);
const benEvent = await benNew;
check('★ 직접 멘션 → 받는 사람 소켓에 notification:new', benEvent?.notification?.messageId === m1 && benEvent?.notification?.type === 'mention', JSON.stringify(benEvent?.notification?.type));
check('…페이로드에 spaceId', benEvent?.spaceId === spaceId);
check('★ 멘션되지 않은 사람 소켓에는 오지 않는다', (await cidLeak) === null);
const [n1] = await noteFor(ben, m1);
check('목록에 type=mention 한 줄', n1?.type === 'mention' && n1?.read === false, JSON.stringify(n1));
check(
  '한 줄의 모양 — actor · channel · body · threadId',
  n1?.actor?.id === ann.userId && n1?.actor?.name === 'Noti A' && n1?.channel?.kind === 'text' &&
    n1?.channel?.name === general?.name && n1?.body === `hi <@${ben.userId}>` && n1?.threadId === null &&
    n1?.deleted === false && n1?.channelId === generalId,
  JSON.stringify(n1),
);
check('★ 자기 글은 알리지 않는다', (await noteFor(ann, m1)).length === 0);

const m2 = await send(ann, generalId, '@everyone release today');
const [b2] = await noteFor(ben, m2);
const [c2] = await noteFor(cid, m2);
check('@everyone → 볼 수 있는 사람 모두 broadcast', b2?.type === 'broadcast' && c2?.type === 'broadcast', `${b2?.type},${c2?.type}`);
check('…작성자는 받지 않는다', (await noteFor(ann, m2)).length === 0);

const m3 = await send(ann, generalId, `@channel <@${ben.userId}> look`);
const b3 = await noteFor(ben, m3);
check('★ 겹치면 하나 — 멘션이 @channel 을 이긴다', b3.length === 1 && b3[0]?.type === 'mention', JSON.stringify(b3.map((n) => n.type)));
check('…다른 사람은 broadcast', (await noteFor(cid, m3))[0]?.type === 'broadcast');

const dm = await api('POST', `/spaces/${spaceId}/dms`, { token: ann.token, body: { userId: ben.userId } });
const dmId = dm.json?.id;
const m4 = await send(ann, dmId, 'psst');
const [b4] = await noteFor(ben, m4);
check('DM → 상대에게 dm', b4?.type === 'dm' && b4?.channel?.kind === 'dm', JSON.stringify(b4));
const m5 = await send(ann, dmId, `<@${ben.userId}> are you there`);
const b5 = await noteFor(ben, m5);
check('DM 에서 부르면 멘션 하나', b5.length === 1 && b5[0]?.type === 'mention', JSON.stringify(b5.map((n) => n.type)));
check('★ DM 밖의 사람은 받지 않는다', (await noteFor(cid, m4)).length === 0);

const root = await send(ben, generalId, 'my question');
const r1 = await send(cid, generalId, 'an answer', root);
const [b6] = await noteFor(ben, r1);
check('★ 내 글의 답글 → reply · threadId=부모', b6?.type === 'reply' && b6?.threadId === root, JSON.stringify(b6));
const r2 = await send(ann, generalId, 'another', root);
check('다른 사람의 답글도 부모 작성자에게', (await noteFor(ben, r2))[0]?.type === 'reply');
check('스레드 참여자(cid)는 받지 않는다(N4)', (await noteFor(cid, r2)).length === 0);
const r3 = await send(cid, generalId, `<@${ben.userId}> see this`, root);
const b7 = await noteFor(ben, r3);
check('답글에서 부르면 멘션 하나', b7.length === 1 && b7[0]?.type === 'mention' && b7[0]?.threadId === root);
const r4 = await send(ben, generalId, 'self reply', root);
check('제 글에 제가 단 답글은 없다', (await noteFor(ben, r4)).length === 0);

// ── 볼 수 없는 사람 ──────────────────────────────
console.log('\n[볼 수 없는 사람]');

const priv = await api('POST', `/spaces/${spaceId}/channels`, {
  token: ann.token,
  body: { name: `secret-${stamp}`, isPrivate: true },
});
const privId = priv.json?.id;
check('비공개 채널 준비', priv.status === 201 && !!privId, `status=${priv.status}`);
// 목록은 볼 수 있는 채널로 다시 거르므로(N15) 목록만 보면 만들기 쪽 구멍이 가려진다 —
// 소켓과 「나중에 명단에 들어와도 없다」로 본다.
const cidPrivLeak = waitFor(cidSocket, 'notification:new', 1200);
const p1 = await send(ann, privId, `<@${cid.userId}> secret plan`);
check('★ 명단 밖의 사람을 멘션해도 소켓으로 본문이 새지 않는다', !!p1 && (await cidPrivLeak) === null);
await api('POST', `/spaces/${spaceId}/channels/${privId}/members`, { token: ann.token, body: { userIds: [cid.userId] } });
check('★ …나중에 명단에 들어와도 그 알림은 없다(만들지 않았다)', !!p1 && (await noteFor(cid, p1)).length === 0);
await api('DELETE', `/spaces/${spaceId}/channels/${privId}/members/${cid.userId}`, { token: ann.token });
const p2 = await send(ann, privId, '@everyone in here');
check('@everyone 도 명단 밖에는 없다', !!p2 && (await noteFor(ben, p2)).length === 0 && (await noteFor(cid, p2)).length === 0);
const p3 = await send(ann, generalId, `<@${eve.userId}> hello stranger`);
check('스페이스 밖의 사람 id 는 버린다(메시지는 간다)', !!p3);
check('…스페이스 밖의 사람은 이 스페이스 알림을 못 본다(SpaceGuard 404)', (await api('GET', `/spaces/${spaceId}/notifications`, { token: eve.token })).status === 404);

// ── 음소거 ─────────────────────────────────────
console.log('\n[음소거 — 직접 멘션만]');

await api('PUT', `/spaces/${spaceId}/channels/${generalId}/mute`, { token: ben.token, body: { muted: true } });
const u1 = await send(ann, generalId, '@everyone muted?');
check('★ 음소거 → @everyone 은 오지 않는다', (await noteFor(ben, u1)).length === 0);
check('…음소거하지 않은 사람에게는 온다', (await noteFor(cid, u1))[0]?.type === 'broadcast');
const u2 = await send(ann, generalId, `<@${ben.userId}> still you`);
check('★ 음소거해도 직접 멘션은 온다', (await noteFor(ben, u2))[0]?.type === 'mention');
const u3 = await send(cid, generalId, 'muted reply', root);
check('음소거 → 내 글의 답글도 오지 않는다', (await noteFor(ben, u3)).length === 0);
check('음소거해도 이미 온 알림은 남는다(N8)', (await noteFor(ben, m2)).length === 1);
await api('PUT', `/spaces/${spaceId}/channels/${dmId}/mute`, { token: ben.token, body: { muted: true } });
const u4 = await send(ann, dmId, 'muted dm');
check('음소거한 DM → dm 은 오지 않는다', (await noteFor(ben, u4)).length === 0);
await api('PUT', `/spaces/${spaceId}/channels/${generalId}/mute`, { token: ben.token, body: { muted: false } });
await api('PUT', `/spaces/${spaceId}/channels/${dmId}/mute`, { token: ben.token, body: { muted: false } });

// ── 스위치 ─────────────────────────────────────
console.log('\n[스위치]');

const s0 = await api('GET', '/me/notification-settings', { token: ben.token });
check(
  '기본값은 넷 다 켜짐',
  s0.status === 200 && s0.json?.mentions === true && s0.json?.broadcast === true && s0.json?.dms === true && s0.json?.replies === true,
  JSON.stringify(s0.json),
);
const s1 = await api('PATCH', '/me/notification-settings', { token: ben.token, body: { dms: false } });
check('부분 갱신 — 하나만 꺼지고 응답은 넷 다', s1.status === 200 && s1.json?.dms === false && s1.json?.mentions === true, JSON.stringify(s1.json));
const w1 = await send(ann, dmId, 'dm while off');
check('★ DM 스위치를 끄면 dm 이 오지 않는다', (await noteFor(ben, w1)).length === 0);
const w2 = await send(ann, dmId, `<@${ben.userId}> but this`);
check('★ …DM 에서 부르면 멘션으로 내려간다', (await noteFor(ben, w2))[0]?.type === 'mention');
await api('PATCH', '/me/notification-settings', { token: ben.token, body: { mentions: false, broadcast: false } });
const w3 = await send(ann, generalId, `@everyone <@${ben.userId}> both off`);
check('멘션 · broadcast 를 다 끄면 없다', (await noteFor(ben, w3)).length === 0);
const s2 = await api('PATCH', '/me/notification-settings', {
  token: ben.token,
  body: { mentions: true, broadcast: true, dms: true, replies: true },
});
check('되돌린다', s2.json?.dms === true && s2.json?.broadcast === true);
const bad1 = await api('PATCH', '/me/notification-settings', { token: ben.token, body: { dms: 'no' } });
check('불리언이 아니면 400', bad1.status === 400, `status=${bad1.status}`);
const bad2 = await api('PATCH', '/me/notification-settings', { token: ben.token, body: { push: true } });
check('모르는 필드는 400', bad2.status === 400, `status=${bad2.status}`);
const other = await api('GET', '/me/notification-settings', { token: cid.token });
check('남의 스위치는 그대로', other.json?.dms === true);

// ── 목록 · 수 ──────────────────────────────────
console.log('\n[목록 · 수]');

const all = await notesOf(ben);
const count0 = await unread(ben);
check('수 = 목록의 안 읽은 줄 수', typeof count0 === 'number' && count0 === all.filter((n) => !n.read).length, `${count0} vs ${all.filter((n) => !n.read).length}`);
check('최신순', all.length >= 2 && new Date(all[0].createdAt) >= new Date(all[all.length - 1].createdAt));
const page1 = await api('GET', `/spaces/${spaceId}/notifications?limit=2`, { token: ben.token });
const page2 = await api('GET', `/spaces/${spaceId}/notifications?limit=2&cursor=${page1.json?.nextCursor}`, { token: ben.token });
check(
  '커서 페이지가 이어진다',
  page1.json?.items?.length === 2 && !!page1.json?.nextCursor && page2.json?.items?.[0]?.id === all[2]?.id,
  `${page2.json?.items?.[0]?.id} vs ${all[2]?.id}`,
);

// ── 읽음 ───────────────────────────────────────
console.log('\n[읽음]');

const readEvent = waitFor(benSocket2, 'notification:read');
const read1 = await api('POST', `/spaces/${spaceId}/notifications/${n1?.id}/read`, { token: ben.token });
check('하나 읽음(200 · read=true)', read1.status === 200 && read1.json?.read === true && read1.json?.id === n1?.id, `status=${read1.status}`);
const ev = await readEvent;
check('★ 내 다른 기기에 notification:read { ids }', ev?.spaceId === spaceId && Array.isArray(ev?.ids) && ev.ids[0] === n1?.id, JSON.stringify(ev));
check('수가 하나 준다', (await unread(ben)) === count0 - 1);
const read1again = await api('POST', `/spaces/${spaceId}/notifications/${n1?.id}/read`, { token: ben.token });
check('다시 읽어도 200(멱등) · 수는 그대로', read1again.status === 200 && (await unread(ben)) === count0 - 1);
const steal = await api('POST', `/spaces/${spaceId}/notifications/${b6?.id}/read`, { token: cid.token });
check('★ 남의 알림을 읽으면 404', steal.status === 404, `status=${steal.status}`);
const missing = await api('POST', `/spaces/${spaceId}/notifications/00000000-0000-4000-8000-000000000000/read`, { token: ben.token });
check('없는 id 404', missing.status === 404, `status=${missing.status}`);
const notUuid = await api('POST', `/spaces/${spaceId}/notifications/nope/read`, { token: ben.token });
check('uuid 가 아니면 400', notUuid.status === 400, `status=${notUuid.status}`);

// 채널을 읽으면 최상위 메시지 알림이 따라 읽힌다 — 답글 알림은 아니다(N12).
const before = await notesOf(ben);
const topUnread = before.filter((n) => !n.read && n.channelId === generalId && n.threadId === null);
const replyUnread = before.filter((n) => !n.read && n.channelId === generalId && n.threadId !== null);
check('준비 — 일반 채널에 안 읽은 최상위 · 답글 알림이 있다', topUnread.length > 0 && replyUnread.length > 0, `${topUnread.length},${replyUnread.length}`);
const latest = await send(ann, generalId, 'latest line');
const channelRead = waitFor(benSocket2, 'notification:read');
const mark = await api('POST', `/spaces/${spaceId}/channels/${generalId}/read`, {
  token: ben.token,
  body: { lastReadMessageId: latest },
});
check('채널 읽음 위치 저장', mark.status === 200 || mark.status === 201, `status=${mark.status}`);
const after = await notesOf(ben);
const stillTop = after.filter((n) => !n.read && n.channelId === generalId && n.threadId === null);
const stillReply = after.filter((n) => !n.read && n.channelId === generalId && n.threadId !== null);
check('★ 채널을 읽으면 그 채널의 최상위 알림이 읽힌다', stillTop.length === 0, `남음 ${stillTop.length}`);
check('★ 답글 알림은 남는다', stillReply.length === replyUnread.length, `${stillReply.length} vs ${replyUnread.length}`);
const crEv = await channelRead;
check('…내 다른 기기에 그 id 들이 간다', Array.isArray(crEv?.ids) && topUnread.every((n) => crEv.ids.includes(n.id)), JSON.stringify(crEv));
check('다른 채널(DM)의 알림은 그대로', after.some((n) => !n.read && n.channelId === dmId));

// ── 가시성이 바뀌면 ─────────────────────────────
console.log('\n[명단에서 빠지면]');

await api('POST', `/spaces/${spaceId}/channels/${privId}/members`, { token: ann.token, body: { userIds: [ben.userId] } });
const v1 = await send(ann, privId, `<@${ben.userId}> welcome`);
const [bv] = await noteFor(ben, v1);
check('명단에 들어오면 비공개 채널 멘션이 온다', bv?.type === 'mention', JSON.stringify(bv));
const countIn = await unread(ben);
const drop = await api('DELETE', `/spaces/${spaceId}/channels/${privId}/members/${ben.userId}`, { token: ann.token });
check('명단에서 뺀다', drop.status === 200 || drop.status === 204, `status=${drop.status}`);
check('★ 빠지면 목록에서 사라진다', !!bv && (await noteFor(ben, v1)).length === 0);
check('★ …수에서도 빠진다', (await unread(ben)) === countIn - 1, `${await unread(ben)} vs ${countIn - 1}`);
const readHidden = await api('POST', `/spaces/${spaceId}/notifications/${bv?.id}/read`, { token: ben.token });
check('…그 알림을 읽으려 하면 404', readHidden.status === 404, `status=${readHidden.status}`);

// ── 삭제된 메시지 ───────────────────────────────
console.log('\n[삭제된 메시지]');

const d1 = await send(ann, generalId, `<@${ben.userId}> oops secret`);
await api('DELETE', `/spaces/${spaceId}/messages/${d1}`, { token: ann.token });
const [bd] = await noteFor(ben, d1);
check('★ 알림은 남고 본문은 비운다(deleted=true)', !!bd && bd.body === '' && bd.deleted === true, JSON.stringify(bd));

// ── 모두 읽음 ──────────────────────────────────
console.log('\n[모두 읽음]');

const allEvent = waitFor(benSocket2, 'notification:read');
const readAll = await api('POST', `/spaces/${spaceId}/notifications/read-all`, { token: ben.token });
check('모두 읽음(200 · 바뀐 수)', readAll.status === 200 && readAll.json?.count > 0, JSON.stringify(readAll.json));
check('수가 0', (await unread(ben)) === 0);
const allEv = await allEvent;
check('…내 다른 기기에 ids=null', allEv?.spaceId === spaceId && allEv?.ids === null, JSON.stringify(allEv));
const readAll2 = await api('POST', `/spaces/${spaceId}/notifications/read-all`, { token: ben.token });
check('다시 해도 200 · 0', readAll2.status === 200 && readAll2.json?.count === 0);
check('남의 수는 그대로', (await unread(cid)) > 0);

for (const s of [benSocket, benSocket2, cidSocket]) s?.close?.();
process.exit(summary() === 0 ? 0 : 1);
