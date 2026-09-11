// Nexus 발표 자료 양식 — 디자인 토큰 · 도형 도우미 · 한국어 줄바꿈 처리.
//
// 색은 Nexus 앱의 디자인 토큰(design-system/tokens.css) 그대로다. 발표와 제품이
// 같은 얼굴이어야 해서 발표용 팔레트를 따로 두지 않는다.
//
// 쓰는 법: 작업 폴더에서 `npm i pptxgenjs@3.12.0` 을 한 뒤, 빌드 스크립트에서
//   const { makeDeck, C, M, W, CW } = require('<이 파일 경로>');
// 로 불러 쓴다. 전체 예시는 ../examples/tech-status.js.
const fs = require('fs');
const path = require('path');

// pptxgenjs · jszip 은 **작업 폴더(cwd)에서** 찾는다. 이 파일은 저장소의
// .claude/skills 밑에 있어 여기 node_modules 를 두면 저장소에 의존성이 생긴다.
function need(name) {
  try {
    return require(require.resolve(name, { paths: [process.cwd(), __dirname] }));
  } catch {
    throw new Error(`${name} 를 찾지 못했습니다. 작업 폴더에서 npm i pptxgenjs@3.12.0 을 먼저 실행하세요 (jszip 은 함께 설치됩니다).`);
  }
}
const pptxgen = need('pptxgenjs');
const JSZip = need('jszip');

const C = {
  // 라이트 — 본문 슬라이드
  bg: 'FFFFFF',
  ink: '27374D', // --text-primary (light)
  accent: '326C8F', // --accent (light)
  muted: '5E6165', // --text-secondary (light)
  soft: 'F3F5F7', // 카드 바탕
  hair: 'DDE1E5', // 가는 선
  line: 'A8ABAE', // --border-strong (light)
  onInk: 'C9D3DD', // 짙은 상자 위 보조 글자
  // 다크 — 표지 · 마지막 장. 앱의 다크 테마
  dBg: '121314', // --bg-base
  dSurface: '1C1D1F', // --bg-surface
  dText: 'DDE6ED', // --text-primary ★원본
  dMuted: '9DA0A4', // --text-secondary
  dAccent: '77AECF', // --accent ★원본
};

// 맑은 고딕은 Windows 에 기본으로 있다 — 다른 PC 에서 열어도 똑같이 보인다.
// Pretendard 가 더 깔끔하지만 받는 사람 PC 에 없으면 다른 글꼴로 바뀐다.
const F = 'Malgun Gothic';
const MONO = 'Consolas'; // 코드 · 식별자 · 버전
const M = 0.6; // 좌우 여백(인치). 16:9 캔버스는 10 x 5.625
const W = 10;
const CW = W - M * 2; // 본문 폭 8.8
const LOGO = path.resolve(__dirname, '..', '..', '..', '..', 'design-system', 'logo', 'nexus-mark.png');

function makeDeck(title, { author = '이윤건' } = {}) {
  const pres = new pptxgen();
  pres.layout = 'LAYOUT_16x9';
  pres.title = title;
  pres.author = author;
  pres.theme = { headFontFace: F, bodyFontFace: F };
  let page = 0;

  const text = (s, str, opts) => s.addText(str, { fontFace: F, margin: 0, isTextBox: true, ...opts });

  // 머리 — 섹션 라벨(점 + 글자)과 한 줄 제목. 모든 본문 장이 같은 자리를 쓴다.
  // 점은 로고 N 의 대각선 위 점을 옮긴 것이다. 제목 밑줄 · 색 띠는 쓰지 않는다.
  function header(s, label, headline, dark) {
    const dot = dark ? C.dAccent : C.accent;
    s.addShape(pres.shapes.OVAL, { x: M, y: 0.6, w: 0.09, h: 0.09, fill: { color: dot }, line: { color: dot, width: 0 } });
    text(s, label, { x: M + 0.2, y: 0.5, w: 7, h: 0.3, fontSize: 11, bold: true, color: dot, valign: 'middle' });
    text(s, headline, { x: M, y: 0.92, w: CW, h: 0.7, fontSize: 24, bold: true, color: dark ? C.dText : C.ink, valign: 'top' });
  }

  function lightSlide(label, headline, notes) {
    page++;
    const s = pres.addSlide();
    s.background = { color: C.bg };
    header(s, label, headline, false);
    text(s, String(page).padStart(2, '0'), { x: W - M - 0.6, y: 5.12, w: 0.6, h: 0.25, fontSize: 9, color: C.line, align: 'right' });
    if (notes) s.addNotes(notes);
    return s;
  }

  function darkSlide(label, headline, notes) {
    page++;
    const s = pres.addSlide();
    s.background = { color: C.dBg };
    if (label) header(s, label, headline, true);
    if (notes) s.addNotes(notes);
    return s;
  }

  // 표지와 마지막 장은 같은 자리 · 같은 크기다 — 덱의 처음과 끝이 짝을 이룬다.
  function coverSlide({ title, subtitle, tagline, footLeft, footRight = 'github.com/dbsrjs/Nexus', notes }) {
    const s = darkSlide(null, null, notes);
    s.addImage({ path: LOGO, x: M - 0.12, y: 0.95, w: 1.0, h: 1.0 });
    text(s, title, { x: M, y: 2.1, w: 8, h: 0.9, fontSize: 48, bold: true, color: C.dText });
    if (subtitle) text(s, subtitle, { x: M, y: 3.0, w: 8, h: 0.5, fontSize: 20, color: C.dText });
    if (tagline) text(s, tagline, { x: M, y: 3.5, w: 8, h: 0.4, fontSize: 14, color: C.dMuted });
    if (footLeft) text(s, footLeft, { x: M, y: 4.85, w: 5, h: 0.3, fontSize: 11, color: C.dMuted });
    text(s, footRight, { x: W - M - 4, y: 4.85, w: 4, h: 0.3, fontSize: 11, color: C.dAccent, align: 'right' });
    return s;
  }

  function closingSlide({ footLeft, footRight = 'github.com/dbsrjs/Nexus', notes }) {
    const s = darkSlide(null, null, notes);
    s.addImage({ path: LOGO, x: M - 0.12, y: 0.95, w: 1.0, h: 1.0 });
    text(s, '감사합니다', { x: M, y: 2.1, w: 8, h: 0.9, fontSize: 44, bold: true, color: C.dText });
    text(s, 'Q & A', { x: M, y: 3.05, w: 8, h: 0.5, fontSize: 22, bold: true, color: C.dAccent });
    if (footLeft) text(s, footLeft, { x: M, y: 4.85, w: 5, h: 0.3, fontSize: 11, color: C.dMuted });
    text(s, footRight, { x: W - M - 4, y: 4.85, w: 4, h: 0.3, fontSize: 11, color: C.dAccent, align: 'right' });
    return s;
  }

  // 카드 — 그림자 없이 바탕 색으로만 구분한다(앱의 표면 세 단계와 같은 방식)
  function card(s, x, y, w, h, fill = C.soft) {
    s.addShape(pres.shapes.ROUNDED_RECTANGLE, { x, y, w, h, rectRadius: 0.06, fill: { color: fill }, line: { color: fill, width: 0 } });
  }

  // 테두리 상자 — 흐름도 · 구조도의 한 칸. 초점인 칸은 fill: C.ink
  function box(s, x, y, w, h, { fill = C.bg, border = C.hair } = {}) {
    s.addShape(pres.shapes.ROUNDED_RECTANGLE, { x, y, w, h, rectRadius: 0.06, fill: { color: fill }, line: { color: border, width: 1 } });
  }

  // 화살표. 오른쪽→왼쪽 · 아래→위는 flip 으로 뒤집는다(좌표만 바꾸면 방향이 안 바뀐다)
  function arrow(s, x1, y1, x2, y2, color = C.line, both = false) {
    const line = { color, width: 1.25, endArrowType: 'triangle' };
    if (both) line.beginArrowType = 'triangle';
    s.addShape(pres.shapes.LINE, {
      x: Math.min(x1, x2), y: Math.min(y1, y2), w: Math.abs(x2 - x1), h: Math.abs(y2 - y1), line, flipH: x2 < x1, flipV: y2 < y1,
    });
  }

  // 제목 + 설명. 본문의 \n 은 줄마다 새 단락이 된다 — 단락 앞 여백을 모든 줄에
  // 주면 줄 사이가 벌어져 카드 밖으로 넘친다. 첫 줄에만 준다.
  function titled(s, x, y, w, h, title, body, { titleSize = 14, bodySize = 11.5, titleColor = C.ink, bodyColor = C.muted, mono = false } = {}) {
    const lines = body.split('\n');
    s.addText(
      [
        { text: title, options: { fontSize: titleSize, bold: true, color: titleColor, fontFace: mono ? MONO : F, breakLine: true } },
        ...lines.map((line, i) => ({
          text: line,
          options: { fontSize: bodySize, color: bodyColor, fontFace: F, paraSpaceBefore: i === 0 ? 4 : 0, breakLine: i < lines.length - 1 },
        })),
      ],
      { x, y, w, h, margin: 0, valign: 'top', isTextBox: true, fontFace: F, lineSpacingMultiple: 1.15 },
    );
  }

  // 불릿 — 글머리 기호는 bullet 옵션으로. 글자 '•' 를 넣으면 두 번 찍힌다
  function bullets(s, x, y, w, h, items, { size = 11.5, color = C.ink, gap = 6 } = {}) {
    s.addText(
      items.map((t, i) => ({ text: t, options: { bullet: { indent: 12 }, breakLine: i < items.length - 1 } })),
      { x, y, w, h, fontFace: F, fontSize: size, color, margin: 0, paraSpaceAfter: gap, valign: 'top', isTextBox: true, lineSpacingMultiple: 1.1 },
    );
  }

  // ── 저장 + 한국어 줄바꿈 ─────────────────────────────
  // pptxgenjs 는 글자마다 lang="en-US" 와 동아시아 글꼴 charset="-122"(GB2312,
  // **중국어 간체**)를 박는다. 그러면 PowerPoint 가 중국어 규칙으로 **글자마다**
  // 줄을 끊는다("비정/규화한다"). 한국어로 표시하고 eaLnBrk="0" 을 주면 단어
  // 단위가 된다. eaLnBrk 만으로는 안 됐다 — 언어 표시가 핵심이다.
  // charset 은 부호 있는 바이트라 HANGUL(129) 이 -127 로 적힌다.
  // **pres.writeFile() 을 직접 부르지 말 것** — 이 처리가 빠진다.
  async function save(out) {
    const buf = await pres.write({ outputType: 'nodebuffer' });
    const zip = await JSZip.loadAsync(buf);
    const slides = Object.keys(zip.files).filter((n) => /^ppt\/slides\/slide\d+\.xml$/.test(n));
    for (const name of slides) {
      let xml = await zip.file(name).async('string');
      xml = xml.replace(/<a:pPr(?![^>]*eaLnBrk)/g, '<a:pPr eaLnBrk="0"');
      xml = xml.replace(/<a:p>(?!<a:pPr)/g, '<a:p><a:pPr eaLnBrk="0"/>');
      xml = xml.replace(/lang="en-US"/g, 'lang="ko-KR" altLang="en-US"');
      xml = xml.replace(/(<a:ea typeface="[^"]*"[^>]*?)charset="-122"/g, '$1charset="-127"');
      zip.file(name, xml);
    }
    fs.writeFileSync(out, await zip.generateAsync({ type: 'nodebuffer', compression: 'DEFLATE' }));
    console.log(`저장: ${out} (슬라이드 ${slides.length}장)`);
  }

  return { pres, text, lightSlide, darkSlide, coverSlide, closingSlide, card, box, arrow, titled, bullets, save };
}

module.exports = { makeDeck, C, F, MONO, M, W, CW, LOGO };
