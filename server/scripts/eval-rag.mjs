// RAG 검색 품질 · 응답 시간 측정 (2026-10-10).
//
// **계약 검증(check:*)이 아니다.** 그쪽은 「약속한 대로 동작하는가」를 가짜
// provider 로 단언하고, 이것은 「진짜 모델로 맞는 근거를 찾아 오는가」를 숫자로
// 잰다. 통과 · 실패가 없고 CI 에서 돌지 않는다 — 진짜 임베딩 모델이 필요하다.
//
// **왜 GitHub 을 거치지 않나.** 인덱싱 경로(트리 순회 → blob)는 check:indexing 이
// 덮는다. 여기서 재고 싶은 것은 청킹 · 임베딩 · 검색이라, 같은 거르기와 청킹을
// **로컬 체크아웃**에 그대로 돌려 DB 에 넣는다 — 키 없이 · 한도 없이 · 몇 번이고
// 같은 코퍼스로 다시 잴 수 있어야 비교가 된다.
//
// 쓰는 코드는 서버의 것이다(dist). 거르기 · 청킹 · provider · 검색 SQL 을 여기서
// 다시 쓰면 재는 것이 서버가 아니게 된다 — 그래서 먼저 빌드해야 한다.
//
//   npm --prefix server run build
//   node server/scripts/eval-rag.mjs                # 저장소 루트 체크아웃을 코퍼스로
//   node server/scripts/eval-rag.mjs --source <경로> --queries <질의.json> --keep
//
// 임베딩은 `server/.rag-eval/<모델>.jsonl` 에 캐시한다(본문 해시 → 벡터). 두 번째
// 실행부터는 바뀐 청크만 임베딩한다. 모델이 다르면 파일이 다르다.

import { createHash } from 'node:crypto';
import { execFileSync } from 'node:child_process';
import {
  appendFileSync,
  existsSync,
  mkdirSync,
  readFileSync,
  statSync,
  writeFileSync,
} from 'node:fs';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';

const HERE = dirname(fileURLToPath(import.meta.url));
const SERVER = resolve(HERE, '..');
const DIST = join(SERVER, 'dist');

// ── 인자 ─────────────────────────────────────────────────────────────────────
function argOf(name, fallback) {
  const i = process.argv.indexOf(name);
  return i >= 0 && process.argv[i + 1] ? process.argv[i + 1] : fallback;
}
const SOURCE = resolve(argOf('--source', resolve(SERVER, '..')));
const QUERIES = resolve(argOf('--queries', join(HERE, 'rag-eval', 'queries.json')));
const KEEP = process.argv.includes('--keep');
/** AI 패널이 쓰는 개수와 같다(ai.service.ts 의 CODE_TOP_K). 여기서 지표를 끊는다. */
const TOP_K = 8;

// ── 준비 ─────────────────────────────────────────────────────────────────────
if (!process.env.DATABASE_URL) {
  try {
    process.loadEnvFile(join(SERVER, '.env'));
  } catch {
    // 아래 PrismaClient 가 알아듣는 오류로 던진다.
  }
}
if (!existsSync(join(DIST, 'repos', 'indexing', 'lexical.js'))) {
  console.error(
    'server/dist 에 지금 코드가 없습니다. 먼저 `npm --prefix server run build`.',
  );
  process.exit(1);
}

// Windows 경로(C:\…)는 file:// 를 붙여도 URL 이 되지 않는다 — pathToFileURL 로 만든다.
const dist = (p) => import(pathToFileURL(join(DIST, p)).href);
const { chunkText } = await dist('repos/indexing/chunker.js');
const { isGenerated, isTooLarge, langOf } = await dist('repos/indexing/index-filter.js');
const { resolveBlobBody } = await dist('repos/blob-content.js');
const { IndexChunksRepository, HYBRID_CANDIDATES } = await dist(
  'repos/indexing/index-chunks.repository.js',
);
const { fuseRankings, queryTermsOf } = await dist('repos/indexing/lexical.js');
const { resolveEmbedding } = await dist('embedding/embedding.config.js');
const { assertDimensions } = await dist('embedding/embedding.provider.js');
const { FakeEmbeddingProvider } = await dist('embedding/fake-embedding.provider.js');
const { LocalEmbeddingProvider } = await dist('embedding/local-embedding.provider.js');
const { GeminiEmbeddingProvider } = await dist('embedding/gemini-embedding.provider.js');
const { PrismaClient } = await import('@prisma/client');

// ConfigService 대신 — resolveEmbedding 은 get() 만 부른다.
const resolved = resolveEmbedding({ get: (k) => process.env[k] });
if (!resolved) {
  console.error(
    'EMBEDDING_PROVIDER 가 비어 있습니다(server/.env). 재려면 진짜 모델이 필요합니다.',
  );
  process.exit(1);
}
const embedder =
  resolved.provider === 'fake'
    ? new FakeEmbeddingProvider()
    : resolved.provider === 'local'
      ? new LocalEmbeddingProvider(resolved)
      : new GeminiEmbeddingProvider(resolved);
if (resolved.provider === 'fake') {
  console.warn(
    '⚠ fake 임베딩이다 — 벡터 · 하이브리드 숫자는 뜻이 없다. 낱말 검색만 읽을 것.\n',
  );
}

// ── 코퍼스: 인덱싱과 같은 거르기 · 청킹 ─────────────────────────────────────
function corpus() {
  const files = execFileSync('git', ['-C', SOURCE, 'ls-files', '-z'], {
    maxBuffer: 64 << 20,
  })
    .toString('utf8')
    .split('\0')
    .filter(Boolean)
    // 질의 세트 자체는 뺀다 — 질문이 글자 그대로 들어 있어 낱말 갈래가 늘 그
    // 파일을 1위로 낸다(실제로 그렇게 오염됐다). 운영 인덱스에는 그대로 들어간다.
    .filter((p) => !p.startsWith('server/scripts/rag-eval/'));
  const out = [];
  let skipped = 0;
  for (const path of files) {
    const full = join(SOURCE, path);
    let size;
    try {
      size = statSync(full).size;
    } catch {
      continue; // 지운 채 커밋하지 않은 파일
    }
    // indexing.service 의 순서 그대로: 크기 → 바이너리 → 생성 파일 → 청킹.
    if (isTooLarge(size)) {
      skipped++;
      continue;
    }
    const body = resolveBlobBody(readFileSync(full).toString('base64'), size);
    if (body.content === null || isGenerated(body.content)) {
      skipped++;
      continue;
    }
    const chunks = chunkText(body.content);
    if (chunks.length > 0) out.push({ path, chunks });
  }
  return { files: out, skipped };
}

// ── 임베딩 캐시 ─────────────────────────────────────────────────────────────
const CACHE_DIR = join(SERVER, '.rag-eval');
mkdirSync(CACHE_DIR, { recursive: true });
const cacheFile = join(CACHE_DIR, `${embedder.modelId.replace(/[^\w.-]+/g, '_')}.jsonl`);
const cache = new Map();
if (existsSync(cacheFile)) {
  for (const line of readFileSync(cacheFile, 'utf8').split('\n')) {
    if (!line) continue;
    const { h, v } = JSON.parse(line);
    cache.set(h, v);
  }
}
const keyOf = (task, text) =>
  createHash('sha256').update(`${task}\0${text}`).digest('hex');

/** 캐시에 없는 것만 묶어 부른다. 돌려주는 순서는 넣은 순서다. */
async function embedAll(texts, task, onProgress) {
  const keys = texts.map((t) => keyOf(task, t));
  const missing = [
    ...new Set(keys.map((k, i) => (cache.has(k) ? -1 : i)).filter((i) => i >= 0)),
  ];
  const batch = resolved.batchSize;
  let calls = 0;
  let ms = 0;
  for (let at = 0; at < missing.length; at += batch) {
    const idx = missing.slice(at, at + batch);
    const t0 = performance.now();
    const vectors = await embedder.embed(
      idx.map((i) => texts[i]),
      task,
    );
    ms += performance.now() - t0;
    calls++;
    assertDimensions(vectors);
    idx.forEach((i, j) => {
      cache.set(keys[i], vectors[j]);
      appendFileSync(cacheFile, JSON.stringify({ h: keys[i], v: vectors[j] }) + '\n');
    });
    onProgress?.(Math.min(at + batch, missing.length), missing.length);
  }
  return { vectors: keys.map((k) => cache.get(k)), embedded: missing.length, calls, ms };
}

// ── 지표 ─────────────────────────────────────────────────────────────────────
function rankOf(hits, expect) {
  const i = hits.findIndex((h) => expect.includes(h.path));
  return i < 0 ? null : i + 1;
}
function pct(xs, p) {
  if (xs.length === 0) return null;
  const s = [...xs].sort((a, b) => a - b);
  return s[Math.min(s.length - 1, Math.floor((p / 100) * s.length))];
}
function summarize(rows) {
  const n = rows.length;
  const at = (k) => rows.filter((r) => r.rank !== null && r.rank <= k).length;
  return {
    n,
    hit1: at(1),
    hit3: at(3),
    hitK: at(TOP_K),
    mrr: rows.reduce((s, r) => s + (r.rank ? 1 / r.rank : 0), 0) / n,
    // 상위 K 에 서로 다른 파일이 몇 개인가 — 겹친 청크가 자리를 먹는지 본다.
    files: rows.reduce((s, r) => s + r.distinctFiles, 0) / n,
    p50: pct(
      rows.map((r) => r.ms),
      50,
    ),
    p95: pct(
      rows.map((r) => r.ms),
      95,
    ),
  };
}

// ── 본문 ─────────────────────────────────────────────────────────────────────
const prisma = new PrismaClient();
const chunksRepo = new IndexChunksRepository(prisma);
const EVAL_EMAIL = 'rag-eval@bot.nexus.invalid';
const EVAL_SLUG = 'rag-eval';

async function evalRepo() {
  // 서버가 만드는 계정은 .invalid 도메인 · 비밀번호 없음(로그인할 수 없다) — CLAUDE.md §2.
  const user = await prisma.user.upsert({
    where: { email: EVAL_EMAIL },
    create: { email: EVAL_EMAIL, name: 'RAG 평가', passwordHash: null },
    update: {},
  });
  await prisma.space.deleteMany({ where: { slug: EVAL_SLUG } });
  const space = await prisma.space.create({
    data: { slug: EVAL_SLUG, name: 'RAG 평가', ownerId: user.id },
  });
  const repo = await prisma.repo.create({
    data: {
      spaceId: space.id,
      provider: 'github',
      externalProjectId: 'rag-eval',
      name: 'rag-eval',
      fullPath: 'local/rag-eval',
    },
  });
  return { spaceId: space.id, repoId: repo.id };
}

async function main() {
  const { queries } = JSON.parse(readFileSync(QUERIES, 'utf8'));
  const commit = execFileSync('git', ['-C', SOURCE, 'rev-parse', 'HEAD'])
    .toString()
    .trim();

  const { files, skipped } = corpus();
  const allChunks = files.flatMap((f) => f.chunks);
  console.log(
    `코퍼스: ${SOURCE} @ ${commit.slice(0, 7)} — 파일 ${files.length} (거름 ${skipped}) · 청크 ${allChunks.length}`,
  );

  // 정답 파일이 코퍼스에 없으면 그 질의는 처음부터 못 맞힌다 — 질의 세트의 결함이다.
  const indexed = new Set(files.map((f) => f.path));
  const broken = queries.flatMap((q) =>
    q.expect.filter((p) => !indexed.has(p)).map((p) => `${q.q} → ${p}`),
  );
  if (broken.length > 0) {
    console.error(`정답 파일이 코퍼스에 없다:\n  ${broken.join('\n  ')}`);
    process.exit(1);
  }

  console.log(`임베딩: ${embedder.modelId} (캐시 ${cache.size}개)`);
  const docs = await embedAll(
    allChunks.map((c) => c.content),
    'document',
    (done, total) => process.stdout.write(`\r  문서 임베딩 ${done}/${total}`),
  );
  if (docs.embedded > 0) process.stdout.write('\n');

  const { spaceId, repoId } = await evalRepo();
  let offset = 0;
  for (const f of files) {
    const vectors = docs.vectors.slice(offset, offset + f.chunks.length);
    offset += f.chunks.length;
    await chunksRepo.replaceFile({
      spaceId,
      repoId,
      path: f.path,
      lang: langOf(f.path),
      commitSha: commit,
      chunks: f.chunks,
      embeddings: vectors,
    });
  }

  // 통계를 채운다. 막 쌓은 표는 통계가 없어 계획이 어긋난다(벡터 100ms+ ·
  // 낱말 수백 ms 를 실측) — 운영에서는 autovacuum 이 1분 안팎에 채우므로,
  // 재는 것은 그 뒤의 평소 상태다.
  await prisma.$executeRawUnsafe('ANALYZE repo_index_chunks');

  // 질의 임베딩은 캐시해도 시간을 따로 잰다 — 캐시에 없던 것만 잰 값이 남는다.
  const qEmb = [];
  const qMs = [];
  for (const q of queries) {
    const r = await embedAll([q.q], 'query');
    qEmb.push(r.vectors[0]);
    if (r.embedded > 0) qMs.push(r.ms);
  }

  const strategies = {
    // 바꾸기 전의 운영 경로 그대로다(indexing.service 가 부르던 search()).
    vector: (i) => chunksRepo.search(spaceId, repoId, qEmb[i], TOP_K),
    lexical: (i) =>
      chunksRepo.searchLexical(spaceId, repoId, queryTermsOf(queries[i].q), TOP_K),
    // 운영 경로 — 식별자 없는 질문은 낱말 가중치 0.5(lexicalWeightOf).
    hybrid: (i) => chunksRepo.searchHybrid(spaceId, repoId, qEmb[i], queries[i].q, TOP_K),
    // 비교용 — 가중치를 늘 1 로 둔 RRF. 안전장치가 무엇을 잃고 얻는지 본다.
    'hybrid=1': async (i) => {
      const [v, l] = await Promise.all([
        chunksRepo.search(spaceId, repoId, qEmb[i], HYBRID_CANDIDATES),
        chunksRepo.searchLexical(
          spaceId,
          repoId,
          queryTermsOf(queries[i].q),
          HYBRID_CANDIDATES,
        ),
      ]);
      return fuseRankings([v, l], TOP_K);
    },
  };

  // 한 바퀴 버린다 — 첫 쿼리는 계획 · 캐시를 데우느라 느려 p95 를 왜곡한다.
  for (const run of Object.values(strategies)) await run(0);

  const results = {};
  for (const [name, run] of Object.entries(strategies)) {
    results[name] = [];
    for (let i = 0; i < queries.length; i++) {
      const t0 = performance.now();
      const hits = await run(i);
      const ms = performance.now() - t0;
      results[name].push({
        q: queries[i].q,
        kind: queries[i].kind,
        rank: rankOf(hits, queries[i].expect),
        top: hits.slice(0, 3).map((h) => `${h.path}:${h.startLine}`),
        distinctFiles: new Set(hits.map((h) => h.path)).size,
        ms,
      });
    }
  }

  // ── 출력 ──
  const kinds = ['all', ...new Set(queries.map((q) => q.kind))];
  const fmt = (x, d = 0) => (x === null ? '—' : x.toFixed(d));
  console.log(`\n상위 ${TOP_K} 기준 · 정답은 파일 단위\n`);
  console.log('갈래      종류    n  1위  3위안  8위안   MRR   파일수  p50ms  p95ms');
  const summary = {};
  for (const [name, rows] of Object.entries(results)) {
    summary[name] = {};
    for (const kind of kinds) {
      const s = summarize(kind === 'all' ? rows : rows.filter((r) => r.kind === kind));
      summary[name][kind] = s;
      console.log(
        `${name.padEnd(9)} ${kind.padEnd(6)} ${String(s.n).padStart(2)}  ${String(s.hit1).padStart(3)}  ${String(s.hit3).padStart(5)}  ${String(s.hitK).padStart(5)}  ${s.mrr.toFixed(3)}  ${s.files.toFixed(1).padStart(6)}  ${fmt(s.p50, 1).padStart(5)}  ${fmt(s.p95, 1).padStart(5)}`,
      );
    }
  }
  if (qMs.length > 0) {
    console.log(
      `\n질의 임베딩(캐시에 없던 ${qMs.length}개): p50 ${fmt(pct(qMs, 50), 1)}ms · p95 ${fmt(pct(qMs, 95), 1)}ms`,
    );
  }

  console.log('\n갈래마다 못 맞힌 질의(상위 3):');
  for (const [name, rows] of Object.entries(results)) {
    const misses = rows.filter((r) => r.rank === null);
    console.log(`  [${name}] ${misses.length}개`);
    for (const m of misses)
      console.log(`    · ${m.q}\n        → ${m.top.join(' · ') || '(없음)'}`);
  }

  const report = join(
    CACHE_DIR,
    `report-${new Date().toISOString().replace(/[:.]/g, '-')}.json`,
  );
  writeFileSync(
    report,
    JSON.stringify(
      { commit, model: embedder.modelId, topK: TOP_K, summary, results },
      null,
      2,
    ),
  );
  console.log(`\n보고서: ${report}`);

  if (!KEEP) await prisma.space.deleteMany({ where: { slug: EVAL_SLUG } });
}

try {
  await main();
} finally {
  await prisma.$disconnect();
}
