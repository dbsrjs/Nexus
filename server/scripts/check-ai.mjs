// AI(13-1 대화 요약) 검증. 실제 서버 · 실제 DB · 실제 소켓으로 확인한다.
//
// 사전 조건: npm run db:up && npm run server:dev
//            server/.env 에 LLM_PROVIDER=fake
// 사용: npm run check:ai
//
// 자체 계정 · 자체 스페이스를 만들어 쓴다.
import { requireServer } from './lib/preflight.mjs';
import { BASE, stamp, api, signup } from './lib/api.mjs';
import { check, summary } from './lib/checks.mjs';
import { connect, waitFor } from './lib/socket.mjs';
await requireServer(BASE);

console.log('\nAI 검증 — 실서버 · 실DB · 실소켓\n');

const alice = await signup('ai', 'a', 'AI검증a');
const bob = await signup('ai', 'b', 'AI검증b');
const outsider = await signup('ai', 'x', 'AI검증x');

const space = await api('POST', '/spaces', {
  token: alice.token,
  body: { name: `ai check ${stamp}` },
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

const m1 = await send(alice.token, { body: '배포를 금요일로 미룹시다' });
const m2 = await send(bob.token, { body: `<@${alice.userId}> 알겠습니다` });
check('요약할 메시지 준비', m1.status === 201 && m2.status === 201);

const ids = [m1.json.id, m2.json.id];
const summarize = (token, body) =>
  api('POST', `/spaces/${spaceId}/ai/summarize`, { token, body });

// ── 기본 흐름 ──────────────────────────────────
console.log('\n[요약 적재와 완료]');

const socket = await connect(alice.token);
check('소켓 연결', typeof socket?.on === 'function');

const started = await summarize(alice.token, {
  channelId: channel.id,
  messageIds: ids,
});
check('요약 적재', started.status === 201, `status=${started.status}`);
check(
  '★ runId 를 즉시 돌려준다 - 결과를 기다리지 않는다',
  typeof started.json?.runId === 'string' && started.json.runId.length > 0,
  JSON.stringify(started.json),
);
check('처음에는 queued 다', started.json?.state === 'queued');

const runId = started.json?.runId;
const done = await waitFor(socket, 'ai:run:done', 15000);
check('★ ai:run:done 이 요청자에게 도착한다', done !== null, 'timeout');
check(
  '이벤트에 runId · kind · state 가 실린다',
  done?.runId === runId && done?.kind === 'summarize' && done?.state === 'done',
  JSON.stringify(done),
);
check(
  '★ 결과 본문을 소켓에 싣지 않는다 - 앱이 GET 으로 가져온다',
  done !== null && done.result === undefined,
  JSON.stringify(done),
);

const fetched = await api('GET', `/spaces/${spaceId}/ai/runs/${runId}`, {
  token: alice.token,
});
check('결과 조회', fetched.status === 200, `status=${fetched.status}`);
check('state 가 done 이다', fetched.json?.state === 'done');
check(
  '★ result.markdown 에 본문이 있다',
  typeof fetched.json?.result?.markdown === 'string' &&
    fetched.json.result.markdown.length > 0,
  JSON.stringify(fetched.json?.result),
);
check(
  '실제로 응답한 모델이 기록된다',
  typeof fetched.json?.model === 'string' && fetched.json.model.length > 0,
  `model=${fetched.json?.model}`,
);

// ── 캐시 ───────────────────────────────────────
console.log('\n[promptHash 캐시]');

const again = await summarize(alice.token, {
  channelId: channel.id,
  messageIds: ids,
});
check(
  '★ 같은 입력은 곧바로 done 이다 - 두 번 돈을 쓰지 않는다',
  again.json?.state === 'done',
  JSON.stringify(again.json),
);
check(
  '★ 같은 runId 를 돌려준다 - 새 행을 만들지 않는다',
  typeof again.json?.runId === 'string' &&
    again.json.runId.length > 0 &&
    again.json.runId === runId,
  `${again.json?.runId} vs ${runId}`,
);

const narrower = await summarize(alice.token, {
  channelId: channel.id,
  messageIds: [m1.json.id],
});
check(
  '★ 입력이 다르면 캐시가 맞지 않는다',
  typeof narrower.json?.runId === 'string' &&
    narrower.json.runId.length > 0 &&
    narrower.json.runId !== runId,
  JSON.stringify(narrower.json),
);

// ── 권한 ───────────────────────────────────────
console.log('\n[권한]');

const byOutsider = await summarize(outsider.token, {
  channelId: channel.id,
  messageIds: ids,
});
check(
  '★ 비멤버는 404 다 - 403 은 그 스페이스가 있다는 것을 알려 준다',
  byOutsider.status === 404,
  `status=${byOutsider.status}`,
);

const othersRun = await api('GET', `/spaces/${spaceId}/ai/runs/${runId}`, {
  token: bob.token,
});
check(
  '★ 같은 스페이스라도 남의 실행은 404 다',
  othersRun.status === 404,
  `status=${othersRun.status}`,
);

const priv = await api('POST', `/spaces/${spaceId}/channels`, {
  token: alice.token,
  body: { name: `private-${stamp}`, isPrivate: true },
});
check('비공개 채널 준비', priv.status === 201, `status=${priv.status}`);

const privMsg = await api(
  'POST',
  `/spaces/${spaceId}/channels/${priv.json.id}/messages`,
  { token: alice.token, body: { body: '비밀 이야기' } },
);
check('비공개 채널 메시지 준비', privMsg.status === 201);

const byBob = await summarize(bob.token, {
  channelId: priv.json.id,
  messageIds: [privMsg.json.id],
});
check(
  '★ 비공개 채널은 멤버가 아니면 404 다',
  byBob.status === 404,
  `status=${byBob.status}`,
);

// ── 입력 검증 ──────────────────────────────────
console.log('\n[입력 검증]');

const empty = await summarize(alice.token, {
  channelId: channel.id,
  messageIds: [],
});
check('빈 선택은 400 이다', empty.status === 400, `status=${empty.status}`);

const tooMany = await summarize(alice.token, {
  channelId: channel.id,
  messageIds: Array.from({ length: 201 }, () => m1.json.id),
});
check(
  '★ 201개는 400 이다 - 조용히 자르지 않는다',
  tooMany.status === 400,
  `status=${tooMany.status}`,
);

const unknown = await summarize(alice.token, {
  channelId: channel.id,
  messageIds: [m1.json.id, '00000000-0000-4000-8000-000000000000'],
});
check(
  '★ 고른 것 중 하나라도 없으면 404 다 - 일부만 요약하지 않는다',
  unknown.status === 404,
  `status=${unknown.status}`,
);

const extraField = await summarize(alice.token, {
  channelId: channel.id,
  messageIds: ids,
  nope: 1,
});
check(
  'DTO 밖 필드는 400 이다',
  extraField.status === 400,
  `status=${extraField.status}`,
);

// ── 전처리 ─────────────────────────────────────
console.log('\n[프롬프트 전처리]');

// fake 어댑터가 입력을 결과에 되비추므로 전처리 결과를 여기서 볼 수 있다.
const withMention = await api(
  'GET',
  `/spaces/${spaceId}/ai/runs/${narrower.json.runId}`,
  { token: alice.token },
);
check('좁힌 요약도 완료된다', withMention.status === 200);

// 메시지 삭제는 채널이 아니라 스페이스 하위 라우트다
// (server/src/messages/messages.controller.ts — `/spaces/:spaceId/messages/:messageId`).
const deleted = await api(
  'DELETE',
  `/spaces/${spaceId}/messages/${m1.json.id}`,
  { token: alice.token },
);
check('소프트 삭제 준비', deleted.status === 200 || deleted.status === 204);

const afterDelete = await summarize(alice.token, {
  channelId: channel.id,
  messageIds: ids,
});
check(
  '★ 삭제된 메시지가 섞여도 요약이 적재된다 - 본문 대신 자리만 둔다',
  afterDelete.status === 201,
  `status=${afterDelete.status}`,
);

socket.close();
process.exit(summary() === 0 ? 0 : 1);
