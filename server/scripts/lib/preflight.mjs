// 계약 검증 스크립트의 공용 전제조건 검사.
//
// **왜 있는가.** 2026-08-21, server/.env 에 PUBLIC_BASE_URL 이 없다는 이유로
// check:browse 가 37개 실패로 무너졌다. 화면에 보인 것은 빨간 줄 37개였고,
// 원인은 그중 첫 줄의 400 응답 본문 안에만 있었다.
//
// 진짜 문제는 설정이 아니라 **준비 단계의 실패를 케이스 실패로 취급한 것**이다.
// 준비가 안 됐으면 뒤의 케이스들은 "틀린 것"이 아니라 **검증하지 못한 것**이다.
// 둘을 같은 FAIL 로 찍으면 읽는 사람이 원인을 찾지 못한다.

/**
 * 준비 단계가 무너졌을 때 던진다. 각 스크립트의 최상위 catch 가 받아
 * 가짜 서버를 닫은 뒤 종료 코드를 세팅한다 — 그 정리 경로를 그대로 쓰려고
 * 예외로 만들었다. 여기서 process.exit() 를 부르면 열려 있는 핸들과 경합해
 * Windows 에서 UV_HANDLE_CLOSING 으로 죽는다.
 */
export class PreflightAbort extends Error {
  constructor(reason, hint) {
    super(reason);
    this.name = 'PreflightAbort';
    this.reason = reason;
    this.hint = hint ?? null;
  }
}

/**
 * 알려진 실패를 알아보고 어디를 봐야 하는지 알려 준다.
 *
 * **실제로 겪은 것만 넣는다.** 겪지 않은 실패에 힌트를 붙이면 확인할 수 없는
 * 가정 위에 코드를 쌓게 되고, 틀린 힌트는 없느니만 못하다. 모르는 실패는
 * 서버가 준 메시지를 그대로 보여 주는 것으로 충분하다.
 */
export function hintFor(json) {
  const message =
    json && typeof json === 'object' && typeof json.message === 'string'
      ? json.message
      : '';

  if (message.includes('PUBLIC_BASE_URL')) {
    return [
      'server/.env 에 PUBLIC_BASE_URL 이 없습니다.',
      '',
      '계약 검증에서는 아무 http 주소면 됩니다 — 가짜 GitHub 이 훅 URL 을',
      '검사하지 않습니다:',
      '',
      '  PUBLIC_BASE_URL=http://127.0.0.1:3000',
      '',
      '값을 넣은 뒤 서버를 **재시작**해야 합니다(.env 는 부팅 때 읽습니다).',
      '자세한 것은 docs/10-2a-인수인계.md §2.3 을 볼 것.',
    ].join('\n');
  }

  return null;
}

/** 준비 단계 호출이 실패하면 중단한다. 뒤를 더 돌아 봐야 읽을 것이 없다. */
export function abortUnless(ok, reason, json) {
  if (ok) return;
  throw new PreflightAbort(reason, hintFor(json));
}

/**
 * 서버가 떠 있는지 확인한다. 안 떠 있으면 한 줄로 안내하고 끝낸다.
 *
 * /api/me 는 인증이 필요해 401 이 온다 — 여기서 보려는 것은 "서버가
 * 답하는가" 하나다. 이 시점에는 소켓도 가짜 서버도 아직 열리지 않아
 * 열린 핸들이 없으므로 process.exit() 가 안전하다.
 */
export async function requireServer(base) {
  try {
    await fetch(`${base}/me`, { signal: AbortSignal.timeout(3000) });
    return;
  } catch {
    /* 아래에서 안내한다 */
  }

  console.error('');
  console.error(`서버에 닿지 못했습니다 — ${base}`);
  console.error('');
  console.error('계약 검증은 실제로 부팅한 서버에 밖에서 붙습니다. 먼저 띄우십시오:');
  console.error('');
  console.error('  npm run db:up        (다른 터미널)');
  console.error('  npm run server:dev   (다른 터미널)');
  console.error('');
  process.exit(1);
}
