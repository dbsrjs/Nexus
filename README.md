# Nexus

**개발자를 위한 커뮤니케이션 허브.**
대화 · 통화 · 파일 · 이슈 · 저장소 · AI 를 한 화면에 모은다.

일반 메신저는 개발 맥락을 모르고, 개발 도구는 대화를 담지 못한다. Nexus 는 그 사이를 메운다.

- 커밋 · PR · 푸시 이벤트가 **채널 안으로 흘러 들어온다**
- 대화 중에 **그 자리에서 이슈를 만든다** — 원문 링크가 남는다
- AI 가 **대화와 코드를 같은 맥락으로 읽는다** — 인덱싱된 저장소를 근거로 답하고 출처를 인용한다
- **오프라인에서도 동작한다** — 캐시로 대화를 보여 주고, 쓴 메시지는 재연결 때 내보낸다

---

## 기능

| 영역 | 내용 |
|---|---|
| **대화** | 스페이스 · 카테고리 · 채널(공개/비공개) · 실시간 전송 · 스레드 · 답장(인용) · 멘션 · 리액션 · 핀 · 마크다운 |
| **통화** | 음성 채널(들어가기 · 말하는 사람 표시 · 채널을 옮겨도 이어지는 통화 줄) · 화면 공유(웹 · Windows — Android 는 받아 보기만). 미디어는 LiveKit |
| **DM · 프레즌스** | 스페이스 안 1:1 DM · 온라인 / 자리비움(10분 무입력) / 오프라인 · 입력 중 표시 |
| **멤버 · 권한** | 스페이스 만들기 · 초대 코드 · 초대 링크 · 역할(owner · admin · member · guest) · 비공개 채널 명단 · 역할별 채널 권한(가리기 · 읽기 전용) |
| **알림** | 알림함(멘션 · `@channel` · DM · 내 글의 답글) · 종류별 스위치 · 채널 음소거 · 앱을 보고 있지 않을 때 OS 알림(Windows 토스트 · 브라우저) · Windows 트레이 |
| **파일** | 첨부 업로드(진행률) · 이미지 미리보기 · 스페이스 파일 목록 · 무기한 보관 |
| **이슈** | 칸반 보드(끌어 옮기기) · 상세 · 댓글 · 라벨 · 대화 → 이슈 · 스프린트 · 번다운(스페이스마다 켜는 선택 기능) |
| **GitHub** | 계정 연결(OAuth) · 웹훅 자동 등록 · 브랜치 · 파일 트리 · 커밋 · PR 열람 |
| **인덱싱** | 저장소를 청크로 나눠 임베딩 · 벡터 검색(pgvector HNSW) · push 마다 증분 갱신 |
| **AI 패널** | 자유 지시문 + 프리셋(요약 · 이슈 초안) · 컨텍스트(메시지 · 채널 최근 대화 · 저장소 RAG) · 이어 묻기 · 지난 대화 다시 열기 |
| **설정** | 표시 이름 · 프로필 사진 · 비밀번호 변경 · 알림 · 테마(시스템 · 라이트 · 다크) |
| **화면** | 자체 UI — Material · Cupertino 없이 직접 만든 부품(`app/lib/ui/`) · 반응형(데스크톱 · 태블릿 · 모바일) · 새로고침 · 로그인 뒤 원래 주소로 |

---

## 아키텍처

```
app/     Flutter — 한 코드베이스로 Windows · Android · Web (iOS 는 macOS 가 없어 동결)
   │     Riverpod · go_router · dio · drift(오프라인 캐시 + 전송 큐) · 자체 UI(WidgetsApp)
   │
   │  REST + Socket.IO
   ▼
server/  NestJS + Prisma
   ├─ PostgreSQL + pgvector   모든 데이터 · 코드 임베딩 · 작업 큐(AI · 인덱싱)
   ├─ 스토리지                첨부 파일 (개발은 로컬 디스크, 배포는 S3 호환 — R2)
   ├─ LLM                     gemini · local(Ollama) · fake
   └─ 임베딩                  gemini · local(Ollama) · fake

deploy/  VM 한 대 — Docker Compose(postgres · server · nginx · cloudflared · backup)
         웹과 API 를 nginx 한 오리진으로 낸다 · Cloudflare Tunnel · R2
```

**Space** 가 모든 데이터의 루트인 멀티테넌트 구조다. 채널 · 메시지 · 이슈 · 저장소는 전부 스페이스에 속하고,
스페이스에 속한 테이블은 `spaceId` 를 직접 가진다. 볼 수 없는 리소스는 403 이 아니라 404 로 답한다.

외부 원본(GitHub)은 사본을 두지 않고 프록시한다. Redis 는 쓰지 않는다 — 큐도 Postgres 에 둔다.

---

## 폴더 구조

| 폴더 | 설명 |
|---|---|
| [`server/`](server/) | NestJS 백엔드 — REST API · Socket.IO 게이트웨이 · 계약 검증 스크립트(`scripts/`) |
| [`app/`](app/) | Flutter 앱 — 실행법은 [app/README.md](app/README.md) |
| [`deploy/`](deploy/) | 배포 구성 — prod compose · nginx · 절차는 [deploy/README.md](deploy/README.md) |
| [`design-system/`](design-system/) | 디자인 토큰(`tokens.css`) · 컴포넌트 · 화면 프리뷰 |
| [`docs/`](docs/) | 기획 · 설계 문서 · 진행 기록 |

---

## 시작하기

필요한 것: **Node.js 22** · **Flutter 3.44.9 이상** · **WSL2(Ubuntu)** 또는 **Docker**

### 서버

```bash
git clone https://github.com/dbsrjs/Nexus.git && cd Nexus

npm --prefix server install
npm run env:setup                          # server/.env 생성 · 시크릿 자동 채움

npm run db:setup                           # (1회) WSL 안에 Postgres + pgvector
npm run db:up                              # Docker 라면 위 둘 대신 npm run db:up:docker

npm --prefix server run prisma:generate
npm --prefix server run prisma:deploy
npm run db:seed

npm run server:dev                         # http://localhost:3000/api
```

`env:setup` 은 여러 번 돌려도 안전하다. 만들어 낼 수 없는 값(`GITHUB_CLIENT_ID` · `GITHUB_CLIENT_SECRET` ·
`PUBLIC_BASE_URL`)은 끝에 목록으로 알려 준다 — GitHub 연동을 쓸 때만 필요하다.
AI · 인덱싱은 `.env` 의 `LLM_PROVIDER` · `EMBEDDING_PROVIDER` 를 채워야 켜진다.

> Windows 에서는 `DATABASE_URL` 에 `localhost` 대신 **`127.0.0.1`** 을 쓴다(WSL 포워딩이 IPv4 만 동작한다).
> 서버가 `listen EACCES ...:3000` 으로 죽으면 Windows 가 그 포트를 예약한 것이다 — 처방은 [CLAUDE.md §2](CLAUDE.md).


### 앱

```bash
cd app
flutter pub get

flutter run -d windows --dart-define=API_BASE=http://127.0.0.1:3000
flutter run -d chrome  --web-port=5173     # 서버 CORS 가 5173 만 허용한다
```

Android 에뮬레이터는 `--dart-define=API_BASE=http://10.0.2.2:3000` 을 넘긴다(에뮬레이터에게 `127.0.0.1` 은 자기 자신이다).
Windows 데스크톱 빌드에는 **개발자 모드**가 켜져 있어야 한다.

---

## 검증

| 명령 | 내용 |
|---|---|
| 명령 | 내용 | 규모 (2026-10-09) |
|---|---|---|
| `npm run server:test` · `server:lint` | 서버 단위 테스트(Jest) · ESLint — 순수 로직 · 가드 · 권한 규칙 | 551개 |
| `npm run check:*` | **실서버 · 실DB · 실소켓 계약 검증** — 실시간 · 리액션 · 스레드 · 첨부 · 이슈 · GitHub 연동 · 인덱싱 · AI · 설정 · 멤버 · 권한 · DM · 프레즌스 · 알림 · 통화(실제 LiveKit 컨테이너) · **테넌트 격리**(`check:tenancy` — 스페이스 경로 전부를 남의 id 로 친다). GitHub 은 스스로 띄우는 가짜 서버로 대신한다 | 21종 1,169개 |
| `npm run check:migrations` · `check:sql-time` | 마이그레이션 · raw SQL 정적 검사 (DB 불필요) | |
| `cd app && flutter analyze && flutter test` | 앱 정적 분석 · 단위 · 위젯 테스트 | 624개 |
| `npm run app:flow` | 앱 통합 테스트 — Windows 앱을 실서버에 붙여 로그인부터 전송 · 실시간 · 설정 · 멤버 · DM · 알림함 · AI 까지 돈다 | 약 30초 |
| `npm run app:flow:headless` | 같은 흐름을 창 없이(flutter_tester) 돈다 — CI 가 이것을 돈다 | 약 15초 |

CI(`.github/workflows/ci.yml`)가 `main` 과 `feat/**` 의 push 마다 위 전부를 돈다 — 앱 통합 테스트는 창 없는 쪽(`app:flow:headless`)으로, 첨부는 S3 경로(SeaweedFS)로도 한 번 더. Windows 창으로 보는 `app:flow` 는 화면 모습을 바꿨을 때 사람이 돌린다.

---

## 진행 상황

**1~19단계와 «마지막»(출시 준비)의 네 갈래가 끝났다**(2026-10-09). 위 기능표가 전부 동작하고,
배포 구성(`deploy/`) · 테넌트 격리 통합 검증 · 딥링크 · 데스크톱 · 웹 알림 + Windows 트레이까지 들어갔다.

| 남은 것 | 내용 |
|---|---|
| **실제 VM 배포** | 구성과 절차([deploy/README.md](deploy/README.md))는 있다. VM · R2 · Cloudflare Tunnel 을 정하고 올리는 일 |
| OS 수준 링크 연결 | Android App Links · Windows 프로토콜 등록 — 공개 도메인이 정해진 뒤 |

**20단계 통화**(음성 채널 · 화면 공유, LiveKit)는 PR 에 있다(2026-10-10) — 배포 때 VM 에 미디어 포트 둘을 연다. 모바일 푸시(FCM)와 GitLab 연동은 범위에서 뺐다. 단계마다의 결정과 확인 내역은 [진행 기록](docs/진행-기록.md) 에 있다.

| 로드맵 | 목표 |
|---|---|
| **Phase 0** | 나 혼자 쓰는 개발 허브 — 프로젝트를 채널로 나누고 할 일 · 저장소를 붙인다 |
| **Phase 1** | 2~10인 소규모 팀 — 초대 · 온보딩 · 알림 |
| **Phase 2** | 공개 서비스 — 테넌트 격리 · 스토리지 쿼터 · 과금 |

---

## 문서

| 문서 | 내용 |
|---|---|
| [코드 둘러보기](docs/코드-둘러보기.md) | **처음 열었을 때 여기부터.** 돌려 보기 · 구조 · 한 줄기 따라가기 |
| [제품 기획](docs/제품-기획.md) | 방향 · 타겟 · 기능 범위 · 로드맵 |
| [백엔드 설계](docs/백엔드-설계.md) | 멀티테넌시 · 데이터 모델 · API 계약 · 실시간 · 인증 |
| [앱 설계](docs/앱-설계.md) | Flutter 스택 · 화면 · 상태 관리 · 오프라인 전략 |
| [인프라 설계](docs/인프라-설계.md) | 배포 구성 · 공개 저장소 보안 체크리스트 |
| [디자인 시스템](docs/디자인-시스템.md) | 색 · 타이포 · 간격 · 컴포넌트 |
| [전환 계획](docs/전환-계획.md) | 작업 목록과 진행 상황 |
| [진행 기록](docs/진행-기록.md) | 단계마다 갈린 결정 · 확인한 것 · 확인하지 못한 것 |
| [기술 스택 가이드](docs/기술-스택-가이드.md) | 스택별 학습 순서 · 코드 읽기 시작점 |
| [서버 README](server/README.md) | 서버 셋업 · 규약 · Ollama · 실제 GitHub 웹훅 붙이는 법 |
| [배포 README](deploy/README.md) | VM · R2 · Cloudflare Tunnel 로 올리는 절차 |
| [단계별 설계 스펙](docs/superpowers/specs/) | 단계마다 정한 것 · **범위에서 뺀 것과 그 이유** |
