// 13-2 AI 패널 실제 태우기 — 진짜 LLM · 진짜 임베딩으로 세 기능을 완주한다.
//
// 계약 검증이 아니다(CI 에서 돌지 않는다). fake 로는 프롬프트가 쓸모 있는지,
// 인용 번호가 맞는 코드를 가리키는지 알 수 없어 사람이 결과를 읽기 위한 것이다.
//
// 사전 조건: server/.env 에 LLM_PROVIDER=gemini · EMBEDDING_PROVIDER=gemini ·
//            GITHUB_*_BASE=http://127.0.0.1:4599 (check:indexing 과 같다)
// 사용: node server/scripts/burn-ai.mjs
//
// **가짜 GitHub 이 이 저장소의 실제 소스 파일 몇 개를 서비스한다.** 진짜
// GitHub 저장소를 다시 붙이지 않고도 「진짜 임베딩 + 진짜 LLM」 경로를 탄다.
import { createServer } from 'node:http';
import { readFileSync } from 'node:fs';
import { requireServer } from './lib/preflight.mjs';
import { BASE, stamp, api, signup } from './lib/api.mjs';

await requireServer(BASE);
const FAKE_PORT = 4599;
const ROOT = new URL('../../', import.meta.url);

const FILES = [
  'server/src/ai/ai.worker.ts',
  'server/src/ai/prompt-hash.ts',
  'server/src/ai/transcript.ts',
  'server/src/repos/indexing/search-guard.ts',
  'app/lib/features/ai/ai_controller.dart',
];
const BLOBS = Object.fromEntries(
  FILES.map((path, i) => [`sha_${i}`, { path, text: readFileSync(new URL(path, ROOT), 'utf8') }]),
);
const HEAD_SHA = 'burn111111111111111111111111111111111111';
const REPO = {
  id: 9313,
  full_name: 'octocat/nexus-burn',
  private: false,
  default_branch: 'main',
  permissions: { admin: true },
};

const fake = createServer((req, res) => {
  const url = new URL(req.url, `http://127.0.0.1:${FAKE_PORT}`);
  const json = (code, body) => {
    res.writeHead(code, { 'content-type': 'application/json' });
    res.end(JSON.stringify(body));
  };
  if (req.method === 'POST' && url.pathname === '/login/oauth/access_token') {
    let raw = '';
    req.on('data', (c) => (raw += c));
    req.on('end', () => json(200, { access_token: `gho_${JSON.parse(raw).code}`, scope: 'repo' }));
    return;
  }
  if (url.pathname === '/user') return json(200, { id: 7373, login: 'octocat', avatar_url: '' });
  if (url.pathname === '/user/repos') return json(200, [REPO]);
  if (url.pathname === `/repositories/${REPO.id}`) return json(200, REPO);
  if (req.method === 'POST' && url.pathname.endsWith('/hooks')) return json(201, { id: 902 });
  const blob = url.pathname.match(/\/git\/blobs\/(.+)$/);
  if (blob) {
    const b = BLOBS[blob[1]];
    return b
      ? json(200, { content: Buffer.from(b.text).toString('base64'), encoding: 'base64', size: b.text.length })
      : json(404, {});
  }
  if (/\/git\/trees\//.test(url.pathname)) {
    return json(200, {
      sha: HEAD_SHA,
      truncated: false,
      tree: Object.entries(BLOBS).map(([sha, b]) => ({
        path: b.path,
        type: 'blob',
        sha,
        size: Buffer.byteLength(b.text),
      })),
    });
  }
  if (/\/branches\//.test(url.pathname)) return json(200, { name: 'main', commit: { sha: HEAD_SHA } });
  res.writeHead(404).end();
});
await new Promise((r) => fake.listen(FAKE_PORT, r));

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

async function waitRun(token, spaceId, runId) {
  // 5분. Gemini 가 503 을 주면 러너가 60초 간격으로 세 번까지 다시 건다.
  for (let i = 0; i < 1200; i++) {
    const r = await api('GET', `/spaces/${spaceId}/ai/runs/${runId}`, { token });
    if (r.json?.state === 'done' || r.json?.state === 'failed') return r.json;
    await sleep(250);
  }
  return null;
}

async function askAndShow(label, token, spaceId, body) {
  const t0 = Date.now();
  const started = await api('POST', `/spaces/${spaceId}/ai/ask`, { token, body });
  if (started.status !== 201) {
    console.log(`\n### ${label}\n적재 실패 ${started.status} ${JSON.stringify(started.json)}`);
    return null;
  }
  const run = await waitRun(token, spaceId, started.json.runId);
  const sec = ((Date.now() - t0) / 1000).toFixed(1);
  console.log(`\n### ${label}  (${sec}초 · ${run?.model} · prompt=${run?.promptTokens} completion=${run?.completionTokens})`);
  if (run?.state !== 'done') {
    console.log(run ? `실패: ${run.error}` : '5분 안에 끝나지 않음');
    return run;
  }
  const r = run.result;
  if (r.title !== undefined) console.log(`제목: ${r.title}\n\n${r.description}`);
  else console.log(r.markdown);
  if (r.citations?.length) {
    console.log('\n참고한 코드:');
    for (const c of r.citations) console.log(`  [${c.n}] ${c.path}:${c.startLine}-${c.endLine}`);
  }
  return run;
}

try {
  const a = await signup('burn', 'a', '가영');
  const b = await signup('burn', 'b', '민준');
  const c = await signup('burn', 'c', '서연');
  const space = await api('POST', '/spaces', { token: a.token, body: { name: `Burn ${stamp}` } });
  const spaceId = space.json.id;
  for (const who of [b, c]) {
    const inv = await api('POST', `/spaces/${spaceId}/invites`, { token: a.token, body: { role: 'member' } });
    await api('POST', `/invites/${inv.json.code}/accept`, { token: who.token });
  }
  const channel = (await api('GET', `/spaces/${spaceId}/channels`, { token: a.token })).json[0];
  const say = (who, body) =>
    api('POST', `/spaces/${spaceId}/channels/${channel.id}/messages`, { token: who.token, body: { body } });

  const lines = [
    [a, '어제 배포 후에 AI 요약이 가끔 30초씩 늦게 뜬다는 제보가 있었어요'],
    [b, '워커가 큐를 비우는 도중에 들어온 요청이 크론까지 밀리는 것 같아요. 재현은 됩니다'],
    [a, `그럼 금요일까지 고칠 수 있을까요? <@${b.userId}> 님이 맡아 주세요`],
    [b, '네 제가 볼게요. 재현 테스트도 같이 넣겠습니다'],
    [c, '그 김에 캐시 키에 모델 이름이 들어가는지도 확인 부탁해요. 모델 바꾸면 옛 답이 나올까 봐요'],
    [b, 'promptHash 에 modelId 가 섞여 있어서 괜찮을 거예요. 그래도 한 번 볼게요'],
    [a, '앱에서 소켓 알림을 놓치면 스피너가 계속 도는 문제는 해결됐나요?'],
    [c, '다시 확인 버튼이 들어가서 해결됐어요. 배포 일정은 아직 미정이에요'],
  ];
  const ids = [];
  for (const [who, body] of lines) ids.push((await say(who, body)).json.id);

  // 저장소 연결 → 인덱싱(진짜 임베딩)
  const started = await api('POST', '/me/connections/github/start', { token: a.token });
  const state = new URL(started.json.authorizeUrl).searchParams.get('state');
  await fetch(`${BASE}/auth/github/callback?${new URLSearchParams({ code: `burn-${stamp}`, state })}`);
  const linked = await api('POST', `/spaces/${spaceId}/repos/connect`, {
    token: a.token,
    body: { githubRepoId: REPO.id, linkedChannelId: channel.id },
  });
  const repoId = linked.json.id;
  const t0 = Date.now();
  let idx = null;
  for (let i = 0; i < 240; i++) {
    idx = (await api('GET', `/spaces/${spaceId}/repos/${repoId}/index`, { token: a.token })).json;
    if (idx?.state === 'done' || idx?.state === 'failed') break;
    await sleep(500);
  }
  console.log(
    `인덱싱: ${idx?.state} · 청크 ${idx?.chunkCount} · ${idx?.indexedEmbeddingModel} · ${((Date.now() - t0) / 1000).toFixed(1)}초 ${idx?.lastError ?? ''}`,
  );

  const conv = { channelId: channel.id, messageIds: ids };
  await askAndShow('① 자유 요약 — 양식 밖 지시', a.token, spaceId, {
    instruction: '누가 무엇을 언제까지 하기로 했는지만 한 줄씩 적어 줘',
    context: conv,
  });
  await askAndShow('② 자유 지시 — 영어 세 줄', a.token, spaceId, {
    instruction: 'Summarize this in three English bullet points',
    context: conv,
  });
  await askAndShow('③ 요약 프리셋(13-1 양식)', a.token, spaceId, { preset: 'summary', context: conv });
  await askAndShow('④ 이슈 초안 프리셋', a.token, spaceId, { preset: 'issue', context: conv });
  await askAndShow('⑤ 채널 최근 대화로 질문', a.token, spaceId, {
    instruction: '아직 결정되지 않은 게 뭐야?',
    context: { channelId: channel.id },
  });
  await askAndShow('⑥ 코드 질문', a.token, spaceId, {
    instruction: '소켓 알림을 놓쳤을 때 앱은 결과를 어떻게 가져와?',
    context: { repoId },
  });
  await askAndShow('⑦ 대화 + 코드', a.token, spaceId, {
    instruction: '대화에서 말한 「30초씩 늦게 뜨는」 문제의 원인이 코드 어디에 있는지 짚어 줘',
    context: { ...conv, repoId },
  });
  await askAndShow('⑧ 이슈 초안 + 코드', a.token, spaceId, {
    preset: 'issue',
    context: { ...conv, repoId },
  });
} finally {
  fake.close();
}
