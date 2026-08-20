// 저장소 연동(10-1) 검증. 실제 서버 · 실제 DB 로 확인한다.
//
// 사전 조건: npm run db:up && npm run server:dev
// 사용: npm run check:repos
//
// **GitHub 이 없어도 전부 돈다.** 웹훅 서명을 우리가 직접 만들어 보내면
// 되기 때문이다 — 그것이 이 조각을 외부 의존 없이 자를 수 있었던 이유다.
import { createHmac } from 'node:crypto';

const BASE = 'http://127.0.0.1:3000/api';

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

/**
 * 웹훅을 보낸다. **본문 문자열을 그대로 서명하고 그대로 보낸다** —
 * 서명한 것과 보내는 것이 한 바이트라도 다르면 서버가 위조로 판정한다.
 */
async function deliver(repoId, { secret, event, deliveryId, payload, provider = 'github' }) {
  const raw = JSON.stringify(payload);
  const headers = {
    'content-type': 'application/json',
    'x-github-event': event,
  };
  if (deliveryId) headers['x-github-delivery'] = deliveryId;
  if (secret !== null) {
    headers['x-hub-signature-256'] =
      'sha256=' + createHmac('sha256', secret).update(raw).digest('hex');
  }

  const res = await fetch(`${BASE}/webhooks/${provider}/${repoId}`, {
    method: 'POST',
    headers,
    body: raw,
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
      email: `repo-${tag}-${stamp}@example.com`,
      password: 'check-repos-1234',
      name: `저장소검증${tag}`,
      client: 'native',
    },
  });
  if (res.status !== 201) {
    console.error('가입 실패:', res.status, JSON.stringify(res.json));
    process.exit(1);
  }
  return { token: res.json.accessToken, userId: res.json.user.id };
}

const pushPayload = (message = '보드 폭 계산을 고친다') => ({
  ref: 'refs/heads/main',
  pusher: { name: '윤건' },
  commits: [{ message }],
});

console.log('\n저장소 연동 검증 — 실서버 · 실DB (GitHub 없이 돈다)\n');

const alice = await signup('a');
const outsider = await signup('x');

const space = await api('POST', '/spaces', {
  token: alice.token,
  body: { name: `repos${stamp}` },
});
const spaceId = space.json.id;
const channels = await api('GET', `/spaces/${spaceId}/channels`, {
  token: alice.token,
});
const channel = channels.json[0];
check('스페이스 · 채널 준비', !!channel);

// ── 1. 등록 ──────────────────────────────────────────
const created = await api('POST', `/spaces/${spaceId}/repos`, {
  token: alice.token,
  body: {
    provider: 'github',
    fullPath: 'dbsrjs/Nexus',
    linkedChannelId: channel.id,
  },
});
check('저장소 등록 201', created.status === 201, JSON.stringify(created.json));
check('등록 응답에 시크릿이 있다', typeof created.json?.webhookSecret === 'string');

const repoId = created.json.id;
const secret = created.json.webhookSecret;

const listed = await api('GET', `/spaces/${spaceId}/repos`, { token: alice.token });
check(
  '★ 목록에는 시크릿이 없다',
  listed.json.every((r) => r.webhookSecret === undefined),
  JSON.stringify(listed.json[0]),
);

const badPath = await api('POST', `/spaces/${spaceId}/repos`, {
  token: alice.token,
  body: { provider: 'github', fullPath: '이름만' },
});
check('소유자/이름 형식이 아니면 400', badPath.status === 400, `status=${badPath.status}`);

const foreignChannel = await api('POST', `/spaces/${spaceId}/repos`, {
  token: alice.token,
  body: { provider: 'github', fullPath: 'a/b', linkedChannelId: crypto.randomUUID() },
});
check('없는 채널에 붙이면 404', foreignChannel.status === 404, `status=${foreignChannel.status}`);

const asOutsider = await api('GET', `/spaces/${spaceId}/repos`, { token: outsider.token });
check('비멤버의 목록 조회는 404', asOutsider.status === 404, `status=${asOutsider.status}`);

// ── 2. 서명 검증 ─────────────────────────────────────
const noSignature = await deliver(repoId, {
  secret: null, event: 'push', payload: pushPayload(),
});
check('서명이 없으면 401', noSignature.status === 401, `status=${noSignature.status}`);

const wrongSecret = await deliver(repoId, {
  secret: 'whsec_wrong', event: 'push', payload: pushPayload(),
});
check('다른 시크릿으로 서명하면 401', wrongSecret.status === 401, `status=${wrongSecret.status}`);

const unknownRepo = await deliver(crypto.randomUUID(), {
  secret, event: 'push', payload: pushPayload(),
});
check('없는 저장소는 404 — 401 과 뭉개지 않는다', unknownRepo.status === 404,
  `status=${unknownRepo.status}`);

// ── 3. 이벤트가 채널로 흘러 들어온다 ─────────────────
const before = (await api(
  'GET', `/spaces/${spaceId}/channels/${channel.id}/messages`, { token: alice.token },
)).json.items.length;

const pushed = await deliver(repoId, {
  secret, event: 'push', deliveryId: `d-${stamp}-1`, payload: pushPayload(),
});
check('서명이 맞으면 200', pushed.status === 200, JSON.stringify(pushed.json));
check('적재하고 게시했다', pushed.json?.stored === true && pushed.json?.posted === true,
  JSON.stringify(pushed.json));

const after = (await api(
  'GET', `/spaces/${spaceId}/channels/${channel.id}/messages`, { token: alice.token },
)).json.items;
check('★ 채널에 메시지가 하나 늘었다', after.length === before + 1,
  `${before} → ${after.length}`);
check('본문이 한 줄로 요약된다',
  after[0]?.body === '윤건 님이 main 에 커밋을 올렸습니다 — 보드 폭 계산을 고친다',
  after[0]?.body);
check('작성자가 GitHub 봇이다', after[0]?.author?.name === 'GitHub',
  JSON.stringify(after[0]?.author));

const members = await api('GET', `/spaces/${spaceId}/members`, { token: alice.token });
check('★ 봇은 스페이스 멤버가 아니다',
  members.json.every((m) => m.user?.name !== 'GitHub' && m.name !== 'GitHub'),
  JSON.stringify(members.json.map((m) => m.user?.name ?? m.name)));

// ── 4. 중복 배달 ─────────────────────────────────────
const again = await deliver(repoId, {
  secret, event: 'push', deliveryId: `d-${stamp}-1`, payload: pushPayload(),
});
check('같은 배달을 다시 보내도 200', again.status === 200, `status=${again.status}`);
check('★ 중복으로 걸러 메시지를 만들지 않는다', again.json?.duplicate === true,
  JSON.stringify(again.json));

const afterDupe = (await api(
  'GET', `/spaces/${spaceId}/channels/${channel.id}/messages`, { token: alice.token },
)).json.items;
check('채널 메시지가 늘지 않았다', afterDupe.length === after.length,
  `${after.length} → ${afterDupe.length}`);

// ── 5. 모르는 이벤트 ─────────────────────────────────
const starred = await deliver(repoId, {
  secret, event: 'star', deliveryId: `d-${stamp}-2`, payload: { action: 'created' },
});
check('모르는 이벤트도 200 — 재시도를 부르지 않는다', starred.status === 200,
  `status=${starred.status}`);
check('모르는 이벤트는 적재하지 않는다', starred.json?.stored === false,
  JSON.stringify(starred.json));

const noisy = await deliver(repoId, {
  secret,
  event: 'pull_request',
  deliveryId: `d-${stamp}-3`,
  payload: { action: 'synchronize', number: 1, pull_request: { title: 't', user: { login: 'x' } } },
});
check('PR synchronize 는 채널을 덮지 않는다', noisy.json?.stored === false,
  JSON.stringify(noisy.json));

// ── 6. 채널을 붙이지 않은 저장소 ─────────────────────
const detached = await api('POST', `/spaces/${spaceId}/repos`, {
  token: alice.token,
  body: { provider: 'github', fullPath: 'dbsrjs/detached' },
});
const detachedPush = await deliver(detached.json.id, {
  secret: detached.json.webhookSecret,
  event: 'push',
  deliveryId: `d-${stamp}-4`,
  payload: pushPayload('채널 없는 저장소'),
});
check('★ 채널이 없으면 적재만 하고 게시하지 않는다',
  detachedPush.json?.stored === true && detachedPush.json?.posted === false,
  JSON.stringify(detachedPush.json));

// 저장소마다 시크릿이 다르다 — 하나가 새도 다른 저장소는 안전해야 한다.
const crossSecret = await deliver(detached.json.id, {
  secret, event: 'push', payload: pushPayload(),
});
check('★ 다른 저장소의 시크릿으로는 401', crossSecret.status === 401,
  `status=${crossSecret.status}`);

// ── 7. 시크릿 재발급 ─────────────────────────────────
const rotated = await api('POST', `/spaces/${spaceId}/repos/${repoId}/secret`, {
  token: alice.token,
});
check('재발급 응답에 새 시크릿이 있다', typeof rotated.json?.webhookSecret === 'string');
check('시크릿이 실제로 바뀐다', rotated.json.webhookSecret !== secret);

const withOldSecret = await deliver(repoId, {
  secret, event: 'push', deliveryId: `d-${stamp}-5`, payload: pushPayload(),
});
check('★ 옛 시크릿은 그 순간부터 401', withOldSecret.status === 401,
  `status=${withOldSecret.status}`);

const withNewSecret = await deliver(repoId, {
  secret: rotated.json.webhookSecret,
  event: 'push',
  deliveryId: `d-${stamp}-6`,
  payload: pushPayload('새 시크릿으로'),
});
check('새 시크릿은 통과한다', withNewSecret.status === 200, `status=${withNewSecret.status}`);

// ── 8. 삭제 ──────────────────────────────────────────
const messagesBeforeDelete = (await api(
  'GET', `/spaces/${spaceId}/channels/${channel.id}/messages`, { token: alice.token },
)).json.items.length;

await api('DELETE', `/spaces/${spaceId}/repos/${repoId}`, { token: alice.token });

const gone = await deliver(repoId, {
  secret: rotated.json.webhookSecret,
  event: 'push',
  deliveryId: `d-${stamp}-7`,
  payload: pushPayload(),
});
check('지운 저장소의 웹훅은 404', gone.status === 404, `status=${gone.status}`);

const messagesAfterDelete = (await api(
  'GET', `/spaces/${spaceId}/channels/${channel.id}/messages`, { token: alice.token },
)).json.items.length;
check('★ 저장소를 지워도 채널 메시지는 남는다 — 대화의 일부다',
  messagesAfterDelete === messagesBeforeDelete,
  `${messagesBeforeDelete} → ${messagesAfterDelete}`);

console.log(`\n통과 ${pass} · 실패 ${fail}\n`);
process.exit(fail === 0 ? 0 : 1);
