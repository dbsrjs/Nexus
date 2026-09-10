// raw SQL 이 **DB 의 시계**(`now()` · `CURRENT_TIMESTAMP`)를 쓰는지 검사한다.
//
// 사용: npm run check:sql-time   (DB 도 서버도 필요 없다 — 파일만 읽는다)
//
// 왜 필요한가:
//   이 스키마의 시각 컬럼은 전부 `TIMESTAMP(3)` = **`timestamp without time
//   zone`** 이고, **Prisma 는 거기에 UTC 를 쓴다.** 그런데 Postgres 의
//   `now()` 를 그 타입으로 받으면 **DB 의 로컬 시간**이 들어온다.
//
//   개발 PC 의 Postgres 가 `Asia/Seoul` 이라 아홉 시간이 어긋났고,
//   `lease_until < now()` 가 **언제나 참**이 됐다 — 인덱싱 리스가 한 번도
//   아무것도 막지 못했다(2026-09-10 발견). 실패 뒤 물러서야 할 자리에서
//   초당 한 번씩 재시도하는 회전이 됐고, 돌고 있는 작업을 다른 인스턴스가
//   곧바로 가져갈 수 있었다.
//
//   **테스트로 잡을 수 없는 종류다.** 단위 테스트에는 DB 가 없고, 계약 검증은
//   가짜 GitHub 상대라 전부 빨리 성공해 물러설 일이 자체가 없었다. CI 서버가
//   UTC 면 로컬에서만 틀리고 CI 는 초록이다 — 그래서 정적으로 잡는다.
//
//   쓰려면 `(now() at time zone 'utc')` 를 쓸 것. Prisma 가 쓰는 값과 같은
//   기준이 된다.
import { readdirSync, readFileSync, statSync } from 'node:fs';
import { join, dirname, relative } from 'node:path';
import { fileURLToPath } from 'node:url';

const SRC_DIR = join(dirname(fileURLToPath(import.meta.url)), '..', 'src');
const NEWLINE = String.fromCharCode(10);

/**
 * Prisma 의 raw SQL 진입점. 이 뒤에 오는 템플릿 문자열만 본다.
 *
 * **제네릭을 정규식으로 건너뛰려 하지 않는다.** 처음에 `<[^>]*>` 로 썼다가
 * `$queryRaw<Array<{ repo_id: string }>>` 처럼 **중첩된 제네릭**에서 깨져
 * `lease()` 의 SQL 을 통째로 놓쳤다 — 일부러 심은 버그를 검사가 못 잡아서
 * 알았다. 여는 백틱은 아래에서 꺾쇠 깊이를 세며 찾는다.
 */
const RAW_CALLS = /\$(?:queryRaw|executeRaw)(?:Unsafe)?\b/g;

/**
 * 금지 패턴. **`at time zone` 이 붙은 것은 통과시킨다** — 그것이 올바른 형태다.
 */
// **끝에 `\b` 를 두지 않는다.** `now()` 다음 글자가 `)` 면 둘 다 비단어라
// 단어 경계가 성립하지 않아 매칭이 통째로 빗나간다 — 일부러 심은 버그를 검사가
// 못 잡아서 알았다.
const BAD_CLOCK = /(\bnow\s*\(\s*\)|\bcurrent_timestamp\b)/gi;
const GOOD_FORM = /\(\s*now\s*\(\s*\)\s+at\s+time\s+zone\s+'utc'\s*\)/gi;

/** TS 주석을 걷어낸다 — 왜 쓰면 안 되는지 설명하려면 그 구문을 적어야 한다. */
function stripComments(source) {
  return source
    .replace(/\/\*[\s\S]*?\*\//g, '')
    .split(NEWLINE)
    .map((line) => line.replace(/\/\/.*$/, ''))
    .join(NEWLINE);
}

/** `src` 아래 모든 .ts (spec 제외 — 목이라 DB 를 안 탄다). */
function walk(dir, out = []) {
  for (const entry of readdirSync(dir)) {
    const path = join(dir, entry);
    if (statSync(path).isDirectory()) walk(path, out);
    else if (entry.endsWith('.ts') && !entry.endsWith('.spec.ts')) out.push(path);
  }
  return out;
}

/**
 * 호출 이름 뒤에서 **여는 백틱**을 찾는다.
 *
 * 사이에 낄 수 있는 것은 공백과 제네릭(`<…>`)뿐이다. 꺾쇠 깊이를 세므로
 * `<Array<{ repo_id: string }>>` 같은 중첩도 지나간다. 그 밖의 글자가 나오면
 * 템플릿 호출이 아니다(예: `$queryRawUnsafe(sql)`) — 그 경우는 SQL 이 변수라
 * 정적으로 볼 것이 없으므로 건너뛴다.
 */
function openingBacktick(source, from) {
  let depth = 0;
  for (let k = from; k < source.length; k++) {
    const ch = source[k];
    if (ch === '`' && depth === 0) return k;
    if (ch === '<') depth++;
    else if (ch === '>') depth--;
    else if (depth === 0 && !/\s/.test(ch)) return -1;
  }
  return -1;
}

/**
 * raw SQL 호출 뒤의 템플릿 문자열을 통째로 잘라 낸다.
 *
 * **중첩 백틱을 세면서 읽는다** — `${UTC_NOW}` 처럼 보간이 들어가고 그 안에
 * 또 템플릿이 있을 수 있다. 정규식 하나로 끝내려 하면 첫 백틱에서 끊긴다.
 */
function rawSqlBlocks(source) {
  const blocks = [];
  RAW_CALLS.lastIndex = 0;
  let match;
  while ((match = RAW_CALLS.exec(source)) !== null) {
    const i = openingBacktick(source, match.index + match[0].length);
    if (i === -1) continue;
    let depth = 0;
    let end = -1;
    for (let k = i + 1; k < source.length; k++) {
      if (source[k] === '\\') {
        k++;
        continue;
      }
      if (source[k] === '`') {
        if (depth === 0) {
          end = k;
          break;
        }
        depth--;
      } else if (source[k] === '$' && source[k + 1] === '{') {
        // 보간 안에 또 템플릿이 있을 수 있다.
        const nested = source.indexOf('`', k);
        const close = source.indexOf('}', k);
        if (nested !== -1 && nested < close) depth++;
      }
    }
    if (end === -1) continue;
    blocks.push({ sql: source.slice(i + 1, end), at: match.index });
  }
  return blocks;
}

let failures = 0;
let checked = 0;

for (const path of walk(SRC_DIR)) {
  const source = stripComments(readFileSync(path, 'utf8'));
  const blocks = rawSqlBlocks(source);
  if (blocks.length === 0) continue;
  checked += blocks.length;

  for (const block of blocks) {
    // 올바른 형태를 먼저 지운 뒤에 남은 것만 본다.
    const rest = block.sql.replace(GOOD_FORM, '');
    BAD_CLOCK.lastIndex = 0;
    const hit = BAD_CLOCK.exec(rest);
    if (!hit) continue;

    failures++;
    const line = source.slice(0, block.at).split(NEWLINE).length;
    console.log(`FAIL  ${relative(SRC_DIR, path)}:${line}`);
    console.log(`      raw SQL 이 DB 의 시계(${hit[0]})를 씁니다.`);
    console.log(
      '      이 스키마의 시각 컬럼은 timestamp without time zone 이고 Prisma 는 거기에 UTC 를 씁니다.',
    );
    console.log(
      "      DB 의 타임존이 UTC 가 아니면 비교가 통째로 어긋납니다. (now() at time zone 'utc') 를 쓰십시오.",
    );
  }
}

if (failures === 0) {
  console.log(`  OK  raw SQL ${checked}개 — DB 시계를 그대로 쓰는 곳 없음`);
  process.exit(0);
}

console.log(`${NEWLINE}실패 ${failures}건${NEWLINE}`);
process.exit(1);
