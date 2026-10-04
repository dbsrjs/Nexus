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

for (const s of [aliceSocket, carolSocket, bobSocket]) s?.close?.();
process.exit(summary() === 0 ? 0 : 1);
