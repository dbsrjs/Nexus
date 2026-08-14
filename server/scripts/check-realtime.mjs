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

  report();
}

function report() {
  for (const s of sockets) s.disconnect();
  console.log(`\n통과 ${pass} / 실패 ${fail}`);
  process.exit(fail ? 1 : 0);
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
