// AI(13-1 대화 요약 · 13-2 AI 패널) 검증. 실제 서버 · 실제 DB · 실제 소켓으로 확인한다.
//
// 저장소 컨텍스트(코드 질문 · 인용 · 모델 불일치 503)는 인덱싱된 저장소가
// 있는 check:indexing 이 본다 — 가짜 GitHub 을 여기 또 띄우지 않는다.
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
import { withDb, closeDb, fromNow } from './lib/db.mjs';
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
// `AiService.ask()` 는 `requireLlm()` 을 검증 · 채널 조회보다 먼저 부르므로
// (ai.service.ts), 채널·메시지가 실존하지 않아도 미설정이면 503 이 온다 —
// 자리 채우기 id 로 충분하다.
const probe = await api('POST', `/spaces/${spaceId}/ai/ask`, {
  token: alice.token,
  body: {
    preset: 'summary',
    context: { channelId: UNKNOWN_UUID, messageIds: [UNKNOWN_UUID] },
  },
});

if (probe.status === 503) {
  console.log('서버가 LLM 미설정 상태다 (LLM_PROVIDER 가 비어 있음).\n');
  check('설정이 없으면 ask 는 503', probe.status === 503, String(probe.status));

  console.log('\n이 상태에서는 503 분기만 확인할 수 있다. 나머지 케이스를 보려면:');
  console.log('  1) server/.env 에 LLM_PROVIDER=fake 를 채운다');
  console.log('  2) npm run server:dev 를 재시작한다');
  console.log('  3) npm run check:ai 를 다시 돌린다\n');
  process.exit(summary() === 0 ? 0 : 1);
}

console.log('서버가 LLM_PROVIDER 로 설정돼 있다 — 이 실행에서는 503(미설정) 분기를');
console.log('태우지 않는다. 그 분기를 보려면 LLM_PROVIDER 를 비우고 서버를 재시작한 뒤');
console.log('이 스크립트를 다시 돌려라.\n');

// ── 큐 실패 갈래 준비 ───────────────────────────
// 5xx 다섯 번 소진은 재시도 대기(5 · 10 · 15 · 20초)만 50초다. 맨 끝에서 띄우면
// 그만큼 스크립트가 길어지므로 여기서 적재해 두고, 나머지 케이스가 도는 동안
// 기다린다. **요청자를 따로 둔다** — 실패 알림이 기본 흐름의 소켓 대기
// (`waitFor(socket, 'ai:run:done')`)에 섞이지 않게.
const carol = await signup('ai', 'f', 'AI검증f');
const failSpace = await api('POST', '/spaces', {
  token: carol.token,
  body: { name: `ai fail ${stamp}` },
});
const failSpaceId = failSpace.json?.id;
const failChannel = (
  await api('GET', `/spaces/${failSpaceId}/channels`, { token: carol.token })
).json?.[0];
const failMsg = await api('POST', `/spaces/${failSpaceId}/channels/${failChannel?.id}/messages`, {
  token: carol.token,
  body: { body: '실패 주입용 대화' },
});
const failSocket = await connect(carol.token);
/** carol 에게 온 `ai:run:done` 전부. 실행마다 무엇이 몇 번 왔는지 본다. */
const failEvents = [];
failSocket.on?.('ai:run:done', (e) => failEvents.push(e));
check(
  '실패 주입 준비 (별도 사용자 · 스페이스 · 소켓)',
  !!failSpaceId && !!failChannel && failMsg.status === 201 && typeof failSocket?.on === 'function',
);

/**
 * `FakeLlmProvider` 의 실패 주입 지시문을 자유 지시문에 실어 보낸다.
 * `stamp` 를 섞는 이유: fake 는 프롬프트마다 호출 수를 세는데 서버 프로세스가
 * 살아 있는 한 그 수가 남는다 — 같은 스크립트를 다시 돌려도 처음부터 세게 한다.
 */
const failAsk = (directive) =>
  api('POST', `/spaces/${failSpaceId}/ai/ask`, {
    token: carol.token,
    body: {
      instruction: `${stamp} ${directive}`,
      context: { channelId: failChannel?.id, messageIds: [failMsg.json?.id] },
    },
  });

const exhaustAt = Date.now();
const exhaust = await failAsk('[[fake-llm:status=503]]');

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
/** 13-1 의 요약 = 13-2 의 `preset: 'summary'`. 기존 케이스는 이것으로 옮겼다. */
const summarize = (token, context, extra = {}) =>
  api('POST', `/spaces/${spaceId}/ai/ask`, {
    token,
    body: { preset: 'summary', context, ...extra },
  });
const ask = (token, body) =>
  api('POST', `/spaces/${spaceId}/ai/ask`, { token, body });

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

// bob 이 alice 와 **같은** 채널·메시지를 고르면 프롬프트가 바이트 단위로
// 같아 같은 promptHash 가 나온다. 캐시 조회가 spaceId 로만 걸리면 alice 의
// runId 를 그대로 돌려주고, bob 이 그 runId 로 GET 하면 getRun() 은
// userId 도 보므로(§9) 404 다 — 최종 whole-branch 리뷰 Important ①. 값이
// 있는지부터 본다(undefined === undefined 로 통과하는 사고를 피하려는 것).
const byBobSameInput = await summarize(bob.token, {
  channelId: channel.id,
  messageIds: ids,
});
check(
  '★ bob 이 같은 구간을 요약해도 적재된다',
  byBobSameInput.status === 201 &&
    typeof byBobSameInput.json?.runId === 'string' &&
    byBobSameInput.json.runId.length > 0,
  JSON.stringify(byBobSameInput.json),
);
check(
  '★ 캐시가 남의 runId 를 주지 않는다 - alice 와 다른 runId 다',
  typeof byBobSameInput.json?.runId === 'string' &&
    byBobSameInput.json.runId.length > 0 &&
    byBobSameInput.json.runId !== runId,
  `bob=${byBobSameInput.json?.runId} vs alice=${runId}`,
);

const bobRunId = byBobSameInput.json?.runId;
if (byBobSameInput.json?.state === 'queued') {
  const finished = await waitForRunDone(bob.token, spaceId, bobRunId);
  check(
    'bob 의 요약이 끝난다',
    finished?.json?.state === 'done',
    JSON.stringify(finished?.json),
  );
}

const bobFetch = await api('GET', `/spaces/${spaceId}/ai/runs/${bobRunId}`, {
  token: bob.token,
});
check(
  '★ bob 이 자기 runId 로 조회하면 200 이다 - 영구 404 가 아니다',
  bobFetch.status === 200,
  `status=${bobFetch.status}`,
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

const extraField = await summarize(
  alice.token,
  { channelId: channel.id, messageIds: ids },
  { nope: 1 },
);
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

// ── 13-2 자유 지시문 ────────────────────────────
console.log('\n[자유 지시문]');

const free = await ask(alice.token, {
  instruction: '세 줄로 요약해 줘',
  context: { channelId: channel.id, messageIds: ids },
});
check('자유 지시문 적재', free.status === 201, `status=${free.status}`);
const freeDone =
  free.json?.state === 'queued'
    ? await waitForRunDone(alice.token, spaceId, free.json.runId)
    : await api('GET', `/spaces/${spaceId}/ai/runs/${free.json?.runId}`, { token: alice.token });
check(
  '★ 자유 지시문은 kind ask 로 끝난다',
  freeDone?.json?.state === 'done' && freeDone.json.kind === 'ask',
  JSON.stringify(freeDone?.json),
);
check(
  '★ 저장소가 없으면 인용은 null 이 아니라 빈 배열이다',
  Array.isArray(freeDone?.json?.result?.citations) &&
    freeDone.json.result.citations.length === 0 &&
    typeof freeDone.json.result.markdown === 'string',
  JSON.stringify(freeDone?.json?.result),
);

const freeOther = await ask(alice.token, {
  instruction: '영어로 요약해 줘',
  context: { channelId: channel.id, messageIds: ids },
});
check(
  '★ 같은 메시지라도 지시문이 다르면 다른 runId 다',
  typeof freeOther.json?.runId === 'string' &&
    freeOther.json.runId.length > 0 &&
    freeOther.json.runId !== free.json?.runId,
  JSON.stringify(freeOther.json),
);
const freeSame = await ask(alice.token, {
  instruction: '  세 줄로 요약해 줘 ',
  context: { channelId: channel.id, messageIds: ids },
});
check(
  '같은 지시문(앞뒤 공백만 다름)이면 같은 runId 다',
  typeof freeSame.json?.runId === 'string' &&
    freeSame.json.runId === free.json?.runId &&
    freeSame.json.state === 'done',
  JSON.stringify(freeSame.json),
);

// ── 13-2 채널 최근 대화 ─────────────────────────
console.log('\n[채널 최근 대화]');

const recentCh = await api('POST', `/spaces/${spaceId}/channels`, {
  token: alice.token,
  body: { name: `recent-${stamp}` },
});
check('최근 대화용 채널 준비', recentCh.status === 201, `status=${recentCh.status}`);
const recentId = recentCh.json?.id;

const emptyRecent = await ask(alice.token, {
  preset: 'summary',
  context: { channelId: recentId },
});
check(
  '★ 메시지가 없는 채널은 400 이다 - 빈 대화를 요약하지 않는다',
  emptyRecent.status === 400,
  `status=${emptyRecent.status}`,
);

const r1 = await api('POST', `/spaces/${spaceId}/channels/${recentId}/messages`, {
  token: alice.token,
  body: { body: '로그인 버튼이 눌리지 않아요' },
});
check('최근 대화 메시지 준비', r1.status === 201);

const byChannel = await ask(alice.token, {
  instruction: '무슨 문제야?',
  context: { channelId: recentId },
});
const byChannelDone =
  byChannel.json?.state === 'queued'
    ? await waitForRunDone(alice.token, spaceId, byChannel.json.runId)
    : null;
check(
  '★ 채널만 주면 최근 대화로 끝난다',
  byChannel.status === 201 && byChannelDone?.json?.state === 'done',
  JSON.stringify(byChannelDone?.json ?? byChannel.json),
);

// 스레드 답글은 최근 대화에 들어가지 않는다 — 채널 목록과 같은 기준.
// 캐시 키로 확인한다: 답글만 늘면 프롬프트가 같아 같은 runId, 최상위가
// 늘면 달라진다.
const reply = await api('POST', `/spaces/${spaceId}/channels/${recentId}/messages`, {
  token: alice.token,
  body: { body: '저도 재현돼요', parentId: r1.json?.id },
});
check('스레드 답글 준비', reply.status === 201, `status=${reply.status}`);
const afterReply = await ask(alice.token, {
  instruction: '무슨 문제야?',
  context: { channelId: recentId },
});
check(
  '★ 스레드 답글은 최근 대화에 없다 - 같은 프롬프트라 같은 runId',
  typeof afterReply.json?.runId === 'string' &&
    afterReply.json.runId === byChannel.json?.runId,
  JSON.stringify({ before: byChannel.json, after: afterReply.json }),
);

await api('POST', `/spaces/${spaceId}/channels/${recentId}/messages`, {
  token: bob.token,
  body: { body: '캐시를 지우면 됩니다' },
});
const afterTop = await ask(alice.token, {
  instruction: '무슨 문제야?',
  context: { channelId: recentId },
});
check(
  '★ 최상위 메시지가 늘면 다른 runId 다 - 적재 시점의 최근 대화로 고정된다',
  typeof afterTop.json?.runId === 'string' &&
    afterTop.json.runId.length > 0 &&
    afterTop.json.runId !== byChannel.json?.runId,
  JSON.stringify(afterTop.json),
);

// ── 13-2 이슈 초안 프리셋 ───────────────────────
console.log('\n[이슈 초안]');

const draft = await ask(alice.token, {
  preset: 'issue',
  context: { channelId: recentId, messageIds: [r1.json?.id] },
});
const draftDone =
  draft.json?.state === 'queued'
    ? await waitForRunDone(alice.token, spaceId, draft.json.runId)
    : null;
check(
  '★ 이슈 프리셋은 kind draft_issue 다',
  draftDone?.json?.state === 'done' && draftDone.json.kind === 'draft_issue',
  JSON.stringify(draftDone?.json),
);
check(
  '★ 결과에 제목 · 본문이 문자열로 있다',
  typeof draftDone?.json?.result?.title === 'string' &&
    draftDone.json.result.title.length > 0 &&
    typeof draftDone.json.result.description === 'string',
  JSON.stringify(draftDone?.json?.result),
);

// ── 13-2 입력 검증 ──────────────────────────────
console.log('\n[13-2 입력 검증]');

const bads = [
  ['지시문과 프리셋 둘 다', { instruction: 'q', preset: 'summary', context: { channelId: channel.id } }],
  ['지시문도 프리셋도 없음', { context: { channelId: channel.id } }],
  ['컨텍스트가 비었음', { instruction: 'q', context: {} }],
  ['messageIds 만 있음', { instruction: 'q', context: { messageIds: ids } }],
  ['프리셋인데 저장소만 있음', { preset: 'issue', context: { repoId: UNKNOWN_UUID } }],
  ['지시문 2001자', { instruction: 'a'.repeat(2001), context: { channelId: channel.id } }],
  ['공백뿐인 지시문', { instruction: '   ', context: { channelId: channel.id } }],
  ['모르는 프리셋', { preset: 'poem', context: { channelId: channel.id } }],
];
for (const [label, body] of bads) {
  const r = await ask(alice.token, body);
  check(`${label}은 400 이다`, r.status === 400, `status=${r.status}`);
}

// ── 13-2 저장소 권한 ────────────────────────────
console.log('\n[저장소 권한]');

const noRepo = await ask(alice.token, {
  instruction: 'q',
  context: { repoId: UNKNOWN_UUID },
});
check(
  '★ 이 스페이스 것이 아닌 저장소는 404 다',
  noRepo.status === 404,
  `status=${noRepo.status}`,
);

// ── 13-3 이어 묻기 ───────────────────────────────
console.log('\n[13-3 이어 묻기]');

/** 적재 응답을 받아 끝날 때까지 기다린다. 캐시 적중이면 바로 조회한다. */
async function settle(token, started) {
  const id = started.json?.runId;
  if (!id) return null;
  if (started.json.state === 'queued') return waitForRunDone(token, spaceId, id);
  return api('GET', `/spaces/${spaceId}/ai/runs/${id}`, { token });
}

const rootAsk = await ask(alice.token, {
  instruction: '핵심만 말해 줘',
  context: { channelId: channel.id, messageIds: ids },
});
const rootDone = await settle(alice.token, rootAsk);
check('첫 문답 준비', rootDone?.json?.state === 'done', JSON.stringify(rootDone?.json));
const rootRunId = rootAsk.json?.runId;

const follow = await ask(alice.token, { instruction: '더 짧게', parentRunId: rootRunId });
check('이어 묻기가 적재된다', follow.status === 201, `status=${follow.status}`);
const followDone = await settle(alice.token, follow);
check(
  '★ 이어 묻기가 끝나고 kind 는 ask, 부모가 기록된다',
  followDone?.json?.state === 'done' &&
    followDone.json.kind === 'ask' &&
    typeof rootRunId === 'string' &&
    followDone.json.parentRunId === rootRunId,
  JSON.stringify(followDone?.json),
);

const followAgain = await ask(alice.token, { instruction: '더 짧게', parentRunId: rootRunId });
check(
  '★ 같은 부모 + 같은 질문이면 캐시 적중(같은 runId)',
  !!follow.json?.runId && followAgain.json?.runId === follow.json.runId,
  JSON.stringify(followAgain.json),
);

const second = await ask(alice.token, { instruction: '더 짧게', parentRunId: follow.json?.runId });
check(
  '★ 부모가 다르면 캐시가 갈린다',
  !!second.json?.runId && second.json.runId !== follow.json?.runId,
  JSON.stringify(second.json),
);
await settle(alice.token, second);

const onSummary = await ask(alice.token, { instruction: '담당자별로', parentRunId: runId });
const onSummaryDone = await settle(alice.token, onSummary);
check(
  '요약 프리셋에도 이어 물을 수 있다',
  onSummaryDone?.json?.state === 'done' && onSummaryDone.json.kind === 'ask',
  JSON.stringify(onSummaryDone?.json),
);

const followBads = [
  ['이어 묻기 + 프리셋', { preset: 'summary', parentRunId: rootRunId }],
  ['이어 묻기 + 컨텍스트', { instruction: 'q', parentRunId: rootRunId, context: { channelId: channel.id } }],
  ['이슈 초안에 이어 묻기', { instruction: 'q', parentRunId: draft.json?.runId }],
];
for (const [label, body] of followBads) {
  const r = await ask(alice.token, body);
  check(`${label}은 400 이다`, r.status === 400, `status=${r.status}`);
}

const bobFollow = await ask(bob.token, { instruction: 'q', parentRunId: rootRunId });
check('★ 다른 사용자의 문답에 이어 물으면 404', bobFollow.status === 404, `status=${bobFollow.status}`);
const ghostFollow = await ask(alice.token, { instruction: 'q', parentRunId: UNKNOWN_UUID });
check('없는 문답에 이어 물으면 404', ghostFollow.status === 404, `status=${ghostFollow.status}`);

// 사슬 상한 — 첫 문답 + 후속 9 까지, 11번째는 400.
let tip = rootRunId;
let chainOk = true;
for (let i = 2; i <= 10; i++) {
  const r = await ask(alice.token, { instruction: `이어서 ${i}`, parentRunId: tip });
  const d = await settle(alice.token, r);
  if (r.status !== 201 || d?.json?.state !== 'done') chainOk = false;
  tip = r.json?.runId;
}
check('사슬 10 문답까지 이어진다', chainOk && typeof tip === 'string');
const eleventh = await ask(alice.token, { instruction: '열한 번째', parentRunId: tip });
check(
  '★ 11번째 문답은 400 이다 - 조용히 앞을 자르지 않는다',
  eleventh.status === 400,
  `status=${eleventh.status}`,
);

// ── 큐 실패 갈래 ─────────────────────────────────
// 13-1 빚(2026-09-27 해소). fake 가 늘 즉시 성공해 재시도 · 소진 · 포기 · 리스
// 복구를 계약 검증이 한 번도 태우지 못했다. 시도 횟수는 응답에 싣지 않는 값이라
// DB 에서 읽는다(`lib/db.mjs`).
console.log('\n[큐 실패 갈래]');

const runOf = (id) => api('GET', `/spaces/${failSpaceId}/ai/runs/${id}`, { token: carol.token });
const attemptsOf = async (id) =>
  (await withDb((db) => db.aiRun.findUnique({ where: { id }, select: { attempts: true } })))
    ?.attempts;
/** 그 실행에 온 알림의 state 들. 소켓이 GET 보다 늦게 닿을 수 있어 잠깐 기다린다. */
const eventsFor = async (id) => {
  await sleep(500);
  return failEvents.filter((e) => e.runId === id).map((e) => e.state);
};
const same = (a, b) => JSON.stringify(a) === JSON.stringify(b);

// 5xx 두 번 뒤 성공 — 대기 5 · 10초
const flaky = await failAsk('[[fake-llm:status=503;times=2]]');
const flakyId = flaky.json?.runId;
const flakyDone = await waitForRunDone(carol.token, failSpaceId, flakyId, 40000);
check(
  '★ 5xx 는 다시 걸어 끝내 성공한다',
  flakyDone?.json?.state === 'done',
  JSON.stringify(flakyDone?.json),
);
check('5xx 는 시도로 센다 — 두 번 실패 뒤 성공이면 2', (await attemptsOf(flakyId)) === 2);
const flakyEvents = await eventsFor(flakyId);
check(
  '★ 재시도 중에는 실패를 알리지 않는다 — done 하나만 온다',
  same(flakyEvents, ['done']),
  JSON.stringify(flakyEvents),
);

// 429 + Retry-After: 0 — 여섯 번. 시도로 셌다면 다섯 번째에 포기했다.
const limited = await failAsk('[[fake-llm:status=429;retry-after=0;times=6]]');
const limitedId = limited.json?.runId;
const limitedDone = await waitForRunDone(carol.token, failSpaceId, limitedId, 10000);
const limitedAttempts = await attemptsOf(limitedId);
check(
  '★ 429 는 시도로 세지 않는다 — 여섯 번 거절돼도 끝내 성공한다',
  limitedDone?.json?.state === 'done' && limitedAttempts === 0,
  `${JSON.stringify(limitedDone?.json)} · attempts=${limitedAttempts}`,
);

// 4xx — 다시 걸어도 같은 거절이다. 곧바로 포기한다.
const rejectAt = Date.now();
const rejected = await failAsk('[[fake-llm:status=400]]');
const rejectedId = rejected.json?.runId;
const rejectedDone = await waitForRunDone(carol.token, failSpaceId, rejectedId, 10000);
const rejectTook = Date.now() - rejectAt;
const rejectedAttempts = await attemptsOf(rejectedId);
check(
  '★ 4xx 는 첫 실패에 포기한다 — 재시도 대기 없이',
  rejectedDone?.json?.state === 'failed' && rejectedAttempts === 1 && rejectTook < 4000,
  `${JSON.stringify(rejectedDone?.json)} · attempts=${rejectedAttempts} · ${rejectTook}ms`,
);
check(
  '실패 이유가 남는다',
  typeof rejectedDone?.json?.error === 'string' && rejectedDone.json.error.includes('400'),
  String(rejectedDone?.json?.error),
);
const rejectedEvents = await eventsFor(rejectedId);
check(
  '포기하면 failed 가 한 번 온다',
  same(rejectedEvents, ['failed']),
  JSON.stringify(rejectedEvents),
);
const rejectedAgain = await failAsk('[[fake-llm:status=400]]');
check(
  '★ 실패한 실행은 캐시가 아니다 — 같은 요청이 새로 적재된다',
  rejectedAgain.json?.state === 'queued' &&
    typeof rejectedAgain.json?.runId === 'string' &&
    rejectedAgain.json.runId !== rejectedId,
  JSON.stringify(rejectedAgain.json),
);
await waitForRunDone(carol.token, failSpaceId, rejectedAgain.json?.runId, 10000);

// 빈 답 · 잘린 답 — 성공으로 굳히면 그 행이 곧 캐시다(13-1 · LLM 교체)
const blank = await failAsk('[[fake-llm:empty]]');
const blankDone = await waitForRunDone(carol.token, failSpaceId, blank.json?.runId, 10000);
check(
  '★ 빈 답은 실패로 끝난다',
  blankDone?.json?.state === 'failed' && String(blankDone.json.error).includes('빈 응답'),
  JSON.stringify(blankDone?.json),
);
const cut = await failAsk('[[fake-llm:truncated]]');
const cutDone = await waitForRunDone(carol.token, failSpaceId, cut.json?.runId, 10000);
check(
  '★ 잘린 답은 실패로 끝나고 올릴 설정을 알린다',
  cutDone?.json?.state === 'failed' && String(cutDone.json.error).includes('LLM_MAX_TOKENS'),
  JSON.stringify(cutDone?.json),
);

// 리스 — 살아 있으면 아무도 잡지 않고, 만료되면 다시 잡는다(= 크래시 복구).
// 워커를 대신 죽일 수 없어 끝난 실행을 「도는 중」으로 되돌려 흉내 낸다.
const setRunning = (leaseMs) =>
  withDb((db) =>
    db.aiRun.updateMany({
      where: { id: flakyId },
      data: { state: 'running', leaseUntil: fromNow(leaseMs), finishedAt: null },
    }),
  );
/** 다른 요청 하나를 적재해 워커를 깨우고, 그 요청이 끝날 때까지 기다린다. */
const kickWorker = async (tag) => {
  const k = await failAsk(`깨우기 ${tag}`);
  return waitForRunDone(carol.token, failSpaceId, k.json?.runId, 10000);
};

const held = await setRunning(10 * 60_000);
const heldKick = await kickWorker('리스 유효');
const heldRun = await runOf(flakyId);
check(
  '★ 리스가 살아 있는 running 실행은 다시 잡지 않는다',
  held.count === 1 && heldKick?.json?.state === 'done' && heldRun.json?.state === 'running',
  `updated=${held.count} · kick=${heldKick?.json?.state} · state=${heldRun.json?.state}`,
);

const expired = await setRunning(-60_000);
await kickWorker('리스 만료');
const recovered = await waitForRunDone(carol.token, failSpaceId, flakyId, 10000);
const recoveredEvents = await eventsFor(flakyId);
check(
  '★ 리스가 만료된 running 실행은 다시 잡혀 끝난다 - 죽은 워커의 실행이 영영 남지 않는다',
  expired.count === 1 && recovered?.json?.state === 'done' && recovered.json.finishedAt != null,
  JSON.stringify(recovered?.json),
);
check(
  '다시 끝나면 요청자에게 다시 알린다',
  same(recoveredEvents, ['done', 'done']),
  JSON.stringify(recoveredEvents),
);

// 5xx 소진 — 맨 앞에서 적재해 둔 것. AI_MAX_ATTEMPTS(5)번 실패하면 포기한다.
const exhaustId = exhaust.json?.runId;
const exhaustDone = await waitForRunDone(carol.token, failSpaceId, exhaustId, 90000);
const exhaustTook = Date.now() - exhaustAt;
const exhaustAttempts = await attemptsOf(exhaustId);
check(
  '★ 5xx 가 계속되면 다섯 번째에 포기한다',
  exhaustDone?.json?.state === 'failed' && exhaustAttempts === 5,
  `${JSON.stringify(exhaustDone?.json)} · attempts=${exhaustAttempts}`,
);
check(
  '★ 재시도 사이에 물러선다 — 대기 합이 50초다(곧바로 다섯 번 태우지 않는다)',
  exhaustTook >= 45_000,
  `${exhaustTook}ms`,
);
const exhaustEvents = await eventsFor(exhaustId);
check(
  '소진해도 failed 는 한 번만 온다',
  same(exhaustEvents, ['failed']),
  JSON.stringify(exhaustEvents),
);

failSocket.close?.();
await closeDb();
socket.close();
process.exit(summary() === 0 ? 0 : 1);
