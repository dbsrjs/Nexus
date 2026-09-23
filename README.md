# Nexus

**개발자를 위한 커뮤니케이션 허브.**
대화 · 파일 · 이슈 · 저장소 · AI 를 한 화면에 모은다.

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
| **파일** | 첨부 업로드(진행률) · 이미지 미리보기 · 스페이스 파일 목록 |
| **이슈** | 칸반 보드 · 상세 · 댓글 · 라벨 · 대화 → 이슈 · 스프린트 · 번다운 |
| **GitHub** | 계정 연결(OAuth) · 웹훅 자동 등록 · 브랜치 · 파일 트리 · 커밋 · PR 열람 |
| **인덱싱** | 저장소를 청크로 나눠 임베딩 · 벡터 검색(pgvector HNSW) · push 마다 증분 갱신 |
| **AI 패널** | 자유 지시문 + 프리셋(요약 · 이슈 초안) · 컨텍스트(메시지 · 채널 최근 대화 · 저장소 RAG) |

---

## 아키텍처

```
app/     Flutter — 한 코드베이스로 Windows · Android · Web (iOS 는 macOS 가 없어 동결)
   │     Riverpod · go_router · dio · drift(오프라인 캐시 + 전송 큐)
   │
   │  REST + Socket.IO
   ▼
server/  NestJS + Prisma
   ├─ PostgreSQL + pgvector   모든 데이터 · 코드 임베딩 · 작업 큐(AI · 인덱싱)
   ├─ 스토리지                첨부 파일 (지금은 로컬 디스크, 배포 때 S3 호환 드라이버)
   ├─ LLM                     gemini · local(Ollama) · fake
   └─ 임베딩                  gemini · local(Ollama) · fake
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
| `npm run server:test` · `server:lint` | 서버 단위 테스트(Jest) · ESLint |
| `npm run check:*` | **실서버 · 실DB · 실소켓 계약 검증** 15종 — 실시간 · 리액션 · 스레드 · 첨부 · 이슈 · GitHub 연동 · 인덱싱 · AI 등. GitHub 은 스스로 띄우는 가짜 서버로 대신한다 |
| `npm run check:migrations` · `check:sql-time` | 마이그레이션 · raw SQL 정적 검사 (DB 불필요) |
| `cd app && flutter analyze && flutter test` | 앱 정적 분석 · 테스트 |

CI(`.github/workflows/ci.yml`)가 `main` 과 `feat/**` 의 push 마다 위 전부를 돈다.

---

## 진행 상황

**1~12단계와 13-1 · 13-2 완료.** 대화 · 파일 · 이슈 · GitHub 연동 · 저장소 인덱싱 · AI 패널이 `main` 에 있다.

| 다음 | 내용 |
|---|---|
| 13-3 | AI 멀티턴(후속 질문) |
| 14 | 사용자 설정 — 표시 이름 · 프로필 사진 · 비밀번호 변경 · 알림 설정 (디스코드식 설정 창) |
| 마지막 | 푸시 알림 · 트레이 · 딥링크 · 테넌트 격리 통합 테스트 · 배포 |

아직 없는 것: DM · 프레즌스 · 타이핑 표시 · 알림 · 채널별 권한.
단계마다의 결정과 확인 내역은 [진행 기록](docs/진행-기록.md) 에 있다.

| 로드맵 | 목표 |
|---|---|
| **Phase 0** | 나 혼자 쓰는 개발 허브 — 프로젝트를 채널로 나누고 할 일 · 저장소를 붙인다 |
| **Phase 1** | 2~10인 소규모 팀 — 초대 · 온보딩 · 푸시 알림 |
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
