// 이슈 보드(9-1) 검증. 실제 서버 · 실제 DB · 실제 소켓으로 확인한다.
//
// 사전 조건: npm run db:up && npm run server:dev
// 사용: npm run check:issues
//
// 자체 계정 · 스페이스를 만들어 쓰므로 시드 비밀번호가 필요 없다.
import { io } from 'socket.io-client';

import { requireServer } from './lib/preflight.mjs';
const BASE = 'http://127.0.0.1:3000/api';
await requireServer(BASE);
const WS = 'http://127.0.0.1:3000';

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

function connect(token) {
  return new Promise((resolve) => {
    const socket = io(WS, {
      auth: { token },
      transports: ['websocket'],
      reconnection: false,
      timeout: 5000,
    });
    socket.once('connect', () => resolve(socket));
    socket.once('connect_error', (err) => resolve(err));
  });
}

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

const stamp = Date.now();

async function signup(tag) {
  const res = await api('POST', '/auth/signup', {
    body: {
      email: `issue-${tag}-${stamp}@example.com`,
      password: 'check-issues-1234',
      name: `이슈검증${tag}`,
      client: 'native',
    },
  });
  if (res.status !== 201) {
    console.error('가입 실패:', res.status, JSON.stringify(res.json));
    process.exit(1);
  }
  return { token: res.json.accessToken, userId: res.json.user.id };
}

console.log('\n이슈 보드 검증 — 실서버 · 실DB · 실소켓\n');

const alice = await signup('a');
const guest = await signup('g');
const outsider = await signup('x');

// ── 준비 ─────────────────────────────────────────────
// slug 를 예측할 수 있도록 영문 이름으로 만든다(한글 이름은 폴백 slug 가 된다).
const space = await api('POST', '/spaces', {
  token: alice.token,
  body: { name: `board${stamp}` },
});
const spaceId = space.json.id;
const slug = space.json.slug;
check('스페이스 준비', !!spaceId, JSON.stringify(space.json));

// 접두사 규칙: slug 의 앞 마디들을 3자 이상이 될 때까지 이어 붙여 6자로 자른다.
const prefix = slug
  .toUpperCase()
  .split(/[^A-Z0-9]+/)
  .filter(Boolean)
  .reduce((acc, part) => (acc.length >= 3 ? acc : acc + part), '')
  .slice(0, 6);

// guest 를 초대로 넣는다.
const invite = await api('POST', `/spaces/${spaceId}/invites`, {
  token: alice.token,
  body: { role: 'guest' },
});
await api('POST', `/invites/${invite.json.code}/accept`, { token: guest.token });

// 남의 스페이스(비교용)
const otherSpace = await api('POST', '/spaces', {
  token: outsider.token,
  body: { name: `other${stamp}` },
});
const otherIssue = await api('POST', `/spaces/${otherSpace.json.id}/issues`, {
  token: outsider.token,
  body: { title: '남의 이슈' },
});

const createIssue = (body, token = alice.token) =>
  api('POST', `/spaces/${spaceId}/issues`, { token, body });

const listIssues = (query = '', token = alice.token) =>
  api('GET', `/spaces/${spaceId}/issues${query}`, { token });

// ── 1. 테넌트 격리 ───────────────────────────────────
const foreign = await api(
  `GET`,
  `/spaces/${spaceId}/issues/${otherIssue.json.id}`,
  { token: alice.token },
);
check('타 스페이스 이슈 조회는 404', foreign.status === 404, `status=${foreign.status}`);

const foreignPatch = await api(
  'PATCH',
  `/spaces/${spaceId}/issues/${otherIssue.json.id}`,
  { token: alice.token, body: { title: '남의 것을 고친다' } },
);
check(
  '타 스페이스 이슈 수정도 404',
  foreignPatch.status === 404,
  `status=${foreignPatch.status}`,
);

const asOutsider = await listIssues('', outsider.token);
check('비멤버의 목록 조회는 404', asOutsider.status === 404, `status=${asOutsider.status}`);

// ── 2. 채번 ──────────────────────────────────────────
const burst = await Promise.all(
  Array.from({ length: 10 }, (_, i) => createIssue({ title: `동시 ${i}` })),
);
const keys = burst.map((r) => r.json?.key);
check('동시 생성 10건이 모두 201', burst.every((r) => r.status === 201));
check('동시 생성 10건의 키가 모두 다르다', new Set(keys).size === 10, keys.join(','));
check(
  `키가 slug 접두사(${prefix})를 쓴다`,
  keys.every((k) => typeof k === 'string' && k.startsWith(`${prefix}-`)),
  keys[0],
);

// ── 3. position — 사이 삽입 ──────────────────────────
const first = (await createIssue({ title: '첫째' })).json;
const second = (await createIssue({ title: '둘째' })).json;
const third = (await createIssue({ title: '셋째' })).json;

// 새 이슈는 맨 위에 놓이므로 지금 순서는 셋째 · 둘째 · 첫째다.
const beforeMove = (await listIssues('?status=backlog')).json.issues.map((i) => i.id);
check(
  '새 이슈는 컬럼 맨 위에 놓인다',
  beforeMove.indexOf(third.id) < beforeMove.indexOf(second.id) &&
    beforeMove.indexOf(second.id) < beforeMove.indexOf(first.id),
  beforeMove.slice(0, 3).join(','),
);

const moved = await api('PUT', `/spaces/${spaceId}/issues/${third.id}/position`, {
  token: alice.token,
  body: { status: 'backlog', afterId: second.id, beforeId: first.id },
});
check('사이로 옮기면 200', moved.status === 200, JSON.stringify(moved.json));

const order = (await listIssues('?status=backlog')).json.issues.map((i) => i.id);
check(
  '목록 순서가 둘째 · 셋째 · 첫째 다',
  order.indexOf(second.id) < order.indexOf(third.id) &&
    order.indexOf(third.id) < order.indexOf(first.id),
  order.slice(0, 3).join(','),
);

// ── 4. 이웃 검증 ─────────────────────────────────────
const cross = await api('PUT', `/spaces/${spaceId}/issues/${third.id}/position`, {
  token: alice.token,
  body: { status: 'doing', afterId: first.id },
});
check('다른 컬럼 카드를 기준으로 옮기면 400', cross.status === 400, `status=${cross.status}`);

const reversed = await api('PUT', `/spaces/${spaceId}/issues/${third.id}/position`, {
  token: alice.token,
  body: { status: 'backlog', afterId: first.id, beforeId: second.id },
});
check('이웃 순서가 뒤바뀌면 400', reversed.status === 400, `status=${reversed.status}`);

const foreignNeighbour = await api(
  'PUT',
  `/spaces/${spaceId}/issues/${third.id}/position`,
  { token: alice.token, body: { status: 'backlog', afterId: otherIssue.json.id } },
);
check(
  '타 스페이스 카드를 기준으로 옮기면 404',
  foreignNeighbour.status === 404,
  `status=${foreignNeighbour.status}`,
);

// ── 5. 권한 ──────────────────────────────────────────
const guestList = await listIssues('', guest.token);
check('guest 열람 허용', guestList.status === 200, `status=${guestList.status}`);

const guestCreate = await createIssue({ title: 'guest 가 만든다' }, guest.token);
check('guest 생성 거부', guestCreate.status === 403, `status=${guestCreate.status}`);

const guestMove = await api('PUT', `/spaces/${spaceId}/issues/${first.id}/position`, {
  token: guest.token,
  body: { status: 'doing' },
});
check('guest 이동 거부', guestMove.status === 403, `status=${guestMove.status}`);

// ── 6. closedAt ──────────────────────────────────────
const toDone = await api('PATCH', `/spaces/${spaceId}/issues/${first.id}`, {
  token: alice.token,
  body: { status: 'done' },
});
check('done 으로 옮기면 closedAt 이 찍힌다', !!toDone.json?.closedAt, JSON.stringify(toDone.json?.closedAt));

const withinDone = await api('PUT', `/spaces/${spaceId}/issues/${first.id}/position`, {
  token: alice.token,
  body: { status: 'done' },
});
check(
  'done 안에서 자리만 옮기면 closedAt 이 그대로다',
  withinDone.json?.closedAt === toDone.json?.closedAt,
  `${withinDone.json?.closedAt} vs ${toDone.json?.closedAt}`,
);

const fromDone = await api('PATCH', `/spaces/${spaceId}/issues/${first.id}`, {
  token: alice.token,
  body: { status: 'doing' },
});
check('done 에서 나오면 closedAt 이 비워진다', fromDone.json?.closedAt === null, JSON.stringify(fromDone.json?.closedAt));

// PATCH 로 컬럼을 옮기면 대상 컬럼 맨 위로 간다.
const doingTop = (await listIssues('?status=doing')).json.issues;
check(
  'PATCH 로 옮긴 카드가 대상 컬럼 맨 위에 있다',
  doingTop[0]?.id === first.id,
  doingTop.map((i) => i.id).join(','),
);

// ── 7. 에픽은 한 단계 ────────────────────────────────
const epic = (await createIssue({ title: '에픽' })).json;
const story = await createIssue({ title: '스토리', parentId: epic.id });
check('에픽 아래 스토리는 만들어진다', story.status === 201, `status=${story.status}`);

const grandchild = await createIssue({ title: '손자', parentId: story.json.id });
check('에픽의 에픽은 400', grandchild.status === 400, `status=${grandchild.status}`);

// ── 8. 소켓 ──────────────────────────────────────────
const socket = await connect(alice.token);
const outsiderSocket = await connect(outsider.token);
check('소켓 연결', !!socket.id && !!outsiderSocket.id);

const createdEvent = waitFor(socket, 'issue:created');
const outsiderEvent = waitFor(outsiderSocket, 'issue:created', 1500);
const made = await createIssue({ title: '소켓으로 올 이슈' });
const arrived = await createdEvent;
check('issue:created 가 도착한다', arrived?.key === made.json.key, JSON.stringify(arrived?.key));
check('비멤버에게는 가지 않는다', (await outsiderEvent) === null);

const updatedEvent = waitFor(socket, 'issue:updated');
await api('PATCH', `/spaces/${spaceId}/issues/${made.json.id}`, {
  token: alice.token,
  body: { status: 'review' },
});
check('issue:updated 가 도착한다', (await updatedEvent)?.status === 'review');

// ── 9. 정렬 자리 소진 → 재채번 ───────────────────────
// 같은 틈에 계속 끼워 넣으면 Decimal 의 유효 자릿수가 소진된다(실측 64회).
// 그때 그 컬럼만 다시 채번하는 경로가 도는지 본다 — 안 돌면 두 카드가 같은
// position 을 갖고 순서가 tie-break 로 넘어가 흔들린다.
const bottom = (await createIssue({ title: '바닥', status: 'review' })).json;
const ceiling = (await createIssue({ title: '천장', status: 'review' })).json;

let anchorId = ceiling.id;
let squeezeOk = true;
for (let i = 0; i < 70; i++) {
  const card = (await createIssue({ title: `끼움 ${i}`, status: 'review' })).json;
  const res = await api('PUT', `/spaces/${spaceId}/issues/${card.id}/position`, {
    token: alice.token,
    body: { status: 'review', afterId: anchorId, beforeId: bottom.id },
  });
  if (res.status !== 200) {
    squeezeOk = false;
    check(`${i}번째 끼워 넣기 실패`, false, JSON.stringify(res.json));
    break;
  }
  anchorId = card.id;
}
check('자리가 소진될 때까지 끼워 넣어도 전부 200', squeezeOk);

const squeezed = (await listIssues('?status=review')).json.issues;
const squeezedPositions = squeezed.map((i) => Number(i.position));
check(
  '재채번 뒤에도 position 이 서로 다르다',
  new Set(squeezed.map((i) => i.position)).size === squeezed.length,
  `${squeezed.length}건 중 유일값 ${new Set(squeezed.map((i) => i.position)).size}개`,
);
check(
  '목록이 position 오름차순으로 온다',
  squeezedPositions.every((p, i) => i === 0 || squeezedPositions[i - 1] <= p),
  squeezedPositions.slice(0, 5).join(','),
);
// 이 컬럼에는 앞 단계(소켓 검증)가 옮겨 놓은 카드도 있으므로 "맨 아래"가
// 아니라 **내가 넣은 카드들보다 아래**인지를 본다. 절대 위치가 아니라
// 상대 순서가 이 기능의 계약이다.
const squeezedIds = squeezed.map((i) => i.id);
const bottomAt = squeezedIds.indexOf(bottom.id);
const mine = squeezed
  .filter((i) => i.title === '천장' || i.title.startsWith('끼움'))
  .map((i) => squeezedIds.indexOf(i.id));
check(
  '끼워 넣은 카드가 전부 바닥 위에 있다',
  bottomAt >= 0 && mine.length === 71 && mine.every((at) => at < bottomAt),
  `바닥=${bottomAt} · 내 카드 ${mine.length}개 중 아래로 샌 것 ${mine.filter((at) => at > bottomAt).length}개`,
);

// ── 10. 이슈 상세 · 댓글 (9-2a) ──────────────────────
const detailTarget = (await createIssue({ title: '댓글이 달릴 이슈' })).json;

const emptyComments = await api(
  'GET',
  `/spaces/${spaceId}/issues/${detailTarget.id}/comments`,
  { token: alice.token },
);
check('댓글이 없으면 빈 목록', emptyComments.status === 200 && emptyComments.json.length === 0,
  JSON.stringify(emptyComments.json));

const wrote = await api('POST', `/spaces/${spaceId}/issues/${detailTarget.id}/comments`, {
  token: alice.token,
  body: { body: '첫 댓글' },
});
check('댓글 작성 201', wrote.status === 201, `status=${wrote.status}`);
check('댓글에 작성자 요약이 붙는다', wrote.json?.author?.id === alice.userId,
  JSON.stringify(wrote.json?.author));

await api('POST', `/spaces/${spaceId}/issues/${detailTarget.id}/comments`, {
  token: alice.token, body: { body: '둘째 댓글' },
});
const comments = await api('GET', `/spaces/${spaceId}/issues/${detailTarget.id}/comments`, {
  token: alice.token,
});
check('댓글은 오래된 것부터 온다',
  comments.json[0]?.body === '첫 댓글' && comments.json[1]?.body === '둘째 댓글',
  comments.json.map((c) => c.body).join(','));

// 남의 스페이스 이슈에는 댓글을 달 수 없다.
const foreignComment = await api(
  'POST',
  `/spaces/${spaceId}/issues/${otherIssue.json.id}/comments`,
  { token: alice.token, body: { body: '남의 이슈에' } },
);
check('타 스페이스 이슈 댓글은 404', foreignComment.status === 404,
  `status=${foreignComment.status}`);

const guestComment = await api(
  'POST',
  `/spaces/${spaceId}/issues/${detailTarget.id}/comments`,
  { token: guest.token, body: { body: 'guest 가 단다' } },
);
check('guest 댓글 작성 거부', guestComment.status === 403, `status=${guestComment.status}`);
check('guest 댓글 열람 허용',
  (await api('GET', `/spaces/${spaceId}/issues/${detailTarget.id}/comments`,
    { token: guest.token })).status === 200);

// key 로 한 건만 찾는 길 — 딥링크용
const byKey = await listIssues(`?key=${detailTarget.key}`);
check('key 로 한 건만 찾는다',
  byKey.json.issues.length === 1 && byKey.json.issues[0].id === detailTarget.id,
  `${byKey.json.issues.length}건`);

// ── 11. 이슈 삭제 (9-2a) ─────────────────────────────
const doomed = (await createIssue({ title: '지워질 이슈' })).json;

const guestDelete = await api('DELETE', `/spaces/${spaceId}/issues/${doomed.id}`, {
  token: guest.token,
});
check('guest 삭제 거부', guestDelete.status === 403, `status=${guestDelete.status}`);

const deletedEvent = waitFor(socket, 'issue:deleted');
const removed = await api('DELETE', `/spaces/${spaceId}/issues/${doomed.id}`, {
  token: alice.token,
});
check('작성자는 자기 이슈를 지운다', removed.status === 204, `status=${removed.status}`);
check('issue:deleted 가 도착한다', (await deletedEvent)?.issueId === doomed.id);

const gone = await api('GET', `/spaces/${spaceId}/issues/${doomed.id}`, { token: alice.token });
check('지운 이슈는 404', gone.status === 404, `status=${gone.status}`);

// 삭제는 하드 삭제라 댓글도 함께 사라진다(Cascade).
const withComment = (await createIssue({ title: '댓글 달린 채 지워질 이슈' })).json;
await api('POST', `/spaces/${spaceId}/issues/${withComment.id}/comments`, {
  token: alice.token, body: { body: '함께 사라질 댓글' },
});
await api('DELETE', `/spaces/${spaceId}/issues/${withComment.id}`, { token: alice.token });
check('이슈를 지우면 댓글도 사라진다',
  (await api('GET', `/spaces/${spaceId}/issues/${withComment.id}/comments`,
    { token: alice.token })).status === 404);

// 부모를 지워도 자식은 남는다 — 할 일이 사라지면 안 된다.
const parent = (await createIssue({ title: '지워질 에픽' })).json;
const child = (await createIssue({ title: '남아야 할 스토리', parentId: parent.id })).json;
await api('DELETE', `/spaces/${spaceId}/issues/${parent.id}`, { token: alice.token });
const orphan = await api('GET', `/spaces/${spaceId}/issues/${child.id}`, { token: alice.token });
check('부모를 지워도 자식은 남는다', orphan.status === 200, `status=${orphan.status}`);
check('자식의 parentId 는 비워진다', orphan.json?.parentId === null,
  JSON.stringify(orphan.json?.parentId));

// ── 12. 라벨 (9-2b) ──────────────────────────────────
const bug = await api('POST', `/spaces/${spaceId}/labels`, {
  token: alice.token,
  body: { name: '버그', color: '#D47D7D' },
});
check('라벨 생성 201', bug.status === 201, JSON.stringify(bug.json));

const dupe = await api('POST', `/spaces/${spaceId}/labels`, {
  token: alice.token,
  body: { name: '버그', color: '#000000' },
});
check('같은 이름 라벨은 409', dupe.status === 409, `status=${dupe.status}`);

const badColor = await api('POST', `/spaces/${spaceId}/labels`, {
  token: alice.token,
  body: { name: '잘못된색', color: 'red' },
});
check('색 형식이 틀리면 400', badColor.status === 400, `status=${badColor.status}`);

const chore = (await api('POST', `/spaces/${spaceId}/labels`, {
  token: alice.token,
  body: { name: '잡일', color: '#74B48F' },
})).json;

const guestLabel = await api('POST', `/spaces/${spaceId}/labels`, {
  token: guest.token, body: { name: 'guest 라벨', color: '#111111' },
});
check('guest 라벨 생성 거부', guestLabel.status === 403, `status=${guestLabel.status}`);

const labeled = (await createIssue({ title: '라벨이 붙을 이슈' })).json;
const setLabels = await api('PUT', `/spaces/${spaceId}/issues/${labeled.id}/labels`, {
  token: alice.token,
  body: { labelIds: [bug.json.id, chore.id] },
});
check('라벨 두 개를 붙인다', setLabels.status === 200 && setLabels.json.length === 2,
  JSON.stringify(setLabels.json?.length));

const withLabels = await api('GET', `/spaces/${spaceId}/issues/${labeled.id}`, {
  token: alice.token,
});
check('이슈 응답에 라벨이 실린다', withLabels.json?.labels?.length === 2,
  JSON.stringify(withLabels.json?.labels?.map((l) => l.name)));

// 통째 교체라 멱등하다 — 같은 요청을 다시 보내도 개수가 늘지 않는다.
await api('PUT', `/spaces/${spaceId}/issues/${labeled.id}/labels`, {
  token: alice.token, body: { labelIds: [bug.json.id, chore.id] },
});
check('같은 라벨을 다시 붙여도 늘지 않는다',
  (await api('GET', `/spaces/${spaceId}/issues/${labeled.id}`, { token: alice.token }))
    .json.labels.length === 2);

const replaced = await api('PUT', `/spaces/${spaceId}/issues/${labeled.id}/labels`, {
  token: alice.token, body: { labelIds: [chore.id] },
});
check('통째 교체라 빠진 것은 떨어진다',
  replaced.json.length === 1 && replaced.json[0].name === '잡일',
  JSON.stringify(replaced.json?.map((l) => l.name)));

const foreignLabel = await api('PUT', `/spaces/${spaceId}/issues/${labeled.id}/labels`, {
  token: alice.token, body: { labelIds: [crypto.randomUUID()] },
});
check('없는 라벨 id 는 404 — 조용히 버리지 않는다', foreignLabel.status === 404,
  `status=${foreignLabel.status}`);

const labelDeleteByMember = await api('DELETE', `/spaces/${spaceId}/labels/${chore.id}`, {
  token: guest.token,
});
check('guest 라벨 삭제 거부', labelDeleteByMember.status === 403,
  `status=${labelDeleteByMember.status}`);

await api('DELETE', `/spaces/${spaceId}/labels/${chore.id}`, { token: alice.token });
check('라벨을 지우면 이슈에서도 떨어진다',
  (await api('GET', `/spaces/${spaceId}/issues/${labeled.id}`, { token: alice.token }))
    .json.labels.length === 0);

// ── 13. 대화 → 이슈 (9-2b) ───────────────────────────
const channels = await api('GET', `/spaces/${spaceId}/channels`, { token: alice.token });
const channel = channels.json[0];
const source = await api('POST', `/spaces/${spaceId}/channels/${channel.id}/messages`, {
  token: alice.token,
  body: { body: '이 논의로 이슈를 만든다' },
});

const fromMessage = await createIssue({
  title: '대화에서 만든 이슈',
  originMessageId: source.json.id,
});
check('대화 → 이슈 생성 201', fromMessage.status === 201, `status=${fromMessage.status}`);
check('원문 요약이 실린다',
  fromMessage.json?.originMessage?.body === '이 논의로 이슈를 만든다' &&
  fromMessage.json?.originMessage?.channelId === channel.id,
  JSON.stringify(fromMessage.json?.originMessage));

// 소프트 삭제된 원문은 링크만 남고 본문은 빠진다.
await api('DELETE', `/spaces/${spaceId}/messages/${source.json.id}`, { token: alice.token });
const afterDelete = await api('GET', `/spaces/${spaceId}/issues/${fromMessage.json.id}`, {
  token: alice.token,
});
check('원문이 지워져도 링크는 남는다', afterDelete.json?.originMessage?.id === source.json.id);
check('지워진 원문의 본문은 싣지 않는다',
  afterDelete.json?.originMessage?.body === null &&
  afterDelete.json?.originMessage?.deleted === true,
  JSON.stringify(afterDelete.json?.originMessage));

// 비공개 채널의 메시지는 걸 수 없다 — 못 보는 대화가 이슈로 샌다.
const priv = await api('POST', `/spaces/${spaceId}/channels`, {
  token: alice.token,
  body: { name: `secret${stamp}`, isPrivate: true },
});
const secret = await api('POST', `/spaces/${spaceId}/channels/${priv.json.id}/messages`, {
  token: alice.token, body: { body: '비공개 대화' },
});
const leak = await api('POST', `/spaces/${spaceId}/issues`, {
  token: guest.token,
  body: { title: '샐 뻔한 이슈', originMessageId: secret.json.id },
});
check('비공개 채널 메시지는 비참여자가 걸 수 없다', leak.status === 403 || leak.status === 404,
  `status=${leak.status}`);

const foreignOrigin = await createIssue({
  title: '남의 메시지', originMessageId: crypto.randomUUID(),
});
check('없는 메시지 id 는 404', foreignOrigin.status === 404, `status=${foreignOrigin.status}`);

// ── 14. 스프린트 (9-3) ───────────────────────────────
const sprintOne = await api('POST', `/spaces/${spaceId}/sprints`, {
  token: alice.token,
  body: { name: '1주차', goal: '보드를 쓸 만하게', startsAt: '2026-08-01T00:00:00.000Z', endsAt: '2026-08-04T00:00:00.000Z' },
});
check('스프린트 생성 201', sprintOne.status === 201, JSON.stringify(sprintOne.json));
check('만들면 planned 다', sprintOne.json?.state === 'planned', sprintOne.json?.state);

const guestSprint = await api('POST', `/spaces/${spaceId}/sprints`, {
  token: guest.token, body: { name: 'guest 스프린트' },
});
check('guest 스프린트 생성 거부', guestSprint.status === 403, `status=${guestSprint.status}`);

const started = await api('PATCH', `/spaces/${spaceId}/sprints/${sprintOne.json.id}`, {
  token: alice.token, body: { state: 'active' },
});
check('planned → active 는 된다', started.json?.state === 'active', JSON.stringify(started.json));

const sprintTwo = (await api('POST', `/spaces/${spaceId}/sprints`, {
  token: alice.token, body: { name: '2주차' },
})).json;
const secondActive = await api('PATCH', `/spaces/${spaceId}/sprints/${sprintTwo.id}`, {
  token: alice.token, body: { state: 'active' },
});
check('진행 중인 스프린트가 둘이 될 수 없다 — 409', secondActive.status === 409,
  `status=${secondActive.status}`);

// 목록 순서 — enum 선언 순서(planned · active · closed)를 그대로 쓰면
// 도는 스프린트가 계획 뒤로 밀린다. 지금 하는 일이 맨 위여야 한다.
const sprintList = await api('GET', `/spaces/${spaceId}/sprints`, { token: alice.token });
check('도는 스프린트가 목록 맨 위에 온다',
  sprintList.json[0]?.state === 'active',
  sprintList.json.map((s) => s.state).join(','));

const backToPlanned = await api('PATCH', `/spaces/${spaceId}/sprints/${sprintOne.json.id}`, {
  token: alice.token, body: { state: 'planned' },
});
check('active → planned 로 되돌릴 수 없다 — 400', backToPlanned.status === 400,
  `status=${backToPlanned.status}`);

// ── 15. 번다운 (9-3) ─────────────────────────────────
const noDates = await api('GET', `/spaces/${spaceId}/sprints/${sprintTwo.id}/burndown`, {
  token: alice.token,
});
check('기간이 없으면 번다운은 400', noDates.status === 400, `status=${noDates.status}`);

// 스프린트에 이슈 셋을 넣고 하나를 닫는다.
const s1 = (await createIssue({ title: '스프린트 이슈 1', storyPoints: 3 })).json;
const s2 = (await createIssue({ title: '스프린트 이슈 2', storyPoints: 5 })).json;
const s3 = (await createIssue({ title: '포인트 없는 이슈' })).json;
for (const issue of [s1, s2, s3]) {
  await api('PATCH', `/spaces/${spaceId}/issues/${issue.id}`, {
    token: alice.token, body: { sprintId: sprintOne.json.id },
  });
}

const burn = await api('GET', `/spaces/${spaceId}/sprints/${sprintOne.json.id}/burndown`, {
  token: alice.token,
});
check('번다운 200', burn.status === 200, `status=${burn.status}`);
check('총량은 포인트 8 · 개수 3',
  burn.json?.total?.points === 8 && burn.json?.total?.count === 3,
  JSON.stringify(burn.json?.total));
check('기간이 4일이면 4칸이다', burn.json?.days?.length === 4,
  `${burn.json?.days?.length}칸`);
check('아무것도 닫히지 않았으면 평평하다',
  burn.json.days.every((d) => d.points === 8 && d.count === 3),
  JSON.stringify(burn.json.days.map((d) => d.points)));

// 하나를 done 으로 옮기면 closedAt 이 찍히고 번다운이 줄어든다.
// 다만 closedAt 은 '지금'이라 스프린트 기간(2026-08-01~04) 밖이다 —
// 기간이 지난 스프린트라 끝까지 남아 있는 것이 맞다.
await api('PATCH', `/spaces/${spaceId}/issues/${s1.id}`, {
  token: alice.token, body: { status: 'done' },
});
const afterDone = await api('GET', `/spaces/${spaceId}/sprints/${sprintOne.json.id}/burndown`, {
  token: alice.token,
});
check('총량은 닫혀도 그대로다 — 분모는 변하지 않는다',
  afterDone.json.total.points === 8, JSON.stringify(afterDone.json.total));
check('기간 뒤에 닫힌 것은 그래프에서 끝까지 남는다',
  afterDone.json.days[afterDone.json.days.length - 1].points === 8,
  JSON.stringify(afterDone.json.days.map((d) => d.points)));

// ── 15-1. 번다운이 실제로 줄어든다 ───────────────────
// 위 케이스는 스프린트 기간이 과거라 '지금' 닫으면 그래프 밖이었다.
// **오늘을 품는 기간**이라야 하락을 볼 수 있다 — 이게 번다운의 본체다.
const today = new Date();
const from = new Date(today.getTime() - 2 * 86400000);
const to = new Date(today.getTime() + 2 * 86400000);

const live = (await api('POST', `/spaces/${spaceId}/sprints`, {
  token: alice.token,
  body: {
    name: '지금 도는 스프린트',
    startsAt: from.toISOString(),
    endsAt: to.toISOString(),
  },
})).json;

const liveIssues = [];
for (const points of [2, 3]) {
  const made = (await createIssue({ title: `번다운 ${points}점`, storyPoints: points })).json;
  await api('PATCH', `/spaces/${spaceId}/issues/${made.id}`, {
    token: alice.token, body: { sprintId: live.id },
  });
  liveIssues.push(made);
}

const before = await api('GET', `/spaces/${spaceId}/sprints/${live.id}/burndown`, {
  token: alice.token,
});
const todayIndex = before.json.days.findIndex(
  (d) => d.date.slice(0, 10) === today.toISOString().slice(0, 10),
);
check('오늘이 그래프 안에 있다', todayIndex >= 0, JSON.stringify(before.json.days.map((d) => d.date)));
check('닫기 전 오늘 남은 양은 5점', before.json.days[todayIndex].points === 5,
  JSON.stringify(before.json.days[todayIndex]));

await api('PATCH', `/spaces/${spaceId}/issues/${liveIssues[0].id}`, {
  token: alice.token, body: { status: 'done' },
});

const after = await api('GET', `/spaces/${spaceId}/sprints/${live.id}/burndown`, {
  token: alice.token,
});
check('★ 2점을 닫으면 오늘부터 3점으로 떨어진다',
  after.json.days[todayIndex].points === 3,
  JSON.stringify(after.json.days.map((d) => d.points)));
check('닫기 전날은 그대로 5점이다 — 과거를 바꾸지 않는다',
  todayIndex === 0 || after.json.days[todayIndex - 1].points === 5,
  JSON.stringify(after.json.days.map((d) => d.points)));
check('개수 계열도 함께 줄어든다', after.json.days[todayIndex].count === 1,
  JSON.stringify(after.json.days.map((d) => d.count)));

// 되돌리면 번다운도 되돌아온다 — closedAt 이 비워지기 때문이다.
await api('PATCH', `/spaces/${spaceId}/issues/${liveIssues[0].id}`, {
  token: alice.token, body: { status: 'doing' },
});
const reopened = await api('GET', `/spaces/${spaceId}/sprints/${live.id}/burndown`, {
  token: alice.token,
});
check('done 에서 빼면 번다운도 되돌아온다',
  reopened.json.days[todayIndex].points === 5,
  JSON.stringify(reopened.json.days.map((d) => d.points)));

// ── 16. 백로그 필터 (9-3) ────────────────────────────
const backlogOnly = await listIssues('?sprint=none&status=backlog');
check('sprint=none 은 스프린트에 없는 것만 준다',
  backlogOnly.json.issues.every((i) => i.sprintId === null),
  backlogOnly.json.issues.filter((i) => i.sprintId !== null).length + '건이 샜다');

const inSprint = await listIssues(`?sprintId=${sprintOne.json.id}`);
check('sprintId 로 그 스프린트의 것만 준다',
  inSprint.json.issues.length === 3 &&
  inSprint.json.issues.every((i) => i.sprintId === sprintOne.json.id),
  `${inSprint.json.issues.length}건`);

// 스프린트를 지우면 이슈는 백로그로 돌아간다 — 할 일이 사라지면 안 된다.
await api('DELETE', `/spaces/${spaceId}/sprints/${sprintTwo.id}`, { token: alice.token });
const guestDeleteSprint = await api('DELETE', `/spaces/${spaceId}/sprints/${sprintOne.json.id}`, {
  token: guest.token,
});
check('guest 스프린트 삭제 거부', guestDeleteSprint.status === 403,
  `status=${guestDeleteSprint.status}`);

await api('DELETE', `/spaces/${spaceId}/sprints/${sprintOne.json.id}`, { token: alice.token });
const orphaned = await api('GET', `/spaces/${spaceId}/issues/${s2.id}`, { token: alice.token });
check('스프린트를 지워도 이슈는 남는다', orphaned.status === 200, `status=${orphaned.status}`);
check('지운 스프린트의 이슈는 백로그로 돌아간다', orphaned.json?.sprintId === null,
  JSON.stringify(orphaned.json?.sprintId));

// ── 17. 컬럼 상한 ────────────────────────────────────
// 채번이 스페이스 행을 잠그므로 200건을 한꺼번에 던지면 잠금 대기로 느려진다.
// 20건씩 끊어 보낸다.
const already = (await listIssues('?status=backlog')).json.issues.length;
const need = 201 - already;
for (let i = 0; i < need; i += 20) {
  await Promise.all(
    Array.from({ length: Math.min(20, need - i) }, (_, j) =>
      createIssue({ title: `상한 ${i + j}` }),
    ),
  );
}
const big = await listIssues('?status=backlog');
check(
  '상한을 넘기면 truncated 에 담긴다',
  big.json.truncated.includes('backlog'),
  JSON.stringify(big.json.truncated),
);
check('상한만큼만 준다', big.json.issues.length === 200, `${big.json.issues.length}건`);

for (const s of [socket, outsiderSocket]) {
  if (s.close) s.close();
}

console.log(`\n통과 ${pass} · 실패 ${fail}\n`);
process.exit(fail === 0 ? 0 : 1);
