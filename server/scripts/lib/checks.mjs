// 계약 검증의 통과/실패 집계와 표시.
//
// **모듈 수준 상태로 충분하다.** 각 스크립트가 자기 프로세스라 모듈이
// 프로세스마다 새로 로드되고, 격리가 공짜다. 팩토리를 만들 이유가 없다.

let pass = 0;
let fail = 0;

export function check(name, ok, detail = '') {
  if (ok) {
    pass++;
    console.log(`  OK  ${name}`);
  } else {
    fail++;
    console.log(`FAIL  ${name} ${detail}`);
  }
}

export function counts() {
  return { pass, fail };
}

/**
 * 집계를 찍고 종료 코드를 세팅한다. **정리에는 관여하지 않는다** —
 * 가짜 서버를 닫고 소켓을 끊는 순서는 스크립트마다 다르고, Windows libuv 의
 * UV_HANDLE_CLOSING 때문에 조심스럽게 짜여 있다.
 *
 * 실패 수를 돌려주는 것은 `process.exit(summary() === 0 ? 0 : 1)` 처럼
 * 쓰기 위함이다 — 소켓이 열려 있어 이벤트 루프가 비지 않는 스크립트는
 * 명시적으로 끝내야 한다.
 *
 * @returns 실패 수
 */
export function summary() {
  console.log(`\n통과 ${pass} · 실패 ${fail}\n`);
  if (fail > 0) process.exitCode = 1;
  return fail;
}
