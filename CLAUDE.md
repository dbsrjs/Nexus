# Nexus — 코딩 에이전트용 안내

개발자 개인을 위한 커뮤니케이션 허브. 대화 · 파일 · 이슈 · 저장소 · AI를 한곳에 모은다.
**NestJS 서버 + Flutter 앱**, Space 단위 멀티테넌트.

이 문서는 세션 시작 시 자동으로 읽힌다. 상세 설계는 `docs/` 를 볼 것.

---

## 0. 먼저 알아야 할 것

| | |
|---|---|
| **작업 브랜치** | `feat/pivot-nexus` — **`main` 은 전환 이전의 옛 코드다.** 헷갈리지 말 것 |
| **상태** | 사내 메신저 → 개인 프로젝트로 **전환 중**. 서버 4단계(실시간 최소) 완료. **앱은 5단계 슬라이스 2(스페이스 선택 + 반응형 셸)까지 — `app/` 에 있다** |
| **언어** | 코드 주석 · 커밋 메시지 · 문서 전부 **한국어** |
| **커밋 저자** | 사용자(`dbsrjs1224@gmail.com`) 단독. **`Co-Authored-By: Claude` 를 넣지 않는다** |

---

## 1. 셋업

```bash
git clone https://github.com/dbsrjs/nexus.git && cd nexus
git checkout feat/pivot-nexus

npm --prefix server install
cp server/.env.example server/.env
# JWT_SECRET 을 채운다. 비어 있으면 서버가 부팅을 거부한다(의도된 동작).
node -e "console.log(require('crypto').randomBytes(48).toString('base64url'))"

npm run db:setup     # (새 PC에서 1회) WSL 안에 Postgres + pgvector 자동 구성
                     #  Docker 를 쓴다면 건너뛰고 db:up:docker 사용
npm run db:up        # DB 기동 + 준비될 때까지 대기
npm --prefix server run prisma:generate   # node_modules 를 새 스키마 기준으로 생성.
                                          # 빠뜨리면 시드가 SpaceRole 없음으로 실패한다
npm --prefix server run prisma:deploy     # migrate deploy
npm run db:seed

npm run server:dev   # http://localhost:3000/api
```

WSL 이 없으면 먼저 `wsl --install -d Ubuntu`.

### 앱 (`app/`)

```bash
cd app
flutter pub get
dart run build_runner build        # freezed · json_serializable 코드 생성 (모델을 고쳤으면 매번)
flutter run -d chrome --web-port=5173 --dart-define=API_BASE=http://127.0.0.1:3000
```

**`--dart-define=API_BASE` 를 반드시 넘긴다.** 기본값은 `http://127.0.0.1:3000` 이라
데스크톱·웹에서는 생략해도 되지만, Android 에뮬레이터는 `http://10.0.2.2:3000` 이어야
한다(에뮬레이터에게 `127.0.0.1` 은 자기 자신이다).

**웹 포트를 5173 으로 고정하는 이유**: 서버 `.env` 의 `CORS_ORIGINS` 가 이 주소만
허용한다. 다른 포트로 띄우면 브라우저가 요청을 막는다.

#### Android 에뮬레이터

이 PC 에는 Android SDK 36 · JDK 21 · AVD(`nexus_pixel`, Pixel 7)가 설치돼 있다.
새 PC 라면 `app/scripts/android-setup.ps1` 을 1회 실행한다(라이선스 동의는 사람이 `y`).

```bash
# 1) 에뮬레이터 기동 (부팅까지 1~2분)
%LOCALAPPDATA%\Android\Sdk\emulator\emulator.exe -avd nexus_pixel

# 2) 빌드 · 설치 · 실행 — flutter run 은 백그라운드에서 stdin EOF 로 죽으므로
#    자동화할 때는 build → adb install 로 간다
cd app
flutter build apk --debug --dart-define=API_BASE=http://10.0.2.2:3000
adb install -r build/app/outputs/flutter-apk/app-debug.apk
adb shell monkey -p com.nexus.nexus_app -c android.intent.category.LAUNCHER 1
```

**화면 확인**은 `adb shell screencap -p /sdcard/s.png` 후 `adb pull` 로 가져온다.
PowerShell 에서 `adb exec-out screencap -p > 파일` 은 **바이너리가 깨진다**(BOM 삽입).

### 자주 쓰는 명령

| 명령 | 설명 |
|---|---|
| `npm run db:up` / `db:down` | WSL Postgres 기동 / `wsl --shutdown` |
| `npm run db:up:docker` / `db:down:docker` | Docker 환경일 때 |
| `npm run db:seed` · `db:studio` | 시드 · Prisma Studio |
| `npm run server:dev` · `server:build` | 개발 서버 · 빌드 |
| `npm --prefix server run typecheck` | 타입 검사만 |
| `npm run check:realtime -- <시드비밀번호>` | 실서버 · 실DB · 실소켓으로 소켓 계약 검증 (`db:up` · `server:dev` 실행 중이어야 함) |
| `cd app && flutter analyze` · `flutter test` | 앱 정적 분석 · 테스트 |
| `cd app && dart run build_runner build` | freezed · json_serializable 재생성 |

### DB 는 PC 마다 따로다

계정 · 스페이스 · 메시지는 git 으로 옮겨지지 않는다. 새 PC 에서는 시드로 새로 만들어진다.

---

## 2. 이 환경의 함정 — 전부 실제로 겪은 것들

**같은 실수를 반복하지 말 것.**

| 증상 | 원인 · 대응 |
|---|---|
| `P1001: Can't reach database server` (Node 로는 붙는데 Prisma 만 실패) | Windows 에서 `localhost` 가 `::1` 로 먼저 해석되는데 WSL 포워딩은 IPv4 만 동작. `DATABASE_URL` 에 **`127.0.0.1`** 을 쓸 것 |
| 잘 되다가 갑자기 `ECONNREFUSED` | WSL2 는 배포판의 **마지막 세션이 닫히면 배포판을 정지**시킨다. Postgres 도 함께 죽는다. `npm run db:up` 이 세션을 잡아 둔다 (`.wslconfig` 의 `vmIdleTimeout` 은 VM 만 잡고 배포판은 못 잡는다 — 시도해 봤고 안 된다) |
| PowerShell 스크립트 파싱 에러 | Windows PowerShell 5.1 은 BOM 없는 UTF-8 을 ANSI 로 읽는다. 한글이 든 `.ps1` 은 **UTF-8 BOM** 으로 저장할 것 |
| `wsl` 명령이 무응답 | Ubuntu OOBE(첫 사용자 생성)가 걸린 상태일 수 있다. `wsl --shutdown` 후 재시도. 이 PC 는 개인 UNIX 계정 없이 **root 로** 쓰고 있다 |
| `bash -c` 안의 따옴표가 깨짐 | Git Bash 는 `/bin/sh` 를 Windows 경로로 바꾼다. WSL 명령은 **PowerShell 도구로** 실행하고, 복잡한 스크립트는 파일로 만들어 `wsl ... /bin/bash <path>` 로 넘길 것 |
| `npm --prefix server exec prisma ...` 가 `Could not find Prisma Schema` 로 실패 | `--prefix` 는 npm 이 패키지를 찾는 경로만 바꾸고 **실행되는 명령의 cwd 는 그대로**라 `prisma/schema.prisma` 를 못 찾는다. `npm --prefix server run <script>` 를 쓸 것 — `npm run` 은 패키지 디렉터리 안에서 스크립트를 실행한다 |
| `Building with plugins requires symlink support` | **Windows 개발자 모드**가 꺼져 있다. `flutter_secure_storage` 같은 네이티브 플러그인이 심볼릭 링크를 쓴다. `start ms-settings:developers` 로 켠다. (예전에 이 자리에 있던 `CMake Error ... Visual Studio 16 2019` 는 **Flutter 3.47 로 올라가며 해결됐다** — VS 2026 을 정상 인식하고 데스크톱 빌드가 된다) |
| Android 빌드가 `Run this build using a Java 11 or newer JVM` 으로 실패 | 이 PC 의 시스템 기본 java 가 **8** 이라 Gradle 이 그걸 집는다. `flutter config --jdk-dir <JDK21 경로>` 로 고정한다(이미 설정돼 있다) |
| `flutter run` 이 시작하자마자 조용히 종료 | `flutter run` 은 stdin 으로 키 명령(r · R · q)을 받는데, 백그라운드로 띄우면 stdin 이 EOF 라 종료로 해석한다. 사람이 직접 터미널에서 돌리거나, 검증 자동화는 `flutter build web` 후 정적 서버로 띄울 것 |
| 브라우저 자동화로 Flutter 웹 입력이 안 먹음 | Flutter 웹은 캔버스로 그려 접근성 트리가 비어 있다. `flutter-semantics-placeholder` 를 클릭해 시맨틱스를 켜면 입력 요소가 노출된다. 그래도 **BackSpace · 값 직접 대입은 컨트롤러까지 전달되지 않고 타이핑만 append 된다** — 폼을 비우려면 페이지를 새로고침할 것 |

---

## 3. 아키텍처와 반드시 지킬 규칙

### 테넌트 격리가 최우선

`Space` 가 모든 데이터의 루트다. 위반하면 다른 사용자의 데이터가 새는 종류의 버그가 된다.

1. **스페이스에 속한 테이블은 예외 없이 `spaceId` 를 직접 갖는다.** 부모를 타고 유추할 수 있어도 비정규화한다 — 모든 쿼리 `WHERE` 에 강제로 넣기 위함이다.
2. **서비스 메서드는 `spaceId`(또는 `SpaceMember`)를 첫 인자로 받는다.** 옵션이 아니다.
3. `:spaceId` 가 있는 라우트에는 **반드시 `SpaceGuard`** 를 건다.
4. **볼 수 없으면 403 이 아니라 404.** 403 은 "그 리소스가 존재한다"를 알려 준다.

```ts
@Get(':spaceId/things')
@UseGuards(SpaceGuard, SpaceRoleGuard)
@MinRole('admin')
list(@Param('spaceId') spaceId: string, @CurrentSpaceMember() member: SpaceMember) { … }
```

### 가드 체인

```
JwtAuthGuard         전역(APP_GUARD). @Public() 으로만 예외
  └ SpaceGuard       :spaceId 멤버십 검증 → req.spaceMember 주입, 비멤버는 404
      └ SpaceRoleGuard   @MinRole('admin') 등. 서열 guest < member < admin < owner
```

역할은 **JWT 에 담지 않는다.** 스페이스마다 다르고, 토큰에 박으면 역할 변경이 만료 전까지 반영되지 않는다. 매 요청 `SpaceGuard` 가 DB 에서 읽는다.

### 채널 가시성

| 채널 | 볼 수 있는 사람 |
|---|---|
| `isPrivate = false` | 스페이스 멤버 전원 |
| `isPrivate = true` | `channel_members` 에 있는 사람만 |

`channel_permissions` 행은 이 기본값을 **덮어쓰는 예외**로만 쓴다(특정 역할 가리기 · 읽기 전용).

### 그 밖의 규칙

- **입력은 전부 class-validator DTO.** 전역 파이프가 `whitelist: true, forbidNonWhitelisted: true` 라 DTO 밖 필드는 400 으로 거부된다(조용히 지우지 않는다).
- **JWT 시크릿은 `src/config/jwt.config.ts` 의 `resolveJwtSecrets()` 한 곳에서만** 읽는다. 하드코딩 폴백 금지 — 미설정이면 부팅을 중단시킨다.
- **메시지 삭제는 소프트 삭제.** 본문만 가리고 행과 첨부는 남긴다. 무기한 보관이 제품 특성이다.
- **`BigInt` 응답 주의.** Prisma 가 `bigint` 컬럼을 `BigInt` 로 주는데 `JSON.stringify` 가 던진다. `main.ts` 의 `enableBigIntSerialization()` 이 전역으로 처리한다.
- **raw SQL 에서 id 를 `::uuid` 로 캐스팅하지 말 것.** Prisma 는 `String @id` 를 **`text`** 컬럼으로 만든다. 캐스팅하면 `operator does not exist: text = uuid`.

### 모듈 구조 (`server/src/`)

```
config/       jwt.config.ts — 시크릿 해석의 유일한 지점
auth/         가입 · 로그인 · 리프레시 회전 · 재사용 탐지 · JWT 전략
users/        /api/me 만. 전역 사용자 목록은 두지 않는다(테넌트 격리)
spaces/       스페이스 CRUD · 멤버 · 초대 · SpaceGuard · SpaceRoleGuard
categories/   채널 그룹
channels/     채널 · 가시성 규칙 · 읽음 마커
messages/     메시지 목록 · 전송 · 수정 이력 · 소프트 삭제
prisma/       PrismaModule(@Global) + PrismaService
common/       예외 필터 · 데코레이터 · 페이지네이션 DTO · slug · bigint 직렬화
```

### 앱 구조 (`app/lib/`) — 슬라이스 2 시점

[앱-설계.md §3](docs/앱-설계.md) 의 구조를 따르되 **쓰는 것만 만든다.** 빈 디렉터리를
미리 파 두지 않는다.

```
core/env.dart            API 주소를 읽는 유일한 지점. 하드코딩 금지
core/theme.dart          design-system/tokens.css 를 이름까지 그대로 이식
core/router.dart         go_router + 인증 가드(redirect)
core/breakpoints.dart    Layout(mobile/tablet/desktop) + 고정 폭 상수
data/api/api_client.dart dio + 401 → 리프레시 1회 재시도
data/api/auth_api.dart   login · me · logout, 실패를 AuthFailure 로 분류
data/api/api_failure.dart 그 밖의 요청 실패 분류(ApiFailure) + 문구
data/api/spaces_api.dart GET /spaces
data/auth_storage.dart   flutter_secure_storage 래퍼
domain/models/           freezed + json_serializable (User · AuthTokens · Space)
features/auth/           로그인 화면 + Riverpod 컨트롤러
features/space/          스페이스 선택 화면 + 목록/현재 스페이스 provider
features/shell/          반응형 셸 — app_shell(분기) · space_rail · channel_pane
shared/widgets/          NexusAvatar 등 공용 위젯
```

**앱 규칙**

- **API 주소는 `core/env.dart` 밖에서 만들지 않는다.** 옛 `www/api.js:6` 이 `localhost` 를 박아 실기기에서 연결 불가였다.
- **디자인 토큰 이름을 바꾸지 않는다.** `--bg-surface` → `bgSurface` 처럼 표기만 바꿔 1:1 대응시킨다. 갈라지면 디자인 문서와 코드를 대조할 수 없다.
- **서버 오류 문구를 화면에 그대로 쓰지 않는다.** 실패 종류(`AuthFailure` · `ApiFailure`)만 받아 앱이 자기 문구를 쓴다. 서버 문구가 바뀔 때마다 앱 UX 가 흔들리면 안 된다.
- **반응형 폭 분기는 `features/shell/app_shell.dart` 한 곳에서만 한다.** 안쪽 위젯은 자기가 어떤 폭에 있는지 모른다. 분기가 화면마다 흩어지면 손댈 수 없게 된다.
- **401 재시도는 1회뿐.** 무한 재시도는 서버의 리프레시 재사용 탐지에 걸려 세션 family 가 끊긴다.
- **모델을 고치면 `dart run build_runner build`** 를 돌린다. `.freezed.dart` · `.g.dart` 는 커밋한다 — 체크아웃 직후 코드젠 없이 빌드되게 하기 위함이다.

### 아직 이관하지 않은 모듈 — 빌드에서 빠져 있다

`src/permissions` `src/notifications` `src/files` `src/issues`
`src/gitlab` `src/ai` 는 **옛 스키마를 참조해 컴파일되지 않는다.** 소스는 참고용으로 남겨 두고
`tsconfig.json` · `tsconfig.build.json` 의 `exclude` 로 빌드에서만 뺐다.
`src/realtime` 은 4단계에서 이관을 마쳤다 — `redis-io.adapter.ts` 하나만 다중
인스턴스가 될 때까지 개별 제외돼 있다.

되살리는 절차: ① 두 tsconfig 의 `exclude` 에서 경로 삭제 → ② `spaceId` 기준으로 코드 수정
→ ③ `app.module.ts` 의 `imports` 에 등록.

---

## 4. 어디까지 됐나

전환 계획 §6 기준. 상세는 [docs/전환-계획.md](docs/전환-계획.md).

| 단계 | 내용 | 상태 |
|---|---|---|
| 1 | 기존 자산 정리 (`www/` · `desktop/` · `mobile/` 삭제) | ✅ `04ecf77` |
| 2 | 멀티테넌시 골격 — 스키마 재작성 · auth 개편 · spaces · SpaceGuard | ✅ `c83013a` |
| 3 | 채팅 API 뼈대 — categories · channels · messages | ✅ `12138c9` |
| — | 실제 DB(Postgres 18 + pgvector 0.8.1)로 종단 확인 | ✅ `55c59a6` |
| 4 | 실시간 최소 — 소켓 인증(`auth.token` 만) · 룸 조인 · `rooms:sync`/`rooms:invalidate` · `message:*` 브로드캐스트 · 읽음 저장 | ✅ `c5806a8` |

**동작이 확인된 것** — 실제 DB 로 38개 케이스 통과:
가입 · 중복 거부 · 로그인 · 리프레시 회전 · **재사용 탐지** · 스페이스 생성(한글 이름) ·
초대 발급/수락 · 타 스페이스 404 · 채널 목록/생성 · 메시지 전송/조회/최신순 ·
**커서 페이지네이션** · 수정 이력 · **소프트 삭제** · **안 읽은 수** · 읽음 마커(뒤로 안 감) ·
권한 거부(403).

**실시간(소켓)도 실서버 · 실DB · 실소켓으로 41개 케이스 통과** (`npm run check:realtime`):
핸드셰이크 인증(토큰 없음/오류 거부) · `rooms:sync` · 테넌트 격리(비멤버에게 안 감) ·
`message:new`/`edited`/`deleted` 브로드캐스트(같은 사용자의 다른 소켓까지 도달 확인) ·
`rooms:invalidate`(채널 생성 시 재동기화) · 소켓 `read`/REST `POST /read` 가 같은 코드로
저장되고 `read:synced` 로 반영 · 잘못된 페이로드 · 비멤버 read 거부에도 연결 유지 ·
**비공개 채널 메시지가 비참여자에게 새지 않음**(생성자에게는 도달하는 것과 짝지어 확인).

다만 **`updateMemberRole` 의 `rooms:invalidate`(`member.role`)** 는 검증하지 못했다 —
두 번째 admin 계정과 역할 왕복이 필요해 검증 스크립트에서 뺐다. 코드 리뷰로만 확인.

### 앱 — 5단계 슬라이스 1 완료 (`ce70d56`)

5단계를 화면이 보이는 지점 기준으로 넷으로 잘랐다
([스펙](docs/superpowers/specs/2026-08-14-앱-슬라이스1-인증-design.md) §1).
그중 **첫 조각(스캐폴드 · 스택 배선 · 테마 · 라우터 · 인증)이 끝났다.**

**실제 브라우저로 확인된 것**: 로그인 성공 후 계정 표시 · 틀린 비밀번호 거절(앱 문구,
화면 유지) · **새로고침 후 로그인 화면 건너뜀**(저장 → 복원 → `/me` → 가드) · 로그아웃.
`flutter analyze` 0건, `flutter test` 2/2.

**확인하지 못한 것**: 서버가 꺼졌을 때의 "서버에 연결할 수 없습니다" 문구.
앱이 죽지 않는 것까지는 봤지만(꺼진 뒤에도 렌더·검증이 동작), 그 분기를 태우려면
캔버스에 텍스트를 넣어야 하는데 §2 의 마지막 함정 때문에 재렌더 후 입력이 들어가지
않았다. 사람이 직접 띄워 확인하면 된다.

### 앱 — 슬라이스 2 완료 (스페이스 선택 + 반응형 셸)

`/spaces`(스페이스 선택) → `/s/:spaceId`(셸)까지 라우트가 이어진다.
자리표시자였던 `home_screen.dart` 는 셸이 대체했다.

- **폭 분기는 `app_shell.dart` 한 곳에서만 한다** (`core/breakpoints.dart` 의 600 · 1024).
  안쪽 위젯(`SpaceRail` · `ChannelPane` · 본문)은 자기가 어떤 폭에 있는지 모른다.
  이 규칙이 깨지면 반응형 분기가 화면마다 흩어진다
- **에뮬레이터 논리 해상도를 바꿔 세 분기를 모두 확인했다** — `adb shell wm size/density`.
  desktop(2560dp) 3단 · tablet(800dp) 드로어 · mobile(기본) 하단 탭.
  확인 후 `wm size reset` · `wm density reset` 으로 되돌릴 것
- 그 과정에서 **드로어·데스크톱 양쪽에 `SafeArea` 누락**을 잡았다. 상태 표시줄과
  레일 첫 아바타·채널 헤더가 겹쳤다. 데스크톱 OS 에는 상태 표시줄이 없지만
  **Android 태블릿이 1024dp 를 넘으면 desktop 분기를 탄다**

**아직 없는 것**: 채널 목록 · 메시지(슬라이스 3), 소켓 연동(슬라이스 4),
스레드 · 리액션 · 멘션 · 핀 · DM, 첨부, 이슈, 저장소 연동, AI, 린트 · CI.
(실시간 서버는 `typing` · `presence:changed` · `thread:*` 룸만 남았다 — §5 참고)

---

## 5. 남은 작업

순서는 2026-08-14 에 개정됐다. **원안(계층을 다 쌓고 앱)은 5단계까지 화면이 없어서**,
부가 기능을 뒤로 미루고 앱을 앞으로 당겼다.

잘라내는 기준: **미루는 것은 기능이지 구조가 아니다.**
스레드 · 리액션은 나중에 붙여도 기존 코드를 안 건드리지만, 실시간을 미루면 앱 상태 계층을
REST 전제로 짰다가 다시 쓰게 된다. 그래서 **실시간은 앱보다 먼저** 했다.

5단계도 같은 기준으로 넷으로 잘랐다 — **한 조각이 끝나면 화면에 뭔가 새로 보여야 한다.**

| 단계 | 내용 | 상태 |
|---|---|---|
| 5-1 | 스캐폴드 · 스택 배선 · 테마 · 라우터 · **인증** | ✅ `ce70d56` |
| 5-2 | **스페이스 선택 + 반응형 셸** (3단 ↔ 모바일 탭) | ✅ |
| **5-3** ← 다음 | 채널 목록 + 메시지 리스트/전송 (REST, 낙관적 갱신) | |
| 5-4 | 소켓 연결 · 실시간 갱신 · catch-up | |
| **6** | drift 캐시 → 단일 진실 공급원 전환 → Phase 0 달성(실사용 가능) | |
| **7~** | **기능 단위로 서버 + 앱을 함께**: 스레드 · 리액션 · 멘션 · 핀 → 첨부 → 이슈 · 스프린트 → repos(웹훅 · 열람 프록시) → PR → 인덱싱 → AI | |
| 마지막 | 푸시 · 트레이 · 딥링크 · CI · 테넌트 격리 통합 테스트 | |

5-2 를 시작하기 전에 [슬라이스 1 스펙](docs/superpowers/specs/2026-08-14-앱-슬라이스1-인증-design.md)
§1 의 분해와 §2-1 의 플랫폼 사정을 읽을 것.

7단계부터는 **한 기능이 서버에서 화면까지 끝나야 완료로 친다.** 그래야 "화면 없는 구간"이
다시 생기지 않는다.

### 알려진 빚

- **테스트 · 린트 · CI 가 전혀 없다.** 루트의 `server:test` · `server:lint` 는 `server/package.json` 에 대상 스크립트가 없어 **실행하면 실패한다.** Jest · ESLint 셋업은 전환 계획 §5 에 있다. 4단계에서 `npm run check:realtime` 이 생겼지만, 이건 실서버 · 실DB · 실소켓으로 동작을 확인하는 스크립트일 뿐 단위 테스트 · CI 를 대신하지 않는다.
- `npm run db:up` · `db:setup` 은 **Windows + WSL 전용**(PowerShell). Mac/Linux 는 `db:up:docker` 를 써야 한다.
- GitHub OAuth 는 스키마(`oauth_accounts`)만 있고 미구현. 저장소 연동 단계에서 만든다.
- **`updateMemberRole` 의 `rooms:invalidate`(`member.role`)는 자동 검증되지 않는다.** 두 번째 admin 계정과 역할 왕복이 필요해 `check:realtime` 에서 뺐다. 코드 리뷰로만 확인.
- **비공개 채널에 다른 사람을 넣는 방법이 없다.** 생성자는 채널 생성 시 자동으로 멤버가 되지만(`ChannelsService.create()`), 채널 멤버 추가·제거 API 가 아직 없어 비공개 채널은 사실상 "나만 보는 채널"이다. 여럿이 쓰는 비공개 채널이 필요해지는 단계에서 함께 설계한다.
- **앱에 자동 테스트가 거의 없다.** `app/test/` 에는 `Env` 불변식 2개 + 반응형 경계 4개뿐이다. 위젯 테스트는 화면이 하나뿐이라 얻는 것이 적었고, 통합 테스트(로그인 → 채널 → 전송)는 슬라이스 3 이 끝나야 의미가 있다. **슬라이스 3 에서 갚기로 한 빚이다.**
- **소켓 CORS 화이트리스트가 검증되지 않았다.** `SocketIoAdapter` 가 `CORS_ORIGINS` 를 적용하지만, 검증 스크립트는 Node 소켓 클라이언트라 브라우저 SOP 를 따르지 않아 실제로 막히는지 확인된 적이 없다. Flutter 웹으로 소켓을 붙이는 슬라이스 4 에서 드러난다.
- ~~Windows 데스크톱 빌드 불가~~ — **해결됐다.** Flutter 3.47 + VS 2026 + 개발자 모드로 빌드된다(`flutter build windows --debug` 확인). 검증 경로는 Windows 데스크톱 · Chrome · Android 에뮬레이터 셋 다 열려 있다.

---

## 6. 검증에 대한 교훈 — 중요

**Prisma 를 스텁으로 대체한 검증은 가드 · 라우팅 · 권한 분기까지만 잡는다.**
그렇게 22개 케이스를 통과시킨 코드에서, 실제 DB 를 붙이자마자 버그 두 개가 나왔다.

| 버그 | 스텁이 놓친 이유 |
|---|---|
| `GET /api/spaces` 가 항상 500 (BigInt 직렬화) | 스텁이 `BigInt` 대신 평범한 숫자를 돌려줬다 |
| 채널 목록이 항상 500 (raw SQL `::uuid` 캐스팅) | 스텁이 `$queryRaw` 를 빈 배열로 가짜 대체했다 |

**스키마 · 쿼리가 걸린 변경은 반드시 실제 DB 로 확인할 것.** `npm run db:up` 이면 된다.

완료를 보고할 때는 **확인한 것과 확인하지 못한 것을 나눠서** 말할 것. 빌드가 통과한 것과
동작하는 것은 다르다.

---

## 7. 문서

| 문서 | 내용 |
|---|---|
| [docs/코드-둘러보기.md](docs/코드-둘러보기.md) | **저장소를 처음 열었을 때.** 돌아가는 걸 보는 법 · 구조 · 한 줄기 따라가기 · 읽는 순서 |
| [docs/제품-기획.md](docs/제품-기획.md) | 방향 · 타겟 · 기능 범위 · 로드맵 |
| [docs/백엔드-설계.md](docs/백엔드-설계.md) | 멀티테넌시 · 데이터 모델 · API 계약 · 실시간 · 인증 |
| [docs/앱-설계.md](docs/앱-설계.md) | Flutter 스택 · 화면 · 상태 관리 · 오프라인 전략 |
| [docs/인프라-설계.md](docs/인프라-설계.md) | 배포 구성 · 공개 저장소 보안 체크리스트 |
| [docs/디자인-시스템.md](docs/디자인-시스템.md) | 색 · 타이포 · 간격 · 컴포넌트 (산출물은 `design-system/`) |
| [docs/전환-계획.md](docs/전환-계획.md) | **작업 목록과 진행 상황. 작업 후 여기를 갱신할 것** |
| [docs/기술-스택-가이드.md](docs/기술-스택-가이드.md) | 스택별 학습 순서 · 코드 읽기 시작점 (사용자용) |
| [server/README.md](server/README.md) | 서버 셋업 · 규약 · 디렉터리 |

### 단계별 설계 스펙 (`docs/superpowers/specs/`)

| 스펙 | 내용 |
|---|---|
| [실시간 최소](docs/superpowers/specs/2026-08-14-실시간-최소-design.md) | 4단계 소켓 계약 — 룸 · 이벤트 · 인증 · 오류 처리 · 범위에서 뺀 것과 그 이유 |
| [앱 슬라이스 1](docs/superpowers/specs/2026-08-14-앱-슬라이스1-인증-design.md) | 5단계 분해(4조각) · 검증 플랫폼 사정 · 인증 흐름 |

계획 문서 `docs/superpowers/plans/` 도 있지만 **실행이 끝난 기록**이다. 현재 상태는
계획이 아니라 이 문서와 스펙을 봐야 한다.

작업을 끝내면 `docs/전환-계획.md` 의 체크박스와 이 문서의 §4 · §5 를 갱신한다.
