// 멘션(7-4) 검증. 실제 서버 · 실제 DB 로 확인한다.
//
// 사전 조건: npm run db:up && npm run server:dev
// 사용: npm run check:mentions
//
// 자체 계정 · 자체 스페이스를 만들어 쓴다.
import { requireServer } from './lib/preflight.mjs';
const BASE = 'http://127.0.0.1:3000/api';
await requireServer(BASE);

let pass = 0;
let fail = 0;

function check(name, ok, detail = '') {
  if (ok) {
    pass++;
    console.log(`  OK  ${name}`);
  } else {
    fail++;
    console.log(`FAIL  ${name} ${detail}`);
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

const stamp = Date.now();

async function signup(tag) {
  const res = await api('POST', '/auth/signup', {
    body: {
      email: `mention-${tag}-${stamp}@example.com`,
      password: 'check-mentions-1234',
      name: `멘션검증${tag}`,
      client: 'native',
    },
  });
  if (res.status !== 201) {
    console.error('가입 실패:', res.status, JSON.stringify(res.json));
    process.exit(1);
  }
  return { token: res.json.accessToken, userId: res.json.user.id };
}

console.log('\n멘션 검증 — 실서버 · 실DB\n');

const alice = await signup('a');
const bob = await signup('b');
const outsider = await signup('x');

const space = await api('POST', '/spaces', {
  token: alice.token,
  body: { name: `멘션 검증 ${stamp}` },
});
const spaceId = space.json.id;

const invite = await api('POST', `/spaces/${spaceId}/invites`, {
  token: alice.token,
  body: { role: 'member' },
});
await api('POST', `/invites/${invite.json.code}/accept`, { token: bob.token });

const channels = await api('GET', `/spaces/${spaceId}/channels`, {
  token: alice.token,
});
const channel = channels.json[0];
check('스페이스 · 채널 · 초대 준비', !!channel && !!spaceId);

const send = (token, body) =>
  api('POST', `/spaces/${spaceId}/channels/${channel.id}/messages`, {
    token,
    body,
  });

// ── 기본 ──────────────────────────────────────
console.log('\n[사용자 멘션]');

const mentioning = await send(alice.token, {
  body: `<@${bob.userId}> 이것 좀 봐 주세요`,
});
check('멘션이 든 메시지 전송', mentioning.status === 201, `status=${mentioning.status}`);
check(
  '★ 전송 응답에 멘션 요약이 실린다 - 앱이 이름을 그릴 수 있어야 한다',
  mentioning.json.mentions?.length === 1 &&
    mentioning.json.mentions[0].userId === bob.userId &&
    mentioning.json.mentions[0].type === 'user' &&
    mentioning.json.mentions[0].name === '멘션검증b',
  JSON.stringify(mentioning.json.mentions),
);

const list = await api(
  'GET',
  `/spaces/${spaceId}/channels/${channel.id}/messages?limit=10`,
  { token: bob.token },
);
const inList = list.json.items.find((m) => m.id === mentioning.json.id);
check(
  '목록에도 멘션이 실린다',
  inList?.mentions?.[0]?.userId === bob.userId,
  JSON.stringify(inList?.mentions),
);

// ── 뱃지 ──────────────────────────────────────
console.log('\n[안 읽은 멘션 수]');

const bobChannels = await api('GET', `/spaces/${spaceId}/channels`, {
  token: bob.token,
});
const bobChannel = bobChannels.json.find((c) => c.id === channel.id);
check(
  '★ 멘션당한 사람의 채널에 mentionCount 가 뜬다',
  bobChannel?.mentionCount === 1,
  JSON.stringify({ mentionCount: bobChannel?.mentionCount }),
);

const aliceChannels = await api('GET', `/spaces/${spaceId}/channels`, {
  token: alice.token,
});
check(
  '★ 보낸 사람에게는 뜨지 않는다',
  aliceChannels.json.find((c) => c.id === channel.id)?.mentionCount === 0,
  JSON.stringify(
    aliceChannels.json.find((c) => c.id === channel.id)?.mentionCount,
  ),
);

// 읽으면 사라진다
await api('POST', `/spaces/${spaceId}/channels/${channel.id}/read`, {
  token: bob.token,
  body: { lastReadMessageId: mentioning.json.id },
});
const afterRead = await api('GET', `/spaces/${spaceId}/channels`, {
  token: bob.token,
});
check(
  '★ 읽으면 멘션 뱃지가 사라진다',
  afterRead.json.find((c) => c.id === channel.id)?.mentionCount === 0,
  JSON.stringify(afterRead.json.find((c) => c.id === channel.id)?.mentionCount),
);

// ── 자기 자신 ──────────────────────────────────
console.log('\n[규칙]');

const selfMention = await send(alice.token, {
  body: `<@${alice.userId}> 메모`,
});
check(
  '★ 자기 자신을 멘션해도 행을 만들지 않는다 - 내 뱃지가 내 글로 켜지면 뜻이 없다',
  selfMention.json.mentions?.length === 0,
  JSON.stringify(selfMention.json.mentions),
);

const dupMention = await send(alice.token, {
  body: `<@${bob.userId}> 그리고 <@${bob.userId}> 다시`,
});
check(
  '★ 같은 사람을 여러 번 불러도 한 번으로 친다',
  dupMention.json.mentions?.length === 1,
  JSON.stringify(dupMention.json.mentions),
);

const outsiderMention = await send(alice.token, {
  body: `<@${outsider.userId}> 남의 스페이스 사람`,
});
check(
  '★ 스페이스 멤버가 아닌 id 는 조용히 버린다 - 메시지는 그대로 남는다',
  outsiderMention.status === 201 && outsiderMention.json.mentions?.length === 0,
  JSON.stringify(outsiderMention.json.mentions),
);

const bogusId = await send(alice.token, {
  body: '<@00000000-0000-4000-8000-000000000000> 없는 사람',
});
check(
  '없는 id 도 메시지를 막지 않는다',
  bogusId.status === 201 && bogusId.json.mentions?.length === 0,
  `status=${bogusId.status}`,
);

const plainText = await send(alice.token, { body: '@멘션검증b 이건 그냥 텍스트다' });
check(
  '★ @이름 표기는 멘션이 아니다 - 본문에는 id 를 박는다',
  plainText.json.mentions?.length === 0,
  JSON.stringify(plainText.json.mentions),
);

// ── 특수 멘션 ──────────────────────────────────
console.log('\n[@channel · @everyone]');

const channelMention = await send(alice.token, { body: '@channel 공지입니다' });
check(
  '@channel 은 대상 사용자가 없다',
  channelMention.json.mentions?.length === 1 &&
    channelMention.json.mentions[0].type === 'channel' &&
    channelMention.json.mentions[0].userId === null,
  JSON.stringify(channelMention.json.mentions),
);

const bothSpecial = await send(alice.token, { body: '@everyone @channel 둘 다' });
check(
  '★ everyone 이 있으면 channel 은 덮인다 - 뱃지가 두 번 세면 안 된다',
  bothSpecial.json.mentions?.length === 1 &&
    bothSpecial.json.mentions[0].type === 'everyone',
  JSON.stringify(bothSpecial.json.mentions),
);

const notSpecial = await send(alice.token, { body: 'name@channel.com 은 이메일' });
check(
  '★ 이메일 속 @channel 은 멘션이 아니다 - 앞에 공백이 있어야 한다',
  notSpecial.json.mentions?.length === 0,
  JSON.stringify(notSpecial.json.mentions),
);

const specialBadge = await api('GET', `/spaces/${spaceId}/channels`, {
  token: bob.token,
});
check(
  '★ @channel · @everyone 도 뱃지를 켠다',
  (specialBadge.json.find((c) => c.id === channel.id)?.mentionCount ?? 0) >= 2,
  JSON.stringify(specialBadge.json.find((c) => c.id === channel.id)?.mentionCount),
);

// ── 스레드 답글 ────────────────────────────────
console.log('\n[스레드 답글에서도]');

const root = await send(alice.token, { body: '스레드 뿌리' });
const reply = await send(alice.token, {
  body: `<@${bob.userId}> 답글에서 부름`,
  parentId: root.json.id,
});
check(
  '★ 답글에서 멘션당해도 잡힌다',
  reply.json.mentions?.length === 1 &&
    reply.json.mentions[0].userId === bob.userId,
  JSON.stringify(reply.json.mentions),
);

// ── 삭제 ──────────────────────────────────────
console.log('\n[삭제된 메시지]');

await api('POST', `/spaces/${spaceId}/channels/${channel.id}/read`, {
  token: bob.token,
  body: { lastReadMessageId: reply.json.id },
});
const beforeDelete = await send(alice.token, {
  body: `<@${bob.userId}> 곧 지울 메시지`,
});
const withMention = await api('GET', `/spaces/${spaceId}/channels`, {
  token: bob.token,
});
const countBefore =
  withMention.json.find((c) => c.id === channel.id)?.mentionCount ?? 0;

await api('DELETE', `/spaces/${spaceId}/messages/${beforeDelete.json.id}`, {
  token: alice.token,
});
const afterDelete = await api('GET', `/spaces/${spaceId}/channels`, {
  token: bob.token,
});
const countAfter =
  afterDelete.json.find((c) => c.id === channel.id)?.mentionCount ?? 0;
check(
  '★ 메시지를 지우면 멘션 뱃지도 함께 내려간다',
  countBefore === 1 && countAfter === 0,
  `before=${countBefore} after=${countAfter}`,
);

console.log(`\n통과 ${pass} · 실패 ${fail}\n`);
process.exit(fail === 0 ? 0 : 1);
