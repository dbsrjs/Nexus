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
  // 미이관 모듈은 컴파일되지 않으므로 테스트 대상에서도 뺀다
  // (tsconfig.build.json 의 exclude 와 같은 목록).
  testPathIgnorePatterns: [
    '/node_modules/',
    '/permissions/',
    '/notifications/',
    '/files/',
    '/gitlab/',
    '/ai/',
  ],
};
