// 실시간(4단계) 검증. 실제 서버 · 실제 DB · 실제 소켓으로 확인한다.
//
// 사전 조건:
//   npm run db:up && npm run server:dev   (다른 터미널)
//   npm run db:seed 로 만든 비밀번호를 인자로 넘긴다
//
// 사용: npm run check:realtime -- <시드비밀번호>
import { io } from 'socket.io-client';

const BASE = 'http://127.0.0.1:3000/api';
const WS = 'http://127.0.0.1:3000';
const OWNER_EMAIL = 'dbsrjs1224@gmail.com';
const OWNER_PASSWORD = process.argv[2];

if (!OWNER_PASSWORD) {
  console.error('사용: npm run check:realtime -- <시드 비밀번호>');
  process.exit(1);
}

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

/** 소켓 하나를 연결한다. 성공하면 소켓, 실패하면 Error 를 돌려준다(던지지 않는다). */
function connect(token) {
  return new Promise((resolve) => {
    const socket = io(WS, {
      auth: token === undefined ? {} : { token },
      transports: ['websocket'],
      reconnection: false,
      timeout: 5000,
    });
    socket.once('connect', () => resolve(socket));
    socket.once('connect_error', (err) => resolve(err));
  });
}

/** 이벤트를 기다린다. ms 안에 안 오면 null. */
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
  // 이제 outsider 는 스페이스 멤버다. 그래도 비공개 채널은 룸에 들어오면 안 된다.
  //
  // ⚠ 이 채널에 메시지를 보내 "새는지" 까지는 확인하지 못한다. 현재 구현에서는
  //    비공개 채널을 만들어도 생성자가 channel_members 에 들어가지 않아 생성자
  //    본인조차 404 라 메시지를 보낼 수 없다. 4단계 범위 밖이므로 여기서 고치지
  //    않고 별도 작업으로 남긴다. 룸 계산 자체는 아래로 확인된다.
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
    '비공개 채널은 참여하지 않은 생성자의 룸에도 없다',
    !ownerSync?.channels?.includes(priv.json.id),
    JSON.stringify(ownerSync?.channels),
  );

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
  console.log(`\n통과 ${pass} / 실패 ${fail}`);
  process.exitCode = fail ? 1 : 0;
}

main().catch((err) => {
  console.error(err);
  for (const s of sockets) s.disconnect();
  process.exitCode = 1;
});
