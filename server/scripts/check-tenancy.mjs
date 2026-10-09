// 테넌트 격리 통합 검증(«마지막»). 실제 서버 · 실제 DB 로, **스페이스에 걸린 모든 경로**를
// 남의 손으로 두드려 본다.
//
// 다른 check:* 는 기능마다 「비멤버는 404」를 몇 줄씩 단언한다. 그 방식은 새 경로가 생길 때
// 누군가 단언을 더해야만 덮인다. 여기서는 **컨트롤러 소스를 읽어 경로 목록을 만들고**,
// 목록에 있는 모든 경로를 두 가지로 친다:
//
//   1. 바깥사람 — 스페이스 A 의 경로를 A 의 실제 id 로, A 의 멤버가 아닌 B 가 부른다.
//   2. 끼워 넣기 — B 가 **자기 스페이스(SB)** 경로에 A 의 id 를 끼운다. SpaceGuard 는
//      통과하므로(B 는 SB 의 주인이다) 서비스가 `spaceId` 로 거르지 않으면 여기서 샌다.
//      CLAUDE.md §3 의 「모든 쿼리 WHERE 에 spaceId」가 실제로 지켜지는지 보는 자리다.
//
// 기대는 둘 다 **404** 다(볼 수 없으면 403 이 아니라 404 — CLAUDE.md §3). 400 도 실패로
// 친다 — 검증 파이프에서 막히면 서비스까지 가지 않아 아무것도 증명하지 않는다. 그래서
// 쓰기 경로에는 통과할 본문을 준다(BODIES).
//
// **경로 매개변수를 모르면 실패한다.** 새 경로가 `:somethingId` 를 들고 오면 아래 ids 에
// A 의 실제 값을 준비하라는 실패가 난다 — 조용히 건너뛰면 이 스크립트의 의미가 사라진다.
//
// 사전 조건: npm run db:up && npm run server:dev (LLM_PROVIDER=fake)
// 사용: npm run check:tenancy

import { randomUUID } from 'node:crypto';
import { readdirSync, readFileSync, statSync } from 'node:fs';
import { dirname, join, relative } from 'node:path';
import { fileURLToPath } from 'node:url';

import { requireServer, abortUnless } from './lib/preflight.mjs';
import { BASE, stamp, api, signup } from './lib/api.mjs';
import { check, summary } from './lib/checks.mjs';
await requireServer(BASE);

const srcDir = join(dirname(fileURLToPath(import.meta.url)), '..', 'src');

// ── 경로 목록 ───────────────────────────────────

/** src 아래 컨트롤러에서 (메서드, 경로)를 뽑는다. 한 파일에 컨트롤러가 둘일 수 있다. */
function collectRoutes() {
  const files = [];
  const walk = (dir) => {
    for (const name of readdirSync(dir)) {
      const path = join(dir, name);
      if (statSync(path).isDirectory()) walk(path);
      else if (name.endsWith('.controller.ts')) files.push(path);
    }
  };
  walk(srcDir);

  const routes = [];
  for (const file of files) {
    const text = readFileSync(file, 'utf8');
    // 주석 안의 `@Controller()` 를 읽지 않게 줄 주석 · 블록 주석을 먼저 지운다.
    const code = text.replace(/\/\*[\s\S]*?\*\//g, '').replace(/^\s*\/\/.*$/gm, '');
    const decorator = /@(Controller|Get|Post|Patch|Put|Delete)\(\s*(?:'([^']*)')?[^)]*\)/g;
    let base = null;
    for (const m of code.matchAll(decorator)) {
      const [, kind, arg = ''] = m;
      if (kind === 'Controller') {
        base = arg;
        continue;
      }
      const path = '/' + [base, arg].filter(Boolean).join('/');
      routes.push({ method: kind.toUpperCase(), path, file: relative(srcDir, file) });
    }
  }
  return routes;
}

const all = collectRoutes();
const spaced = all.filter((r) => r.path.includes(':spaceId'));
// 목록이 비면 파서가 깨진 것이다 — 「0개 통과」로 초록이 되면 안 된다.
abortUnless(spaced.length >= 80, `스페이스 경로가 ${spaced.length}개뿐 — 컨트롤러 파서를 확인하십시오`);
console.log(`스페이스 경로 ${spaced.length}개 (전체 ${all.length}개)`);

// ── 준비: A 의 스페이스를 채운다 ─────────────────

const a = await signup('tenancy', 'a', 'TenancyA');
const b = await signup('tenancy', 'b', 'TenancyB');
const c = await signup('tenancy', 'c', 'TenancyC');

async function must(label, res, ok = [200, 201]) {
  abortUnless(ok.includes(res.status), `${label} 실패 (${res.status})`, res.json);
  return res.json;
}

const sa = await must('A 스페이스', await api('POST', '/spaces', { token: a.token, body: { name: `Tenancy A ${stamp}` } }));
const sb = await must('B 스페이스', await api('POST', '/spaces', { token: b.token, body: { name: `Tenancy B ${stamp}` } }));
const SA = sa.id;
const SB = sb.id;

// 스프린트는 스위치가 켜져야 만들어진다(16-1).
await must('A 스프린트 켜기', await api('PATCH', `/spaces/${SA}`, { token: a.token, body: { sprintsEnabled: true } }));
await must('B 스프린트 켜기', await api('PATCH', `/spaces/${SB}`, { token: b.token, body: { sprintsEnabled: true } }));

const channels = await must('A 채널 목록', await api('GET', `/spaces/${SA}/channels`, { token: a.token }));
const channelId = channels[0].id;
const bChannels = await must('B 채널 목록', await api('GET', `/spaces/${SB}/channels`, { token: b.token }));
const bChannelId = bChannels[0].id;

const category = await must('A 카테고리', await api('POST', `/spaces/${SA}/categories`, { token: a.token, body: { name: 'tenancy' } }));
const message = await must('A 메시지', await api('POST', `/spaces/${SA}/channels/${channelId}/messages`, { token: a.token, body: { body: 'secret of A' } }));
const issue = await must('A 이슈', await api('POST', `/spaces/${SA}/issues`, { token: a.token, body: { title: 'A 의 이슈' } }));
const label = await must('A 라벨', await api('POST', `/spaces/${SA}/labels`, { token: a.token, body: { name: 'a-label', color: '#aa3355' } }));
const sprint = await must('A 스프린트', await api('POST', `/spaces/${SA}/sprints`, { token: a.token, body: { name: 'A 스프린트' } }));
const invite = await must('A 초대', await api('POST', `/spaces/${SA}/invites`, { token: a.token, body: { role: 'member' } }));
const repo = await must(
  'A 저장소',
  await api('POST', `/spaces/${SA}/repos`, {
    token: a.token,
    body: { provider: 'github', fullPath: `tenancy/a-${stamp}`, linkedChannelId: channelId },
  }),
);

// 첨부 하나.
const form = new FormData();
form.append('file', new Blob([Buffer.from('A 만 보는 파일')], { type: 'text/plain' }), 'a.txt');
const up = await fetch(`${BASE}/spaces/${SA}/channels/${channelId}/attachments`, {
  method: 'POST',
  headers: { authorization: `Bearer ${a.token}` },
  body: form,
});
abortUnless(up.status === 201, `A 첨부 실패 (${up.status})`);
const attachment = await up.json();

// 알림 하나 — C 가 A 의 스페이스에 들어와 A 를 멘션한다.
await must('C 참여', await api('POST', `/invites/${invite.code}/accept`, { token: c.token }));
await must(
  'C 의 멘션',
  await api('POST', `/spaces/${SA}/channels/${channelId}/messages`, { token: c.token, body: { body: `<@${a.userId}> 봐 주세요` } }),
);
const notes = await must('A 알림', await api('GET', `/spaces/${SA}/notifications`, { token: a.token }));
const noteList = Array.isArray(notes) ? notes : (notes.items ?? []);
abortUnless(noteList.length > 0, 'A 에게 알림이 생기지 않았습니다', notes);

// AI 실행 하나 — fake provider 라 결정적이다. 실행 행만 있으면 되므로 끝날 때까지 기다리지 않는다.
const ask = await must(
  'A 의 AI 묻기',
  await api('POST', `/spaces/${SA}/ai/ask`, { token: a.token, body: { preset: 'summary', context: { channelId } } }),
  [200, 201, 202],
);
const runId = ask.runId ?? ask.id;
abortUnless(typeof runId === 'string', 'AI 실행 id 를 못 찾았습니다', ask);

/** 경로 매개변수 → A 의 실제 값. 끼워 넣기에서 의미가 있는 것은 `real: true` 인 것뿐이다. */
const ids = {
  channelId: { value: channelId, real: true },
  messageId: { value: message.id, real: true },
  categoryId: { value: category.id, real: true },
  issueId: { value: issue.id, real: true },
  labelId: { value: label.id, real: true },
  sprintId: { value: sprint.id, real: true },
  inviteId: { value: invite.id, real: true },
  repoId: { value: repo.id, real: true },
  attachmentId: { value: attachment.id, real: true },
  notificationId: { value: noteList[0].id, real: true },
  runId: { value: runId, real: true },
  rootRunId: { value: runId, real: true },
  // A 는 SB 의 멤버가 아니다 — SB 의 멤버 경로에 A 를 넣으면 「없는 멤버」여야 한다.
  userId: { value: a.userId, real: true },
  // 웹훅 이벤트는 가짜 GitHub 없이 만들 수 없다. 바깥사람 검사만 의미가 있다.
  eventId: { value: randomUUID(), real: false },
  // id 가 아닌 값들 — 이것만으로는 다른 스페이스의 무엇도 가리키지 않는다.
  role: { value: 'member', real: false },
  emoji: { value: encodeURIComponent('👍'), real: false },
  sha: { value: 'a'.repeat(40), real: false },
  number: { value: '1', real: false },
};

/** 쓰기 경로의 본문. 검증 파이프(400)에서 멈추지 않고 서비스까지 닿게 한다. */
const BODIES = {
  'PATCH /spaces/:spaceId': { name: 'renamed' },
  'POST /spaces/:spaceId/ai/ask': { preset: 'summary', context: { channelId: bChannelId } },
  'POST /spaces/:spaceId/categories': { name: 'x' },
  'PATCH /spaces/:spaceId/categories/:categoryId': { name: 'x' },
  'POST /spaces/:spaceId/channels': { name: `x-${stamp}` },
  'PATCH /spaces/:spaceId/channels/:channelId': { name: 'x' },
  'POST /spaces/:spaceId/channels/:channelId/members': { userIds: [b.userId] },
  'POST /spaces/:spaceId/channels/:channelId/messages': { body: 'x' },
  'PUT /spaces/:spaceId/channels/:channelId/mute': { muted: true },
  'PUT /spaces/:spaceId/channels/:channelId/permissions/:role': { canView: true, canSend: true },
  'POST /spaces/:spaceId/channels/:channelId/read': { lastReadMessageId: message.id },
  'POST /spaces/:spaceId/dms': { userId: b.userId },
  'POST /spaces/:spaceId/invites': { role: 'member' },
  'POST /spaces/:spaceId/issues': { title: 'x' },
  'PATCH /spaces/:spaceId/issues/:issueId': { title: 'x' },
  'POST /spaces/:spaceId/issues/:issueId/comments': { body: 'x' },
  'PUT /spaces/:spaceId/issues/:issueId/labels': { labelIds: [] },
  'PUT /spaces/:spaceId/issues/:issueId/position': { status: 'backlog' },
  'POST /spaces/:spaceId/labels': { name: `x-${stamp}`, color: '#123456' },
  'PATCH /spaces/:spaceId/members/:userId': { role: 'member' },
  'PATCH /spaces/:spaceId/messages/:messageId': { body: 'x' },
  'POST /spaces/:spaceId/messages/:messageId/reactions': { emoji: '👍' },
  'POST /spaces/:spaceId/repos': { provider: 'github', fullPath: `tenancy/x-${stamp}` },
  'POST /spaces/:spaceId/repos/connect': { githubRepoId: 1 },
  'POST /spaces/:spaceId/repos/:repoId/index/search': { query: 'x' },
  'POST /spaces/:spaceId/sprints': { name: 'x' },
  'PATCH /spaces/:spaceId/sprints/:sprintId': { name: 'x' },
};

/**
 * 404 대신 400 을 받아들이는 경로. **부르는 사람에 대한 전제**가 리소스를 찾기 전에 걸리는
 * 경우만 둔다 — 그 400 은 A 의 리소스가 있든 없든 같으므로 아무것도 새지 않는다.
 */
const CALLER_PRECONDITION = {
  // B 는 GitHub 을 연결하지 않았다(requireReady 가 저장소 조회보다 먼저다).
  'POST /spaces/:spaceId/repos/:repoId/webhook': 400,
};

/** 읽기 경로에 꼭 필요한 쿼리. */
const QUERIES = {
  'GET /spaces/:spaceId/repos/:repoId/blob': '?path=README.md',
};

function fill(path, spaceId) {
  const missing = [];
  const out = path.replace(/:(\w+)/g, (_, name) => {
    if (name === 'spaceId') return spaceId;
    if (!ids[name]) {
      missing.push(name);
      return 'x';
    }
    return ids[name].value;
  });
  return { url: out, missing };
}

const hasRealForeignId = (path) =>
  [...path.matchAll(/:(\w+)/g)].some(([, name]) => name !== 'spaceId' && ids[name]?.real);

// ── 1. 바깥사람 ─────────────────────────────────
console.log('\n[바깥사람 — A 의 스페이스를 B 가 부른다]');

for (const r of spaced) {
  const key = `${r.method} ${r.path}`;
  const { url, missing } = fill(r.path, SA);
  if (missing.length) {
    check(`${key} — 매개변수 ${missing.join(', ')} 의 값을 준비하지 않았다(ids 에 더할 것)`, false, r.file);
    continue;
  }
  const res = await api(r.method, url + (QUERIES[key] ?? ''), { token: b.token, body: BODIES[key] });
  check(`${key} → 404`, res.status === 404, `status=${res.status} (${r.file})`);
}

// ── 2. 끼워 넣기 ────────────────────────────────
console.log('\n[끼워 넣기 — B 가 자기 스페이스 경로에 A 의 id 를 넣는다]');

const smuggle = spaced.filter((r) => hasRealForeignId(r.path));
for (const r of smuggle) {
  const key = `${r.method} ${r.path}`;
  const { url, missing } = fill(r.path, SB);
  if (missing.length) continue; // 위에서 이미 실패로 알렸다
  const res = await api(r.method, url + (QUERIES[key] ?? ''), { token: b.token, body: BODIES[key] });
  const allowed = [404, CALLER_PRECONDITION[key]].filter(Boolean);
  check(`SB 의 ${key} 에 A 의 id → ${allowed.join('/')}`, allowed.includes(res.status), `status=${res.status} (${r.file})`);
}

// 경로가 아니라 **본문**으로 남의 id 를 넣는 쓰기. 경로 목록으로는 드러나지 않아 손으로 적는다.
console.log('\n[본문으로 끼워 넣기]');
const bodySmuggle = [
  ['DM 상대가 A(SB 멤버 아님)', 'POST', `/spaces/${SB}/dms`, { userId: a.userId }],
  ['저장소를 A 의 채널에 잇기', 'POST', `/spaces/${SB}/repos`, { provider: 'github', fullPath: `tenancy/y-${stamp}`, linkedChannelId: channelId }],
  ['AI 문맥에 A 의 채널', 'POST', `/spaces/${SB}/ai/ask`, { preset: 'summary', context: { channelId } }],
  ['AI 문맥에 A 의 메시지', 'POST', `/spaces/${SB}/ai/ask`, { preset: 'summary', context: { messageIds: [message.id] } }],
  ['AI 문맥에 A 의 저장소', 'POST', `/spaces/${SB}/ai/ask`, { instruction: 'x', context: { repoId: repo.id } }],
  ['AI 이어 묻기의 부모가 A 의 실행', 'POST', `/spaces/${SB}/ai/ask`, { instruction: 'x', parentRunId: runId }],
  ['비공개 채널 명단에 A', 'POST', `/spaces/${SB}/channels/${bChannelId}/members`, { userIds: [a.userId] }],
  ['읽음 마커를 A 의 메시지로', 'POST', `/spaces/${SB}/channels/${bChannelId}/read`, { messageId: message.id }],
  ['저장소 자동 등록을 A 의 채널에', 'POST', `/spaces/${SB}/repos/connect`, { githubRepoId: 1, linkedChannelId: channelId }],
  ['채널을 A 의 카테고리에 만들기', 'POST', `/spaces/${SB}/channels`, { name: `y-${stamp}`, categoryId: category.id }],
  ['채널을 A 의 카테고리로 옮기기', 'PATCH', `/spaces/${SB}/channels/${bChannelId}`, { categoryId: category.id }],
  ['메시지에 A 의 첨부', 'POST', `/spaces/${SB}/channels/${bChannelId}/messages`, { body: 'x', attachmentIds: [attachment.id] }],
  ['A 의 메시지에 답글', 'POST', `/spaces/${SB}/channels/${bChannelId}/messages`, { body: 'x', parentId: message.id }],
  ['A 의 메시지를 인용', 'POST', `/spaces/${SB}/channels/${bChannelId}/messages`, { body: 'x', quotedMessageId: message.id }],
  ['이슈를 A 의 스프린트에', 'POST', `/spaces/${SB}/issues`, { title: 'x', sprintId: sprint.id }],
  ['이슈 담당자가 A(SB 멤버 아님)', 'POST', `/spaces/${SB}/issues`, { title: 'x', assigneeId: a.userId }],
  ['A 의 이슈를 상위로', 'POST', `/spaces/${SB}/issues`, { title: 'x', parentId: issue.id }],
  ['A 의 메시지에서 이슈 만들기', 'POST', `/spaces/${SB}/issues`, { title: 'x', originMessageId: message.id }],
];
for (const [label, method, path, body] of bodySmuggle) {
  const res = await api(method, path, { token: b.token, body });
  // 본문 쪽은 「없는 것을 가리켰다」가 404 일 수도 400 일 수도 있다(필드마다 다르다).
  // 샌 것은 2xx 다 — 그것만 막는다. 500 은 판정이 서비스에서 터진 것이라 함께 실패로 친다.
  check(`${label} → 거부(4xx, 403 아님)`, res.status >= 400 && res.status < 500 && res.status !== 403, `status=${res.status}`);
}

// 경로의 이슈는 B 것, 본문의 참조가 A 것인 수정들.
const bIssue = await must('B 이슈', await api('POST', `/spaces/${SB}/issues`, { token: b.token, body: { title: 'B 의 이슈' } }));
for (const [label, body] of [
  ['스프린트를 A 의 것으로', { sprintId: sprint.id }],
  ['담당자를 A 로', { assigneeId: a.userId }],
]) {
  const res = await api('PATCH', `/spaces/${SB}/issues/${bIssue.id}`, { token: b.token, body });
  check(`B 의 이슈 ${label} → 404`, res.status === 404, `status=${res.status}`);
}
const move = await api('PUT', `/spaces/${SB}/issues/${bIssue.id}/position`, {
  token: b.token,
  body: { status: 'backlog', afterId: issue.id },
});
check('B 의 이슈를 A 의 이슈 옆으로 → 404', move.status === 404, `status=${move.status}`);
const bIssueAfter = await api('GET', `/spaces/${SB}/issues/${bIssue.id}`, { token: b.token });
check(
  'B 의 이슈에 A 의 스프린트 · 담당자가 붙지 않았다',
  bIssueAfter.status === 200 && bIssueAfter.json.sprintId == null && bIssueAfter.json.assignee == null,
  JSON.stringify({ sprintId: bIssueAfter.json?.sprintId, assignee: bIssueAfter.json?.assignee }),
);

const lab = await api('PUT', `/spaces/${SB}/issues/${bIssue.id}/labels`, { token: b.token, body: { labelIds: [label.id] } });
check('B 의 이슈에 A 의 라벨 → 404', lab.status === 404, `status=${lab.status}`);

// ── 3. 스페이스 밖 경로 ─────────────────────────
console.log('\n[스페이스 밖]');
const avatar = await api('GET', `/users/${a.userId}/avatar`, { token: b.token });
check('함께 쓰는 스페이스가 없는 사람의 아바타 → 404', avatar.status === 404, `status=${avatar.status}`);
const spacesOfB = await must('B 의 스페이스 목록', await api('GET', '/spaces', { token: b.token }));
check('B 의 스페이스 목록에 A 의 스페이스가 없다', Array.isArray(spacesOfB) && !spacesOfB.some((s) => s.id === SA));

// ── 대조군 ─────────────────────────────────────
// 위가 전부 404 인 이유가 「경로가 틀려서」가 아님을 보인다 — 같은 주소를 A 가 부르면 열린다.
console.log('\n[대조군 — 같은 주소를 주인이 부른다]');
const own = [
  ['GET', `/spaces/${SA}/messages/${message.id}/replies`],
  ['GET', `/spaces/${SA}/issues/${issue.id}`],
  ['GET', `/spaces/${SA}/attachments/${attachment.id}`],
  ['GET', `/spaces/${SA}/sprints`],
  ['GET', `/spaces/${SA}/ai/runs/${runId}`],
];
for (const [method, path] of own) {
  const res = await api(method, path, { token: a.token });
  check(`${method} ${path.replace(SA, ':SA')} → 200`, res.status === 200, `status=${res.status}`);
}

// A 의 데이터가 그대로인지 — 위의 쓰기 중 하나라도 새어 들어갔다면 여기서 드러난다.
const after = await api('GET', `/spaces/${SA}/issues/${issue.id}`, { token: a.token });
check('A 의 이슈 제목이 그대로다', after.json?.title === 'A 의 이슈', `title=${after.json?.title}`);
const aSpace = await api('GET', `/spaces/${SA}`, { token: a.token });
check('A 의 스페이스 이름이 그대로다', aSpace.json?.name === `Tenancy A ${stamp}`, `name=${aSpace.json?.name}`);

process.exit(summary() === 0 ? 0 : 1);
