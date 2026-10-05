/**
 * 브라우저에 그릴 페이지 두 장. 템플릿 엔진을 들이지 않는다 — 페이지가 둘뿐이다.
 *
 * 앱은 이 화면을 보지 않는다. 연결 성공은 소켓(`oauth:connected`)으로 알고,
 * 실패는 아무것도 오지 않는 것으로 안다 (설계 §2).
 */
function page(title: string, message: string, accent: string, extra = ''): string {
  return `<!doctype html>
<html lang="ko">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>${title} · Nexus</title>
<style>
  body { margin:0; min-height:100vh; display:grid; place-items:center;
         background:#0f1115; color:#e6e8ec;
         font-family:'Pretendard','Segoe UI',system-ui,sans-serif; }
  main { text-align:center; padding:32px; }
  h1 { font-size:20px; margin:0 0 8px; color:${accent}; }
  p  { margin:0; font-size:14px; color:#9aa1ad; }
  strong { color:#e6e8ec; }
  form { margin-top:20px; }
  button { font:inherit; font-size:14px; padding:10px 20px; border:0; border-radius:8px;
           background:#5b8def; color:#fff; cursor:pointer; }
  .hint { margin-top:16px; font-size:12px; }
</style>
</head>
<body><main><h1>${title}</h1><p>${message}</p>${extra}</main></body>
</html>`;
}

export const CALLBACK_SUCCESS_HTML = page(
  'GitHub 을 연결했습니다',
  '이 창을 닫고 Nexus 로 돌아가세요.',
  '#7dd3a0',
);

export const CALLBACK_FAILURE_HTML = page(
  '연결하지 못했습니다',
  '이 창을 닫고 Nexus 에서 다시 시도해 주세요.',
  '#f2777a',
);

/**
 * 연결 확인 화면(2026-10-05 보안 점검). **GET 콜백은 연결하지 않는다** — 이 화면만 그리고,
 * 사람이 [연결] 을 눌러야 POST 로 토큰을 교환한다.
 *
 * `state` 는 연결을 **시작한 Nexus 계정**에 묶여 있을 뿐 **이 브라우저**에 묶여 있지 않다.
 * 앱이 시스템 브라우저를 여는 구조라 쿠키로 묶을 수 없다. 그래서 남이 시작한 연결 주소를
 * 열면, 이 OAuth 앱을 이미 승인한 사람에게는 GitHub 이 화면 없이 돌려보내 **내 GitHub 토큰이
 * 남의 계정에 붙었다.** 어느 계정에 붙는지 보여 주고 한 번 더 누르게 해 그 경로를 끊는다.
 *
 * 값은 전부 사용자 입력이다(이름 · 쿼리스트링) — 반드시 이스케이프한다. 스크립트는 쓰지 않는다
 * (CSP 가 막는다).
 */
export function confirmPage(
  account: { name: string; email: string },
  code: string,
  state: string,
): string {
  const who = `<strong>${escapeHtml(account.name)}</strong> (${escapeHtml(maskEmail(account.email))})`;
  return page(
    'GitHub 연결 확인',
    `Nexus 계정 ${who} 에 이 GitHub 계정을 연결합니다.`,
    '#e6e8ec',
    `<form method="post" action="callback">
<input type="hidden" name="code" value="${escapeHtml(code)}">
<input type="hidden" name="state" value="${escapeHtml(state)}">
<button type="submit">연결</button>
</form>
<p class="hint">내 계정이 아니면 누르지 말고 이 창을 닫으세요.</p>`,
  );
}

/**
 * 확인 화면은 폼을 내보내야 한다. 전역 CSP 의 `sandbox` 는 폼 전송을 막으므로 이 화면만
 * 폼을 같은 오리진으로 보내는 것을 연다. 스크립트는 여전히 막혀 있다.
 */
export const CONFIRM_PAGE_CSP =
  "default-src 'none'; style-src 'unsafe-inline'; form-action 'self'; frame-ancestors 'none'";

/** `ab***@example.com` — 내 계정인지 알아볼 만큼만 보인다. */
export function maskEmail(email: string): string {
  const at = email.lastIndexOf('@');
  if (at <= 0) return '***';
  const local = email.slice(0, at);
  return `${local.slice(0, Math.min(2, local.length))}***${email.slice(at)}`;
}

export function escapeHtml(value: string): string {
  return value
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#39;');
}
