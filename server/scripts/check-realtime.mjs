// 실시간(4단계) 검증. 실제 서버 · 실제 DB · 실제 소켓으로 확인한다.
//
// 사전 조건:
//   npm run db:up && npm run server:dev   (다른 터미널)
//   npm run db:seed 로 만든 비밀번호를 인자로 넘긴다
//
// 사용: npm run check:realtime -- <시드비밀번호>

import { requireServer } from './lib/preflight.mjs';
import { BASE, api } from './lib/api.mjs';
import { check, summary } from './lib/checks.mjs';
import { connect, waitFor } from './lib/socket.mjs';
await requireServer(BASE);
const OWNER_EMAIL = 'dbsrjs1224@gmail.com';
const OWNER_PASSWORD = process.argv[2];

if (!OWNER_PASSWORD) {
  console.error('사용: npm run check:realtime -- <시드 비밀번호>');
  process.exit(1);
}


/** 소켓 하나를 연결한다. 성공하면 소켓, 실패하면 Error 를 돌려준다(던지지 않는다). */
/** 이벤트를 기다린다. ms 안에 안 오면 null. */
/** ack 이 있는 이벤트를 보낸다. */
function emitWithAck(socket, event, payload, ms = 3000) {
  return new Promise((resolve) => {
    const timer = setTimeout(() => resolve(null), ms);
    socket.emit(event, payload, (ack) => {
      clearTimeout(timer);
      resolve(ack);
    });
  });
}

const sockets = [];
function track(socket) {
  sockets.push(socket);
  return socket;
}

async function main() {
  const login = await api('POST', '/auth/login', {
    body: { email: OWNER_EMAIL, password: OWNER_PASSWORD },
  });
  if (login.status !== 200) {
    console.error('로그인 실패 — 시드 비밀번호를 확인하십시오.', login.json);
    process.exit(1);
  }
  const ownerToken = login.json.accessToken;

  console.log('\n── 인증 ──');

  const noToken = await connect(undefined);
  check('토큰 없이 연결하면 거부', noToken instanceof Error, `-> ${noToken?.constructor?.name}`);

  const badToken = await connect('이건.유효하지.않은토큰');
  check('잘못된 토큰이면 거부', badToken instanceof Error, `-> ${badToken?.constructor?.name}`);

  const owner = await connect(ownerToken);
  check('올바른 토큰이면 연결', !(owner instanceof Error), `-> ${owner?.message ?? ''}`);
  if (owner instanceof Error) {
    report();
    return;
  }
  track(owner);

  console.log('\n── 룸 ──');

  const spaces = await api('GET', '/spaces', { token: ownerToken });
  const spaceId = spaces.json[0].id;
  const channels = await api('GET', `/spaces/${spaceId}/channels`, { token: ownerToken });
  const channelIds = channels.json.map((c) => c.id);

  const sync = await emitWithAck(owner, 'rooms:sync', {});
  check('rooms:sync 가 ack 을 준다', sync?.ok === true, JSON.stringify(sync));
  check(
    'ack 의 채널이 REST 채널 목록과 같다',
    sync?.channels?.length === channelIds.length &&
      channelIds.every((id) => sync.channels.includes(id)),
    `소켓=${sync?.channels?.length} REST=${channelIds.length}`,
  );
  check('ack 에 스페이스가 담긴다', sync?.spaces?.includes(spaceId), JSON.stringify(sync?.spaces));

  console.log('\n── 메시지 브로드캐스트 ──');

  // 두 번째 사용자를 만들어 초대로 같은 스페이스에 넣는다.
  const outsiderEmail = `check-outsider-${Date.now()}@example.com`;
  const outsiderPassword = 'check-outsider-password-1234';
  const signup = await api('POST', '/auth/signup', {
    body: { email: outsiderEmail, password: outsiderPassword, name: '검증용 외부인' },
  });
  check('두 번째 사용자 가입', signup.status === 201, JSON.stringify(signup.json));
  const outsiderToken = signup.json.accessToken;

  // 아직 스페이스 멤버가 아닌 상태로 연결한다.
  const outsider = track(await connect(outsiderToken));
  check('비멤버도 소켓 연결은 된다', !(outsider instanceof Error));

  const outsiderSync = await emitWithAck(outsider, 'rooms:sync', {});
  check(
    '비멤버는 그 스페이스 룸에 없다',
    !outsiderSync?.spaces?.includes(spaceId),
    JSON.stringify(outsiderSync?.spaces),
  );

  const channelId = channelIds[0];
  const newEvent = waitFor(owner, 'message:new');
  const outsiderShouldNotGet = waitFor(outsider, 'message:new', 1500);

  const sent = await api('POST', `/spaces/${spaceId}/channels/${channelId}/messages`, {
    token: ownerToken,
    body: { body: '실시간 검증 메시지' },
  });
  check('REST 로 메시지 전송', sent.status === 201, JSON.stringify(sent.json));

  const received = await newEvent;
  check('멤버 소켓에 message:new 도착', received?.message?.id === sent.json.id, JSON.stringify(received));
  check('payload 에 spaceId · channelId 가 있다', received?.spaceId === spaceId && received?.channelId === channelId);
  check('비멤버에게는 안 간다 (테넌트 격리)', (await outsiderShouldNotGet) === null);

  // ── 사용자 간 전달 ──
  // 위까지는 보낸 사람이 자기 이벤트를 받은 것뿐이라, 룸이 실제로 다른 사용자에게
  // 닿는지는 증명되지 않았다. 초대로 멤버를 만들어 확인한다.
  const invite = await api('POST', `/spaces/${spaceId}/invites`, { token: ownerToken, body: {} });
  check('초대 발급', invite.status === 201, JSON.stringify(invite.json));

  const accepted = await api('POST', `/invites/${invite.json.code}/accept`, { token: outsiderToken });
  check('초대 수락', accepted.status === 200 || accepted.status === 201, JSON.stringify(accepted.json));

  const memberSync = await emitWithAck(outsider, 'rooms:sync', {});
  check('수락 후 rooms:sync 에 스페이스가 들어온다', memberSync?.spaces?.includes(spaceId));

  const crossUser = waitFor(outsider, 'message:new');
  const sent2 = await api('POST', `/spaces/${spaceId}/channels/${channelId}/messages`, {
    token: ownerToken,
    body: { body: '다른 사용자에게 갈 메시지' },
  });
  check(
    '다른 사용자의 소켓에 message:new 도착',
    (await crossUser)?.message?.id === sent2.json.id,
    '룸이 실제로 다른 연결에 닿는지',
  );

  // ── 비공개 채널 격리 ──
  // outsider 는 이제 스페이스 멤버다. 그래도 비공개 채널은 룸에 들어오면 안 된다.
  // 반대로 생성자는 채널 생성 시 channel_members 에 함께 들어가므로 자기 채널을
  // 보고 쓸 수 있어야 한다.
  const priv = await api('POST', `/spaces/${spaceId}/channels`, {
    token: ownerToken,
    body: { name: `비공개-${Date.now()}`, isPrivate: true },
  });
  check('비공개 채널 생성', priv.status === 201, JSON.stringify(priv.json));

  const privSync = await emitWithAck(outsider, 'rooms:sync', {});
  check(
    '비공개 채널은 비참여자의 룸에 없다',
    !privSync?.channels?.includes(priv.json.id),
    JSON.stringify(privSync?.channels),
  );

  const ownerSync = await emitWithAck(owner, 'rooms:sync', {});
  check(
    '생성자는 자기 비공개 채널의 룸에 있다',
    ownerSync?.channels?.includes(priv.json.id),
    JSON.stringify(ownerSync?.channels),
  );

  // 여기부터가 백엔드 설계 §5 가 요구하던 격리 케이스다. 4단계에서는 생성자조차
  // 비공개 채널에 메시지를 보낼 수 없어(404) 실행하지 못했다.
  // "룸 계산이 맞다"와 "실제로 새지 않는다"는 다른 이야기다.
  const privOwnerGets = waitFor(owner, 'message:new');
  const privLeak = waitFor(outsider, 'message:new', 1500);
  const privSent = await api('POST', `/spaces/${spaceId}/channels/${priv.json.id}/messages`, {
    token: ownerToken,
    body: { body: '비공개 채널 메시지' },
  });
  check(
    '생성자는 자기 비공개 채널에 메시지를 보낼 수 있다',
    privSent.status === 201,
    JSON.stringify(privSent.json),
  );
  // 양쪽이 undefined 여도 참이 되지 않도록 id 가 실제로 있는지부터 본다.
  // 전송이 404 면 두 값이 모두 undefined 가 되어 공허하게 통과한다.
  const privReceived = await privOwnerGets;
  check(
    '생성자 소켓에 비공개 채널 message:new 도착',
    !!privSent.json?.id && privReceived?.message?.id === privSent.json.id,
    JSON.stringify(privReceived),
  );
  check('비공개 채널 메시지가 비참여자에게 새지 않는다', (await privLeak) === null);

  const editedEvent = waitFor(owner, 'message:edited');
  await api('PATCH', `/spaces/${spaceId}/messages/${sent.json.id}`, {
    token: ownerToken,
    body: { body: '수정된 본문' },
  });
  const edited = await editedEvent;
  check('message:edited 도착', edited?.message?.body === '수정된 본문', JSON.stringify(edited));

  const deletedEvent = waitFor(owner, 'message:deleted');
  await api('DELETE', `/spaces/${spaceId}/messages/${sent.json.id}`, { token: ownerToken });
  const deleted = await deletedEvent;
  check('message:deleted 도착', deleted?.messageId === sent.json.id, JSON.stringify(deleted));

  console.log('\n── 읽음 ──');

  // 같은 사용자의 두 번째 기기.
  const owner2 = track(await connect(ownerToken));
  check('같은 사용자의 두 번째 소켓 연결', !(owner2 instanceof Error));

  const marker = await api('POST', `/spaces/${spaceId}/channels/${channelId}/messages`, {
    token: ownerToken,
    body: { body: '읽음 기준 메시지' },
  });

  // (1) 소켓 경로
  const syncedOnDevice2 = waitFor(owner2, 'read:synced');
  const readAck = await emitWithAck(owner, 'read', {
    spaceId,
    channelId,
    lastReadMessageId: marker.json.id,
  });
  check('소켓 read 가 ok ack', readAck?.ok === true, JSON.stringify(readAck));

  const synced = await syncedOnDevice2;
  check('다른 기기에 read:synced 도착', synced?.lastReadMessageId === marker.json.id, JSON.stringify(synced));

  // DB 에 실제로 저장됐는지는 채널 목록의 lastReadMessageId 로 확인한다.
  const after = await api('GET', `/spaces/${spaceId}/channels`, { token: ownerToken });
  const row = after.json.find((c) => c.id === channelId);
  check('DB 에 읽음이 저장됨', row?.lastReadMessageId === marker.json.id, JSON.stringify(row?.lastReadMessageId));

  // (2) REST 경로도 같은 코드를 지나가는지
  const marker2 = await api('POST', `/spaces/${spaceId}/channels/${channelId}/messages`, {
    token: ownerToken,
    body: { body: '두 번째 읽음 기준' },
  });
  const syncedFromRest = waitFor(owner2, 'read:synced');
  await api('POST', `/spaces/${spaceId}/channels/${channelId}/read`, {
    token: ownerToken,
    body: { lastReadMessageId: marker2.json.id },
  });
  check('REST 읽음도 read:synced 를 쏜다', (await syncedFromRest)?.lastReadMessageId === marker2.json.id);

  // (3) 잘못된 페이로드로 연결이 끊기지 않는다
  const badAck = await emitWithAck(owner, 'read', { spaceId, channelId });
  check('DTO 위반은 ok:false', badAck?.ok === false, JSON.stringify(badAck));
  check('잘못된 페이로드로 연결이 끊기지 않는다', owner.connected);

  // (3-1) markRead() 가 실제로 예외를 던지는 경우 (read_failed) — 스페이스 멤버지만
  // 그 채널은 못 보는 경우다. outsider 는 초대를 수락해 스페이스 멤버이지만 위에서
  // 만든 비공개 채널 priv 의 채널 멤버는 아니라 assertCanView 가 404 를 던진다.
  // (owner 로는 확인할 수 없다 — 생성자는 자기 비공개 채널을 볼 수 있다.)
  // ack 형태는 read_failed 로 동일해야 하고, 서버 로그에 에러가 남는지는 이 스크립트가
  // 아니라 server.log 를 직접 확인한다.
  const readFailedAck = await emitWithAck(outsider, 'read', {
    spaceId,
    channelId: priv.json.id,
    lastReadMessageId: marker2.json.id,
  });
  check('볼 수 없는 채널의 read 는 read_failed', readFailedAck?.ok === false, JSON.stringify(readFailedAck));
  check('read_failed 이후에도 연결은 유지된다', outsider.connected);

  // outsider 는 위 "메시지 브로드캐스트" 절에서 초대를 수락해 이미 스페이스
  // 멤버가 됐다. 진짜 비멤버로 거부 분기(not_a_member)를 확인하려면 그
  // 스페이스에 한 번도 들어간 적 없는 사용자가 필요해 여기서 새로 만든다.
  const strangerEmail = `check-stranger-${Date.now()}@example.com`;
  const strangerPassword = 'check-stranger-password-1234';
  const strangerSignup = await api('POST', '/auth/signup', {
    body: { email: strangerEmail, password: strangerPassword, name: '읽음 검증용 비멤버' },
  });
  check('읽음 검증용 비멤버 가입', strangerSignup.status === 201, JSON.stringify(strangerSignup.json));
  const stranger = track(await connect(strangerSignup.json.accessToken));

  const foreignAck = await emitWithAck(stranger, 'read', {
    spaceId,
    channelId,
    lastReadMessageId: marker2.json.id,
  });
  check('비멤버의 read 는 거부된다', foreignAck?.ok === false, JSON.stringify(foreignAck));
  check('거부해도 연결은 유지된다', stranger.connected);

  console.log('\n── rooms:invalidate ──');

  const invalidated = waitFor(owner, 'rooms:invalidate');
  const created = await api('POST', `/spaces/${spaceId}/channels`, {
    token: ownerToken,
    body: { name: `검증채널-${Date.now()}` },
  });
  check('채널 생성 201', created.status === 201, JSON.stringify(created.json));
  check(
    '채널 생성 시 rooms:invalidate 도착',
    (await invalidated)?.reason === 'channel.created',
    JSON.stringify(await invalidated),
  );

  // 재계산하면 새 채널이 룸에 들어와 있어야 한다.
  const resync = await emitWithAck(owner, 'rooms:sync', {});
  check('rooms:sync 후 새 채널이 룸에 있다', resync?.channels?.includes(created.json.id));

  const newChannelEvent = waitFor(owner, 'message:new');
  await api('POST', `/spaces/${spaceId}/channels/${created.json.id}/messages`, {
    token: ownerToken,
    body: { body: '새 채널 메시지' },
  });
  check('새 채널의 메시지도 받는다', (await newChannelEvent)?.channelId === created.json.id);

  report();
}

/**
 * disconnect() 직후 process.exit() 를 부르면, libuv 가 소켓을 닫는 중인 핸들을
 * 프로세스 종료 절차가 한 번 더 닫으려 해서 Windows 에서 assert 로 죽는다
 * (`UV_HANDLE_CLOSING`, src/win/async.c). 룸이 늘어 소켓이 여러 개 열리면서
 * 드러났다.
 *
 * process.exit() 를 아예 쓰지 않고 process.exitCode 만 설정한 뒤 자연 종료를
 * 기다린다. 통과/실패는 그대로 종료 코드에 반영되지만(0 = 전부 통과), 진행
 * 중이던 핸들을 강제로 끊지 않으므로 이 crash 가 생기지 않는다.
 */
function report() {
  for (const s of sockets) s.disconnect();
  summary();
}

main().catch((err) => {
  console.error(err);
  for (const s of sockets) s.disconnect();
  process.exitCode = 1;
});
