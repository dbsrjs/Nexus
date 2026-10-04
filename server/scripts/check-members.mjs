// 멤버 · 권한(16단계) 검증 — 초대 · 멤버 이벤트 · 내보내기 · 나가기.
// 실제 서버 · 실제 DB · 실제 소켓으로 확인한다.
//
// 사전 조건: npm run db:up && npm run server:dev
// 사용: npm run check:members
//
// 자체 계정 넷 — owner(alice) · admin(bob) · member(carol) · 손님(dave).
import { requireServer } from './lib/preflight.mjs';
import { BASE, api, signup, stamp } from './lib/api.mjs';
import { check, summary } from './lib/checks.mjs';
import { connect, waitFor } from './lib/socket.mjs';
await requireServer(BASE);

console.log('\n멤버 · 권한 검증 — 실서버 · 실DB · 실소켓\n');

const alice = await signup('members', 'a', 'Members A');
const bob = await signup('members', 'b', 'Members B');
const carol = await signup('members', 'c', 'Members C');
const dave = await signup('members', 'd', 'Members D');

const space = await api('POST', '/spaces', { token: alice.token, body: { name: `members ${stamp}` } });
const spaceId = space.json?.id;
check('준비 (스페이스)', space.status === 201 && !!spaceId, `status=${space.status}`);

const invite = (token, body = {}) => api('POST', `/spaces/${spaceId}/invites`, { token, body });
const accept = (token, code) => api('POST', `/invites/${code}/accept`, { token });
/** 이벤트가 오지 않아야 하는 쪽. 받으면 그 페이로드, 안 오면 null. */
const silence = (socket, event, ms = 1200) => waitFor(socket, event, ms);

// ── 만들기 ──────────────────────────────────────
console.log('\n[만들기]');

// 앱은 이름만 받는다 — 같은 영문 이름이 이미 있어도 막히면 안 된다(slug 는 전역 유일).
const sameName = `Members Same ${stamp}`;
const first = await api('POST', '/spaces', { token: carol.token, body: { name: sameName } });
const second = await api('POST', '/spaces', { token: dave.token, body: { name: sameName } });
check(
  '같은 이름의 스페이스를 둘 만들 수 있다',
  first.status === 201 && second.status === 201 && !!first.json?.slug && first.json.slug !== second.json?.slug,
  `status=${first.status},${second.status}`,
);
const pinned = await api('POST', '/spaces', {
  token: dave.token,
  body: { name: 'pinned', slug: first.json?.slug },
});
check('직접 고른 slug 가 겹치면 여전히 409', pinned.status === 409, `status=${pinned.status}`);

// ── 초대 ────────────────────────────────────────
console.log('\n[초대]');

const adminInvite = await invite(alice.token, { role: 'admin' });
const bobAccept = await accept(bob.token, adminInvite.json?.code);
check('admin 초대를 수락한다', bobAccept.status === 200, `status=${bobAccept.status}`);

const aliceSocket = await connect(alice.token);
const carolSocket = await connect(carol.token);
// 'connect' 직후에는 서버의 룸 조인(handleConnection)이 아직 끝나지 않았을 수 있다.
// ack 를 받으면 룸에 들어가 있다 — 이걸 빼면 member:joined 를 간헐적으로 놓친다.
await aliceSocket.emitWithAck('rooms:sync');

const memberInvite = await invite(alice.token, { role: 'member', maxUses: 1 });
const joined = waitFor(aliceSocket, 'member:joined');
const carolRooms = waitFor(carolSocket, 'rooms:invalidate');
const carolAccept = await accept(carol.token, memberInvite.json?.code);
check('member 초대를 수락한다', carolAccept.status === 200 && carolAccept.json?.id === spaceId, `status=${carolAccept.status}`);
const joinedEvent = await joined;
check(
  '기존 멤버가 member:joined 를 받는다',
  joinedEvent?.userId === carol.userId && joinedEvent?.spaceId === spaceId,
  JSON.stringify(joinedEvent),
);
const roomsEvent = await carolRooms;
check('들어온 사람이 rooms:invalidate 를 받는다', roomsEvent?.reason === 'member.joined', JSON.stringify(roomsEvent));

const list1 = await api('GET', `/spaces/${spaceId}/invites`, { token: alice.token });
const listedCodes = (list1.json ?? []).map((i) => i.code);
check('초대 목록은 admin 이상이 본다', list1.status === 200 && Array.isArray(list1.json), `status=${list1.status}`);
check('한도가 찬 초대는 목록에 없다', !!memberInvite.json?.code && !listedCodes.includes(memberInvite.json.code));
check('쓸 수 있는 초대는 목록에 있다', !!adminInvite.json?.code && listedCodes.includes(adminInvite.json.code));
check(
  '목록에 만든 사람 이름이 실린다',
  list1.json?.[0]?.createdBy?.name === 'Members A',
  JSON.stringify(list1.json?.[0]?.createdBy),
);

const memberList = await api('GET', `/spaces/${spaceId}/invites`, { token: carol.token });
check('member 는 초대 목록을 못 본다(403)', memberList.status === 403, `status=${memberList.status}`);

const exhausted = await accept(dave.token, memberInvite.json?.code);
check('한도가 찬 코드는 400', exhausted.status === 400, `status=${exhausted.status}`);

const revokeMe = await invite(alice.token, {});
const revoked = await api('DELETE', `/spaces/${spaceId}/invites/${revokeMe.json?.id}`, { token: bob.token });
check('admin 이 초대를 취소한다(204)', !!revokeMe.json?.id && revoked.status === 204, `status=${revoked.status}`);
const afterRevoke = await accept(dave.token, revokeMe.json?.code);
check('취소한 코드는 404', afterRevoke.status === 404, `status=${afterRevoke.status}`);
const revokeAgain = await api('DELETE', `/spaces/${spaceId}/invites/${revokeMe.json?.id}`, { token: bob.token });
check('이미 취소한 초대를 다시 취소하면 404', revokeAgain.status === 404, `status=${revokeAgain.status}`);
const listAfter = await api('GET', `/spaces/${spaceId}/invites`, { token: alice.token });
check('취소한 초대는 목록에서 빠진다', !(listAfter.json ?? []).some((i) => i.id === revokeMe.json?.id));

const otherSpace = await api('POST', '/spaces', { token: dave.token, body: { name: `members other ${stamp}` } });
const otherInvite = await api('POST', `/spaces/${otherSpace.json?.id}/invites`, { token: dave.token, body: {} });
const crossRevoke = await api('DELETE', `/spaces/${spaceId}/invites/${otherInvite.json?.id}`, { token: alice.token });
check('다른 스페이스의 초대 id 는 404', !!otherInvite.json?.id && crossRevoke.status === 404, `status=${crossRevoke.status}`);
const stillThere = await api('GET', `/spaces/${otherSpace.json?.id}/invites`, { token: dave.token });
check('…그리고 그 초대는 지워지지 않았다', (stillThere.json ?? []).some((i) => i.id === otherInvite.json?.id));

// 손님 — 이후 16-2 갈래도 쓴다.
const guestInvite = await invite(alice.token, { role: 'guest' });
const daveAccept = await accept(dave.token, guestInvite.json?.code);
check('손님 초대를 수락한다', daveAccept.status === 200, `status=${daveAccept.status}`);

// ── 역할 ────────────────────────────────────────
console.log('\n[역할]');

const updated = waitFor(aliceSocket, 'member:updated');
const demote = await api('PATCH', `/spaces/${spaceId}/members/${carol.userId}`, {
  token: bob.token,
  body: { role: 'guest' },
});
check('admin 이 member 를 guest 로 바꾼다', demote.status === 200, `status=${demote.status}`);
const updatedEvent = await updated;
check(
  'member:updated 가 사람과 역할을 싣는다',
  updatedEvent?.userId === carol.userId && updatedEvent?.role === 'guest' && updatedEvent?.spaceId === spaceId,
  JSON.stringify(updatedEvent),
);
await api('PATCH', `/spaces/${spaceId}/members/${carol.userId}`, { token: bob.token, body: { role: 'member' } });

const members = await api('GET', `/spaces/${spaceId}/members`, { token: dave.token });
check('손님도 멤버 목록을 본다', members.status === 200 && members.json?.length === 4, `n=${members.json?.length}`);
check('멤버 목록에 역할이 실린다', (members.json ?? []).some((m) => m.userId === bob.userId && m.role === 'admin'));

// ── 내보내기 ────────────────────────────────────
console.log('\n[내보내기]');

const channels = await api('GET', `/spaces/${spaceId}/channels`, { token: alice.token });
const general = channels.json?.[0];
check('준비 (채널)', !!general?.id);

// carol 이 그 채널의 메시지를 실제로 받고 있는지 먼저 본다 — 아니면 아래 ★ 가 공짜로 통과한다.
const carolHears = waitFor(carolSocket, 'message:new');
await carolSocket.emitWithAck('rooms:sync');
await api('POST', `/spaces/${spaceId}/channels/${general?.id}/messages`, {
  token: alice.token,
  body: { body: 'before kick' },
});
check('내보내기 전에는 carol 소켓이 그 채널의 message:new 를 받는다', (await carolHears)?.message?.body === 'before kick');

const removed = waitFor(carolSocket, 'space:removed');
const left = waitFor(aliceSocket, 'member:left');
const kick = await api('DELETE', `/spaces/${spaceId}/members/${carol.userId}`, { token: bob.token });
check('admin 이 member 를 내보낸다(204)', kick.status === 204, `status=${kick.status}`);
const removedEvent = await removed;
check('내보내진 사람이 space:removed 를 받는다', removedEvent?.spaceId === spaceId, JSON.stringify(removedEvent));
const leftEvent = await left;
check('남은 멤버가 member:left 를 받는다', leftEvent?.userId === carol.userId, JSON.stringify(leftEvent));

// carol 의 소켓은 rooms:sync 를 부르지 않는다 — 고친 클라이언트의 흉내(설계 D13a).
const leak = silence(carolSocket, 'message:new');
await api('POST', `/spaces/${spaceId}/channels/${general?.id}/messages`, {
  token: alice.token,
  body: { body: 'after kick' },
});
check('★ 내보내진 소켓은 sync 없이도 그 채널의 새 메시지를 받지 않는다', (await leak) === null);

const kickedRead = await api('GET', `/spaces/${spaceId}/channels`, { token: carol.token });
check('내보내진 사람은 채널 목록이 404', kickedRead.status === 404, `status=${kickedRead.status}`);

const kickOwner = await api('DELETE', `/spaces/${spaceId}/members/${alice.userId}`, { token: bob.token });
check('owner 는 내보낼 수 없다(403)', kickOwner.status === 403, `status=${kickOwner.status}`);

// ── 나가기 ──────────────────────────────────────
console.log('\n[나가기]');

const bobSocket = await connect(bob.token);
await bobSocket.emitWithAck('rooms:sync');
const bobRemoved = waitFor(bobSocket, 'space:removed');
const leakSpace = silence(carolSocket, 'member:left', 2000);
const bobLeave = await api('POST', `/spaces/${spaceId}/leave`, { token: bob.token });
check('admin 이 스스로 나간다(204)', bobLeave.status === 204, `status=${bobLeave.status}`);
check('나간 사람도 space:removed 를 받는다', (await bobRemoved)?.spaceId === spaceId);
check('★ 내보내진 소켓은 그 스페이스 룸의 이벤트(member:left)도 받지 않는다', (await leakSpace) === null);
const bobSpaces = await api('GET', '/spaces', { token: bob.token });
check('나간 스페이스는 목록에서 빠진다', bobSpaces.status === 200 && !(bobSpaces.json ?? []).some((s) => s.id === spaceId));

const ownerLeave = await api('POST', `/spaces/${spaceId}/leave`, { token: alice.token });
check('owner 는 나갈 수 없다(403)', ownerLeave.status === 403, `status=${ownerLeave.status}`);
const strangerLeave = await api('POST', `/spaces/${spaceId}/leave`, { token: carol.token });
check('멤버가 아니면 나가기도 404', strangerLeave.status === 404, `status=${strangerLeave.status}`);

// ══ 16-2 — 채널 수준 ══════════════════════════════
// 새 스페이스 하나에 owner(own) · admin(adm) · member(mem) · 손님(gst) · 남(out).
console.log('\n[16-2 준비]');
const own = await signup('members2', 'o', 'Ch Owner');
const adm = await signup('members2', 'a', 'Ch Admin');
const mem = await signup('members2', 'm', 'Ch Member');
const gst = await signup('members2', 'g', 'Ch Guest');
const out = await signup('members2', 'x', 'Ch Outsider');
const sp2 = (await api('POST', '/spaces', { token: own.token, body: { name: `members2 ${stamp}` } })).json?.id;
for (const [who, role] of [[adm, 'admin'], [mem, 'member'], [gst, 'guest']]) {
  const inv = await api('POST', `/spaces/${sp2}/invites`, { token: own.token, body: { role } });
  await accept(who.token, inv.json?.code);
}
const ch = (path) => `/spaces/${sp2}/channels${path}`;
const pub = (await api('GET', ch(''), { token: own.token })).json?.[0];
check('준비 (스페이스 · 공개 채널)', !!sp2 && !!pub?.id);

const memSocket = await connect(mem.token);
await memSocket.emitWithAck('rooms:sync');

// ── 비공개 채널 명단 ──
console.log('\n[비공개 채널 명단]');
const priv = (await api('POST', ch(''), { token: adm.token, body: { name: 'secret room', isPrivate: true } })).json;
check('admin 이 비공개 채널을 만든다', !!priv?.id && priv.isPrivate === true);
const memCantSee = await api('GET', ch(`/${priv?.id}`), { token: mem.token });
check('명단에 없는 member 는 비공개 채널이 404', memCantSee.status === 404, `status=${memCantSee.status}`);

const memRooms = waitFor(memSocket, 'rooms:invalidate');
const add = await api('POST', ch(`/${priv?.id}/members`), { token: adm.token, body: { userIds: [mem.userId] } });
check(
  '명단의 admin 이 member 를 들인다',
  add.status === 200 && (add.json ?? []).some((m) => m.userId === mem.userId),
  `status=${add.status}`,
);
check('들어온 사람이 rooms:invalidate(channel.members) 를 받는다', (await memRooms)?.reason === 'channel.members');
const memList = (await api('GET', ch(''), { token: mem.token })).json ?? [];
check('들어온 사람의 채널 목록에 비공개 채널이 생긴다', memList.some((c) => c.id === priv?.id));
const again = await api('POST', ch(`/${priv?.id}/members`), { token: adm.token, body: { userIds: [mem.userId] } });
check(
  '같은 사람을 다시 들여도 멱등(200, 한 줄)',
  again.status === 200 && (again.json ?? []).filter((m) => m.userId === mem.userId).length === 1,
);

const withOutsider = await api('POST', ch(`/${priv?.id}/members`), {
  token: adm.token,
  body: { userIds: [gst.userId, out.userId] },
});
check('스페이스 멤버가 아닌 id 가 섞이면 404', withOutsider.status === 404, `status=${withOutsider.status}`);
const listAfter404 = (await api('GET', ch(`/${priv?.id}/members`), { token: adm.token })).json ?? [];
check(
  '…그때는 아무도 들어가지 않는다(손님도)',
  listAfter404.length === 2 && !listAfter404.some((m) => m.userId === gst.userId),
  `n=${listAfter404.length}`,
);

const memAddsGuest = await api('POST', ch(`/${priv?.id}/members`), { token: mem.token, body: { userIds: [gst.userId] } });
check('명단의 member 도 사람을 들인다', memAddsGuest.status === 200, `status=${memAddsGuest.status}`);
const gstAdds = await api('POST', ch(`/${priv?.id}/members`), { token: gst.token, body: { userIds: [own.userId] } });
check('손님은 들일 수 없다(403)', gstAdds.status === 403, `status=${gstAdds.status}`);
const pubMembers = await api('POST', ch(`/${pub?.id}/members`), { token: own.token, body: { userIds: [mem.userId] } });
check('공개 채널에는 명단이 없다(400)', pubMembers.status === 400, `status=${pubMembers.status}`);
const emptyIds = await api('POST', ch(`/${priv?.id}/members`), { token: adm.token, body: { userIds: [] } });
check('userIds 가 비면 400', emptyIds.status === 400, `status=${emptyIds.status}`);

const memKicksGuest = await api('DELETE', ch(`/${priv?.id}/members/${gst.userId}`), { token: mem.token });
check('member 가 남을 빼면 403', memKicksGuest.status === 403, `status=${memKicksGuest.status}`);
const gstLeaves = await api('DELETE', ch(`/${priv?.id}/members/${gst.userId}`), { token: gst.token });
check('본인은 나갈 수 있다(204)', gstLeaves.status === 204, `status=${gstLeaves.status}`);

// 빼낸 사람의 소켓은 sync 없이도 그 채널의 새 메시지를 받지 않는다(D20 · D13a).
await memSocket.emitWithAck('rooms:sync');
const memHearsPriv = waitFor(memSocket, 'message:new');
await api('POST', ch(`/${priv?.id}/messages`), { token: adm.token, body: { body: 'priv before' } });
check('빼기 전에는 비공개 채널의 message:new 를 받는다', (await memHearsPriv)?.message?.body === 'priv before');
const kickMem = await api('DELETE', ch(`/${priv?.id}/members/${mem.userId}`), { token: adm.token });
check('admin 이 남을 뺀다(204)', kickMem.status === 204, `status=${kickMem.status}`);
const privLeak = silence(memSocket, 'message:new');
await api('POST', ch(`/${priv?.id}/messages`), { token: adm.token, body: { body: 'priv after' } });
check('★ 빠진 소켓은 sync 없이도 비공개 채널 메시지를 받지 않는다', (await privLeak) === null);
const notMember = await api('DELETE', ch(`/${priv?.id}/members/${mem.userId}`), { token: adm.token });
check('명단에 없는 사람을 빼면 404', notMember.status === 404, `status=${notMember.status}`);

const lastOne = await api('DELETE', ch(`/${priv?.id}/members/${adm.userId}`), { token: adm.token });
check('마지막 한 명은 나갈 수 없다(409)', lastOne.status === 409, `status=${lastOne.status}`);

// ── 채널별 권한 ──
console.log('\n[채널별 권한]');
const perms0 = await api('GET', ch(`/${pub?.id}/permissions`), { token: own.token });
check(
  '권한은 손님 · 멤버 두 줄, 행이 없으면 기본값',
  perms0.status === 200 && perms0.json?.length === 2 && perms0.json.every((p) => p.canView && p.canSend && !p.explicit),
  JSON.stringify(perms0.json),
);
const memPerms = await api('GET', ch(`/${pub?.id}/permissions`), { token: mem.token });
check('member 는 권한을 못 본다(403)', memPerms.status === 403, `status=${memPerms.status}`);
const adminRow = await api('PUT', ch(`/${pub?.id}/permissions/admin`), {
  token: own.token,
  body: { canView: false, canSend: false },
});
check('admin 역할 행은 400(D21)', adminRow.status === 400, `status=${adminRow.status}`);
const privHide = await api('PUT', ch(`/${priv?.id}/permissions/member`), {
  token: adm.token,
  body: { canView: false, canSend: true },
});
check('비공개 채널에 canView=false 는 400(D22)', privHide.status === 400, `status=${privHide.status}`);

// 읽기 전용
const ro = await api('PUT', ch(`/${pub?.id}/permissions/member`), {
  token: own.token,
  body: { canView: true, canSend: false },
});
check(
  'member 를 읽기 전용으로',
  ro.status === 200 && ro.json?.find((p) => p.role === 'member')?.explicit === true,
  `status=${ro.status}`,
);
const memSend = await api('POST', ch(`/${pub?.id}/messages`), { token: mem.token, body: { body: 'blocked' } });
check('읽기 전용 채널에 member 가 보내면 403', memSend.status === 403, `status=${memSend.status}`);
const ownMsg = (await api('POST', ch(`/${pub?.id}/messages`), { token: own.token, body: { body: 'owner speaks' } })).json;
check('owner 는 그대로 보낸다', !!ownMsg?.id);
const memReact = await api('POST', `/spaces/${sp2}/messages/${ownMsg?.id}/reactions`, {
  token: mem.token,
  body: { emoji: '👍' },
});
check('읽기 전용이어도 리액션은 남긴다(§3-9)', memReact.status === 201, `status=${memReact.status}`);
const memPin = await api('POST', `/spaces/${sp2}/messages/${ownMsg?.id}/pin`, { token: mem.token });
check('읽기 전용이면 고정은 403', memPin.status === 403, `status=${memPin.status}`);
const memChannels = (await api('GET', ch(''), { token: mem.token })).json ?? [];
check('채널 목록에 canSend 가 실린다 — member 는 false', memChannels.find((c) => c.id === pub?.id)?.canSend === false);
const ownChannels = (await api('GET', ch(''), { token: own.token })).json ?? [];
check('…owner 는 true', ownChannels.find((c) => c.id === pub?.id)?.canSend === true);
const reset = await api('DELETE', ch(`/${pub?.id}/permissions/member`), { token: own.token });
check('기본값으로 되돌린다(204)', reset.status === 204, `status=${reset.status}`);
const memSendAgain = await api('POST', ch(`/${pub?.id}/messages`), { token: mem.token, body: { body: 'free again' } });
check('…되돌리면 다시 보낸다', memSendAgain.status === 201, `status=${memSendAgain.status}`);

// 가리기 — member 는 이 공개 채널을 읽어(멤버 행이 있어) 본 적이 있다(D23).
const readRes = await api('POST', ch(`/${pub?.id}/read`), { token: mem.token, body: { lastReadMessageId: ownMsg?.id } });
check('준비 — member 가 공개 채널을 읽어 멤버 행이 생긴다', readRes.status === 200, `status=${readRes.status}`);
await memSocket.emitWithAck('rooms:sync');
const memInvalid = waitFor(memSocket, 'rooms:invalidate');
const hide = await api('PUT', ch(`/${pub?.id}/permissions/member`), {
  token: own.token,
  body: { canView: false, canSend: false },
});
check('member 에게서 공개 채널을 가린다', hide.status === 200, `status=${hide.status}`);
check('가리면 스페이스에 rooms:invalidate(channel.permissions)', (await memInvalid)?.reason === 'channel.permissions');
const hiddenGet = await api('GET', ch(`/${pub?.id}`), { token: mem.token });
check('★ 읽어 본 적 있는 공개 채널도 가리면 404(D23)', hiddenGet.status === 404, `status=${hiddenGet.status}`);
const hiddenList = (await api('GET', ch(''), { token: mem.token })).json ?? [];
check('…채널 목록에서도 빠진다', !hiddenList.some((c) => c.id === pub?.id));
const pubLeak = silence(memSocket, 'message:new');
await api('POST', ch(`/${pub?.id}/messages`), { token: own.token, body: { body: 'hidden talk' } });
check('★ 가려진 소켓은 sync 없이도 그 채널 메시지를 받지 않는다', (await pubLeak) === null);
const gstSees = await api('GET', ch(`/${pub?.id}`), { token: gst.token });
check('다른 역할(손님)은 그대로 본다', gstSees.status === 200, `status=${gstSees.status}`);
await api('DELETE', ch(`/${pub?.id}/permissions/member`), { token: own.token });

// ── 스프린트 스위치 ──
console.log('\n[스프린트 스위치]');
const before = (await api('GET', '/spaces', { token: own.token })).json?.find((s) => s.id === sp2);
check('새 스페이스는 스프린트가 꺼져 있다(D31)', before?.sprintsEnabled === false, JSON.stringify(before?.sprintsEnabled));
const memToggle = await api('PATCH', `/spaces/${sp2}`, { token: mem.token, body: { sprintsEnabled: true } });
check('member 는 못 켠다(403)', memToggle.status === 403, `status=${memToggle.status}`);
await memSocket.emitWithAck('rooms:sync');
const spaceUpdated = waitFor(memSocket, 'space:updated');
const toggle = await api('PATCH', `/spaces/${sp2}`, { token: adm.token, body: { sprintsEnabled: true } });
check('admin 이 켠다', toggle.status === 200 && toggle.json?.sprintsEnabled === true, `status=${toggle.status}`);
check('멤버가 space:updated 를 받는다(D34)', (await spaceUpdated)?.spaceId === sp2);
const after = (await api('GET', '/spaces', { token: mem.token })).json?.find((s) => s.id === sp2);
check('…목록에 반영된다', after?.sprintsEnabled === true);
const badToggle = await api('PATCH', `/spaces/${sp2}`, { token: adm.token, body: { sprintsEnabled: 'yes' } });
check('불리언이 아니면 400', badToggle.status === 400, `status=${badToggle.status}`);

for (const s of [aliceSocket, carolSocket, bobSocket, memSocket]) s?.close?.();
process.exit(summary() === 0 ? 0 : 1);
