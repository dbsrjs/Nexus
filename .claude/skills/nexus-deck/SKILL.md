---
name: nexus-deck
description: Use when making any presentation, slide deck, PPT or .pptx about Nexus — project introductions, technical progress reports, weekly updates (이번 주 작업), roadmap/schedule slides, interview or team decks, 발표 자료. Also use when editing or extending a deck built with this template, even if the user only says "PPT 만들어줘" or "슬라이드 한 장 추가해줘" inside this repo. Covers the house design (Nexus tokens, dark–light–dark, dot motif), Korean copy rules, the shared pptxgenjs module, the Korean line-break fix, and PowerPoint-based visual QA.
---

# Nexus 발표 자료 양식

2026-09-11 에 두 덱(프로젝트 소개 12장 · 기술 진행 현황 10장)을 만들며 세 번 고쳐
굳힌 양식이다. 사용자가 요구한 것은 **"최대한 심플하고 깔끔하게"** 였다 —
장식을 더하고 싶어지면 이 문장으로 돌아온다.

만드는 법은 anthropic-skills `pptx` 스킬(pptxgenjs 주의점 · validate.py)을
따르고, 이 스킬은 **그 위의 Nexus 규칙과 이 PC 의 함정**만 다룬다.

## 파일

| 파일 | 역할 |
|---|---|
| `scripts/lib.js` | 토큰 · 머리 · 표지/마지막 장 · 카드 · 화살표 · 불릿 · **한국어 줄바꿈을 고치는 `save()`** |
| `scripts/render.ps1` | PowerPoint 로 슬라이드마다 PNG — 사용자의 PowerPoint 를 닫지 않게 막아 둔 것 |
| `examples/tech-status.js` | 실제로 쓴 10장. 레이아웃은 여기서 베낀다(아래 표) |

## 순서

1. **작업 폴더는 스크래치패드.** 저장소에 `node_modules` · 출력물을 만들지 않는다.
   ```bash
   npm i pptxgenjs@3.12.0
   ```
   `lib.js` 는 pptxgenjs · jszip 을 **실행한 폴더(cwd)에서** 찾는다.
2. **사실부터 모은다. 숫자를 지어내지 않는다.** 커밋 수 · 테스트 수 · 계약 검증
   케이스 · 단계 상태는 `CLAUDE.md` §5, `docs/진행-기록.md`, `docs/전환-계획.md`, `git log` 에서
   가져온다. 기능 범위는 `docs/제품-기획.md`. 예시 덱의 숫자는 9/11 기준이라 낡았다.
   날짜를 쓰면 요일을 코드로 확인한다(공휴일 · 연휴도).
3. 빌드 스크립트를 쓴다 — `require('<저장소>/.claude/skills/nexus-deck/scripts/lib')`.
   `save(out)` 으로 저장한다. **`pres.writeFile()` 을 직접 부르면 한국어 줄바꿈이 깨진다.**
4. 렌더하고 **모든 장을 눈으로 본다** (아래 「검수」).
5. 고치고, 바뀐 장만 다시 본다.
6. `validate.py` 를 통과시킨다.
7. `SendUserFile` 로 보낸다. 무엇을 확인했고 무엇을 못 했는지(예: Mac · Keynote) 함께 말한다.

## 디자인 규칙

### 색 — 앱 토큰 그대로 (`design-system/tokens.css`)

| 이름 | 값 | 쓰임 |
|---|---|---|
| `C.ink` | `27374D` | 제목 · 본문 · 초점 카드 바탕 |
| `C.accent` | `326C8F` | 라벨 점 · 숫자 · 진행 막대. **한 장에 한두 곳만** |
| `C.muted` | `5E6165` | 설명 · 보조 글자 |
| `C.soft` | `F3F5F7` | 카드 바탕 |
| `C.hair` · `C.line` | `DDE1E5` · `A8ABAE` | 가는 선 · 쪽 번호 · 남은 구간 |
| `C.onInk` | `C9D3DD` | 짙은 카드 위 보조 글자 |
| `C.dBg` · `C.dText` · `C.dMuted` · `C.dAccent` | `121314` · `DDE6ED` · `9DA0A4` · `77AECF` | 표지 · 마지막 장 |

발표용 팔레트를 따로 만들지 않는다 — 발표와 제품이 같은 얼굴이어야 한다.

### 구조

- **표지(다크) → 본문(라이트) → 마지막 장(다크).** 마지막 장은 「감사합니다 / Q & A」.
  표지와 같은 자리 · 같은 크기다(`coverSlide` · `closingSlide`).
- **모티프는 하나 — 섹션 라벨 앞의 작은 강조색 점**(로고 N 의 점을 옮긴 것).
- **쓰지 않는 것**: 제목 밑줄 · 색 띠 · 가장자리 줄무늬 · 카드 한쪽 테두리 ·
  그림자 · 그라데이션 · 아이콘 남발. 카드는 바탕 색(`soft`)으로만 구분하고,
  강조할 카드 하나만 `ink` 로 채운다.
- **한국어에 기울임을 쓰지 않는다** — 맑은 고딕의 기울임은 가짜라 흉하다.
- **라벨에 자간(`charSpacing`)을 주지 않는다.**

### 글꼴과 크기

글꼴은 **맑은 고딕** 하나(받는 PC 에 늘 있다). 코드 · 식별자 · 잡 이름 · 버전은 **Consolas**.

| 요소 | 크기 |
|---|---|
| 표지 제목 / 부제 / 한 줄 | 48 / 20 / 14 bold·일반·muted |
| 섹션 라벨 | 11 bold, 강조색 |
| 본문 장 제목 | 24 bold, 한 줄 |
| 카드 제목 | 13.5–16 bold |
| 본문 · 불릿 | 10.5–11.5 |
| 큰 숫자 | 20–26 bold, 강조색 |
| 각주 · 쪽 번호 | 9–9.5 |

### 좌표 (16:9 = 10 × 5.625 인치)

- 좌우 여백 `M = 0.6`, 본문 폭 `CW = 8.8`
- 라벨 y 0.5 · 제목 y 0.92 (`lightSlide` 가 그린다)
- **본문 영역 y 1.95 – 4.95**, 쪽 번호 y 5.12
- 카드 사이 간격 0.3(한 덱 안에서 섞지 않는다)

### 문구

- **슬라이드 글은 명사형으로 끝낸다.** 「~한다」도 「~함 · ~음」도 아니다.
  - ✗ `스키마를 재작성한다` → ✓ `스키마 재작성`
  - ✗ `테넌트 경계부터 세웠다` → ✓ `테넌트 경계부터 세운 기반`
- **제목은 주제가 아니라 "왜/무엇을 말하려는가"를 담는다** —
  ✗ `서버` → ✓ `스키마 재작성, 테넌트 경계부터 세운 기반`.
- **발표자 노트는 말투(~습니다)로**, 화면에서 뺀 설명 · 예상 질문의 답을 여기 둔다.
- 용어: **「출시」가 아니라 「배포」.** 저장소 연동은 **GitHub 만**(GitLab 은 계획에 없다).
- 제품 기획서 §5.1 MUST(DM · 프레즌스 · 타이핑 · 알림 · 채널 권한 등)를
  "범위 밖"이라고 쓰지 않는다 — 한 번 틀렸다.
- **글자 예산**: 3열 카드(안쪽 폭 약 2.3")에서 10.5pt 한 줄은 **한글 16자 안팎**.
  넘으면 줄이 접혀 카드를 넘친다 — 문구를 줄이는 것이 먼저, 글자 크기를 줄이는 것은 나중.
- 통계 라벨이 두 줄이 되면 숫자를 합치거나 라벨을 줄인다(`251 · 252` → `503` / `서버 · 앱 테스트`).

## 레이아웃 패턴 (`examples/tech-status.js`)

| 장 | 패턴 | 언제 |
|---|---|---|
| 01 | 표지 — `coverSlide` | 늘 |
| 02 | **진행 트랙**(점 열 개 · 끝난 구간 실선/남은 구간 점선) + 숫자 카드 넷 | 전체 진척 한눈에 |
| 03 · 04 | **결정 목록**(왼쪽 `titled` 넷) + 오른쪽 스택 카드(Consolas) | 한 계층의 설계 판단 |
| 05 | **3열 카드**(태그 · 제목 · 불릿) + 아래 한 줄 | 나란한 묶음 셋 |
| 06 | **가로 행 카드 셋**(태그 · 이름 | 설명) | 설명이 긴 항목 |
| 07 | 3열 카드 중 **하나만 `ink`** + 카드 없는 숫자 넷 | 이번 주 · 초점이 있는 비교 |
| 08 | 테두리 상자 셋(`box`) + 아래 교훈 카드 | 구성 요소 · 파이프라인 |
| 09 | **간트** — `xOf(y, m, d)` 로 날짜 → x. 첫 막대 강조색 · 나머지 `ink` · 여유는 점선 | 일정 |
| 10 | 마지막 장 — `closingSlide`, 노트에 예상 질문 | 늘 |

한 덱에서 같은 패턴을 연달아 쓰지 않는다. 화살표 흐름도가 필요하면 `arrow(s, x1, y1, x2, y2, color, both)`
— 오른쪽→왼쪽 · 아래→위는 내부에서 flip 한다.

## 검수

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File <저장소>\.claude\skills\nexus-deck\scripts\render.ps1 -Pptx 덱.pptx -OutDir render
```

그다음 `render/slide-NN.png` 를 **한 장씩 Read 로 연다.** 코드를 방금 쓴 눈은 의도한
것을 본다 — 이미지로 봐야 보인다. 볼 것: 줄이 단어 중간에서 끊겼는지 · 카드 밖으로
넘쳤는지 · 겹침 · 라벨이 두 줄이 됐는지 · 간격이 들쭉날쭉한지.

```powershell
$env:PYTHONUTF8 = '1'; & <py3.10+ 가상환경>\Scripts\python.exe <pptx 스킬>\scripts\office\validate.py 덱.pptx
```

LibreOffice(`soffice`) 렌더로 검수하지 않는다 — 맑은 고딕 · Consolas 가 대체 글꼴로
바뀌어 줄바꿈이 실제와 다르다.

## 함정 — 전부 실제로 겪었다

| 증상 | 원인 · 대응 |
|---|---|
| 한국어가 **글자마다** 줄바꿈된다(「비정/규화한다」) | pptxgenjs 가 `lang="en-US"` 와 동아시아 `charset="-122"`(GB2312, 중국어)를 박아 PowerPoint 가 중국어 규칙으로 끊는다. `eaLnBrk="0"` **만으로는 안 됐다.** `save()` 가 `ko-KR` · `charset="-127"` · `eaLnBrk="0"` 으로 고친다 — 그래서 `writeFile()` 을 쓰지 않는다 |
| 카드 글이 아래로 넘친다 | 본문의 `\n` 은 줄마다 새 단락이다. 단락 앞 여백을 모든 줄에 주면 줄 사이가 벌어진다. `titled()` 는 첫 줄에만 준다 — 직접 `addText` 할 때도 같게 |
| 렌더가 `0x80048240` 으로 실패 | 사용자가 같은 덱을 **제한된 보기**(「사용 허가되지 않은 제품」)나 편집 창으로 열어 두었다. 사용자에게 PowerPoint 를 닫아 달라고 하고 다시 돌린다 |
| 렌더 뒤 사용자의 PowerPoint 가 닫힐 뻔했다 | PowerPoint 는 인스턴스가 하나라 COM 이 사용자 창에 붙는다. `render.ps1` 은 **열린 프레젠테이션 · 제한된 보기 창이 하나도 없을 때만** `Quit()` 한다. 이 가드를 빼지 않는다 |
| `validate.py` 가 문법 오류 / 모듈 없음 / `cp949` 디코딩 오류 | 이 PC 의 기본 Python 은 3.9 라 `match` 문을 못 읽는다. **3.10+ 가상환경**(`py -3.13 -m venv .venv` + `pip install lxml defusedxml`)에서, **`PYTHONUTF8=1`** 로 돌린다(한국어 Windows 기본 인코딩이 cp949) |
| 빌드 스크립트의 정규식 · 백틱이 깨진다 | Bash heredoc 으로 JS 를 쓰면 백슬래시 · 백틱이 먹힌다. **Write · Edit 도구로 파일을 쓴다** |
| `.ps1` 파싱 오류 | 한글이 든 `.ps1` 은 UTF-8 **BOM** 으로 저장한다(저장소 CLAUDE.md §2) |
