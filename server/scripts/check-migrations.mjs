// 마이그레이션 SQL 에 **수동 관리 객체를 지우는 구문**이 섞였는지 검사한다.
//
// 사용: npm run check:migrations   (DB 도 서버도 필요 없다 — 파일만 읽는다)
//
// 왜 필요한가:
//   Prisma 는 스키마로 표현하지 못하는 것을 **드리프트로 오인**한다. pgvector
//   의 HNSW 인덱스가 그것이다 — schema.prisma 에 쓸 수 없어 마이그레이션 SQL
//   에 직접 만들어 두었는데, `prisma migrate diff` 는 그것을 "스키마에 없는데
//   DB 에 있는 것"으로 보고 삭제 구문을 끼워 넣는다.
//
//   7-1 · 7-3 · 9-1 · 9-2a 에서 **네 번** 겪었다. 매번 사람이 눈으로 잡았고,
//   한 번이라도 놓치면 AI 코드 질의(설계 §8)의 전제인 벡터 인덱스가 사라진다.
//   **조용히 사라지는 것이 문제다** — 인덱스가 없어도 쿼리는 돌고, 느려질 뿐이다.
import { readdirSync, readFileSync } from 'node:fs';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const MIGRATIONS_DIR = join(
  dirname(fileURLToPath(import.meta.url)),
  '..',
  'prisma',
  'migrations',
);

/**
 * Prisma 가 표현하지 못해 **손으로 관리하는** 객체들. 마이그레이션이 이것을
 * 지우려 하면 거의 확실히 드리프트 오인이다.
 *
 * 정말로 지워야 할 일이 생기면 이 목록에서 빼고, 왜 뺐는지를 커밋에 남길 것.
 */
const MANUAL_INDEXES = [
  {
    name: 'repo_index_chunks_embedding_hnsw_idx',
    what: 'pgvector HNSW 인덱스',
    why: 'AI 코드 질의(설계 §8)의 전제다. 없어도 쿼리는 돌고 느려질 뿐이라 조용히 사라진다.',
  },
];

/** 확장을 지우면 vector 타입을 쓰는 컬럼이 통째로 깨진다. */
const FORBIDDEN_PATTERNS = [
  {
    pattern: /DROP\s+EXTENSION[^;]*\bvector\b/i,
    what: 'pgvector 확장 삭제',
    why: 'vector 타입을 쓰는 컬럼이 통째로 깨진다.',
  },
];

const NEWLINE = String.fromCharCode(10);

/**
 * 주석을 걷어낸다.
 *
 * **줄 주석(`--`)과 블록 주석(`/* *\/`)을 모두 걷어내야 한다.** 왜 그 구문을
 * 빼냈는지 설명하려면 그 구문을 적어야 하고, 실제로 이 저장소의 마이그레이션
 * 들이 그렇게 적어 두었다 — 걷어내지 않으면 **설명이 곧 실패가 된다.**
 * 처음에 줄 주석만 걸렀다가 멀쩡한 마이그레이션 둘을 실패로 잡았다.
 */
function stripComments(sql) {
  return sql
    .replace(/\/\*[\s\S]*?\*\//g, '')
    .split(NEWLINE)
    .filter((line) => !line.trimStart().startsWith('--'))
    .join(NEWLINE);
}

let failures = 0;

function fail(file, what, why, line) {
  failures++;
  console.log(`FAIL  ${file}`);
  console.log(`      ${what} 를 지우는 구문이 있습니다.`);
  console.log(`      ${line.trim()}`);
  console.log(`      ${why}`);
  console.log(
    '      prisma migrate diff 가 드리프트로 오인한 것입니다. 그 줄을 지우고 다시 커밋하십시오.',
  );
}

const dirs = readdirSync(MIGRATIONS_DIR, { withFileTypes: true })
  .filter((entry) => entry.isDirectory())
  .map((entry) => entry.name)
  .sort();

let checked = 0;

for (const dir of dirs) {
  const path = join(MIGRATIONS_DIR, dir, 'migration.sql');
  let sql;
  try {
    sql = readFileSync(path, 'utf8');
  } catch {
    continue; // migration.sql 이 없는 폴더는 건너뛴다
  }
  checked++;

  const lines = stripComments(sql)
    .split(NEWLINE)
    .filter((line) => line.trim().length > 0);

  for (const index of MANUAL_INDEXES) {
    const hit = lines.find(
      (line) => /DROP\s+INDEX/i.test(line) && line.includes(index.name),
    );
    if (hit) fail(`${dir}/migration.sql`, index.what, index.why, hit);
  }

  for (const rule of FORBIDDEN_PATTERNS) {
    const hit = lines.find((line) => rule.pattern.test(line));
    if (hit) fail(`${dir}/migration.sql`, rule.what, rule.why, hit);
  }
}

if (failures === 0) {
  console.log(
    `  OK  마이그레이션 ${checked}개 — 수동 관리 객체를 지우는 구문 없음`,
  );
  process.exit(0);
}

console.log(`${NEWLINE}실패 ${failures}건${NEWLINE}`);
process.exit(1);
