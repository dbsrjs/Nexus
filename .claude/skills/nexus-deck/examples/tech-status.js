// Nexus 기술 진행 현황 — 무엇을 했고 무엇이 남았나 (10장)
//
// 2026-09-11 에 실제로 발표한 덱이다. 새 덱을 만들 때 레이아웃을 여기서 골라
// 베껴 쓴다 — 어느 장이 어떤 패턴인지는 ../SKILL.md 「레이아웃 패턴」 표.
// 숫자 · 날짜 · 커밋은 그날의 사실이라 그대로 가져다 쓰면 틀린다.
//
// 실행: pptxgenjs 를 설치한 작업 폴더에서
//   node <저장소>/.claude/skills/nexus-deck/examples/tech-status.js 출력.pptx
const { makeDeck, C, F, MONO, M, W, CW } = require('../scripts/lib');

const { pres, text, lightSlide, coverSlide, closingSlide, card, box, titled, bullets, save } = makeDeck('Nexus — 기술 진행 현황');

// 오른쪽 "스택" 카드 — 서버 · 앱 두 장이 같은 모양을 쓴다
function stackCard(s, x, y, w, h, lines, foot) {
  card(s, x, y, w, h);
  text(s, '스택', { x: x + 0.3, y: y + 0.25, w: w - 0.6, h: 0.3, fontSize: 11, bold: true, color: C.accent });
  s.addText(
    lines.map((l, i) => ({ text: l, options: { breakLine: i < lines.length - 1 } })),
    { x: x + 0.3, y: y + 0.62, w: w - 0.6, h: h - 1.2, fontFace: MONO, fontSize: 12, color: C.ink, margin: 0, paraSpaceAfter: 5, valign: 'top', isTextBox: true },
  );
  if (foot) text(s, foot, { x: x + 0.3, y: y + h - 0.55, w: w - 0.6, h: 0.35, fontSize: 10, color: C.muted, valign: 'bottom' });
}

// 왼쪽 결정 목록 — 제목 한 줄 + 설명 한두 줄
function decisions(s, items, { x = M, y = 1.95, w = 5.6, step = 0.76 } = {}) {
  items.forEach(([t, b], i) => titled(s, x, y + i * step, w, step - 0.05, t, b, { titleSize: 13.5, bodySize: 11 }));
}

// ═════════════════════════════════════════════════
// 01 표지
// ═════════════════════════════════════════════════
coverSlide({
  title: 'Nexus',
  subtitle: '기술 진행 현황',
  tagline: '만든 것과 남은 것',
  footLeft: '2026-09-11 · main 22faa2c',
  notes: '이번에는 기술적인 이야기를 합니다. 1단계부터 12단계까지 무엇을 어떻게 만들었는지, 그리고 무엇이 남았는지입니다.',
});

// ═════════════════════════════════════════════════
// 02 한눈에
// ═════════════════════════════════════════════════
{
  const s = lightSlide('진행 현황', '12단계 완료, 12월 말까지 남은 다섯 묶음',
    '공식 일정은 12월 말까지입니다. 서버 기반, 앱과 오프라인, 대화·파일·이슈, GitHub 연동, 인덱싱까지 12단계가 끝났고, AI · 채널 권한 · DM · 알림 · 배포 준비 다섯 묶음이 남았습니다. 계약 검증 508 케이스가 CI 에서 push 마다 돌고, 테스트는 서버 단위 테스트 251개와 앱 테스트 252개입니다.');

  const nodes = [
    ['1–4', '서버', true],
    ['5–6', '앱', true],
    ['7–9', '기능', true],
    ['10–11', 'GitHub', true],
    ['12', '인덱싱', true],
    ['13', 'AI', false],
    ['14', '권한', false],
    ['15', 'DM', false],
    ['16', '알림', false],
    ['12월', '배포', false],
  ];
  const y = 2.35;
  const x0 = M + 0.6;
  const span = CW - 1.2;
  const step = span / (nodes.length - 1);
  // 선: 끝난 구간은 강조색, 남은 구간은 회색
  const lastDone = nodes.filter((n) => n[2]).length - 1;
  s.addShape(pres.shapes.LINE, { x: x0, y, w: step * lastDone, h: 0, line: { color: C.accent, width: 2 } });
  s.addShape(pres.shapes.LINE, { x: x0 + step * lastDone, y, w: step * (nodes.length - 1 - lastDone), h: 0, line: { color: C.hair, width: 2, dashType: 'dash' } });
  nodes.forEach(([n, l, done], i) => {
    const cx = x0 + i * step;
    const r = 0.13;
    s.addShape(pres.shapes.OVAL, {
      x: cx - r, y: y - r, w: r * 2, h: r * 2,
      fill: { color: done ? C.accent : C.bg }, line: { color: done ? C.accent : C.line, width: 1.5 },
    });
    // 점이 열 개라 칸 폭이 좁다 — 라벨은 점 간격 안에서 가운데로
    text(s, n, { x: cx - step / 2, y: y + 0.25, w: step, h: 0.28, fontSize: 11, bold: true, color: done ? C.ink : C.muted, align: 'center' });
    text(s, l, { x: cx - step / 2, y: y + 0.53, w: step, h: 0.28, fontSize: 10.5, color: C.muted, align: 'center' });
  });

  const stats = [
    ['242', '커밋'],
    ['508', '계약 검증 케이스'],
    ['503', '서버 · 앱 테스트'],
    ['3', 'CI 잡 · push 마다'],
  ];
  const gap = 0.3;
  const sw = (CW - gap * 3) / 4;
  stats.forEach(([n, l], i) => {
    const x = M + i * (sw + gap);
    card(s, x, 3.75, sw, 1.2);
    text(s, n, { x: x + 0.25, y: 3.9, w: sw - 0.5, h: 0.55, fontSize: 26, bold: true, color: C.accent, valign: 'bottom' });
    text(s, l, { x: x + 0.25, y: 4.5, w: sw - 0.5, h: 0.3, fontSize: 11, color: C.muted });
  });
}

// ═════════════════════════════════════════════════
// 03 서버 기반 (1–4)
// ═════════════════════════════════════════════════
{
  const s = lightSlide('1–4단계 · 서버 기반', '스키마 재작성, 테넌트 경계부터 세운 기반',
    '사내 메신저였던 코드베이스를 개인 프로젝트로 돌리면서 스키마를 통째로 다시 썼습니다. Space 가 모든 데이터의 루트이고, 인증은 리프레시 토큰 회전과 재사용 탐지로 바꿨습니다. 실시간은 앱보다 먼저 넣었습니다 — 나중에 붙이면 앱 상태 계층을 다시 써야 하기 때문입니다.');
  decisions(s, [
    ['스키마 재작성', 'Space 가 루트 · 스페이스 소속 테이블은 예외 없이 spaceId 직접 보유'],
    ['인증 개편', '리프레시 토큰 회전 · 재사용을 탐지하면 family 전체 무효화'],
    ['가드 체인', 'JwtAuthGuard → SpaceGuard → SpaceRoleGuard · 비멤버는 404'],
    ['실시간을 앱보다 먼저', '핸드셰이크 인증 · 룸 · rooms:sync / invalidate · message:* 브로드캐스트'],
  ]);
  stackCard(s, M + 6.0, 1.95, CW - 6.0, 2.95, ['NestJS 10', 'Prisma 5', 'PostgreSQL 18', 'pgvector 0.8.1', 'Socket.IO 4'], '멀티테넌트 · 단일 DB');
}

// ═════════════════════════════════════════════════
// 04 앱 (5–6)
// ═════════════════════════════════════════════════
{
  const s = lightSlide('5–6단계 · 앱과 오프라인', 'Flutter 한 벌, 로컬 DB 만 구독하는 화면',
    '앱은 Flutter 한 코드베이스로 Windows, Android, Web 을 덮습니다. 화면은 서버를 직접 보지 않고 로컬 DB 인 drift 만 구독합니다. 보내기는 전송 큐에 넣는 일이라 오프라인에서 쓴 메시지도 재연결 때 쓴 순서대로 나갑니다.');
  decisions(s, [
    ['화면은 drift 만 구독', 'REST · 소켓은 로컬 DB 갱신만 담당 · 오프라인 표시와 실시간 갱신이 한 경로'],
    ['보내기 = 큐에 넣기', '큐는 캐시와 별도 테이블(사용자가 쓴 유일본) · 순서는 삽입 순번 seq 기준'],
    ['시각은 UTC 마이크로초 정수', 'drift 기본(초 단위) · 텍스트 저장 모두 실제 순서 버그 발생'],
    ['폭 분기는 한 곳에서만', 'mobile · tablet · desktop 분기는 app_shell 에서만 · 안쪽 위젯은 폭과 무관'],
  ]);
  stackCard(s, M + 6.0, 1.95, CW - 6.0, 2.95, ['Flutter 3.44+', 'Riverpod 3', 'go_router 17', 'drift 2', 'freezed 3'], 'Windows · Android · Web');
}

// ═════════════════════════════════════════════════
// 05 대화 · 파일 · 이슈 (7–9)
// ═════════════════════════════════════════════════
{
  const s = lightSlide('7–9단계 · 대화 · 파일 · 이슈', '완료 기준은 서버부터 화면까지',
    '7단계부터는 작업 단위를 계층이 아니라 기능으로 바꿨습니다. 한 기능이 서버에서 화면까지 끝나야 완료로 칩니다. 첨부는 서명 URL 을 발급하지 않고 언제나 서버를 통해 스트리밍하고, 이슈 키는 세지 않고 발급합니다.');
  const cols = [
    // 좁은 카드라 한 줄에 들어가게(10.5pt 에서 16자 안팎) 줄였다
    ['7단계', '대화', ['리액션 · 스레드 · 답장', '멘션 · 핀 고정', '멘션 저장 형식 <@id>', '메시지 · 멘션 한 트랜잭션']],
    ['8단계', '첨부', ['로컬 ↔ S3 · R2 드라이버', '서명 URL 없이 스트리밍', '업로드 먼저 · 전송 때 연결', '고아 정리가 유일한 자동 삭제']],
    ['9단계', '이슈', ['키는 UPDATE…RETURNING', '자리 소진 시 재채번', '칸반 · 라벨 · 스프린트', '번다운은 closedAt 역산']],
  ];
  const gap = 0.3;
  const cw = (CW - gap * 2) / 3;
  cols.forEach(([tag, t, items], i) => {
    const x = M + i * (cw + gap);
    card(s, x, 1.95, cw, 2.15);
    text(s, tag, { x: x + 0.28, y: 2.15, w: 1.5, h: 0.25, fontSize: 10, bold: true, color: C.accent });
    text(s, t, { x: x + 0.28, y: 2.42, w: cw - 0.56, h: 0.4, fontSize: 16, bold: true, color: C.ink });
    bullets(s, x + 0.28, 2.95, cw - 0.45, 1.3, items, { size: 10.5, color: C.muted, gap: 3 });
  });
  text(s, '그 사이에 — 마크다운 · 코드 하이라이팅 · UI 리디자인 · 테마 토글', {
    x: M, y: 4.45, w: CW, h: 0.3, fontSize: 11, color: C.muted,
  });
}

// ═════════════════════════════════════════════════
// 06 GitHub 연동 (10–11)
// ═════════════════════════════════════════════════
{
  const s = lightSlide('10–11단계 · GitHub 연동', 'GitHub 이 원본, 사본 없는 프록시',
    'GitHub 연동은 세 조각입니다. 웹훅 수신은 서명이 곧 인증이라 원문 바이트로 검증합니다. 계정 연결은 state 를 저장하지 않고 서명하며, 토큰은 AES-256-GCM 으로 암호화합니다. 저장소 · 커밋 · PR 열람은 전부 프록시이고, push 웹훅에 이미 들어 있는 커밋 목록은 GitHub 을 다시 부르지 않습니다.');
  const rows = [
    ['10-1', '웹훅 수신', '서명이 곧 인증 — 원문 바이트로 HMAC, timingSafeEqual 비교 · X-GitHub-Delivery 로 중복 배달 차단'],
    ['10-2', '계정 연결', 'OAuth state 는 저장 없이 서명(purpose 검사) · 토큰은 AES-256-GCM 암호화 · 콜백은 소켓 개인 룸으로 통지'],
    ['10-3 · 11', '열람', '브랜치 · 트리 · 파일 · 커밋 · PR 전부 프록시 · push 의 커밋 목록은 페이로드에 있어 GitHub 호출 0회'],
  ];
  const rh = 0.88, rg = 0.16;
  rows.forEach(([tag, t, b], i) => {
    const y = 1.95 + i * (rh + rg);
    card(s, M, y, CW, rh);
    text(s, tag, { x: M + 0.3, y: y + 0.17, w: 1.4, h: 0.25, fontFace: MONO, fontSize: 11, bold: true, color: C.accent });
    text(s, t, { x: M + 0.3, y: y + 0.42, w: 1.8, h: 0.32, fontSize: 14, bold: true, color: C.ink });
    text(s, b, { x: M + 2.3, y, w: CW - 2.6, h: rh, fontSize: 11.5, color: C.muted, valign: 'middle', lineSpacingMultiple: 1.15 });
  });
}

// ═════════════════════════════════════════════════
// 07 이번 주 (9/7 – 9/11) — 곧 12단계 인덱싱이다
// ═════════════════════════════════════════════════
{
  const s = lightSlide('이번 주 · 9/7 – 9/11', '12단계 구현과 실제 환경 검증',
    '이번 주 작업은 전부 12단계 저장소 인덱싱입니다. 화요일에 설계와 구현 계획을 쓰고 큐 · 청킹 · 워커 · 검색 API 를 만들었고, 수요일에 실제 임베딩 어댑터와 증분 재인덱싱을 붙여 main 에 합친 뒤 CI 에서 드러난 경합을 고쳤습니다. 목요일에는 진짜 GitHub 저장소와 진짜 임베딩 모델로 끝까지 태웠는데, 계약 검증이 모두 초록인 상태에서 결함 넷이 나왔고 임베딩 모델을 세 번 바꿨습니다. 금요일에는 이 발표 자료를 만들었습니다.');

  const days = [
    ['화 9/8', '설계 · 구현', ['설계 · 구현 계획 문서', 'DB 큐 · 청킹 · 파일 선별', '재귀 트리 · 워커 · 검색 API', '계약 검증 추가']],
    ['수 9/9', '증분 · 병합', ['Gemini · Ollama 어댑터', 'push → compare 증분', '청크 삭제 누락 · 거짓 통과', 'main 병합 · CI 경합 수정']],
    ['목 9/10', '실제 환경 검증', ['실제 GitHub · 임베딩 완주', '리스 UTC / KST 결함 수정', '문서 · 질의 신호 · 429 흡수', 'embeddinggemma 로 교체']],
  ];
  const gap = 0.3;
  const cw = (CW - gap * 2) / 3;
  days.forEach(([d, t, items], i) => {
    const x = M + i * (cw + gap);
    const focus = i === 2;
    card(s, x, 1.95, cw, 2.15, focus ? C.ink : C.soft);
    text(s, d, { x: x + 0.28, y: 2.15, w: 1.5, h: 0.25, fontSize: 10, bold: true, color: focus ? C.dAccent : C.accent });
    text(s, t, { x: x + 0.28, y: 2.42, w: cw - 0.56, h: 0.4, fontSize: 16, bold: true, color: focus ? 'FFFFFF' : C.ink });
    bullets(s, x + 0.28, 2.95, cw - 0.45, 1.1, items, { size: 10.5, color: focus ? C.onInk : C.muted, gap: 3 });
  });

  // 한 주의 결과 — 숫자 넷
  const stats = [
    ['35', '커밋'],
    ['188 → 251', '서버 단위 테스트'],
    ['474 → 508', '계약 검증 케이스'],
    ['1,939', '청크 · 5위 안 8/10'],
  ];
  const sg = 0.3;
  const sw = (CW - sg * 3) / 4;
  stats.forEach(([n, l], i) => {
    const x = M + i * (sw + sg);
    text(s, n, { x, y: 4.3, w: sw, h: 0.42, fontSize: 20, bold: true, color: C.accent, valign: 'bottom' });
    text(s, l, { x, y: 4.72, w: sw, h: 0.26, fontSize: 10.5, color: C.muted });
  });
}

// ═════════════════════════════════════════════════
// 08 검증 체계
// ═════════════════════════════════════════════════
{
  const s = lightSlide('검증', 'CI 에서 실서버 · 실DB 로 계약 검증',
    'CI 는 세 잡입니다. 서버 잡이 린트, 빌드, 단위 테스트와 정적 검사 둘을 돌리고, 앱 잡이 분석과 테스트, 그리고 코드 생성 결과가 최신인지를 봅니다. 가장 중요한 것은 서버 통합 잡입니다 — Postgres 와 pgvector 컨테이너를 띄우고 실제 서버를 기동해 계약 검증 14종 508 케이스를 돌립니다.');
  const jobs = [
    ['server', ['lint · build', '단위 테스트 251', '정적 검사 2종'], false],
    ['app', ['flutter analyze', '코드 생성 결과 최신 여부', '테스트 252'], false],
    ['server-integration', ['pgvector DB 컨테이너', '실제 서버 기동', '계약 검증 14종 · 508 케이스'], true],
  ];
  const gap = 0.35;
  const jw = (CW - gap * 2) / 3;
  jobs.forEach(([n, items, focus], i) => {
    const x = M + i * (jw + gap);
    box(s, x, 1.95, jw, 1.8, { fill: focus ? C.ink : C.bg, border: focus ? C.ink : C.hair });
    text(s, n, { x: x + 0.28, y: 2.12, w: jw - 0.5, h: 0.32, fontFace: MONO, fontSize: 12.5, bold: true, color: focus ? 'FFFFFF' : C.ink });
    bullets(s, x + 0.28, 2.58, jw - 0.5, 1.1, items, { size: 11, color: focus ? C.onInk : C.muted, gap: 4 });
  });

  card(s, M, 4.0, CW, 0.95);
  s.addText(
    [
      { text: '스텁으로 22개를 통과한 코드가 실제 DB 에서 곧바로 500 두 건', options: { bold: true, color: C.ink, breakLine: true } },
      { text: '이후 쿼리 변경은 실제 DB 로만, 화면은 Windows 에서 육안 확인', options: { color: C.muted, paraSpaceBefore: 3 } },
    ],
    { x: M + 0.3, y: 4.0, w: CW - 0.6, h: 0.95, fontFace: F, fontSize: 11.5, valign: 'middle', margin: 0, isTextBox: true },
  );
}

// ═════════════════════════════════════════════════
// 09 남은 작업 — 12월 말까지의 일정
// ═════════════════════════════════════════════════
{
  const s = lightSlide('남은 작업 · 12월 말 마감', '12월 말까지, 기획서 MUST 전부 일정 반영',
    '공식 일정은 12월 말까지입니다. 지난 발표에서 "범위 밖"이라고 적은 DM, 프레즌스, 타이핑 표시, 알림, 채널 권한은 사실 제품 기획서의 MUST 항목이라 모두 일정에 넣었습니다. 지금까지는 약 4주에 12단계를 했는데, 남은 16주는 그보다 넉넉하게 잡았습니다. 13단계 AI 는 추석 연휴(9/24~26)와 한글날이 끼어 4주로 두었고, 12월 21일부터는 성탄절을 포함한 여유 기간입니다. 저장소 연동은 GitHub 만 지원합니다 — GitLab 은 계획에 없습니다. PR diff 화면은 11단계에서 바뀐 파일 목록으로 대체하기로 이미 정했습니다.');

  // 시간축: 9/14(월) ~ 12/31. 날짜를 x 좌표로 바꾼다.
  const t0 = Date.UTC(2026, 8, 14);
  const t1 = Date.UTC(2027, 0, 1);
  const ax0 = M + 3.5;
  const ax1 = W - M;
  const xOf = (y, m, d) => ax0 + ((Date.UTC(y, m - 1, d) - t0) / (t1 - t0)) * (ax1 - ax0);

  // 월 경계선과 월 이름
  const months = [[9, 14, '9월'], [10, 1, '10월'], [11, 1, '11월'], [12, 1, '12월']];
  months.forEach(([m, d, label], i) => {
    const x = xOf(2026, m, d);
    const next = i < months.length - 1 ? xOf(2026, months[i + 1][0], 1) : ax1;
    if (i > 0) s.addShape(pres.shapes.LINE, { x, y: 1.9, w: 0, h: 2.85, line: { color: C.hair, width: 0.75 } });
    text(s, label, { x: x + 0.06, y: 1.88, w: next - x - 0.1, h: 0.25, fontSize: 10, bold: true, color: C.muted });
  });

  const rows = [
    ['13 · AI', '9/14 – 10/9', '코드 질의(인용) · 대화 요약 · 이슈 초안', [9, 14], [10, 9], '4주'],
    ['14 · 채널 권한', '10/12 – 10/23', '채널별 권한 · 비공개 멤버 · 보드 드래그', [10, 12], [10, 23], '2주'],
    ['15 · DM · 프레즌스', '10/26 – 11/13', '1:1 DM · 타이핑 표시 · 온라인 상태', [10, 26], [11, 13], '3주'],
    ['16 · 알림', '11/16 – 11/27', '인앱 알림 센터 · 멘션 알림', [11, 16], [11, 27], '2주'],
    ['배포 준비', '11/30 – 12/18', '푸시 · 트레이 · 딥링크 · 파이프라인 · 격리 테스트', [11, 30], [12, 18], '3주'],
    ['여유', '12/21 – 12/31', '성탄절 포함 · 지연분 흡수', [12, 21], [12, 31], ''],
  ];
  const top = 2.2;
  const pitch = 0.43;
  rows.forEach(([name, dates, scope, [sm, sd], [em, ed], dur], i) => {
    const y = top + i * pitch;
    const buffer = i === rows.length - 1;
    s.addText(
      [
        { text: name, options: { fontSize: 11, bold: true, color: buffer ? C.muted : C.ink } },
        { text: '   ' + dates, options: { fontSize: 9, color: C.muted, breakLine: true } },
        { text: scope, options: { fontSize: 9.5, color: C.muted } },
      ],
      { x: M, y, w: 3.35, h: pitch - 0.02, fontFace: F, margin: 0, valign: 'middle', isTextBox: true },
    );
    const bx = xOf(2026, sm, sd);
    const bw = xOf(2026, em, ed + 1) - bx;
    const by = y + (pitch - 0.26) / 2;
    s.addShape(pres.shapes.ROUNDED_RECTANGLE, {
      x: bx, y: by, w: bw, h: 0.26, rectRadius: 0.05,
      fill: { color: buffer ? C.bg : i === 0 ? C.accent : C.ink },
      line: buffer ? { color: C.line, width: 1, dashType: 'dash' } : { color: i === 0 ? C.accent : C.ink, width: 0 },
    });
    if (dur) text(s, dur, { x: bx, y: by, w: bw, h: 0.26, fontSize: 9, bold: true, color: 'FFFFFF', align: 'center', valign: 'middle' });
  });

  text(s, '저장소 연동은 GitHub 만 지원(GitLab 제외) · PR diff 화면은 바뀐 파일 목록으로 대체(11단계)', {
    x: M, y: 4.85, w: CW - 0.8, h: 0.25, fontSize: 9.5, color: C.muted,
  });
}

// ═════════════════════════════════════════════════
// 10 감사합니다 · Q&A (다크) — 표지와 같은 자리에 같은 크기로 둔다
// ═════════════════════════════════════════════════
// 기술 부채 장을 이 장으로 바꿨다. 화면에서는 뺐지만 질문이 나올 수 있어
// 노트에 답을 남긴다.
closingSlide({
  footLeft: 'Nexus · 기술 진행 현황',
  notes: [
    '감사합니다. 질문 받겠습니다.',
    '',
    '[예상 질문 — 알고 있는 기술 부채]',
    '· 인덱스에 모델 이름이 없다: 모델을 바꾸고 push 만 하면 옛 벡터와 새 벡터가 조용히 섞인다. 13단계에서 모델 이름을 기록해 막는다.',
    '· 앱 통합 테스트가 없다: 위젯 테스트 252개는 있지만 화면을 도는 테스트는 없다. UI 리디자인이 심은 라우터 결함이 열흘 뒤에야 드러났다.',
    '· 다중 인스턴스를 재 본 적이 없다: 리스는 그렇게 짰지만 인스턴스는 하나다. Redis 소켓 어댑터는 빌드에서 빠져 있다.',
    '· 자동 검증이 안 되는 경로: 인덱싱 중 들어온 push, 역할 변경 재동기화, 15분 뒤 소켓 토큰 갱신.',
  ].join('\n'),
});

save(process.argv[2] || 'Nexus-기술현황.pptx');
