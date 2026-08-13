# Nexus

**개발자를 위한 커뮤니케이션 허브.**
Discord의 가벼움, Slack의 업무 구조, 그리고 개발 워크플로(이슈 · 저장소 · AI)를 한 화면에 합친다.

개인용으로 시작해 서비스화를 목표로 하는 개인 프로젝트.

## 무엇이 다른가

일반 메신저는 개발 맥락을 모르고, 개발 도구는 대화를 담지 못한다. Nexus는 그 사이를 메운다.

- 커밋 · PR/MR · 이슈 이벤트가 **채널 안으로 흘러 들어온다**
- 대화 중에 **그 자리에서 이슈를 만든다** (원문 링크가 남는다)
- AI가 **대화와 코드를 같은 맥락으로 읽는다**

## 아키텍처

```
app/     Flutter — 단일 코드베이스로 모바일 · 데스크톱 · 웹
   │
   │  REST + Socket.IO
   ▼
server/  NestJS + Prisma
   ├─ PostgreSQL   사용자 · 스페이스 · 채널 · 메시지 · 이슈
   ├─ Redis        프레즌스 · Socket.IO 어댑터 · AI 작업 큐
   └─ S3 호환      첨부 파일 (개발: MinIO / 운영: S3 · R2)
```

멀티테넌트 구조다. **Space**(Discord의 서버 / Slack의 워크스페이스)가 모든 데이터의 루트이며, 채널 · 메시지 · 이슈 · 저장소는 전부 스페이스에 속한다.

## 폴더 구조

| 폴더 | 설명 |
|---|---|
| `app/` | **Flutter 앱.** iOS · Android · Windows · macOS · Linux · Web을 한 코드베이스로 |
| `server/` | **NestJS 백엔드.** REST API + Socket.IO 게이트웨이 |
| `design-system/` | 토큰 · 컴포넌트 · 화면 프리뷰 (자기완결 HTML) |
| `docs/` | 기획 · 설계 문서 |

## 문서

| 문서 | 내용 |
|---|---|
| [제품 기획서](docs/제품-기획.md) | 방향 · 타겟 · 기능 범위 · 로드맵 |
| [백엔드 설계](docs/백엔드-설계.md) | 멀티테넌시 · 데이터 모델 · API · 실시간 |
| [앱 설계](docs/앱-설계.md) | Flutter 스택 · 화면 · 상태 관리 · 오프라인 전략 |
| [인프라 설계](docs/인프라-설계.md) | 무료 운영 전제의 배포 구성 · 공개 저장소 보안 체크리스트 |
| [디자인 시스템](docs/디자인-시스템.md) | 색 · 타이포 · 간격 · 컴포넌트 (산출물은 `design-system/`) |
| [전환 계획](docs/전환-계획.md) | 현재 코드에서 새 구조로 가는 작업 목록 |

## 실행

### 백엔드

```bash
cd server
docker compose up -d          # postgres + redis + minio
cp .env.example .env          # JWT_SECRET 등 필수 값 설정
npm install
npx prisma migrate dev
npm run seed
npm run start:dev             # http://localhost:3000/api
```

### 앱

```bash
cd app
flutter pub get
flutter run --dart-define=API_BASE=http://localhost:3000/api
```

API 주소는 빌드 타임에 주입한다. Android 에뮬레이터에서 호스트를 가리키려면 `http://10.0.2.2:3000/api`를 쓴다.

플랫폼별 빌드:

```bash
flutter build apk    --dart-define=API_BASE=https://api.example.com
flutter build web    --dart-define=API_BASE=https://api.example.com
flutter build windows --dart-define=API_BASE=https://api.example.com
```

## 현재 상태

이 프로젝트는 **전환 중**이다. 기존 구현(사내 메신저 통합 솔루션)에서 개인 프로젝트로 재기획했고, 구 프론트엔드 자산은 정리를 마쳤다.

- ✅ 재기획 완료 — 제품 · 백엔드 · 앱 · 인프라 · 전환 계획 문서
- ✅ 디자인 시스템 — 토큰 · 컴포넌트 8종 · 검증 화면 2종 (`design-system/`)
- ✅ 기존 자산 정리 — `www/`(React) · `desktop/`(Electron) · `mobile/`(Capacitor) · 루트 `index.html` 삭제, 구 디자인 소스는 `docs/archive/`로 이관
- 🔄 서버 개편 — 멀티테넌시 도입, 근태 · 업무일지 · 공지 제거, 스레드 · 리액션 · 멘션 추가
- ⬜ Flutter 앱 신규 구축 (`app/`)
- ⬜ 저장소 웹훅 연동 · AI 기능

진행 순서는 [전환 계획 §6](docs/전환-계획.md)을 따른다.

## 로드맵

| 단계 | 목표 |
|---|---|
| **Phase 0** | 나 혼자 쓰는 개발 허브. 내 프로젝트를 채널로 나누고 할 일 · 저장소를 붙인다 |
| **Phase 1** | 2~10인 소규모 팀. 초대 · 온보딩 · 푸시 알림 |
| **Phase 2** | 공개 서비스. 테넌트 격리 · 스토리지 쿼터 · 과금 |
