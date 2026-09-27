// 사용자 설정(14단계) 검증 — 표시 이름 · 프로필 사진 · 비밀번호 변경 · 채널 음소거.
// 실제 서버 · 실제 DB · 실제 소켓으로 확인한다.
//
// 사전 조건: npm run db:up && npm run server:dev
// 사용: npm run check:settings
//
// 자체 계정 셋을 만든다 — alice · bob 은 스페이스를 함께 쓰고, carol 은 남이다.
// 아바타 열람 규칙(설계 D6)이 「함께 쓰는가」라 세 번째 사람이 반드시 있어야 한다.
import sharp from 'sharp';
import { requireServer } from './lib/preflight.mjs';
import { BASE, PASSWORD, api, signup, stamp } from './lib/api.mjs';
import { check, summary } from './lib/checks.mjs';
import { connect, waitFor } from './lib/socket.mjs';
await requireServer(BASE);

console.log('\n사용자 설정 검증 — 실서버 · 실DB · 실소켓\n');

const alice = await signup('settings', 'a', 'Settings A');
const bob = await signup('settings', 'b', 'Settings B');
const carol = await signup('settings', 'c', 'Settings C');

const space = await api('POST', '/spaces', {
  token: alice.token,
  body: { name: `settings ${stamp}` },
});
const spaceId = space.json?.id;
const invite = await api('POST', `/spaces/${spaceId}/invites`, {
  token: alice.token,
  body: { role: 'member' },
});
await api('POST', `/invites/${invite.json?.code}/accept`, { token: bob.token });
const channels = await api('GET', `/spaces/${spaceId}/channels`, { token: alice.token });
const channel = channels.json?.[0];
check('준비 (계정 셋 · 스페이스 · 초대 · 채널)', !!spaceId && !!channel);

const bobSocket = await connect(bob.token);
const carolSocket = await connect(carol.token);
const aliceSocket2 = await connect(alice.token);
const sockets = [bobSocket, carolSocket, aliceSocket2];

/** 이벤트가 오지 않아야 하는 쪽. 받으면 그 페이로드, 안 오면 null. */
const silence = (socket, event, ms = 1200) => waitFor(socket, event, ms);

async function uploadAvatar(token, { bytes, type = 'image/png', name = 'me.png' }) {
  const form = new FormData();
  form.append('file', new Blob([bytes], { type }), name);
  const res = await fetch(`${BASE}/me/avatar`, {
    method: 'PUT',
    headers: { authorization: `Bearer ${token}` },
    body: form,
  });
  let json = null;
  try {
    json = await res.json();
  } catch {
    /* 본문 없음 */
  }
  return { status: res.status, json };
}

/** 아바타 바이트를 받는다. `path` 는 응답의 `avatarUrl`(= /users/…) 그대로다. */
async function fetchAvatar(token, path) {
  const res = await fetch(`${BASE}${path}`, {
    headers: { authorization: `Bearer ${token}` },
  });
  const bytes = res.status === 200 ? Buffer.from(await res.arrayBuffer()) : null;
  return { status: res.status, bytes, headers: res.headers };
}

// ── 표시 이름 ───────────────────────────────────
console.log('\n[표시 이름]');

const bobHearsName = waitFor(bobSocket, 'user:updated', 3000);
const carolHearsName = silence(carolSocket, 'user:updated');
const renamed = await api('PATCH', '/me', {
  token: alice.token,
  body: { name: 'Alice Renamed' },
});
check('이름을 바꾼다', renamed.status === 200 && renamed.json?.name === 'Alice Renamed');
const nameEvent = await bobHearsName;
check(
  '★ 함께 쓰는 사람에게 user:updated 가 간다',
  nameEvent?.userId === alice.userId && nameEvent?.name === 'Alice Renamed',
  JSON.stringify(nameEvent),
);
check(
  '이벤트에 사진 칸도 함께 실린다 — 받는 쪽이 무엇이 바뀌었는지 가리지 않는다',
  nameEvent !== null && 'avatarUrl' in nameEvent,
  JSON.stringify(nameEvent),
);
check('★ 스페이스 밖 사람에게는 가지 않는다', (await carolHearsName) === null);

const said = await api('POST', `/spaces/${spaceId}/channels/${channel?.id}/messages`, {
  token: alice.token,
  body: { body: 'after rename' },
});
check(
  '이후 메시지의 작성자명이 새 이름이다',
  said.json?.author?.name === 'Alice Renamed',
  JSON.stringify(said.json?.author),
);

for (const [label, body] of [
  ['빈 이름', { name: '' }],
  ['51자 이름', { name: 'x'.repeat(51) }],
  ['★ 임의 아바타 URL(설계 D9)', { avatarUrl: 'https://tracker.invalid/p.gif' }],
]) {
  const r = await api('PATCH', '/me', { token: alice.token, body });
  check(`${label} → 400`, r.status === 400, `status=${r.status}`);
}

// ── 프로필 사진 ─────────────────────────────────
console.log('\n[프로필 사진]');

const wide = await sharp({
  create: { width: 600, height: 300, channels: 3, background: '#3366ff' },
})
  .png()
  .toBuffer();

const bobHearsAvatar = waitFor(bobSocket, 'user:updated', 3000);
const up = await uploadAvatar(alice.token, { bytes: wide });
const avatarUrl = up.json?.avatarUrl;
check('사진을 올린다', up.status === 200, `status=${up.status} ${JSON.stringify(up.json)}`);
check(
  '★ avatarUrl 은 서버가 만든 열람 경로다',
  typeof avatarUrl === 'string' &&
    avatarUrl.startsWith(`/users/${alice.userId}/avatar?v=`),
  String(avatarUrl),
);
const avatarEvent = await bobHearsAvatar;
check(
  '사진이 바뀌어도 user:updated 가 간다',
  typeof avatarUrl === 'string' && avatarEvent?.avatarUrl === avatarUrl,
  JSON.stringify(avatarEvent),
);

const byBob = await fetchAvatar(bob.token, avatarUrl ?? '/users/x/avatar');
const meta = byBob.bytes ? await sharp(byBob.bytes).metadata() : null;
check('★ 함께 쓰는 사람은 받는다', byBob.status === 200, `status=${byBob.status}`);
check(
  '★ 256×256 WebP 로 바뀌어 있다',
  meta?.format === 'webp' && meta.width === 256 && meta.height === 256,
  JSON.stringify(meta && { format: meta.format, width: meta.width, height: meta.height }),
);
check(
  '응답 헤더 — image/webp · private 캐시',
  byBob.headers.get('content-type') === 'image/webp' &&
    (byBob.headers.get('cache-control') ?? '').includes('private'),
  `${byBob.headers.get('content-type')} · ${byBob.headers.get('cache-control')}`,
);
const bySelf = await fetchAvatar(alice.token, avatarUrl ?? '/users/x/avatar');
check('본인도 받는다', bySelf.status === 200, `status=${bySelf.status}`);
const byCarol = await fetchAvatar(carol.token, avatarUrl ?? '/users/x/avatar');
check('★ 스페이스 밖 사람은 404 다 (403 이 아니다)', byCarol.status === 404, `status=${byCarol.status}`);
const ghost = await fetchAvatar(alice.token, '/users/00000000-0000-4000-8000-000000000000/avatar');
check('없는 사람도 404 다 — 스페이스 밖과 가릴 수 없다', ghost.status === 404, `status=${ghost.status}`);
const noPhoto = await fetchAvatar(alice.token, `/users/${bob.userId}/avatar`);
check('사진이 없는 사람도 404 다', noPhoto.status === 404, `status=${noPhoto.status}`);

const msgs = await api('GET', `/spaces/${spaceId}/channels/${channel?.id}/messages`, {
  token: bob.token,
});
const aliceMsg = (msgs.json?.items ?? msgs.json ?? []).find((m) => m.author?.id === alice.userId);
check(
  '메시지 응답의 작성자 avatarUrl 이 같은 값이다',
  typeof avatarUrl === 'string' && aliceMsg?.author?.avatarUrl === avatarUrl,
  JSON.stringify(aliceMsg?.author),
);

const up2 = await uploadAvatar(alice.token, { bytes: wide });
check(
  '★ 다시 올리면 버전이 바뀐다 — 앱 캐시가 옛 사진을 붙들지 않는다',
  up2.status === 200 && typeof up2.json?.avatarUrl === 'string' && up2.json.avatarUrl !== avatarUrl,
  `${avatarUrl} → ${up2.json?.avatarUrl}`,
);

const oldPath = await fetchAvatar(bob.token, avatarUrl ?? '/users/x/avatar');
check(
  '옛 주소로도 받는다 — 버전은 캐시를 가르는 표식일 뿐 따로 보관하지 않는다',
  oldPath.status === 200,
  `status=${oldPath.status}`,
);

const notImage = await uploadAvatar(alice.token, {
  bytes: Buffer.from('not an image'),
  type: 'text/plain',
  name: 'note.txt',
});
check('이미지가 아니면 400 이다', notImage.status === 400, `status=${notImage.status}`);
const fakePng = await uploadAvatar(alice.token, {
  bytes: Buffer.from('pretending to be png'),
  type: 'image/png',
});
check('★ 확장자만 이미지면 400 이다 — mime 을 믿지 않는다', fakePng.status === 400, `status=${fakePng.status}`);
const huge = await uploadAvatar(alice.token, {
  bytes: Buffer.alloc(5 * 1024 * 1024 + 1),
});
check('5MB 를 넘으면 413 이다', huge.status === 413, `status=${huge.status}`);

const removed = await api('DELETE', '/me/avatar', { token: alice.token });
check('지우면 avatarUrl 이 null 이다', removed.status === 200 && removed.json?.avatarUrl === null);
const afterRemove = await fetchAvatar(bob.token, up2.json?.avatarUrl ?? '/users/x/avatar');
check('지운 뒤에는 404 다', afterRemove.status === 404, `status=${afterRemove.status}`);

// ── 비밀번호 ────────────────────────────────────
console.log('\n[비밀번호]');

// bob 으로 한다 — alice 는 뒤의 음소거에서 계속 쓴다.
const bobLogin = await api('POST', '/auth/login', {
  body: { email: `settings-b-${stamp}@example.com`, password: PASSWORD, client: 'native' },
});
const oldRefresh = bobLogin.json?.refreshToken;
check('준비 — 로그인해 두 번째 세션을 만든다', typeof oldRefresh === 'string');

const NEW_PASSWORD = 'settings-new-pass-99';
for (const [label, body] of [
  ['★ 틀린 현재 비밀번호', { currentPassword: 'wrong-pass-000', newPassword: NEW_PASSWORD }],
  ['9자 새 비밀번호', { currentPassword: PASSWORD, newPassword: 'short-999' }],
  ['현재와 같은 새 비밀번호', { currentPassword: PASSWORD, newPassword: PASSWORD }],
]) {
  const r = await api('POST', '/auth/password', { token: bob.token, body });
  check(`${label} → 400 (401 이 아니다)`, r.status === 400, `status=${r.status}`);
}

const changed = await api('POST', '/auth/password', {
  token: bob.token,
  body: { currentPassword: PASSWORD, newPassword: NEW_PASSWORD, client: 'native' },
});
check(
  '비밀번호를 바꾸면 새 토큰 쌍을 준다',
  changed.status === 200 &&
    typeof changed.json?.accessToken === 'string' &&
    typeof changed.json?.refreshToken === 'string',
  `status=${changed.status}`,
);
const staleRefresh = await api('POST', '/auth/refresh', {
  body: { refreshToken: oldRefresh, client: 'native' },
});
check('★ 다른 세션의 리프레시 토큰은 끊긴다', staleRefresh.status === 401, `status=${staleRefresh.status}`);
const freshRefresh = await api('POST', '/auth/refresh', {
  body: { refreshToken: changed.json?.refreshToken, client: 'native' },
});
check('★ 바꾼 기기의 새 토큰은 산다', freshRefresh.status === 200, `status=${freshRefresh.status}`);
const oldLogin = await api('POST', '/auth/login', {
  body: { email: `settings-b-${stamp}@example.com`, password: PASSWORD },
});
check('옛 비밀번호로는 로그인되지 않는다', oldLogin.status === 401, `status=${oldLogin.status}`);
const newLogin = await api('POST', '/auth/login', {
  body: { email: `settings-b-${stamp}@example.com`, password: NEW_PASSWORD },
});
check('새 비밀번호로 로그인된다', newLogin.status === 200, `status=${newLogin.status}`);

// ── 채널 음소거 ─────────────────────────────────
console.log('\n[채널 음소거]');

const mutePath = (id) => `/spaces/${spaceId}/channels/${id}/mute`;
const listChannel = async () =>
  (await api('GET', `/spaces/${spaceId}/channels`, { token: alice.token })).json?.find(
    (c) => c.id === channel?.id,
  );

// 읽음 위치를 먼저 남겨 둔다 — 음소거가 이것을 되돌리지 않는지 본다.
await api('POST', `/spaces/${spaceId}/channels/${channel?.id}/read`, {
  token: alice.token,
  body: { lastReadMessageId: said.json?.id },
});
const readBefore = (await listChannel())?.lastReadMessageId;

const secondHears = waitFor(aliceSocket2, 'channel:muted', 3000);
const bobHearsMute = silence(bobSocket, 'channel:muted');
const muted = await api('PUT', mutePath(channel?.id), {
  token: alice.token,
  body: { muted: true },
});
check('음소거를 켠다', muted.status === 200 && muted.json?.muted === true, JSON.stringify(muted.json));
check('★ 채널 목록에 muted 가 실린다', (await listChannel())?.muted === true);
const muteEvent = await secondHears;
check(
  '★ 내 다른 기기에 channel:muted 가 간다',
  muteEvent?.channelId === channel?.id && muteEvent?.muted === true && muteEvent?.spaceId === spaceId,
  JSON.stringify(muteEvent),
);
check('★ 다른 사람에게는 가지 않는다', (await bobHearsMute) === null);
check(
  '★ 음소거가 읽음 위치를 바꾸지 않는다',
  typeof readBefore === 'string' && (await listChannel())?.lastReadMessageId === readBefore,
  String(readBefore),
);
const again = await api('PUT', mutePath(channel?.id), {
  token: alice.token,
  body: { muted: true },
});
check('두 번 켜도 200 이다 (멱등)', again.status === 200);
const unmuted = await api('PUT', mutePath(channel?.id), {
  token: alice.token,
  body: { muted: false },
});
check('끈다', unmuted.status === 200 && (await listChannel())?.muted === false);

// 공개 채널에 행이 없는 사람(bob 은 이 채널에서 읽음을 남긴 적이 없다)
const bobMute = await api('PUT', mutePath(channel?.id), {
  token: bob.token,
  body: { muted: true },
});
const bobList = await api('GET', `/spaces/${spaceId}/channels`, { token: bob.token });
check(
  '★ 멤버 행이 없는 공개 채널도 음소거된다 (upsert)',
  bobMute.status === 200 && bobList.json?.find((c) => c.id === channel?.id)?.muted === true,
);

const priv = await api('POST', `/spaces/${spaceId}/channels`, {
  token: alice.token,
  body: { name: `secret-${stamp}`, isPrivate: true },
});
const privMute = await api('PUT', mutePath(priv.json?.id), {
  token: bob.token,
  body: { muted: true },
});
check('못 보는 비공개 채널은 404 다', priv.status === 201 && privMute.status === 404, `status=${privMute.status}`);
const otherSpace = await api('POST', '/spaces', {
  token: carol.token,
  body: { name: `settings other ${stamp}` },
});
const otherChannel = (
  await api('GET', `/spaces/${otherSpace.json?.id}/channels`, { token: carol.token })
).json?.[0];
const crossMute = await api('PUT', mutePath(otherChannel?.id), {
  token: alice.token,
  body: { muted: true },
});
check('다른 스페이스의 채널 id 는 404 다', !!otherChannel && crossMute.status === 404, `status=${crossMute.status}`);
const badBody = await api('PUT', mutePath(channel?.id), {
  token: alice.token,
  body: { muted: 'yes' },
});
check('muted 가 불리언이 아니면 400 이다', badBody.status === 400, `status=${badBody.status}`);

for (const s of sockets) s?.close?.();
process.exit(summary() === 0 ? 0 : 1);
