#!/usr/bin/env node
/**
 * server/.env 를 이 PC 에서 만들어 낸다.
 *
 * 두 PC 를 오가며 작업하는데 .env 는 git 으로 옮겨지지 않는다. 그런데 뜯어 보면
 * **옮겨야 할 값이 거의 없다** — 시크릿 셋은 무작위라 PC 마다 새로 만들면 되고
 * (토큰도 DB 도 PC 를 건너가지 않는다), 나머지는 .env.example 이 이미 들고 있는
 * 고정값이다. 그래서 "시크릿을 옮기는 문제"가 아니라 "만들어 내는 문제"로 푼다.
 *
 * 규칙 셋:
 *   1. **이미 채워진 값은 절대 건드리지 않는다.** 여러 번 돌려도 안전하다.
 *   2. **.env.example 에만 있는 키는 덧붙인다.** 옛 .env 를 쓰던 PC 가 새 키를
 *      (PUBLIC_BASE_URL 처럼) 조용히 빠뜨린 채로 남지 않게 한다.
 *   3. **묻지 않는다.** 사람이 채워야 하는 것은 끝에 목록으로 알린다 — 프롬프트를
 *      두면 CI · 후크 같은 비대화형 자리에서 멈춘다.
 *
 * 값은 화면에 찍지 않는다. 키 이름만 찍는다.
 */
import { randomBytes } from 'node:crypto';
import { existsSync, readFileSync, writeFileSync } from 'node:fs';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const serverDir = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const examplePath = join(serverDir, '.env.example');
const envPath = join(serverDir, '.env');

/** 비어 있으면 이 PC 에서 만들어 내는 것들. 길이는 서버가 검사하는 값과 같아야 한다. */
const GENERATED = {
  // config/jwt.config.ts — 폴백이 없어 비면 부팅이 멈춘다.
  JWT_SECRET: () => randomBytes(48).toString('base64url'),
  // 비우면 JWT_SECRET 을 재사용하지만, 나누면 액세스 토큰 유출로 리프레시까지
  // 위조되는 경로가 막힌다. 공짜라서 나눠 둔다.
  JWT_REFRESH_SECRET: () => randomBytes(48).toString('base64url'),
  // config/oauth.config.ts 가 32바이트를 요구한다 — 길이가 틀리면 부팅을 멈춘다.
  // 이 PC 의 DB 에 든 GitHub 토큰만 푸는 키라 PC 마다 달라도 된다.
  OAUTH_TOKEN_KEY: () => randomBytes(32).toString('base64url'),
};

/** 만들어 낼 수 없어 사람이 채우는 것들. 왜 필요한지까지 함께 알린다. */
const MANUAL = {
  GITHUB_CLIENT_ID: 'GitHub OAuth App (Settings → Developer settings → OAuth Apps).',
  GITHUB_CLIENT_SECRET: '위와 같은 앱에서 발급. 콜백이 양쪽 PC 다 localhost 라 PC 마다 따로 등록해도 된다.',
  PUBLIC_BASE_URL:
    '웹훅 자동 등록용. cloudflared tunnel --url http://localhost:3000 의 주소.\n' +
    '        계약 검증(check:oauth · check:browse)만 돌릴 거면 http://127.0.0.1:3000 로 둬도 된다.',
};

if (!existsSync(examplePath)) {
  console.error(`.env.example 이 없다: ${examplePath}`);
  process.exit(1);
}

const example = readFileSync(examplePath, 'utf8');
const created = !existsSync(envPath);
const source = created ? example : readFileSync(envPath, 'utf8');
const eol = source.includes('\r\n') ? '\r\n' : '\n';
const lines = source.split(/\r?\n/);

/** `KEY=value` 줄에서 키를 뽑는다. 주석과 빈 줄은 건너뛴다. */
const keyOf = (line) => {
  const m = /^([A-Za-z_][A-Za-z0-9_]*)=/.exec(line.trim());
  return m ? m[1] : null;
};
const valueOf = (line) => line.slice(line.indexOf('=') + 1).trim();

const present = new Map();
lines.forEach((line, i) => {
  const key = keyOf(line);
  if (key && !present.has(key)) present.set(key, i);
});

const generated = [];
const kept = [];

// 1. 비어 있는 것만 만들어 채운다.
for (const [key, make] of Object.entries(GENERATED)) {
  const at = present.get(key);
  if (at === undefined) continue; // 없는 키는 아래 3에서 덧붙는다
  if (valueOf(lines[at]) !== '') {
    kept.push(key);
    continue;
  }
  lines[at] = `${key}=${make()}`;
  generated.push(key);
}

// 2. .env.example 에만 있는 키를 모은다.
const added = [];
for (const line of example.split(/\r?\n/)) {
  const key = keyOf(line);
  if (key && !present.has(key)) added.push(line.trim());
}

// 3. 덧붙이면서, 그중 만들 수 있는 것은 만들어서 넣는다.
if (added.length) {
  const block = added.map((line) => {
    const key = keyOf(line);
    if (GENERATED[key] && valueOf(line) === '') {
      generated.push(key);
      return `${key}=${GENERATED[key]()}`;
    }
    return line;
  });
  while (lines.length && lines[lines.length - 1].trim() === '') lines.pop();
  lines.push('', '# ── env:setup 이 덧붙였다 (.env.example 에는 있고 이 .env 에는 없던 키) ──', ...block, '');
}

writeFileSync(envPath, lines.join(eol), 'utf8');

// ── 보고 ─────────────────────────────────────────
// 값은 찍지 않는다. 키 이름만.
const say = (s) => console.log(s);
say(created ? '\n.env 를 새로 만들었다 (.env.example 기준).' : '\n.env 가 이미 있어 빈 자리만 채웠다.');
if (generated.length) say(`  만들어 넣음: ${generated.join(' · ')}`);
if (kept.length) say(`  이미 있어 그대로 둠: ${kept.join(' · ')}`);
if (added.length) say(`  .env.example 에서 덧붙임: ${added.map(keyOf).join(' · ')}`);

const missing = Object.keys(MANUAL).filter((key) => {
  const at = present.get(key);
  const line = at === undefined ? added.find((l) => keyOf(l) === key) : lines[at];
  return !line || valueOf(line) === '';
});

if (missing.length) {
  say('\n사람이 채워야 하는 것 — 이것은 만들어 낼 수 없다:');
  for (const key of missing) say(`  ${key}\n        ${MANUAL[key]}`);
  say('\n비워 둬도 서버는 뜬다. GitHub 연결(503)과 웹훅 자동 등록(400)만 막힌다.');
} else {
  say('\n비어 있는 필수 값이 없다. npm run db:up && npm run server:dev 로 간다.');
}
say('');
