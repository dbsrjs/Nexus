// 계약 검증 공용 — DB 를 직접 만진다.
//
// **HTTP 로 만들 수 없는 상태를 흉내 낼 때만 쓴다.** 계약 검증은 API 가 약속한
// 것을 API 로 확인하는 것이 원칙이고, 여기를 부르는 곳은 그 원칙으로는 닿지
// 않는 자리다:
//
//   · 기록된 임베딩 모델 바꾸기 — 서버의 모델을 실행 중에 바꿀 수 없다(check:indexing)
//   · 리스가 만료된 `running` 행 — 프로세스가 작업 도중 죽은 뒤를 흉내 낸다(check:ai ·
//     check:indexing). 서버를 대신 죽일 수 없다
//   · 시도 횟수 읽기 — 응답에 싣지 않는 값이다(check:ai)
//
// **@prisma/client 는 이 함수 안에서만 불러온다** — DB 를 만지지 않는 케이스가
// 접속 설정에 묶이지 않게 한다. `DATABASE_URL` 은 CI 에서는 잡의 환경변수로 오고,
// 로컬에서는 `server/.env` 에서 읽는다(`npm run` 을 저장소 루트에서 돌리므로
// Prisma 가 스스로 찾으리라 기대하지 않는다).

let client = null;

async function prisma() {
  if (client) return client;
  if (!process.env.DATABASE_URL) {
    try {
      process.loadEnvFile(new URL('../../.env', import.meta.url));
    } catch {
      // 없으면 아래 PrismaClient 가 알아듣는 오류로 던진다.
    }
  }
  const { PrismaClient } = await import('@prisma/client');
  client = new PrismaClient();
  return client;
}

/** `fn(prisma)` 를 돌린다. 연결은 스크립트가 끝날 때 `closeDb()` 로 닫는다. */
export async function withDb(fn) {
  return fn(await prisma());
}

/** 열린 연결을 닫는다. 열지 않았으면 아무것도 하지 않는다 — 끝에서 늘 불러도 된다. */
export async function closeDb() {
  if (!client) return;
  await client.$disconnect();
  client = null;
}

/**
 * 지금부터 `ms` 뒤의 시각. **UTC 로 쓰인다** — Prisma 가 `Date` 를
 * `timestamp without time zone` 에 UTC 로 쓰고, 큐의 리스 비교도 UTC 다
 * (CLAUDE.md §2 · `check:sql-time`). 음수면 과거다.
 */
export function fromNow(ms) {
  return new Date(Date.now() + ms);
}
