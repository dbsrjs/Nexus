# Nexus — 코딩 에이전트용 안내

개발자 개인을 위한 커뮤니케이션 허브. 대화 · 파일 · 이슈 · 저장소 · AI를 한곳에 모은다.
**NestJS 서버 + Flutter 앱**, Space 단위 멀티테넌트.

이 문서는 세션 시작 시 자동으로 읽힌다. 상세 설계는 `docs/` 를 볼 것.

---

## 0. 먼저 알아야 할 것

| | |
|---|---|
| **기준 브랜치** | **`main`.** 새 작업은 `feat/*` 를 따 쓰고 끝나면 main 으로 합친다(CI 가 `main` 과 `feat/**` 를 돈다) |
| **상태** | **1~19단계와 «마지막»의 네 갈래(배포 구성 · 테넌트 격리 검증 · 딥링크 · 데스크톱 · 웹 알림 + 트레이)가 `main` 에 있다**(2026-10-09). 남은 것은 실제 VM 배포 · OS 수준 링크 연결과 20 GitLab — §5 의 «마지막» 칸. 단계별로 — 19단계는 AI 기록(AI 패널의 「지난 대화」 · 다시 열어 이어 묻기), 18단계는 인앱 알림(멘션 · DM · 내 글의 답글 · 알림함 · 종류별 스위치), 17단계는 DM · 프레즌스 · 타이핑(17-1 DM · 17-2 프레즌스 · 입력 중), 16단계는 멤버 · 권한(16-1 스페이스 수준 · 16-2 채널 수준 · 스프린트 선택 기능) — 오프라인 대화 · 파일 · 이슈 보드 · GitHub 연동(웹훅 · 열람 · PR) · 저장소 인덱싱 · AI 패널(이어 묻기 포함) · 사용자 설정(이름 · 사진 · 비밀번호 · 음소거 · 테마) · 자체 UI(앱에 Material · Cupertino 가 없다). 12 · 13단계는 진짜 GitHub · 진짜 임베딩 · 진짜 Gemini 로 완주했다(13-3 이어 묻기 · 자동 전환 포함). **20 GitLab 연동**은 배포 뒤로 미뤄도 되는 유일한 단계다(§5). 단계마다의 경과는 [docs/진행-기록.md](docs/진행-기록.md) |
| **새 PC 셋업** | §1 순서대로. `.env` 는 `npm run env:setup` 이 만들고, 손으로 채울 값(GitHub OAuth App · 터널 주소 · AI provider)은 [server/README.md «선택 기능을 켜는 값»](server/README.md). PC 를 오갈 때 옮겨지지 않는 것은 `nexus-pc-handoff` 스킬 |
| **언어** | 코드 주석 · 커밋 메시지 · 문서 전부 **한국어** |
| **커밋 저자** | 사용자(`dbsrjs1224@gmail.com`) 단독. **`Co-Authored-By: Claude` 를 넣지 않는다** |
| **커밋 메시지** | 제목은 **명사로 끝낸다** — `수정` · `추가` · `삭제`. **`고친다` · `걷는다` · `반영한다` 같은 「~한다」 동사형을 쓰지 않는다.** 예: `fix: 코드 생성 훅이 다른 PC 경로를 가리키던 증상 수정`. **이 저장소의 옛 커밋은 전부 반대 스타일이므로 이력을 따라가면 틀린다** — 2026-09-08 이후로 바뀐 규칙이고 새 규칙이 이력을 이긴다. 타입 접두사(`fix:` · `feat:` · `chore:` · `docs:`)와 한국어 본문은 그대로 |

---

## 1. 셋업

```bash
git clone https://github.com/dbsrjs/Nexus.git && cd Nexus

npm --prefix server install
npm run env:setup    # server/.env 를 만든다. 시크릿 셋(JWT 둘 · OAUTH_TOKEN_KEY)은
                     # 이 PC 에서 새로 만들어 넣는다 — 무작위 값이라 PC 끼리 같을
                     # 이유가 없다. 채워진 값은 건드리지 않으니 여러 번 돌려도 된다.
                     # 만들어 낼 수 없는 것(GITHUB_CLIENT_ID · SECRET ·
                     # PUBLIC_BASE_URL)은 끝에 목록으로 알려 준다.

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

# 기본 검증 대상은 Windows 다 (아래 "검증 플랫폼" 참고)
flutter run -d windows --dart-define=API_BASE=http://127.0.0.1:3000
```

#### Flutter 버전 — CI 가 하한선을 고정한다

`.github/workflows/ci.yml` 이 **`env.FLUTTER_VERSION: 3.44.9`** 로 못 박혀 있다(앱 잡 · 통합 잡이 함께 쓴다).
`channel: stable` 만 두면 CI 만 늘 최신을 쓰게 되어, **어느 개발 PC 에서도
재현되지 않는 실패가 CI 에서만 난다.**

값은 개발에 쓰는 것 중 **가장 낮은 버전**이다 — CI 가 하한선을 지켜야 새 SDK
의 API 를 쓴 코드가 낮은 PC 에서 깨지는 것을 여기서 잡는다. 올릴 때는 모든
개발 PC 를 함께 올리고 이 값을 고칠 것.

**PC 마다 Flutter 가 다르면 `pubspec.lock` 이 뒤집힌다.** SDK 가 고정하는
패키지(`matcher` · `collection` · `meta` 등)의 버전이 SDK 버전마다 달라
`flutter pub get` 이 이 파일을 다시 쓴다. 파일 자체는 저장소에 있지만
**버전 차이로 생긴 그 변경은 커밋하지 않는다**(`git restore app/pubspec.lock`) —
CI 는 어차피 `pub get` 을 새로 돌고, 커밋하면 PC 를 오갈 때마다 뒤집힌다. 근본 해법은
FVM 으로 프로젝트마다 버전을 고정하는 것인데 아직 도입하지 않았다.

#### 검증 플랫폼 — Windows 하나로 좁혀 둔다

플랫폼이 넷이어도 **UI 코드는 한 벌이다.** 비싼 것은 매 변경을 네 곳에서 확인하려는
것이고, 실측 차이가 크다 — Windows 는 빌드 23초 + 즉시 실행, Android 는 증분 빌드
11초에 **에뮬레이터 부팅만 1~2분**(게다가 종종 스스로 꺼진다).

| 플랫폼 | 언제 |
|---|---|
| **Windows** | **모든 변경.** 개발 루프의 기본값 |
| Android | 슬라이스 경계 + 플랫폼 민감 변경(보안 저장소 · 키보드 · `10.0.2.2` · 레이아웃 경계) |
| Web | 슬라이스 경계. 포트폴리오 데모가 웹이다 |
| **iOS** | **동결.** macOS 없이는 빌드 불가 — 이 PC 에서는 작업 대상이 아니다 |

**좁히는 것은 검증이지 코드가 아니다.** 반응형은 기능이 아니라 구조라, PC 전용으로
짜 두면 나중에 모든 화면을 다시 손대야 한다. 플랫폼 폴더도 지우지 않는다.
근거는 [앱-설계.md §0-1](docs/앱-설계.md).

**`--dart-define=API_BASE` 를 반드시 넘긴다.** 기본값은 `http://127.0.0.1:3000` 이라
데스크톱·웹에서는 생략해도 되지만, Android 에뮬레이터는 `http://10.0.2.2:3000` 이어야
한다(에뮬레이터에게 `127.0.0.1` 은 자기 자신이다).

**웹 포트를 5173 으로 고정하는 이유**: 서버 `.env` 의 `CORS_ORIGINS` 가 이 주소만
허용한다(`flutter run -d chrome --web-port=5173`). 다른 포트로 띄우면 브라우저가 요청을 막는다.

**Windows 데스크톱 빌드에는 개발자 모드가 필요하다** — `flutter_secure_storage` 같은
네이티브 플러그인이 심볼릭 링크를 쓴다. 이 PC 는 이미 켜져 있다. 새 PC 라면
`start ms-settings:developers`.

#### Android 에뮬레이터 — 슬라이스 경계에서만

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

계약 검증(`check:*`)은 **CI 에서 push 마다 자동으로 돈다.** 아래 명령은 고치는
중에 손으로 돌려 볼 때 쓴다 — 서버가 안 떠 있으면 한 줄로 알려 준다.

| 명령 | 설명 |
|---|---|
| `npm run db:up` / `db:down` | WSL Postgres 기동 / `wsl --shutdown` |
| `npm run env:setup` | `server/.env` 생성 · 빈 자리 채우기. **여러 번 돌려도 안전하다** |
| `npm run db:up:docker` / `db:down:docker` | Docker 환경일 때. **postgres 하나만 뜬다** — redis · s3(SeaweedFS) 는 개발 루프가 쓰지 않아 프로필(`--profile redis` · `--profile s3`) 뒤에 있다. 배포 구성은 `deploy/`(절차 [deploy/README.md](deploy/README.md)) |
| `npm run db:seed` · `db:studio` | 시드 · Prisma Studio |
| `npm run server:dev` · `server:build` | 개발 서버 · 빌드 |
| `npm --prefix server run typecheck` | 타입 검사만 |
| `npm run server:test` · `server:lint` | 서버 단위 테스트(Jest) · ESLint |
| `npm --prefix server run format` | 서버 Prettier 정렬. **CI 가 `format:check` 를 돈다** — 서버 코드를 고쳤으면 커밋 전에 한 번 |
| `npm run check:<이름>` | **실서버 · 실DB · 실소켓 계약 검증 20종(1,123개)** — CI 가 push 마다 돈다. 목록 · 개수 · 전제(`.env` 값 · 가짜 GitHub · `LLM_PROVIDER=fake`) · 실패할 때 볼 것은 **`nexus-verify` 스킬**이 원본이다. 정적 검사 둘(`check:migrations` · `check:sql-time`)은 DB · 서버 없이 돈다 |
| `cd app && flutter analyze` · `flutter test` | 앱 정적 분석 · 테스트 |
| `npm run app:flow` | **앱 통합 테스트** — Windows 데스크톱 앱을 실서버에 붙여 로그인부터 전송 · 실시간 · 스레드 · 셸 안 화면 · 설정 창(이름 · 사진 · 테마 · 음소거) · 멤버 · DM · 알림함 · AI(묻기 · 이어 묻기 · 지난 대화 다시 열기)까지 끝까지 돈다(약 30초, `db:up` · `server:dev` 필요). 보안 저장소 · drift 는 메모리로 바꿔 개발용 앱의 세션을 건드리지 않는다 |
| `npm run app:flow:headless` | 같은 흐름을 **창 없이**(flutter_tester) 돈다(약 15초). **CI 통합 잡이 push 마다 이것을 돈다**(2026-10-06). 위 흐름이 플랫폼 플러그인을 부르지 않아 창이 필요 없다 — 창 크기가 데스크톱 폭보다 좁으면 테스트가 1280×720 으로 맞춘다 |
| `cd app && dart run build_runner build` | freezed · json_serializable 재생성 |

### 인덱싱 실사용 · 실제 GitHub 웹훅

절차는 [server/README.md](server/README.md) 의 두 절(Ollama 와 모델 · 웹훅 붙이는 법)에
있다. 잊으면 조용히 틀리는 것 둘만 여기 둔다.

- **임베딩은 `nomic-embed-text` 계열을 쓰지 않는다** — v1.5 는 한국어를 못 하고
  v2-moe 는 512 토큰을 넘으면 오류 없이 뒤를 버린다. 기본은 `embeddinggemma`
- **임베딩 모델을 바꾸면 반드시 전체 재인덱싱**(`POST .../repos/:repoId/index`).
  push 만 하면 증분이 돌아 옛 벡터와 새 벡터가 섞이고, 순위만 조용히 틀린다

### DB 는 PC 마다 따로다

계정 · 스페이스 · 메시지는 git 으로 옮겨지지 않는다. 새 PC 에서는 시드로 새로 만들어진다.

---

## 2. 이 환경의 함정 — 전부 실제로 겪은 것들

**같은 실수를 반복하지 말 것.**

| 증상 | 원인 · 대응 |
|---|---|
| `P1001: Can't reach database server` (Node 로는 붙는데 Prisma 만 실패) | Windows 에서 `localhost` 가 `::1` 로 먼저 해석되는데 WSL 포워딩은 IPv4 만 동작. `DATABASE_URL` 에 **`127.0.0.1`** 을 쓸 것 |
| 서버 코드를 고쳤는데 계약 검증이 옛 동작으로 통과함 | `server:dev`(`nest start --watch`)가 **`dist` 는 다시 빌드했는데 실행 중인 서버는 재시작되지 않은 채** 몇 시간째 옛 코드였다(2026-10-06 리팩토링 중 발견 — 그 사이 돌린 검증이 전부 무효). 서버 코드를 고친 뒤 검증하기 전에 **3000번을 잡은 프로세스의 시작 시각**이 고친 시각보다 뒤인지 본다(`Get-Process -Id … | StartTime`). 아니면 `server:dev` 를 내리고 다시 띄운다 |
| `check:oauth` · `browse` · `pulls` · `indexing` 이 결과 없이 `EACCES ... port: 4599` 로 죽음 | Windows 가 부팅 때 **포트 범위를 예약**한다(Hyper-V · WSL — `netsh interface ipv4 show excludedportrange protocol=tcp`). 2026-10-06 재부팅 뒤 4517~4716 이 잡혀 가짜 GitHub 이 못 떴다. 스크립트는 `FAKE_GITHUB_PORT` 를 읽는다 — 범위 밖 포트(예: 4799)로 **서버의 `GITHUB_OAUTH_BASE` · `GITHUB_API_BASE` 와 같이** 맞춘다. **2026-10-09 에는 2927~3126 이 잡혀 `server:dev` 가 `listen EACCES 0.0.0.0:3000` 으로 죽었다** — 관리자 셸에서 `net stop winnat` → `netsh int ipv4 add excludedportrange protocol=tcp startport=3000 numberofports=1` → `net start winnat` 으로 3000 을 영구 제외해 두었다(이 PC). 새 PC 에서도 같은 일이 나면 같은 처방 |
| `taskkill node.exe` 로 DB 까지 죽음 | Prisma 엔진 DLL 잠금을 풀려고 node 를 전부 잡으면 **WSL 세션 유지 프로세스와 개발 서버까지** 함께 죽는다. 실제로 겪었다 — 잠긴 것은 `server:dev` 하나이므로 그것만 끄고 `prisma:generate` 를 돌릴 것 |
| 잘 되다가 갑자기 `ECONNREFUSED` | WSL2 는 배포판의 **마지막 세션이 닫히면 배포판을 정지**시킨다. Postgres 도 함께 죽는다. `npm run db:up` 이 세션을 잡아 둔다 (`.wslconfig` 의 `vmIdleTimeout` 은 VM 만 잡고 배포판은 못 잡는다 — 시도해 봤고 안 된다) |
| PowerShell 스크립트 파싱 에러 | Windows PowerShell 5.1 은 BOM 없는 UTF-8 을 ANSI 로 읽는다. 한글이 든 `.ps1` 은 **UTF-8 BOM** 으로 저장할 것 |
| `wsl` 명령이 무응답 | Ubuntu OOBE(첫 사용자 생성)가 걸린 상태일 수 있다. `wsl --shutdown` 후 재시도. 이 PC 는 개인 UNIX 계정 없이 **root 로** 쓰고 있다 |
| `bash -c` 안의 따옴표가 깨짐 | Git Bash 는 `/bin/sh` 를 Windows 경로로 바꾼다. WSL 명령은 **PowerShell 도구로** 실행하고, 복잡한 스크립트는 파일로 만들어 `wsl ... /bin/bash <path>` 로 넘길 것 |
| `npm --prefix server exec prisma ...` 가 `Could not find Prisma Schema` 로 실패 | `--prefix` 는 npm 이 패키지를 찾는 경로만 바꾸고 **실행되는 명령의 cwd 는 그대로**라 `prisma/schema.prisma` 를 못 찾는다. `npm --prefix server run <script>` 를 쓸 것 — `npm run` 은 패키지 디렉터리 안에서 스크립트를 실행한다 |
| `Building with plugins requires symlink support` | **Windows 개발자 모드**가 꺼져 있다. `flutter_secure_storage` 같은 네이티브 플러그인이 심볼릭 링크를 쓴다. `start ms-settings:developers` 로 켠다. (예전에 이 자리에 있던 `CMake Error ... Visual Studio 16 2019` 는 **Flutter 3.47 로 올라가며 해결됐다** — VS 2026 을 정상 인식하고 데스크톱 빌드가 된다) |
| Android 빌드가 `Run this build using a Java 11 or newer JVM` 으로 실패 | 이 PC 의 시스템 기본 java 가 **8** 이라 Gradle 이 그걸 집는다. `flutter config --jdk-dir <JDK21 경로>` 로 고정한다(이미 설정돼 있다) |
| `flutter` 명령이 전부 `애플리케이션 제어 정책에서 이 파일을 차단했습니다` 로 실패 | **Smart App Control** 이 적용 상태가 됐다. Flutter SDK 가 `bin/cache/` 에 직접 내려받는 `dartvm.exe` 는 서명이 없어 로드가 차단된다. Windows 11 은 이 기능을 **평가 모드로 시작해 스스로 적용으로 넘어가므로** 어느 날 재부팅하면 갑자기 걸린다. 확인은 `HKLM:\SYSTEM\CurrentControlSet\Control\CI\Policy` 의 `VerifiedAndReputablePolicyState`(1=적용) 와 `Microsoft-Windows-CodeIntegrity/Operational` 로그. **끄는 것은 사용자만 할 수 있고 되돌릴 수 없다**(`start windowsdefender://smartappcontrol`). **2026-10-06 에 다시 적용 상태로 돌아와 있었고, 이번에는 `dart analyze` 도 막혔다** — 막히는 것은 `dartaotruntime.exe`(분석 서버 · 프런트엔드 컴파일러 · `dart format` 이 이것으로 돈다)이고 **`dart 파일.dart` 로 직접 도는 JIT VM 은 산다.** 그래서 `package:analyzer` · `package:dart_style` 을 부르는 작은 스크립트를 `dart --packages=.dart_tool/package_config.json` 으로 돌리면 정적 분석과 포맷은 된다. 위젯 테스트 · 빌드 · 실행은 우회가 없다 |
| 자동 생성 마이그레이션에 `DROP INDEX ..._hnsw_idx` 가 섞임 | Prisma 가 표현하지 못해 수동 관리하는 pgvector 인덱스를 드리프트로 오인한다. **네 번 겪었다**(7-1 · 7-3 · 9-1 · 9-2a). 이제 `npm run check:migrations` 가 CI 에서 잡는다 — 그래도 생성된 SQL 은 읽고 커밋할 것 |
| `flutter run` 이 시작하자마자 조용히 종료 | `flutter run` 은 stdin 으로 키 명령(r · R · q)을 받는데, 백그라운드로 띄우면 stdin 이 EOF 라 종료로 해석한다. 사람이 직접 터미널에서 돌리거나, 검증 자동화는 `flutter build web` 후 정적 서버로 띄울 것 |
| `flutter run` 을 백그라운드로 띄우고 싶다 | stdin 이 EOF 라 죽는 것이므로 **stdin 을 열어 두면 산다**: `tail -f /dev/null \| flutter run -d web-server --web-port=5173 …`. 디버그 웹 빌드는 난독화되지 않아 **예외 원문과 Dart 스택이 그대로 보인다** — 릴리스 빌드(`flutter build web`)로는 `dartException: Sk` 같은 축약만 나와 원인을 못 찾는다 |
| `prisma migrate dev` 가 거부됨 | 비대화형 환경에서 HNSW 드리프트를 감지해 확인을 물으려 한다. `migrate diff --from-schema-datasource … --to-schema-datamodel … --script` 로 SQL 을 만들어 손질한 뒤 `prisma:deploy` — 절차는 `nexus-migration` 스킬 |
| `adb shell input text` 가 NullPointerException | 한글을 넣지 못한다. 실기기 검증 문구는 영문으로 쓸 것 |
| `adb shell input swipe` 로 길게 눌러 끌기가 시작되지 않음 | 끌기는 500ms 길게 누르기 뒤에 시작하는데 `swipe` · `draganddrop` 은 누르는 시간을 따로 못 준다. `input motionevent DOWN x y` → 1초 → `MOVE` … → `UP` 으로 나눠 보낸다 |
| `--dart-define=ROUTES=/s/...` 가 `s:/...` 로 바뀌어 들어감 | Git Bash 가 `/` 로 시작하는 인자를 Windows 경로로 바꾼다. `MSYS_NO_PATHCONV=1 flutter test …` 로 끈다 |
| 브라우저 자동화로 Flutter 웹 입력이 안 먹음 | Flutter 웹은 캔버스로 그려 접근성 트리가 비어 있다. `flutter-semantics-placeholder` 를 클릭해 시맨틱스를 켜면 입력 요소가 노출된다. 그래도 **BackSpace · 값 직접 대입은 컨트롤러까지 전달되지 않고 타이핑만 append 된다** — 폼을 비우려면 페이지를 새로고침할 것 |
| 웹 확인 중 Chrome 탭이 스크린숏 · 클릭에 응답하지 않음 · 클릭이 가끔 사라짐 | 확장 프로그램(Claude in Chrome)이 연 탭은 **사용자 창 뒤에 가려지면 `visibilityState: hidden` 이 되어 Flutter 가 그리기를 멈춘다.** 사용자 Chrome 을 빌리지 말고 **별도 프로필의 헤드리스 Chrome** 을 띄워 CDP 로 조작한다(`chrome --headless=new --remote-debugging-port=9520 --user-data-dir=<임시>`). 가려져도 그리고, 마우스 이동 · 누름이 사람처럼 들어가 「진입 직후 클릭 유실」도 재현되지 않았다(확장의 부작용이었다). **디버깅 포트는 예약 범위 밖으로** — 9333 은 9312~9411 예약에 걸려 조용히 안 떴다(2026-10-08) |
| 웹 빌드를 고쳤는데 브라우저가 옛 동작 그대로 | `python -m http.server` 는 캐시 헤더를 주지 않아 Chrome 이 **옛 `main.dart.js` 를 디스크 캐시에서** 읽는다(새로고침 · `ignoreCache` 로도 남았다). CDP 의 `Network.setCacheDisabled` + `clearBrowserCache` 뒤 새로고침하고, `performance.getEntriesByType('resource')` 의 `main.dart.js` 크기가 새 빌드와 같은지 본다. **배포 때도 같은 문제다** — `index.html` · `flutter_bootstrap.js` · `main.dart.js` 는 `no-cache` 로 줄 것 |
| `flutter test --platform chrome` 이 `loading …` 에서 영원히 멈춤(Windows) | Flutter 도구의 테스트 서버가 요청 경로를 `path.fromUri` 로 바꿔 Windows 에서 `canvaskit\canvaskit.js`(역슬래시)가 되고, `startsWith('canvaskit/')` 가 거짓이라 **CanvasKit 을 404** 로 준다(`flutter_tools/lib/src/test/flutter_web_platform.dart` 의 `_localCanvasKitHandler`, 3.47). 우리 코드 문제가 아니다 — 이 PC 에서는 앱 테스트를 JS 로 돌릴 수 없다. 리눅스(CI)에서는 돈다. `drift/native` · `dart:io` 를 import 하는 테스트는 어차피 웹으로 컴파일되지 않는다 |
| Windows 러너 C++ 를 고쳤는데 확인할 Windows 가 없다(클라우드) | **zig 로 컴파일 · 링크는 해 볼 수 있다**(«마지막» 4). `pip download ziglang` 의 `zig c++ -target x86_64-windows-gnu`(mingw 헤더) + `flutter precache --windows`(엔진 헤더 · 래퍼 · `flutter_windows.dll.lib`). 실행은 못 하고, MSVC 의 `/W4 /WX` 와 같지 않으니 `-Wall -Wextra -Wconversion` 으로 가깝게 맞춘다. 래퍼 중 `engine_method_result.cc` 는 빼고 링크한다(`core_implementations.cc` 와 중복) |
| `docker compose --profile s3` 가 `pull access denied for minio/minio` 로 실패 | **Docker Hub 의 `minio/minio` 저장소가 사라졌다**(2026-10-09 확인). s3 프로필을 SeaweedFS(`chrislusf/seaweedfs`)로 바꿨다 — 키는 `server/docker/seaweedfs-s3.json`, 버킷은 `node scripts/s3-bucket.mjs` |

### 코드에서 겪은 함정

괄호는 겪은 단계다 — 경위는 [진행 기록](docs/진행-기록.md) 의 그 절.

| 증상 | 원인 · 대응 |
|---|---|
| 인증 없는 경로의 500 응답에 키 길이 · DB 호스트가 실림 | 전역 예외 필터가 `HttpException` 이 아닌 `Error` 의 message 를 응답에 그대로 실었다. **2026-10-05 보안 점검에서 필터가 원문을 접고 로그로만 남기게 바꿨다** — 사람에게 보일 문구는 `HttpException` 으로 던질 것. 공개 경로(OAuth 콜백 · 웹훅)의 감싸기는 그대로 둔다 (10-2a) |
| 사람이 `github@bot.nexus.invalid` 로 가입해 GitHub 봇 자리를 차지함 | 봇은 이메일로 찾는데 가입이 `.invalid` 를 막지 않았다. 이제 가입이 예약 도메인을 400 으로 막고, 웹훅은 봇 표식(`bot:no-login`)이 없는 행이면 게시하지 않는다. **서버가 만드는 계정은 `.invalid` 도메인에 둔다** (보안 점검) |
| 응답 본문에 실은 `retryAfter` 가 앱에 도착하지 않음 | 같은 필터가 본문을 일정한 봉투로 다시 빚으며 **커스텀 필드를 버린다.** 표준 헤더(`Retry-After`)로 보낼 것 (10-3a) |
| `.env` 에 `X=` 로 자리만 잡았더니 엉뚱한 경로가 됨 | `??` 는 빈 문자열을 통과시킨다(`resolve('')` = 작업 디렉터리). **빈 값을 미설정으로 치려면 `\|\|`** (8-1) |
| `retryAfterSec: 0` 이 무시됨 | `x ? … : …` 는 `0` 을 거짓으로 본다. `!= null` 로 볼 것 (12). **12단계에서 고친 뒤에도 인덱싱 큐의 `fail()` 에 같은 모양이 남아 있었다**(2026-09-27) — 판정을 순수 함수로 빼 한 자리에만 두었다 |
| getter 를 읽을 때마다 리스너가 하나씩 늘어남 | Dart 에서 `..` 는 대입보다 느슨하다 — `a ??= B()..listen()` 은 `(a ??= B())..listen()` 이다 (8-2) |
| 화면을 옮기면 build 중 `setState` 예외 | `build()` 안에서 리스너를 거쳐 `setState` 를 부르는 일을 했다. 프레임이 끝난 뒤로 미룰 것 (8-2) |
| 도는 스프린트가 계획 뒤로 밀림 | Prisma 도 Dart 도 enum 을 **선언 순서**로 정렬한다. 명시적 순위를 둘 것 (9-3) |
| GitHub 본문에서 제목 · 번호 목록만 안 그려짐 | **GitHub 본문은 CRLF 다.** `'\n'` 으로만 쪼개면 `\r` 이 남아 `$` 로 끝나는 정규식만 실패한다 (11) |
| 셸 안 화면에서 `push` 하면 `!keyReservation.contains(key)` 로 앱이 죽음 | go_router 는 `ShellRoute` 하나에 페이지 키 하나라, 셸이 떠 있을 때 셸 안 라우트를 push 하면 겹친다. **덮어서 여는 갈래(저장소 · 커밋 · PR)는 셸 밖에 둔다.** 셸 빌더에서는 자식의 `pathParameters` 에 기대지 말고 경로를 직접 읽는다 (11 · UI 리디자인) |
| 소켓 이벤트를 하나 더했더니 컴파일이 막힘 | `SocketEvent` 가 `sealed` 라 의도된 동작이다. `features/realtime/socket_controller.dart` 의 `switch` 를 함께 고친다 (10-2a) |
| 메시지 캐시에 컬럼을 더했는데 큐에 있는 메시지에서 깨짐 | 목록은 캐시와 큐를 `UNION` 하는 쿼리 하나다. **양쪽 SELECT 에 모두** 넣는다(큐 쪽은 `NULL`) (10-3b) |
| 공개 채널의 멘션이 뱃지에서 빠짐 | 공개 채널은 읽음 마커를 남기기 전까지 `channel_members` 행이 없다. 집계는 **`LEFT JOIN`** (7-4) |
| 실패 처리 뒤에 낡은 쓰기가 착지함 | `Promise.all` 은 먼저 실패한 것만 알리고 **나머지를 취소하지 않는다.** 뒤이어 정리할 일이 있으면 `allSettled` 로 전부 정착한 뒤 판단 (12) |
| raw SQL 의 시각 비교가 늘 참 | 시각 컬럼은 `timestamp without time zone` 에 Prisma 가 UTC 를 쓰는데 `now()` 는 DB 로컬(KST)이다. `(now() at time zone 'utc')` — `check:sql-time` 이 잡는다 (12) |
| 계약 검증이 실패해야 할 때 통과함 | `undefined === undefined` — 앞 단계가 실패해 둘 다 없을 때 "같다"가 된다. **값이 있는지부터** 단언한다 (10-2b · 12) |
| 검증 스크립트에서 두 번째 스페이스 생성이 거부됨 | slug 가 한글을 떨어뜨려 이름 둘이 같은 slug 를 요구한다. 검증용 이름은 **영문** (10-2b) |
| 「GitHub 을 부르지 않았다」 단언이 CI 에서만 깨짐 | 저장소를 붙이거나 main push 웹훅을 받으면 인덱싱 워커가 백그라운드로 GitHub 을 부른다. 호출 수를 재기 전에 `scripts/lib/indexing.mjs` 의 `settleIndexing()` 으로 조용하게 만든다 (12) |
| 깨운 작업이 30초 크론까지 밀림(간헐) | 워커의 `running` 플래그가 **비우는 도중 온 `kick()` 을 버렸다** — `lease()` 가 「비었다」를 본 직후 적재된 것이 다음 크론까지 기다린다. 도는 중에 깨우면 `wanted` 를 세워 한 바퀴 더 돈다. AI · 인덱싱 워커 둘 다 그랬다 (13-2) |
| Gemini 모델이 산발적으로 503 을 냄 | `-latest` 별칭은 "새 출시마다 핫스왑" 되는 가장 붐비는 모델을 가리킨다. 특정 안정화 버전(예: `gemini-3.5-flash`)을 박아 둘 것. **혼잡은 날마다 바뀐다** — 9-22 에 503 이던 3.5-flash 가 9-23 엔 매번 200 이었다 (13-1 · LLM 교체) |
| AI 답이 4분 넘게 오지 않음 | Gemini 가 붐비면 200 을 **255초** 뒤에 준다(3.5-flash 실측). 전환은 429 · 5xx 에서만 일어나 느린 응답에는 소용이 없었다. 어댑터가 `AbortSignal.timeout` 으로 **60초**(`LLM_TIMEOUT_SEC`)에 끊고 504 로 던져 전환 모델이 받는다. Node 의 `fetch` 는 `TimeoutError` 로 던진다 (LLM 교체 후) |
| 생각하는 모델로 바꿨더니 답이 몇 줄에서 끊김 | Gemini 3.x 는 **생각 토큰도 `maxOutputTokens` 에서 쓴다.** 3.5-flash 는 기본(medium)으로 생각에만 ~2,600 토큰을 써 상한 2048 에서 잘렸다. 상한 8192 · `thinkingLevel: low` 로 두고, 잘린 답(`finishReason: MAX_TOKENS`)은 러너가 실패로 돌린다 (LLM 교체) |
| 통합 테스트에서 넣은 글자가 사라짐 · 엉뚱한 칸에 들어감(느린 러너에서만) | `enterText` 는 지금 붙은 입력 연결로 보낼 뿐 들어갔는지 알려 주지 않고, `find.byType(NxField).last` 는 **닫히는 다이얼로그의 입력**을 가리킬 수 있다. 칸은 라벨 · 소속(`MessageComposer`)으로 찾고 **`typeInto`**(넣고 · 확인하고 · 다시 넣기)를 쓴다. CPU 1코어(`taskset -c 0`)로 돌리면 재현된다 (2026-10-06) |
| 통합 테스트에서 누른 버튼이 아무 일도 안 함(경고도 없음) | 입력으로 켜지는 버튼은 **다음 프레임에** 켜진다. `enterText` 직후 `tap` 하면 꺼진 버튼을 누른다 — 사이에 `pump()`. 팝업 메뉴는 펼쳐지는 동안 누르면 빗나간다(이쪽은 경고가 뜬다) (14) |
| 테스트에서 provider 안의 `ref.listen` 이 아무 이벤트도 못 받음 | **Riverpod 3 은 구독자가 없는 provider 를 멈춘다.** `container.read` 로는 안 살아난다 — `container.listen` 으로 붙들 것. 앱은 `main.dart` 가 `watch` 해서 괜찮다 (2026-09-27) |
| 길게 누르기 시트가 `BOTTOM OVERFLOWED` 로 잘림 | `showModalBottomSheet` 는 기본 최대 높이가 화면의 9/16 이다. `isScrollControlled: true` 가 없으면 항목이 늘 때 조용히 넘친다 (13-1) |
| 실패한 provider 의 오류 화면이 수십 초 동안 안 뜸(뼈대만 보임) | **Riverpod 3 은 실패한 provider 를 스스로 재시도하고 그동안 상태가 「로딩 + 오류」다.** `AsyncError()` 패턴은 그 상태를 못 잡는다 — `hasError` 로 가를 것. 회전 스피너 시절에는 `pumpAndSettle` 이 재시도가 끝날 때까지 기다려 줘 테스트가 가렸다 (15-2) |
| `tester.pageBack()` 이 뒤로 가기를 못 찾음 | Material · Cupertino 버튼만 찾는다. 자체 머리 줄은 `find.byType(NxBackButton)` 을 누른다 (15-2) |
| 셸 안에서 띄운 오버레이가 모바일 탭 줄 아래에 깔림 | `ShellRoute` 는 제 Navigator(= 제 Overlay)를 가진다. 화면 전체를 덮을 것(동작 카드)은 **`Overlay.of(context, rootOverlay: true)`** 에 넣는다 (15-3) |
| 오버레이에 띄운 패널이 앵커가 아니라 화면 끝에 붙음 | 오버레이 안의 `Align` 은 오버레이 전체로 늘어난다. 위로 여는 메뉴를 `topLeft` 로 두어 화면 맨 위로 튀었다 — **여는 방향 쪽 모서리**에 붙일 것 (15-3) |
| 끌기가 시작되자 옆 카드가 흐려짐 | 키 없는 목록에서 끄는 항목이 빠지면 **이웃이 그 자리의 State 를 물려받는다.** `Draggable` 이 든 목록은 항목마다 키 + `findChildIndexCallback` (15-3) |
| 같은 id 의 색이 플랫폼마다 다름 | **`String.hashCode` 는 VM 과 웹(JS)에서 다르고** 실행마다 같다는 보장도 없다. 화면에 드러나는 값은 직접 해시한다 — 웹의 수는 2^53 까지만 정확하니 31비트 안에서 굴린다(`avatarSlot`) (15-3) |
| 웹에서만 메시지가 하나도 안 보내짐(VM · Windows 는 멀쩡) | **웹(JS)의 시프트는 32비트**라 `1 << 32` 가 0 이다 — `Random().nextInt(1 << 32)` 가 `nextInt(0)` 으로 던졌다. 큰 상수는 리터럴(`0x7fffffff`)로 쓴다. VM 테스트로는 못 잡는다 (6-2 부터, 16-1 에서 잡음) |
| 가시성 규칙을 서비스마다 따로 들고 있으면 새 규칙이 한쪽에만 걸린다 | 16단계에서 역할 가림을 더했는데 AI · 대화→이슈가 옛 「공개 또는 명단」 규칙을 각자 갖고 있어 가린 채널을 우회했다. **채널 판정은 `ChannelsService`(→ `channelAccess()`) 만 부른다** — 새 경로에서 Prisma `where` 로 가시성을 다시 쓰지 않는다 (16단계 검토) |
| 방금 만든 채널의 설정 창을 열자마자 「볼 수 없는 채널」로 쫓겨남 | 그 화면이 보는 provider 가 한동안 구독자가 없어 **Riverpod 3 이 멈춰 둔** 것이었다. 다시 깨어난 첫 값이 옛 목록이다. **목록에 없다고 곧바로 화면을 옮기지 않는다** — 이유를 보이고 새 값을 기다리거나, 「있다가 빠지는 순간」만 본다(셸의 채널 목록 리스너) (16-2) |
| 다이얼로그 · 패널 안 목록 위아래에 큰 빈칸(Android) | `ListView` 의 기본 여백이 기기의 안전 영역(상태 표시줄 · 내비게이션 바)을 가져온다. 화면 전체가 아닌 자리의 `ListView` 는 `padding: EdgeInsets.zero` (16-2) |
| 셸 밖 화면(설정 창)에서 돌아오면 간헐적으로 「build 중 setState」 | 화면이 내려가 provider 의 구독자가 0 이 되면 **Riverpod 3 은 그것을 멈추고**, 그 사이 의존이 바뀌면 돌아온 위젯의 build 안에서 밀린 갱신을 터뜨린다. 여러 화면이 build 중 처음 구독하는 provider 는 **앱 뿌리에서 `listen` 으로 붙든다**(`memberNamesProvider` · `currentSpaceProvider`). 셸에 두면 셸 밖으로 나갈 때 같이 내려간다 (16-1, `currentSpaceProvider` 는 2026-10-06 CI 헤드리스 흐름이 잡았다 — 느린 CPU 에서만 드러난다) |
| 모바일 셸 안 화면에서 키보드를 띄우면 입력창이 키보드 위로 한 번 더 뜸(Android) | 셸의 `NxPage` 안에 화면의 `NxPage` 가 겹쳐 **둘 다 키보드 높이를 더했다.** `NxPage` 가 올린 만큼을 안쪽 `MediaQuery` 에서 지운다 — **`SafeArea` 안쪽 context 로** 지울 것. 바깥 `MediaQuery` 를 복사하면 SafeArea 가 지운 상태 표시줄 여백이 되살아나 머리 줄이 내려간다. 테스트는 `WidgetsApp` 이 뷰에서 MediaQuery 를 다시 만들므로 `tester.view.viewInsets` 에 싣는다 (17, 15단계부터) |
| 화면을 닫으면 디버그 빌드에서 `deactivated widget's ancestor` 로 멈춤 | `dispose()` 안에서 `ProviderScope.containerOf(context)` 같은 조상 조회를 했다. **`didChangeDependencies` 에서 참조를 잡아 두고** `dispose` 는 그것만 쓴다 — 예외로 정리도 못 돌아 구독이 남았다 (13-2 후 `74ccc01`) |
| 토큰을 갱신하고 다시 붙어도 소켓이 영영 「연결 끊김」(서버가 꺼진 채 앱을 열고 저장된 토큰이 만료됐을 때) | socket_io_client 는 주소마다 Manager 를 캐시하고 「같은 이름공간이 이미 있나」로 새로 만들지 정하는데, **경로 없는 API 주소에서는 그 판정이 `''` 를 찾고 소켓은 `'/'` 에 있어 늘 거짓** — 옛 Manager 의 **옛 Socket(옛 `auth`)** 이 돌아와 옛 토큰으로 거부당했다. `forceNew` 로 연결마다 새로 만든다(`socketOptions()`). **`SocketClient` 를 가짜로 바꾼 재연결 테스트는 이것을 못 잡았다** — 실제 라이브러리 경로는 웹에서 재현해 봤다 (웹 확인, 2026-10-07) |
| 재연결 뒤에도 DM 상대가 「나간 사람」 · 멘션 자동완성이 빔 | 실패를 빈 목록으로 삼키는 provider(`spaceMembersProvider`)는 **오프라인으로 켜면 빈 값에 머문다.** 재연결(`SocketConnected`) 때 채널 · 카테고리와 함께 무효화한다. 새로 「실패를 삼키는」 provider 를 만들면 여기에 같이 넣을 것 (웹 확인, 2026-10-07) |

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

### 반복해서 쓰는 판단 — 단계마다 같은 답을 냈다

새 기능에서 같은 갈림길을 만나면 여기서 시작한다. 뒤집을 때는 이유를 적는다(10-3a 의
하이라이팅 · 11 의 `pull_requests` 처럼). 괄호는 그 판단이 나온 단계다.

1. **원본이 외부(GitHub)면 사본도 캐시도 두지 않는다 — 프록시한다.** 사본은 동기화가
   곧 숙제가 되고, 방금 push 한 것을 확인하려는 순간이 캐시가 옛것을 보이는 순간이다.
   스키마의 `pull_requests` 는 있지만 쓰지 않는다 (10-2b · 10-3a · 11)
2. **모르는 값은 `0` 이 아니라 `null` 이고, 모르면 화면이 말하지 않는다.** 0 은 "안
   바뀌었다"로 읽힌다 — `changedCount` · PR 변경량 · 리뷰 상태 (10-3b · 11)
3. **되돌릴 수 없는 쪽을 나중에 한다.** 첨부는 스토리지 → DB(반대면 파일 없는 행을 고아
   정리가 못 잡는다), 저장소 연결은 DB → GitHub 훅. 외부 호출이 실패해도 행을 지우지
   않고 "다시 걸기"를 남긴다 (8-1 · 10-2b)
4. **조용히 자르거나 버리지 않는다.** 상한을 넘으면 `truncated` 로 알리고, 첨부 하나가
   조건에 안 맞으면 메시지를 만들지 않으며, 없는 라벨 id 는 404. **예외는 사람이 쓴
   본문 안** — 잘못된 멘션 하나로 쓴 글을 잃게 하지 않는다(멤버 아닌 id 는 버린다)
   (7-4 · 8-1 · 9-1 · 9-2b)
5. **요약은 한 겹만 펼친다.** 답글의 답글은 400, 인용 · 대화→이슈의 원문도 요약 한 겹.
   **소프트 삭제된 원문은 링크만 남기고 본문을 싣지 않는다** (7-2 · 7-3 · 9-2b)
6. **받는 사람마다 답이 다른 값은 브로드캐스트에 싣지 않는다** — 리액션은 `mine` 대신
   `(emoji, userId)` 를 보내고 앱이 자기 id 로 접는다 (7-1)
7. **눌러 봐야 실패할 버튼은 만들지 않는다** — 답글 고정은 감추고, `canWebhook=false`
   저장소는 회색, 종류가 `other` 인 이벤트는 눌리지 않는다. 모르면 막는 쪽 (7-5 · 10-2b · 11)
8. **직접 만들 수 있으면 패키지를 들이지 않는다** — 차트(`CustomPainter`) · 신택스
   하이라이터 · 마크다운 · `shared_preferences` · Redis 를 거절했다. 늘리기는 쉽고
   걷어내기는 어렵다. Redis 는 배포 비용이 아니라 **새 PC 셋업 비용**이 문제다
   (9-3 · 10-3a · 12 · 테마 토글)
9. **권한의 무게.** 리액션은 **열람** 권한(읽기 전용 채널에서도 반응은 남긴다), 모두에게
   보이는 변경(핀)은 **전송** 권한, 이슈 · 라벨 만들기는 `member`, 채널 구조나 라벨
   삭제처럼 여럿에게 번지는 것은 `admin`. **읽기 라우트에는 `@MinRole` 을 걸지
   않는다** — 걸면 코드를 볼 사람과 설정을 바꿀 사람이 같아진다 (7-1 · 7-5 · 9-1 · 9-2b · 10-3a)
10. **GitHub 원본을 응답에 그대로 흘리지 않는다** — `_links` · `download_url`(토큰이
    있어야 열리는 주소) · `patch` 는 빼고, 공개 주소 `html_url` 은 싣는다 (10-3a · 11)
11. **쓰기는 멱등으로, 함께 성립해야 하는 쓰기는 한 트랜잭션으로.** 리액션 · 핀은
    멱등, 라벨은 통째 교체(`PUT`). 메시지+멘션 · 답글+`replyCount` · 웹훅 적재+채널
    게시 · 첨부 연결+전송 · 라벨 지우기+붙이기는 한 트랜잭션 — 사이에서 끊기면
    재시도로도 낫지 않는다 (7-1 · 7-2 · 7-4 · 8-1 · 9-2b · 10-1)
12. **멘션은 본문에 `<@userId>` 로 저장한다.** 이름으로 저장하면 개명 · 동명이인 · 공백에서
    깨진다. 입력창만 `@이름` 을 보이고 보낼 때 되돌린다(`MentionDraft`). 자기 자신
    멘션은 저장하지 않고 `@everyone` 이 `@channel` 을 덮는다 (7-4)
13. **머무는 곳은 셸 안, 파고드는 곳은 덮어서.** 채널 · 이슈 보드 · 스프린트 · 파일은
    셸 안, 특정 메시지 · 저장소에서 파고드는 스레드 · 저장소 · 커밋 · PR 은 덮어서 연다.
    **카드에 그림자를 쓰지 않는다**(표면 세 단계가 깊이를 맡는다). 색 · 글자 · 간격은
    `NxTheme` 에서만 꺼낸다 — 화면에 값을 박으면 다크 · 라이트 한쪽이 깨진다
    (UI 리디자인 · 15)
14. **웹훅은 서명이 곧 인증이다.** `@Public()` 이지만 **원문 바이트**(`rawBody`)로
    HMAC 을 검증하고 `timingSafeEqual` 로 비교한다 — 파싱한 객체를 다시 직렬화하면
    멀쩡한 요청이 위조로 판정된다. 시스템 메시지의 작성자는 **스페이스 멤버가 아니고
    로그인할 수 없는** 봇 사용자 하나다 (10-1)

### 모듈 구조 (`server/src/`)

```
config/       jwt.config.ts — 시크릿 해석의 유일한 지점
auth/         가입 · 로그인 · 리프레시 회전 · 재사용 탐지 · JWT 전략
users/        /api/me · 아바타(사용자 단위 — 본인 · 함께 쓰는 스페이스만 열람) · user:updated.
              전역 사용자 목록은 두지 않는다(테넌트 격리)
spaces/       스페이스 CRUD · 멤버 · 초대(목록 · 취소) · 나가기 · 멤버 이벤트 · 스프린트 스위치 · SpaceGuard · SpaceRoleGuard
categories/   채널 그룹
channels/     채널 · 가시성 규칙(channel-access.ts 의 channelAccess() 한 곳) · 읽음 마커 · DM 열기(dm-key.ts — key 가 유일성, 17-1)
notifications/ 인앱 알림(18) — 받는 사람 계산(plan · 볼 수 있는 사람 ∩ 스위치 · 음소거) · 메시지와 한 트랜잭션 ·
              알림함 목록 · 읽음(채널 읽음 마커가 따라 읽힘) · 종류별 스위치(/me/notification-settings)
permissions/  채널별 역할 권한 행(guest · member) · 비공개 채널 명단 — 행을 읽고 쓸 뿐 판정은 channels 가 한다(16-2)
messages/     메시지 목록 · 전송 · 수정 이력 · 소프트 삭제 · 리액션 · 멘션 · 스레드 · 답장 · 핀
storage/      StorageDriver — 바이트를 어디에 둘지. URL 을 만들지 않는다. local(개발) · s3(배포 — R2, CI 가 SeaweedFS 로 태운다)
attachments/  업로드 · 스트리밍 다운로드 · 썸네일 · 파일 목록 · 고아 정리
issues/       이슈 · 라벨 · 댓글 · 칸반 정렬 · 채번(Space.issueSeq)
sprints/      스프린트 · 번다운
oauth/        GitHub 계정 연결 · state · 토큰 암호화(OAUTH_TOKEN_KEY)
repos/        웹훅 수신 · 저장소 연결 · 열람 · 커밋 · PR 프록시
  indexing/   트리 순회 · 거르기 · 청킹 · 벡터 검색 · DB 큐 워커
embedding/    임베딩 어댑터(gemini · local · fake) — EMBEDDING_PROVIDER 뒤에 숨는다
llm/          LLM 어댑터(gemini · local · fake) — LLM_PROVIDER 뒤에 숨는다(AI 만 쓴다, 전역 아님)
ai/           AI 패널(13-1~13-3) — POST /ai/ask 하나 · 프리셋 · 컨텍스트(메시지 · 채널 · 저장소 RAG) ·
              이어 묻기(parentRunId 사슬, 최대 10) · ai_runs 큐 · promptHash 캐시 · 러너 · 소켓 알림 ·
              기록(19 — ai-history.service: 재귀 CTE 로 사슬 끝 · 목록 · 다시 열기, 본인 것 · 볼 수 있는 채널만)
realtime/     소켓 게이트웨이 · 룸 계산 · 이벤트 발신 · 프레즌스(메모리, 저장하지 않음) · 타이핑 중계(17-2)
prisma/       PrismaModule(@Global) + PrismaService
common/       예외 필터 · 데코레이터 · 페이지네이션 DTO · slug · bigint 직렬화
```

### 앱 구조 (`app/lib/`)

[앱-설계.md §3](docs/앱-설계.md) 의 구조를 따르되 **쓰는 것만 만든다.** 빈 디렉터리를
미리 파 두지 않는다. 파일 단위 안내는 [코드-둘러보기 §5](docs/코드-둘러보기.md).

```
core/env.dart            API 주소를 읽는 유일한 지점. 하드코딩 금지
core/router.dart         go_router + 인증 가드(redirect). 셸 안(머무는 곳) / 셸 밖(덮어서)
core/auth_redirect.dart  인증 갈래 판정 — 거쳐 가는 화면(/ · /login · /signup)이 `from` 으로 원래 주소를 들고 다닌다(«마지막»). 스스로 로그아웃하면 버린다
core/breakpoints.dart    Layout(mobile/tablet/desktop) + 고정 폭 상수
data/api/                영역마다 한 파일 + api_client(dio · 401 → 리프레시 1회 재시도)
                         실패는 AuthFailure · ApiFailure 로 분류(api_failure.dart)
data/socket/             Socket.IO 연결 + 이벤트(sealed SocketEvent)
data/local/app_database.dart  drift — 캐시 + 전송 큐(outbox_messages)
data/repositories/       API + 캐시를 잇는 곳. **화면은 여기만 통해 데이터를 본다**
data/auth_storage.dart   flutter_secure_storage 래퍼(토큰 + 마지막 계정)
data/settings_storage.dart 같은 저장소의 화면 설정(테마). 수명이 달라 클래스를 나눴다
domain/models/           freezed 모델
features/auth/ space/ channel/  로그인 · 가입(틀은 auth_card) · 스페이스 선택 · 채널 목록(카테고리 묶기)
features/chat/           메시지 리스트 · 입력창 · 낙관적 전송 · 실시간 반영 · 스레드 · 멘션 ·
                         첨부(attachment_draft — 고른 즉시 업로드) · 선택 모드
features/files/          스페이스 파일 목록 (썸네일 · 캐시하지 않는다)
features/issue/          이슈 보드 · 상세 · 스프린트 · 번다운(CustomPainter)
features/repo/           저장소 연결 · 열람 · 커밋 · PR
features/ai/             AI 패널 · 지난 대화(ai_history — 캐시하지 않는다, 19)
features/realtime/       소켓 수명 관리 + 채널 목록 동기화
features/notifications/  알림함(셸 안 /s/:spaceId/notifications · 캐시하지 않는다) · 안 읽은 수(main.dart 가 뿌리에서 붙든다)
features/settings/       설정 창(셸 밖 /settings/:section — 내 계정 · 비밀번호 · 알림 · 화면) · 테마 컨트롤러
features/channel_settings/ 채널 설정 창(셸 밖 /s/:spaceId/c/:channelId/settings/:section — 개요 · 멤버 · 권한, 16-2)
features/space_settings/ 스페이스 설정 창(셸 밖 /s/:spaceId/settings/:section — 일반(이름 · 스프린트) · 멤버 · 초대). 틀은 위 설정 창과
                         같은 SettingsFrame · SettingsNav. 스페이스 메뉴 · 만들기 · 참여 · 나가기는 features/space/
features/desktop/        OS 알림 · 트레이(«마지막» 4) — DesktopShell(조건부 import: Windows 는 러너의 desktop_shell.cpp 와
                         채널 `nexus/desktop`, 웹은 브라우저 Notification) · 새 알림을 띄울지(보고 있으면 안 띄움) · 누르면 이동.
                         main.dart 가 뿌리에서 붙든다. 이 기기 스위치는 설정 창 「알림」
features/presence/       프레즌스(REST 처음 값 + 소켓) · 이 기기 상태 알림(생명주기 · 10분 무입력) · 입력 중(17-2).
                         main.dart 가 뿌리에서 붙든다. DM 묶음 · 사람 고르기는 features/channel/dm.dart(17-1)
features/shell/          반응형 셸 — app_shell(분기) · space_rail · channel_pane
shared/markdown/         마크다운 — 파서(블록 · 인라인) · MarkdownBody · 평문화
                         **멘션이 이 파서 안에 있다**(파서가 하나여야 한다)
shared/widgets/          NexusAvatar 등 공용 위젯
ui/                      자체 UI(15단계) — NxTheme · 아이콘 · 버튼 · 입력 · 메뉴 · 다이얼로그 · 토스트 ·
                         스위치 · 칩 · 화면 틀. **material · cupertino 를 import 하지 않는다.**
                         디버그 빌드의 `/dev/ui` 가 갤러리(`--dart-define=NX_START=/dev/ui` 로 바로 연다)
```

**앱 규칙**

- **화면은 drift 만 구독한다.** REST 도 소켓도 로컬 DB 를 갱신할 뿐이다. 그래야 오프라인 표시와 실시간 갱신이 같은 코드 경로를 탄다. **한 화면이 두 공급원을 보면 회복되지 않는 틈이 생긴다** — 카테고리만 REST 로 남겼다가 실제로 겪었다(오프라인 진입 후 서버가 돌아와도 계속 '기타'에 묶임).
- **`refresh*` 는 실패를 던지지 않고 `false` 를 돌려준다.** 오프라인은 오류가 아니라 정상 경로다. 캐시를 **빈 값으로 덮어쓰지 않는 것**이 핵심이다.
- **캐시 테이블을 고치면 `schemaVersion` 을 올린다.** 마이그레이션은 통째 재생성이다(캐시는 서버에서 다시 받는다). 빠뜨리면 `no such table` 로 앱이 멈춘다 — 실제로 겪었다.
- **전송 큐(`outbox_messages`)는 재생성 대상이 아니다.** 캐시는 버려도 되지만 큐에 있는 것은 **사용자가 쓴 유일본**이다. 이 구분이 큐를 캐시와 다른 테이블에 둔 이유다. 큐 스키마를 고칠 때는 데이터를 옮기는 마이그레이션을 써야 한다.
- **시각은 `IntColumn` + `_UtcMicros` 컨버터(UTC 마이크로초 정수)로 저장한다.** drift 의 `DateTimeColumn` 은 둘 다 못 쓴다 — 기본값은 Unix **초**라 밀리초가 잘리고, `storeDateTimeAsText` 는 `toIso8601String()` 을 그대로 써서 **마이크로초가 0이면 3자리, 아니면 6자리**로 자릿수가 바뀌고 로컬은 ` +09:00` UTC 는 `Z` 가 붙는다. 문자열 정렬이 곧 시간 순서라는 전제가 깨진다. 둘 다 실제로 순서 버그를 냈다.
- **큐의 전송 순서는 시각이 아니라 `seq`(삽입 순번)가 정한다.** Windows 의 `DateTime.now()` 는 밀리초 해상도라 연속 전송이 **완전히 같은 시각**을 갖는다. 시각에 기대면 순서가 tie-break 로 넘어가 뒤집힌다 — 테스트가 15회 중 5회 실패했다.
- **소켓 핸드셰이크는 연결 시점의 토큰으로 한 번만 검증된다.** 액세스 토큰이 15분이라, 거부당하면 `ApiClient.refreshAccessToken()` 으로 갱신한 뒤 다시 붙어야 한다. 이 경로가 없으면 앱을 오래 켜 둔 뒤 소켓이 **영영** 안 붙고, 전송 큐를 내보낼 계기도 사라진다.
- **보내기는 큐에 넣는 일이다.** 네트워크 상태를 묻지 않는다. 온라인이면 곧바로, 오프라인이면 재연결 때 나간다 — 화면에서 두 경우가 구분되지 않는 것이 목표다.
- **한 채널에서 전송이 실패하면 그 채널의 뒤 메시지는 이번 회차를 건너뛴다.** 2번이 실패했는데 3번이 나가면 대화가 뒤집힌다. 다른 채널은 서로 막지 않는다.
- **API 주소는 `core/env.dart` 밖에서 만들지 않는다.** 옛 `www/api.js:6` 이 `localhost` 를 박아 실기기에서 연결 불가였다.
- **디자인 토큰 이름을 바꾸지 않는다.** `--bg-surface` → `bgSurface` 처럼 표기만 바꿔 1:1 대응시킨다. 갈라지면 디자인 문서와 코드를 대조할 수 없다.
- **서버 오류 문구를 화면에 그대로 쓰지 않는다.** 실패 종류(`AuthFailure` · `ApiFailure`)만 받아 앱이 자기 문구를 쓴다. 서버 문구가 바뀔 때마다 앱 UX 가 흔들리면 안 된다.
- **화면은 토큰만 쓴다(2026-10-06).** 색 · 글자 크기 · 반경 · 여백을 숫자로 박지 않는다 — `test/design_tokens_test.dart` 가 `Color(0x…)` · `fontSize: N` · `circular(N)` · `EdgeInsets…(N)` · 빈 `SizedBox(N)` 을 잡는다. 광학 보정만 `// 토큰 밖: 이유` 로 예외. 토큰 목록과 이유는 [디자인 시스템](docs/디자인-시스템.md) §8
- **화면은 `ui/` 만 본다(15단계).** Material · Cupertino 위젯도, 플랫폼 관용 패턴(손잡이 바텀시트 · NavigationBar · 햄버거 · 물결 · 목록 줄 앞 장식 아이콘)도 쓰지 않는다. `test/no_platform_ui_test.dart` 가 material · cupertino import 를 **줄어드는 허용 목록**으로 막는다 — 화면을 옮기면 목록에서 그 줄을 지워야 테스트가 통과한다(15-3 에서 비었다 — **다시 채우지 않는다**). 설계는 [15단계 설계](docs/superpowers/specs/2026-09-27-15-자체-UI-design.md)
- **반응형 폭 분기는 `features/shell/app_shell.dart` 한 곳에서만 한다.** 안쪽 위젯은 자기가 어떤 폭에 있는지 모른다. 분기가 화면마다 흩어지면 손댈 수 없게 된다.
- **메시지 목록은 서버가 주는 최신순 그대로 둔다.** 화면은 `reverse: true` 로 그린다. 뒤집어 보관하면 페이지를 이어붙일 때마다 다시 뒤집어야 한다.
- **전송 실패한 메시지를 조용히 지우지 않는다.** `failed` 로 표시해 재시도·삭제를 남긴다. 사라지면 사용자는 보냈다고 믿는다.
- **Enter 전송은 물리 키보드에서만 동작한다.** 모바일 소프트 키보드는 Enter 를 IME 가 줄바꿈으로 소비하므로 전송 버튼을 쓴다. Shift+Enter 는 어디서나 줄바꿈이다.
- **401 재시도는 1회뿐.** 무한 재시도는 서버의 리프레시 재사용 탐지에 걸려 세션 family 가 끊긴다.
- **모델을 고치면 `dart run build_runner build`** 를 돌린다. `.freezed.dart` · `.g.dart` 는 커밋한다 — 체크아웃 직후 코드젠 없이 빌드되게 하기 위함이다.
- **애노테이션과 클래스 사이에 아무것도 끼우지 않는다.** `@DriftDatabase(...)` 와 `class AppDatabase` 사이에 상수 하나를 넣었더니 애노테이션이 그 상수에 붙어 **drift 가 `.g.dart` 를 아예 만들지 않았다.** 로컬에는 옛 생성물이 남아 있어 `analyze` · `test` 가 전부 통과했고, **깨끗한 체크아웃으로 도는 CI 만 실패했다.** 코드 생성이 걸린 변경은 `.dart_tool/build` 를 지우고 한 번 돌려 볼 것 — 캐시가 있으면 "생성되지 않음"이 "변경 없음"처럼 보인다.

### 옛 모듈 — 남은 것이 없다

단일 테넌트 시절 모듈은 전부 `spaceId` 기준으로 다시 쓰거나 지웠다 — `files`(8-1, 서명 URL 을 발급하던
코드라 참고용으로도 남기지 않았다) · `issues`(9-1) · `ai`(13-1) · `permissions`(16-2) · `notifications`(18). **`gitlab` 은
2026-10-05 정리에서 지웠다** — 20 단계가 새로 쓴다(살릴 줄이 없었다, git 이력에 있다).
`src/realtime/redis-io.adapter.ts` 만 다중 인스턴스가 될 때까지 두 tsconfig 의 `exclude` 로 빠져 있다.

---

## 4. 어디까지 됐나

단계 표는 §5. 단계마다 무엇을 왜 그렇게 정했고 **무엇을 확인하지 못했는지**는
[docs/진행-기록.md](docs/진행-기록.md) 에 있다. **이미 끝난 단계의 코드를 다시 건드릴 때는
그 절부터 읽는다** — 뒤집으면 안 되는 판단과 그 이유가 거기 있다.

**아직 없는 것** — 전부 §5 의 어느 단계가 맡는다(2026-09-27 편입): GitLab(20) · OS 수준 링크 연결(Android App Links · Windows 프로토콜) · 실제 VM 배포(마지막 — 배포 구성 · S3 드라이버 · 테넌트 격리 검증 · 앱 안 딥링크 · 데스크톱 · 웹 알림 · 트레이는 2026-10-09 에 생겼다). **모바일 푸시(FCM)는 «마지막»에서 뺐다**(보스 결정, 2026-10-09). 창 크기 · 위치 기억도 없다.
그룹 DM · 직접 고르는 상태(방해 금지) · 마지막 접속 시각은
17단계 범위에서 뺐다([17단계 설계 §5](docs/superpowers/specs/2026-10-05-17-DM-프레즌스-타이핑-design.md)).
스레드 구독(참여자 전원에게 답글 알림) · 채널마다 다른 알림 스위치 · 이슈 알림은 18단계 범위에서 뺐다([18단계 설계](docs/superpowers/specs/2026-10-05-18-인앱-알림-design.md)).

---

## 5. 남은 작업

잘라내는 기준: **미루는 것은 기능이지 구조가 아니다.** 실시간을 앱보다 먼저 한 이유다
(원안은 계층을 다 쌓고 앱이라 5단계까지 화면이 없었다 — 2026-08-14 개정).
**한 기능이 서버에서 화면까지 끝나야 완료로 친다** — "화면 없는 구간"을 다시 만들지 않는다.

끝난 단계는 한 줄로 접었다. 조각별 경과는 [진행 기록](docs/진행-기록.md) 의 같은 이름 절에 있다.

| 단계 | 내용 | 상태 |
|---|---|---|
| 1~4 | 자산 정리 · 스키마 재작성 · auth · spaces · 채팅 API · 실시간 최소 | ✅ |
| 5 · 6 | Flutter — 인증 · 반응형 셸 · 채널/메시지 · 소켓 → drift 캐시 · 전송 큐 | ✅ **Phase 0** |
| 7 | 대화 — 리액션 · 스레드 · 답장(인용) · 멘션 · 핀 | ✅ |
| 8 | 첨부 — 스토리지 추상화 · 업로드 · 스트리밍 · 썸네일 · 파일 목록 | ✅ |
| 9 | 이슈 보드 · 상세 · 라벨 · 대화 → 이슈 · 스프린트 · 번다운 | ✅ |
| 10 | 웹훅 수신 · GitHub 계정 연결 · 저장소 자동 등록 · 열람 · 커밋 | ✅ |
| — | 코드 하이라이팅 · 마크다운 · UI 리디자인 · 테마 토글 · 세션 도구(스킬 5개) | ✅ |
| 11 | PR 열람 — 목록 · 상세 · 바뀐 파일 · 채널 진입 | ✅ |
| 12 | 저장소 인덱싱 — 트리 순회 · 청킹 · 임베딩 · HNSW 검색 · 증분(compare). 실제 태우기 · 빚 정리(모델 기록) 포함 | ✅ |
| 13-1 | 대화 요약 — LLM 어댑터 · `promptHash` 캐시 · DB 큐(`ai_runs`) · 다중 선택 | ✅ |
| 13-2 | AI 패널 — 자유 지시문 + 프리셋 · 컨텍스트 칩(메시지 · 채널 · 저장소 RAG) · 인용 · 모델 불일치 503 | ✅ |
| — | 브랜드 · 디자인 시스템 정비(2026-10-06) — 마크 «연결점» 교체 · 토큰 보강(글자 크기 · 반경 · 투명도 · 아이콘 크기 · 브랜드 · 장식)과 화면 적용 · 토큰 강제 테스트 · 라이트 의미색 대비(AA) · 모션 줄이기 · 로그인 «연결망» 개편 | ✅ |
| — | 전체 리팩토링(2026-10-06) — 앱 호버 표면 통일 · 채팅 화면 분리, 서버 페이지 · 메시지 꾸미기 · 채널 판정 · 저장소 문지기 · 설정 · 워커 루프 공통화, 죽은 코드 · 린트 무시 목록 정리, **웹훅 게시가 실시간으로 안 닿던 결함** 수정 | ✅ |
| — | LLM 교체 — `gemini-3.1-flash-lite` → **`gemini-3.5-flash`**(무료 티어 재측정) · 생각 수준 `low` · 상한 8192 · 잘린 답 실패 처리 · **429 · 5xx 면 3.1-flash-lite 로 자동 전환**(무료 한도 3.5-flash 하루 20회 · lite 500회, 전환 답은 캐시 제외) | ✅ |
| 13-3 | AI 멀티턴 — `parentRunId` 사슬 · user/assistant 역할 · 첫 문답 근거 물려받기 · 상한 10 · 앱 문답 목록 | ✅ |
| 14 | 사용자 설정 — 설정 창(표시 이름 · 프로필 사진 · 비밀번호 변경 · 채널 음소거 · 테마) · `user:updated` · 아바타 열람 규칙 | ✅ |
| 15 | UI/UX 개편 — Flutter 기본(Material) 컴포넌트를 전부 자체 UI 로 교체 · 디자인 다듬기 · 이슈 보드 드래그 정렬 화면. 설계는 [15단계 설계](docs/superpowers/specs/2026-09-27-15-자체-UI-design.md) — 15-1 기반(자체 컴포넌트 · import 검사 · 갤러리) · 15-2 화면 옮기기(보드 끌어 옮기기 포함) · 15-3 뼈대(WidgetsApp) · Android · 웹 확인 | ✅ |
| 16 | 멤버 · 권한 — 16-1 스페이스 수준(만들기 · 초대 코드 참여 · 스페이스 설정 창 · 역할 · 내보내기 · 나가기) · 16-2 채널 수준(채널 만들기 · 채널 설정 창 · 비공개 채널 명단 · 역할별 채널 권한 — `permissions` 재작성) · 스프린트 선택 기능. 설계 [16단계 설계](docs/superpowers/specs/2026-10-04-16-멤버-권한-design.md) | ✅ |
| 17 | DM · 프레즌스 · 타이핑 — 17-1 DM(`kind=dm` 비공개 채널 + key 유일성 · 사이드바 묶음 · 사람 고르기 · 떠난 상대 읽기 전용) · 17-2 프레즌스(소켓에서 계산 · 5초 유예 · 10분 무입력 자리비움) · 입력 중. 설계 [17단계 설계](docs/superpowers/specs/2026-10-05-17-DM-프레즌스-타이핑-design.md) | ✅ |
| 18 | 인앱 알림 — 알림함(멘션 · `@channel` · DM · 내 글의 답글, 한 메시지에 한 알림) · `notifications` 재작성 · 메시지와 한 트랜잭션 · 볼 수 있는 채널만 · 음소거면 직접 멘션만 · 채널 읽음이 알림도 읽음 · 설정 창의 종류별 스위치. 설계 [18단계 설계](docs/superpowers/specs/2026-10-05-18-인앱-알림-design.md) | ✅ |
| 19 | AI 기록 — AI 패널의 「지난 대화」(사슬 단위 목록 · 끝 답이 늦은 순 · 커서 페이지) · 다시 열어 이어 묻기 · 본인 것 · 볼 수 있는 채널만 · 스키마 변경 없이 재귀 CTE. 설계 [19단계 설계](docs/superpowers/specs/2026-10-07-19-AI-기록-design.md) | ✅ |
| **20** | **GitLab 연동** — provider 추상화 뒤에 GitLab. 배포 뒤로 미뤄도 되는 유일한 단계 | |
| **마지막** | 푸시 · 트레이 · 딥링크 · 테넌트 격리 통합 테스트 · 배포(S3 드라이버 · prod compose). 푸시 · 데스크톱 알림 스위치는 14단계 설정 창에 더한다 | 🔸 배포 기반(S3 드라이버 · `TRUST_PROXY` · `deploy/` compose · nginx 한 오리진 · 백업) ✅ · 테넌트 격리 검증(`check:tenancy`) ✅ · 딥링크(새로고침 · 로그인 뒤 원래 주소 · `/invite/:코드`) ✅ · 가입 화면 ✅ · 데스크톱 · 웹 알림 + Windows 트레이(패키지 없이 — Shell_NotifyIcon · `dart:js_interop`) ✅ · 모바일 푸시는 뺐다 |

16~20 은 2026-09-27 에 **단계 밖에 있던 기능을 편입**한 것이다. 15 뒤에 둔 이유(컴포넌트를
바꾼 뒤 화면을 새로 만든다)와 단계마다의 설계 출발점은 [제품-기획 §5.1-c](docs/제품-기획.md).

### 알려진 빚

2026-09-27 에 한 번 정리했다 — 갚은 것 · 단계로 옮긴 것 · 환경 함정으로 옮긴 것은
[진행 기록](docs/진행-기록.md) «빚 정리 (2026-09-27)».

- **컨트롤러 · 서비스의 실 DB 검증은 계약 검증 스크립트가 담당한다.** 서버 단위 테스트 535개(2026-10-09 «마지막» 5 시점)는 순수 로직 · 가드 · 권한 규칙만 덮는다. 이 경계는 의도한 것이다 — 단위 테스트로 DB 동작을 증명하려 하면 §6 의 실수를 반복한다. **계약 검증은 CI 에서 push 마다 돈다 — 20종 1,123 케이스**(2026-10-09 «마지막» 테넌트 격리 시점, `서버 통합` 잡) + DB 없이 도는 정적 검사 둘(`check:migrations` · `check:sql-time`). 헬퍼는 `server/scripts/lib/` 에 모여 있다. **남은 빚은 러너가 아니라 단언 규율이다** — `undefined === undefined` 는 어떤 프레임워크로 바꿔도 통과한다. 새 케이스는 **코드를 일부러 망가뜨려 빨개지는지** 한 번 본다(2026-09-27 에 넣은 케이스는 전부 그렇게 확인했다). (늘어 온 경과는 [진행 기록](docs/진행-기록.md) 부록)
- **앱 통합 테스트는 CI 에서 창 없이만 돈다(2026-10-06).** `linux/` 플랫폼을 들이지 않고 flutter_tester 로 돌린다(`app:flow:headless`) — 창이 있어야 드러나는 것(실제 렌더링 · 창 크기 변화 · 태블릿 · 모바일 배치의 흐름)은 여전히 덮지 않는다. 흐름은 데스크톱 배치만 탄다. **화면 모습을 바꾼 변경은 Windows 창(`app:flow`)으로 한 번 본다.** 멘션 입력창의 커스텀 `TextEditingController`(커서 · IME)는 여전히 실기기 확인에만 기댄다. 앱 단위 · 위젯 테스트는 `app/test/` 에 **591개**(2026-10-09 «마지막» 5 시점)
- **운영 LLM provider 는 `gemini` 로 정했다(사용자 결정, 2026-10-07).** 실제로 확인한 경로이고 «마지막» 단계의 배포도 이것을 쓴다. **`local`(Ollama) 경로는 실측하지 않은 채 남는다(13-1)** — 쓰는 곳이 없어 깨지는 것이 없다. Gemini 무료 한도(3.5-flash 하루 20회)가 모자라거나 비공개 저장소 코드를 외부로 보내지 않으려 해 `LLM_PROVIDER=local` 로 바꾸게 되면 **그 전에 먼저 태운다.** `llm.config.ts` 의 `qwen2.5-coder:7b` 는 문서만 보고 고른 기본값이다. 설치(`winget install Ollama.Ollama`)와 모델 받기(약 4.7GB)는 사람이 한다.
- **인덱싱 큐의 5xx 소진은 단위 테스트만 덮는다.** 재시도 대기가 1분씩이라 계약 검증으로 세 번을 태우면 3분이 걸린다. 판정(`shouldGiveUpIndexing` · `indexRetryDelayMs`)은 순수 함수로 빼 두었다. 429 · 리스 유효/만료는 `check:indexing` 이 본다.
- **프레즌스는 서버 메모리에 있다(17-2).** 인스턴스가 둘이 되면 서로의 연결을 모른다 — `redis-io.adapter` 를 되살릴 때 함께 Redis 로 옮긴다. 서버를 재시작하면 모두 오프라인이 됐다가 앱이 다시 붙으며 돌아온다
- **운영 의존성에 NestJS 12 로 올려야 풀리는 감사 항목이 넷 남아 있다**(2026-10-10 보안 점검 2차 — `@nestjs/core` · `lodash` · `file-type` · `uuid`, 전부 우리 코드가 그 경로를 쓰지 않는다). `multer` · `qs` · `body-parser` 는 `server/package.json` 의 `overrides` 로 올려 두었다 — **platform-express 를 올릴 때 overrides 를 걷는다.** 목록과 이유는 [진행 기록](docs/진행-기록.md) «보안 점검 2차».
- `npm run db:up` · `db:setup` 은 **Windows + WSL 전용**(PowerShell). Mac/Linux 는 `db:up:docker` 를 써야 한다. 개발 PC 가 둘 다 Windows 라 그대로 둔다.

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
| [docs/앱-설계.md](docs/앱-설계.md) | Flutter 스택 · 화면 · 상태 관리 · 오프라인 전략 · **§6-1 리액션 · 스레드 · 답장의 차이** |
| [docs/인프라-설계.md](docs/인프라-설계.md) | 배포 구성 · 공개 저장소 보안 체크리스트 |
| [docs/디자인-시스템.md](docs/디자인-시스템.md) | 색 · 타이포 · 간격 · 컴포넌트 (산출물은 `design-system/`) |
| [docs/전환-계획.md](docs/전환-계획.md) | **작업 목록과 진행 상황. 작업 후 여기를 갱신할 것** |
| [docs/진행-기록.md](docs/진행-기록.md) | **단계마다의 경과** — 갈린 결정과 이유 · 확인한 것 · 확인하지 못한 것 · 잡은 결함. 끝난 단계를 다시 건드릴 때 읽는다 |
| [docs/기술-스택-가이드.md](docs/기술-스택-가이드.md) | 스택별 학습 순서 · 코드 읽기 시작점 (사용자용) |
| [server/README.md](server/README.md) | 서버 셋업 · 선택 기능 `.env` · 규약 · 디렉터리 · Ollama · 실제 GitHub 웹훅 |
| [app/README.md](app/README.md) | 앱 실행 · 플랫폼별 주의 |
| [.claude/mods/README.md](.claude/mods/README.md) | Claude Code 개인용 모드(git-band · ko-labels) — 앱 · 서버와 관계없다 |

### 단계별 설계 스펙 (`docs/superpowers/specs/`)

| 스펙 | 내용 |
|---|---|
| [실시간 최소](docs/superpowers/specs/2026-08-14-실시간-최소-design.md) | 4단계 소켓 계약 — 룸 · 이벤트 · 인증 · 오류 처리 · 범위에서 뺀 것과 그 이유. **`thread:*` 룸을 쓰지 않기로 한 후속 결정이 각주로 붙어 있다** |
| [앱 슬라이스 1](docs/superpowers/specs/2026-08-14-앱-슬라이스1-인증-design.md) | 5단계 분해(4조각) · 검증 플랫폼 사정 · 인증 흐름 |

그 뒤로는 단계마다 스펙이 하나씩 있다(이슈 보드 · 저장소 연동 · GitHub OAuth · 열람 · 커밋 · 마크다운 ·
UI 리디자인 · PR · 인덱싱 · AI · AI 패널). **범위에서 뺀 것과 그 이유**가 거기 있다.

계획 문서(`docs/superpowers/plans/`)는 **그 단계를 main 에 병합하면 지운다**(2026-10-05 정리에서 1~16단계분을
지웠다 — git 이력에 있다). 실행이 끝난 계획은 다시 읽히지 않고, 결정은 스펙과 진행 기록에 남는다.

작업을 끝내면 `docs/전환-계획.md` 의 체크박스, **`docs/진행-기록.md` 에 그 단계의 절**,
이 문서의 §5 표를 갱신한다.

**단계가 끝날 때마다 문서 전체를 훑는다**(사용자 지시, 2026-09-29) — 위 셋만 고쳤다가 루트
README 가 「1~13단계 완료」에 두 단계 동안 머물렀다. 아래를 차례로 보고, 그 단계가 바꾼 이름 ·
수치(테스트 수 · 계약 검증 종 수) · 화면 모습으로 `grep` 해 옛 표현을 찾는다.

| 문서 | 볼 곳 |
|---|---|
| `CLAUDE.md` | §0 상태 · §2 새 함정 · §3 새 판단 · 앱/서버 구조 · §5 표와 «알려진 빚»의 수치 |
| `README.md` · `app/README.md` · `server/README.md` | 기능표 · 진행 상황 · 검증 명령 |
| `docs/진행-기록.md` · `docs/전환-계획.md` | 그 단계의 절 · 체크리스트 |
| `docs/제품-기획.md` | §5.1 상태표 · 그 단계 절의 완료 표시 |
| `docs/앱-설계.md` · `docs/백엔드-설계.md` | 스택 · 구조 · 화면 · 테스트 수 · 구현 순서 |
| `docs/코드-둘러보기.md` · `docs/기술-스택-가이드.md` · `docs/디자인-시스템.md` | 구조 목록 · 안내 |
| 그 단계의 설계 스펙 | 머리에 완료 표시 |
| `.claude/skills/nexus-verify/SKILL.md` | 계약 검증 목록 · 개수(새 `check:*` 를 더했으면) |

**이 문서에는 경과를 쓰지 않는다** — 새 단계에서 나온 판단이
앞으로도 유효하면 §3 «반복해서 쓰는 판단» 에, 코드에서 겪은 함정이면 §2 에 한 줄로 올린다.
(2026-09-14 에 경과가 쌓여 1,745줄이 됐던 것을 나눴다.)
