// AI(13-1 대화 요약) 검증. 실제 서버 · 실제 DB · 실제 소켓으로 확인한다.
//
// 사전 조건: npm run db:up && npm run server:dev
//            server/.env 에 LLM_PROVIDER=fake
// 사용: npm run check:ai
//
// **미설정 503 은 서버가 지금 미설정 상태여야만 태울 수 있다.** check:oauth
// 와 같은 패턴이다 — 이 스크립트가 서버를 대신 죽였다 켜지는 않는다. 대신
// 시작할 때 현재 상태를 스스로 감지해 두 갈래로 나뉜다.
//   · 미설정이면 503 분기만 확인하고 안내를 찍은 뒤 끝난다.
//   · 설정돼 있으면 나머지 전부를 확인하고, 503 은 이 실행에서 태울 수
//     없다는 것을 화면에 명확히 알린다(조용히 건너뛰지 않는다).
// 둘 다 보려면 이 스크립트를 두 번 돌려야 한다 — 한 번은 LLM_PROVIDER 를
// 비운 채, 한 번은 채운 채로.
//
// 자체 계정 · 자체 스페이스를 만들어 쓴다.
import { requireServer } from './lib/preflight.mjs';
import { BASE, stamp, api, signup } from './lib/api.mjs';
import { check, summary } from './lib/checks.mjs';
import { connect, waitFor } from './lib/socket.mjs';
await requireServer(BASE);

function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

/**
 * 요약이 끝날 때까지 짧게 폴링한다. 소켓 이벤트를 다시 쓰지 않는 이유는
 * 이미 기본 흐름에서 소비한 `ai:run:done` 과 뒤섞이지 않게 하기 위함이다 —
 * 같은 소켓에 여러 실행의 이벤트가 순서 없이 쌓일 수 있다.
 */
async function waitForRunDone(token, spaceId, runId, ms = 15000) {
  const start = Date.now();
  while (Date.now() - start < ms) {
    const r = await api('GET', `/spaces/${spaceId}/ai/runs/${runId}`, { token });
    if (r.json?.state === 'done' || r.json?.state === 'failed') return r;
    await sleep(200);
  }
  return null;
}

/**
 * 분 경계를 넘어가면 프롬프트 한 줄의 `[HH:mm]` 표기(transcript.ts)가
 * 달라져 멘션 치환 검증(아래 [멘션이 실제로 치환되는지])이 우연히 실패할
 * 수 있다. 남은 시간이 3초 이하면 다음 분이 열릴 때까지 기다려 56초 이상의
 * 여유를 확보한다 — 그 뒤로 보내는 요청 두 개가 그 여유를 넘길 일은
 * 실질적으로 없다.
 */
async function avoidMinuteBoundary() {
  const secondsLeft = 60 - new Date().getUTCSeconds();
  if (secondsLeft <= 3) await sleep((secondsLeft + 1) * 1000);
}

const BOB_NAME = 'AI검증b';
/** 형식만 맞으면 되는 자리 채우기 id — 존재할 필요가 없다. */
const UNKNOWN_UUID = '00000000-0000-4000-8000-000000000000';

console.log('\nAI 검증 — 실서버 · 실DB · 실소켓\n');

const alice = await signup('ai', 'a', 'AI검증a');
const bob = await signup('ai', 'b', BOB_NAME);
const outsider = await signup('ai', 'x', 'AI검증x');

const space = await api('POST', '/spaces', {
  token: alice.token,
  body: { name: `ai check ${stamp}` },
});
const spaceId = space.json.id;

// ── 0. 지금 서버가 LLM 으로 설정돼 있는지 스스로 감지한다 ─────
// `AiService.summarize()` 는 `requireLlm()` 을 채널·메시지 조회보다 먼저
// 부르므로(ai.service.ts), 채널·메시지가 실존하지 않아도 미설정이면 503 이
// 온다 — 자리 채우기 id 로 충분하다.
const probe = await api('POST', `/spaces/${spaceId}/ai/summarize`, {
  token: alice.token,
  body: { channelId: UNKNOWN_UUID, messageIds: [UNKNOWN_UUID] },
});

if (probe.status === 503) {
  console.log('서버가 LLM 미설정 상태다 (LLM_PROVIDER 가 비어 있음).\n');
  check('설정이 없으면 summarize 는 503', probe.status === 503, String(probe.status));

  console.log('\n이 상태에서는 503 분기만 확인할 수 있다. 나머지 케이스를 보려면:');
  console.log('  1) server/.env 에 LLM_PROVIDER=fake 를 채운다');
  console.log('  2) npm run server:dev 를 재시작한다');
  console.log('  3) npm run check:ai 를 다시 돌린다\n');
  process.exit(summary() === 0 ? 0 : 1);
}

console.log('서버가 LLM_PROVIDER 로 설정돼 있다 — 이 실행에서는 503(미설정) 분기를');
console.log('태우지 않는다. 그 분기를 보려면 LLM_PROVIDER 를 비우고 서버를 재시작한 뒤');
console.log('이 스크립트를 다시 돌려라.\n');

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
  messageIds: [m1.json.id, UNKNOWN_UUID],
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

// 아래 두 케이스가 증명하는 것은 "전처리가 든 입력으로도 파이프라인이
// 끝까지 돈다"이다 — **fake 어댑터는 입력을 결과에 되비추지 않는다.**
// `FakeLlmProvider.complete()` 는 sha256 다이제스트와 메시지 개수만 돌려
// 준다(fake-llm.provider.ts). 전처리(멘션 치환 · 삭제 표시) 내용 자체가
// 맞는지는 이 계약 검증이 아니라 transcript.spec.ts 의 단위 테스트가 본다.
// 멘션 치환이 실제로 일어나는지는 뒤 [멘션이 실제로 치환되는지] 에서
// promptHash 캐시를 지렛대로 따로 확인한다.
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

// ── 멘션이 실제로 치환되는지 ────────────────────
console.log('\n[멘션이 실제로 치환되는지]');

// fake 어댑터는 내용을 반사하지 않으므로 결과 문자열로는 치환 여부를 알 수
// 없다. 대신 promptHash 캐시를 지렛대로 쓴다 — 해시는 조립된 프롬프트
// 전문에서 나오므로(prompt-hash.ts), 두 입력이 치환 후 같은 문자열이 되면
// 같은 runId 가 나오고 그렇지 않으면 다른 runId 가 나온다. 각 입력을 한
// 메시지짜리 요약으로 따로 돌려 다른 메시지가 문자열에 섞이지 않게 한다.
//
// 분 경계 위험은 avoidMinuteBoundary() 가 파일 위쪽에서 설명한 대로 미리
// 없앤다. 두 번째 호출 전에는 첫 번째가 끝날 때까지 기다린다 — 첫 실행이
// 아직 queued 인 동안 두 번째를 보내면 캐시가 아직 없어(`state: done` 인
// 행이 없다) 새 행이 하나 더 생기고, 그러면 "치환이 안 됐다"가 아니라
// "타이밍이 안 맞았다"로 오판한다.
await avoidMinuteBoundary();

const mentionMsg = await send(alice.token, {
  body: `<@${bob.userId}> 확인 부탁해요`,
});
const literalMsg = await send(alice.token, {
  body: `@${BOB_NAME} 확인 부탁해요`,
});
check(
  '멘션 치환 확인용 메시지 준비',
  mentionMsg.status === 201 && literalMsg.status === 201,
);

const mentionRun = await summarize(alice.token, {
  channelId: channel.id,
  messageIds: [mentionMsg.json.id],
});
check(
  '치환 확인용 첫 요약 적재',
  mentionRun.status === 201 &&
    typeof mentionRun.json?.runId === 'string' &&
    mentionRun.json.runId.length > 0,
  JSON.stringify(mentionRun.json),
);

if (mentionRun.json?.state === 'queued') {
  const finished = await waitForRunDone(
    alice.token,
    spaceId,
    mentionRun.json.runId,
  );
  check(
    '치환 확인용 첫 요약이 끝난다',
    finished?.json?.state === 'done',
    JSON.stringify(finished?.json),
  );
}

const literalRun = await summarize(alice.token, {
  channelId: channel.id,
  messageIds: [literalMsg.json.id],
});
check(
  '★ <@id> 가 표시 이름으로 치환된다 - 치환 후 같은 문장이라 캐시가 맞는다',
  typeof mentionRun.json?.runId === 'string' &&
    mentionRun.json.runId.length > 0 &&
    literalRun.json?.runId === mentionRun.json.runId &&
    literalRun.json?.state === 'done',
  JSON.stringify({ mention: mentionRun.json, literal: literalRun.json }),
);

socket.close();
process.exit(summary() === 0 ? 0 : 1);
