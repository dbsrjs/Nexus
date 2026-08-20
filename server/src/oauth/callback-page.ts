/**
 * 브라우저에 그릴 페이지 두 장. 템플릿 엔진을 들이지 않는다 — 페이지가 둘뿐이다.
 *
 * 앱은 이 화면을 보지 않는다. 연결 성공은 소켓(`oauth:connected`)으로 알고,
 * 실패는 아무것도 오지 않는 것으로 안다 (설계 §2).
 */
function page(title: string, message: string, accent: string): string {
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
</style>
</head>
<body><main><h1>${title}</h1><p>${message}</p></main></body>
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
