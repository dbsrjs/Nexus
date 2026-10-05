/**
 * 단위 테스트 설정.
 *
 * **DB 를 띄우지 않는다.** Prisma 는 테스트마다 필요한 메서드만 가짜로 넣는다.
 * 실제 DB 가 필요한 검증은 `npm run check:realtime`(실서버·실DB·실소켓)과
 * 앱 수동 확인이 담당한다 — 두 층의 역할이 다르다:
 *
 *   단위 테스트   순수 로직 · 가드 분기 · 권한 규칙   (빠르고 CI 에서 매번)
 *   실서버 검증   스키마 · 쿼리 · 직렬화             (사람이 필요할 때)
 *
 * 이 경계는 전환 3단계의 교훈에서 나왔다. 스텁만으로 22개를 통과시킨 코드에서
 * 실제 DB 를 붙이자 BigInt 직렬화와 raw SQL 캐스팅 버그가 나왔다
 * (CLAUDE.md §6). 그래서 **단위 테스트로 DB 동작을 증명하려 하지 않는다.**
 */
module.exports = {
  moduleFileExtensions: ['js', 'json', 'ts'],
  rootDir: 'src',
  testRegex: '.*\\.spec\\.ts$',
  transform: {
    '^.+\\.(t|j)s$': 'ts-jest',
  },
  collectCoverageFrom: ['**/*.(t|j)s'],
  coverageDirectory: '../coverage',
  testEnvironment: 'node',
  // 옛 모듈 경로(`/permissions/` · `/files/` · `/gitlab/`)를 걸러 두었다가 지웠다(2026-10-06).
  // 모듈은 이미 다시 쓰였거나 삭제됐고, 남겨 두면 같은 이름으로 새로 만든 모듈의 테스트가
  // **조용히 건너뛰어진다** — 18단계에서 `/notifications/` 로 실제로 겪었다.
  testPathIgnorePatterns: ['/node_modules/'],
};
