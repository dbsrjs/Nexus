# Nexus — 코딩 에이전트용 안내

개발자 개인을 위한 커뮤니케이션 허브. 대화 · 파일 · 이슈 · 저장소 · AI를 한곳에 모은다.
**NestJS 서버 + Flutter 앱**, Space 단위 멀티테넌트.

이 문서는 세션 시작 시 자동으로 읽힌다. 상세 설계는 `docs/` 를 볼 것.

---

## 0. 먼저 알아야 할 것

| | |
|---|---|
| **기준 브랜치** | **`main`.** 새 작업은 `feat/*` 를 따 쓰고 끝나면 main 으로 합친다(CI 가 `main` 과 `feat/**` 를 돈다) |
| **상태** | **1~12단계와 13-1 · 13-2 가 `main` 에 있다** — 오프라인 대화 · 파일 · 이슈 보드 · GitHub 연동(웹훅 · 열람 · PR) · 저장소 인덱싱 · AI 패널. 12 · 13단계는 진짜 GitHub · 진짜 임베딩 · 진짜 Gemini 로 완주했다. **다음은 AI 멀티턴(13-3) 또는 «마지막» 단계**(§5). 단계마다의 경과는 [docs/진행-기록.md](docs/진행-기록.md) |
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

`.github/workflows/ci.yml` 이 **`flutter-version: 3.44.9`** 로 못 박혀 있다.
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
| `npm run db:up:docker` / `db:down:docker` | Docker 환경일 때. **postgres 하나만 뜬다** — redis · minio 는 지금 빌드가 쓰지 않아 프로필(`--profile redis` · `--profile s3`) 뒤에 있다 |
| `npm run db:seed` · `db:studio` | 시드 · Prisma Studio |
| `npm run server:dev` · `server:build` | 개발 서버 · 빌드 |
| `npm --prefix server run typecheck` | 타입 검사만 |
| `npm run server:test` · `server:lint` | 서버 단위 테스트(Jest) · ESLint |
| `npm run check:realtime` | 실서버 · 실DB · 실소켓으로 소켓 계약 검증(49개) (`db:up` · `server:dev` 실행 중이어야 함). **2026-09-17 부터 시드 비밀번호가 필요 없다** — 자체 계정 · 스페이스를 쓴다 |
| `npm run check:reactions` | 리액션 계약 검증(24개). **자체 계정·스페이스를 만들어 쓰므로 비밀번호가 필요 없다** |
| `npm run check:threads` | 스레드 계약 검증(25개). 위와 같이 자체 계정을 쓴다 |
| `npm run check:quotes` | 답장(인용) 계약 검증(17개) |
| `npm run check:mentions` | 멘션 계약 검증(18개) |
| `npm run check:pins` | 핀 계약 검증(20개) |
| `npm run check:attachments` | 첨부 계약 검증(43개). **드라이버와 무관하게 돈다** — 지금 드라이버는 `local` 하나다. 배포 때 `S3Driver` 를 붙이면 `STORAGE_DRIVER=s3` 로 한 번 더 돌린다 |
| `npm run check:repos` | 저장소 웹훅 계약 검증(30개). **GitHub 없이 돈다** — 서명을 직접 만들어 보낸다 |
| `npm run check:oauth` | GitHub **연동 전체** 계약 검증(설정된 서버에서 76개) — 계정 연결(10-2a)과 저장소 목록 · 자동 등록 · 승격 · 훅 재등록/삭제(10-2b). **가짜 GitHub(4599)을 스스로 띄운다** — `.env` 에 `GITHUB_*_BASE` · `OAUTH_TOKEN_KEY` · `PUBLIC_BASE_URL` 을 넣고 서버를 재시작해야 한다. 미설정 503 분기는 그 값들을 비운 채로 한 번 더 돌려야 확인된다(스크립트가 안내를 찍는다) |
| `npm run check:browse` | 저장소 열람 계약 검증(56개) — 브랜치 · 트리 · 파일(10-3a)과 커밋(10-3b). **가짜 GitHub(4599)을 스스로 띄운다** — `check:oauth` 와 같은 `.env` 를 쓴다. 연결 · 등록이 주제인 그쪽과 섞지 않았다 |
| `npm run check:pulls` | PR 열람 계약 검증(35개) — 목록 · 상세 · 바뀐 파일(11단계). **가짜 GitHub(4599)을 스스로 띄운다** — `check:browse` 와 같은 `.env` 를 쓴다 |
| `npm run check:indexing` | 저장소 인덱싱 계약 검증(48개) — 연결 시 적재 · 거르기(바이너리 · 대용량 · 생성 파일) · 벡터 검색 순위 · 증분 재인덱싱(push 웹훅 → compare, 이름 변경(renamed) 갈래 포함) · force-push(compare 404 로 실제로 응답한 횟수까지 확인) · **임베딩 모델 변경 시 compare 없이 전체**(기록된 모델을 DB 에서 직접 바꿔 흉내 낸다 — 계약 검증에서 DB 를 만지는 유일한 곳) · 기능 브랜치 무시(12단계) · **AI 코드 질문 · 인용 경로 · 모델 불일치 시 검색과 AI 503**(13-2). **가짜 GitHub(4599)을 스스로 띄운다** — `check:browse` 와 같은 `.env` 에 **`EMBEDDING_PROVIDER=fake` 가 더 필요하고**, AI 케이스는 `LLM_PROVIDER=fake` 일 때만 돈다(아니면 건너뛴다고 찍는다) |
| `npm run check:migrations` | 마이그레이션에 **수동 관리 객체를 지우는 구문**이 섞였는지 검사. DB 도 서버도 필요 없다 — CI 서버 잡이 매번 돈다 |
| `npm run check:sql-time` | raw SQL 이 **DB 의 시계**(`now()` · `CURRENT_TIMESTAMP`)를 쓰는지 검사. 이 스키마의 시각 컬럼은 `timestamp without time zone` 이고 **Prisma 는 거기에 UTC 를 쓰는데 `now()` 는 DB 로컬을 준다** — 개발 PC 가 `Asia/Seoul` 이라 아홉 시간이 어긋나 인덱싱 리스가 한 번도 동작하지 않았다(진행 기록 «12 실제 태우기»). **CI 가 UTC 면 로컬에서만 틀리고 CI 는 초록이라** 값이 아니라 코드를 본다. DB 도 서버도 필요 없다 |
| `npm run check:issues` | 이슈 · 스프린트 계약 검증(89개). 자체 계정을 쓴다. **컬럼 상한(200)과 재채번까지 태우므로 다른 스크립트보다 오래 걸린다** |
| `npm run check:ai` | AI 계약 검증(설정된 서버에서 59개) — LLM 캐시 · 큐 · 소켓 알림 · 멘션 치환 실증(13-1) · `/ai/ask` 의 자유 지시문 · 채널 최근 대화 · 이슈 초안 · 입력 조합 검증(13-2). 저장소 컨텍스트는 `check:indexing` 이 본다. **`LLM_PROVIDER=gemini` 로 뜬 서버에서는 무료 티어 쿼터를 쓴다** — `fake` 로 돌리는 쪽이 기본이다. 미설정 503 분기는 `check:oauth` 와 같은 패턴으로 `LLM_PROVIDER` 를 비운 채 한 번 더 돌려야 확인된다(스크립트가 안내를 찍는다) |
| `cd app && flutter analyze` · `flutter test` | 앱 정적 분석 · 테스트 |
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
| `taskkill node.exe` 로 DB 까지 죽음 | Prisma 엔진 DLL 잠금을 풀려고 node 를 전부 잡으면 **WSL 세션 유지 프로세스와 개발 서버까지** 함께 죽는다. 실제로 겪었다 — 잠긴 것은 `server:dev` 하나이므로 그것만 끄고 `prisma:generate` 를 돌릴 것 |
| 잘 되다가 갑자기 `ECONNREFUSED` | WSL2 는 배포판의 **마지막 세션이 닫히면 배포판을 정지**시킨다. Postgres 도 함께 죽는다. `npm run db:up` 이 세션을 잡아 둔다 (`.wslconfig` 의 `vmIdleTimeout` 은 VM 만 잡고 배포판은 못 잡는다 — 시도해 봤고 안 된다) |
| PowerShell 스크립트 파싱 에러 | Windows PowerShell 5.1 은 BOM 없는 UTF-8 을 ANSI 로 읽는다. 한글이 든 `.ps1` 은 **UTF-8 BOM** 으로 저장할 것 |
| `wsl` 명령이 무응답 | Ubuntu OOBE(첫 사용자 생성)가 걸린 상태일 수 있다. `wsl --shutdown` 후 재시도. 이 PC 는 개인 UNIX 계정 없이 **root 로** 쓰고 있다 |
| `bash -c` 안의 따옴표가 깨짐 | Git Bash 는 `/bin/sh` 를 Windows 경로로 바꾼다. WSL 명령은 **PowerShell 도구로** 실행하고, 복잡한 스크립트는 파일로 만들어 `wsl ... /bin/bash <path>` 로 넘길 것 |
| `npm --prefix server exec prisma ...` 가 `Could not find Prisma Schema` 로 실패 | `--prefix` 는 npm 이 패키지를 찾는 경로만 바꾸고 **실행되는 명령의 cwd 는 그대로**라 `prisma/schema.prisma` 를 못 찾는다. `npm --prefix server run <script>` 를 쓸 것 — `npm run` 은 패키지 디렉터리 안에서 스크립트를 실행한다 |
| `Building with plugins requires symlink support` | **Windows 개발자 모드**가 꺼져 있다. `flutter_secure_storage` 같은 네이티브 플러그인이 심볼릭 링크를 쓴다. `start ms-settings:developers` 로 켠다. (예전에 이 자리에 있던 `CMake Error ... Visual Studio 16 2019` 는 **Flutter 3.47 로 올라가며 해결됐다** — VS 2026 을 정상 인식하고 데스크톱 빌드가 된다) |
| Android 빌드가 `Run this build using a Java 11 or newer JVM` 으로 실패 | 이 PC 의 시스템 기본 java 가 **8** 이라 Gradle 이 그걸 집는다. `flutter config --jdk-dir <JDK21 경로>` 로 고정한다(이미 설정돼 있다) |
| `flutter` 명령이 전부 `애플리케이션 제어 정책에서 이 파일을 차단했습니다` 로 실패 | **Smart App Control** 이 적용 상태가 됐다. Flutter SDK 가 `bin/cache/` 에 직접 내려받는 `dartvm.exe` 는 서명이 없어 로드가 차단된다. Windows 11 은 이 기능을 **평가 모드로 시작해 스스로 적용으로 넘어가므로** 어느 날 재부팅하면 갑자기 걸린다. 확인은 `HKLM:\SYSTEM\CurrentControlSet\Control\CI\Policy` 의 `VerifiedAndReputablePolicyState`(1=적용) 와 `Microsoft-Windows-CodeIntegrity/Operational` 로그. **끄는 것은 사용자만 할 수 있고 되돌릴 수 없다**(`start windowsdefender://smartappcontrol`). 참고로 **표준 `dart` 는 막히지 않아 `dart analyze` 는 그대로 돈다** — 차단 중에도 정적 검사는 살아 있다 |
| 자동 생성 마이그레이션에 `DROP INDEX ..._hnsw_idx` 가 섞임 | Prisma 가 표현하지 못해 수동 관리하는 pgvector 인덱스를 드리프트로 오인한다. **네 번 겪었다**(7-1 · 7-3 · 9-1 · 9-2a). 이제 `npm run check:migrations` 가 CI 에서 잡는다 — 그래도 생성된 SQL 은 읽고 커밋할 것 |
| `flutter run` 이 시작하자마자 조용히 종료 | `flutter run` 은 stdin 으로 키 명령(r · R · q)을 받는데, 백그라운드로 띄우면 stdin 이 EOF 라 종료로 해석한다. 사람이 직접 터미널에서 돌리거나, 검증 자동화는 `flutter build web` 후 정적 서버로 띄울 것 |
| `flutter run` 을 백그라운드로 띄우고 싶다 | stdin 이 EOF 라 죽는 것이므로 **stdin 을 열어 두면 산다**: `tail -f /dev/null \| flutter run -d web-server --web-port=5173 …`. 디버그 웹 빌드는 난독화되지 않아 **예외 원문과 Dart 스택이 그대로 보인다** — 릴리스 빌드(`flutter build web`)로는 `dartException: Sk` 같은 축약만 나와 원인을 못 찾는다 |
| 브라우저 자동화로 Flutter 웹 입력이 안 먹음 | Flutter 웹은 캔버스로 그려 접근성 트리가 비어 있다. `flutter-semantics-placeholder` 를 클릭해 시맨틱스를 켜면 입력 요소가 노출된다. 그래도 **BackSpace · 값 직접 대입은 컨트롤러까지 전달되지 않고 타이핑만 append 된다** — 폼을 비우려면 페이지를 새로고침할 것 |

### 코드에서 겪은 함정

괄호는 겪은 단계다 — 경위는 [진행 기록](docs/진행-기록.md) 의 그 절.

| 증상 | 원인 · 대응 |
|---|---|
| 인증 없는 경로의 500 응답에 키 길이 · DB 호스트가 실림 | 전역 예외 필터는 `HttpException` 이 아닌 `Error` 의 message 를 **응답에 그대로 싣는다.** 공개 경로(OAuth 콜백 · 웹훅)의 throw 는 감싸서 접을 것 (10-2a) |
| 응답 본문에 실은 `retryAfter` 가 앱에 도착하지 않음 | 같은 필터가 본문을 일정한 봉투로 다시 빚으며 **커스텀 필드를 버린다.** 표준 헤더(`Retry-After`)로 보낼 것 (10-3a) |
| `.env` 에 `X=` 로 자리만 잡았더니 엉뚱한 경로가 됨 | `??` 는 빈 문자열을 통과시킨다(`resolve('')` = 작업 디렉터리). **빈 값을 미설정으로 치려면 `\|\|`** (8-1) |
| `retryAfterSec: 0` 이 무시됨 | `x ? … : …` 는 `0` 을 거짓으로 본다. `!= null` 로 볼 것 (12) |
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
| Gemini 모델이 산발적으로 503 을 냄 | `-latest` 별칭은 "새 출시마다 핫스왑" 되는 가장 붐비는 모델을 가리킨다. 특정 안정화 버전(예: `gemini-3.1-flash-lite`)을 박아 둘 것 (13-1) |
| 길게 누르기 시트가 `BOTTOM OVERFLOWED` 로 잘림 | `showModalBottomSheet` 는 기본 최대 높이가 화면의 9/16 이다. `isScrollControlled: true` 가 없으면 항목이 늘 때 조용히 넘친다 (13-1) |
| 화면을 닫으면 디버그 빌드에서 `deactivated widget's ancestor` 로 멈춤 | `dispose()` 안에서 `ProviderScope.containerOf(context)` 같은 조상 조회를 했다. **`didChangeDependencies` 에서 참조를 잡아 두고** `dispose` 는 그것만 쓴다 — 예외로 정리도 못 돌아 구독이 남았다 (13-2 후 `74ccc01`) |

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
    **카드에 그림자를 쓰지 않는다**(표면 세 단계가 깊이를 맡는다). 컴포넌트 테마와
    `fontFamily` 는 `ThemeData` 에 둔다 — 스타일마다 넣으면 `textTheme` 에 없는
    스타일이 시스템 폰트로 그려진다 (UI 리디자인)
14. **웹훅은 서명이 곧 인증이다.** `@Public()` 이지만 **원문 바이트**(`rawBody`)로
    HMAC 을 검증하고 `timingSafeEqual` 로 비교한다 — 파싱한 객체를 다시 직렬화하면
    멀쩡한 요청이 위조로 판정된다. 시스템 메시지의 작성자는 **스페이스 멤버가 아니고
    로그인할 수 없는** 봇 사용자 하나다 (10-1)

### 모듈 구조 (`server/src/`)

```
config/       jwt.config.ts — 시크릿 해석의 유일한 지점
auth/         가입 · 로그인 · 리프레시 회전 · 재사용 탐지 · JWT 전략
users/        /api/me 만. 전역 사용자 목록은 두지 않는다(테넌트 격리)
spaces/       스페이스 CRUD · 멤버 · 초대 · SpaceGuard · SpaceRoleGuard
categories/   채널 그룹
channels/     채널 · 가시성 규칙 · 읽음 마커
messages/     메시지 목록 · 전송 · 수정 이력 · 소프트 삭제 · 리액션 · 멘션 · 스레드 · 답장 · 핀
storage/      StorageDriver — 바이트를 어디에 둘지. URL 을 만들지 않는다. **구현은 local 하나**(S3 는 배포 때)
attachments/  업로드 · 스트리밍 다운로드 · 썸네일 · 파일 목록 · 고아 정리
issues/       이슈 · 라벨 · 댓글 · 칸반 정렬 · 채번(Space.issueSeq)
sprints/      스프린트 · 번다운
oauth/        GitHub 계정 연결 · state · 토큰 암호화(OAUTH_TOKEN_KEY)
repos/        웹훅 수신 · 저장소 연결 · 열람 · 커밋 · PR 프록시
  indexing/   트리 순회 · 거르기 · 청킹 · 벡터 검색 · DB 큐 워커
embedding/    임베딩 어댑터(gemini · local · fake) — EMBEDDING_PROVIDER 뒤에 숨는다
llm/          LLM 어댑터(gemini · local · fake) — LLM_PROVIDER 뒤에 숨는다(AI 만 쓴다, 전역 아님)
ai/           AI 패널(13-1 · 13-2) — POST /ai/ask 하나 · 프리셋 · 컨텍스트(메시지 · 채널 · 저장소 RAG) ·
              ai_runs 큐 · promptHash 캐시 · 러너 · 소켓 알림
realtime/     소켓 게이트웨이 · 룸 계산 · 이벤트 발신
prisma/       PrismaModule(@Global) + PrismaService
common/       예외 필터 · 데코레이터 · 페이지네이션 DTO · slug · bigint 직렬화
```

### 앱 구조 (`app/lib/`)

[앱-설계.md §3](docs/앱-설계.md) 의 구조를 따르되 **쓰는 것만 만든다.** 빈 디렉터리를
미리 파 두지 않는다. 파일 단위 안내는 [코드-둘러보기 §5](docs/코드-둘러보기.md).

```
core/env.dart            API 주소를 읽는 유일한 지점. 하드코딩 금지
core/theme.dart          design-system/tokens.css 를 이름까지 그대로 이식
core/router.dart         go_router + 인증 가드(redirect). 셸 안(머무는 곳) / 셸 밖(덮어서)
core/breakpoints.dart    Layout(mobile/tablet/desktop) + 고정 폭 상수
data/api/                영역마다 한 파일 + api_client(dio · 401 → 리프레시 1회 재시도)
                         실패는 AuthFailure · ApiFailure 로 분류(api_failure.dart)
data/socket/             Socket.IO 연결 + 이벤트(sealed SocketEvent)
data/local/app_database.dart  drift — 캐시 + 전송 큐(outbox_messages)
data/repositories/       API + 캐시를 잇는 곳. **화면은 여기만 통해 데이터를 본다**
data/auth_storage.dart   flutter_secure_storage 래퍼(토큰 + 마지막 계정)
data/settings_storage.dart 같은 저장소의 화면 설정(테마). 수명이 달라 클래스를 나눴다
domain/models/           freezed 모델
features/auth/ space/ channel/  로그인 · 스페이스 선택 · 채널 목록(카테고리 묶기)
features/chat/           메시지 리스트 · 입력창 · 낙관적 전송 · 실시간 반영 · 스레드 · 멘션 ·
                         첨부(attachment_draft — 고른 즉시 업로드) · 선택 모드
features/files/          스페이스 파일 목록 (썸네일 · 캐시하지 않는다)
features/issue/          이슈 보드 · 상세 · 스프린트 · 번다운(CustomPainter)
features/repo/           저장소 연결 · 열람 · 커밋 · PR
features/ai/             AI 패널
features/realtime/       소켓 수명 관리 + 채널 목록 동기화
features/settings/       테마 모드 컨트롤러(기본 system · 계정 메뉴에서 바꾼다)
features/shell/          반응형 셸 — app_shell(분기) · space_rail · channel_pane
shared/markdown/         마크다운 — 파서(블록 · 인라인) · MarkdownBody · 평문화
                         **멘션이 이 파서 안에 있다**(파서가 하나여야 한다)
shared/widgets/          NexusAvatar 등 공용 위젯
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
- **반응형 폭 분기는 `features/shell/app_shell.dart` 한 곳에서만 한다.** 안쪽 위젯은 자기가 어떤 폭에 있는지 모른다. 분기가 화면마다 흩어지면 손댈 수 없게 된다.
- **메시지 목록은 서버가 주는 최신순 그대로 둔다.** 화면은 `reverse: true` 로 그린다. 뒤집어 보관하면 페이지를 이어붙일 때마다 다시 뒤집어야 한다.
- **전송 실패한 메시지를 조용히 지우지 않는다.** `failed` 로 표시해 재시도·삭제를 남긴다. 사라지면 사용자는 보냈다고 믿는다.
- **Enter 전송은 물리 키보드에서만 동작한다.** 모바일 소프트 키보드는 Enter 를 IME 가 줄바꿈으로 소비하므로 전송 버튼을 쓴다. Shift+Enter 는 어디서나 줄바꿈이다.
- **401 재시도는 1회뿐.** 무한 재시도는 서버의 리프레시 재사용 탐지에 걸려 세션 family 가 끊긴다.
- **모델을 고치면 `dart run build_runner build`** 를 돌린다. `.freezed.dart` · `.g.dart` 는 커밋한다 — 체크아웃 직후 코드젠 없이 빌드되게 하기 위함이다.
- **애노테이션과 클래스 사이에 아무것도 끼우지 않는다.** `@DriftDatabase(...)` 와 `class AppDatabase` 사이에 상수 하나를 넣었더니 애노테이션이 그 상수에 붙어 **drift 가 `.g.dart` 를 아예 만들지 않았다.** 로컬에는 옛 생성물이 남아 있어 `analyze` · `test` 가 전부 통과했고, **깨끗한 체크아웃으로 도는 CI 만 실패했다.** 코드 생성이 걸린 변경은 `.dart_tool/build` 를 지우고 한 번 돌려 볼 것 — 캐시가 있으면 "생성되지 않음"이 "변경 없음"처럼 보인다.

### 아직 이관하지 않은 모듈 — 빌드에서 빠져 있다

`src/permissions` `src/notifications` `src/gitlab` 셋은 **옛 스키마를 참조해 컴파일되지
않는다.** 소스는 참고용으로 남겨 두고 `tsconfig.json` · `tsconfig.build.json` 의 `exclude` 로
빌드에서만 뺐다. `src/realtime/redis-io.adapter.ts` 도 다중 인스턴스가 될 때까지 개별 제외돼
있다. (`issues`(9-1) · `ai`(13-1)는 `spaceId` 기준으로 다시 써 이관을 마쳤다.)

**`src/files` 는 8-1 에서 `attachments` 로 다시 쓰고 옛 소스를 지웠다.** 참고용으로도
남기지 않은 이유는 그 코드가 **서명 URL 을 발급**하기 때문이다 — 되살리는 사람이
그 구멍을 함께 되살린다. 필요하면 git 이력에 있다.

되살리는 절차: ① 두 tsconfig 의 `exclude` 에서 경로 삭제 → ② `spaceId` 기준으로 코드 수정
→ ③ `app.module.ts` 의 `imports` 에 등록.

---

## 4. 어디까지 됐나

단계 표는 §5. 단계마다 무엇을 왜 그렇게 정했고 **무엇을 확인하지 못했는지**는
[docs/진행-기록.md](docs/진행-기록.md) 에 있다. **이미 끝난 단계의 코드를 다시 건드릴 때는
그 절부터 읽는다** — 뒤집으면 안 되는 판단과 그 이유가 거기 있다.

**아직 없는 것**: DM · 프레즌스 · 타이핑 표시 · 알림(인앱 · 멘션 알림 · 푸시) · 채널별 권한 ·
비공개 채널 멤버 추가 · 앱의 초대/멤버 관리 화면 · AI 멀티턴 · **S3 스토리지 드라이버**(지금은
`local` 하나) · 배포. `notifications` · `permissions` 모듈은 미이관이다(§3 끝). 실시간 서버에서
아직 쓰지 않는 이벤트는 `typing` · `presence:changed` 다.

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
| **13-3** | **AI 멀티턴(후속 질문)** — `parentRunId` | |
| **14** | **사용자 설정** — 디스코드식 설정 창(표시 이름 · 프로필 사진 · 비밀번호 변경 · 알림(채널 음소거) · 화면). 설계 출발점은 [제품-기획 §5.1-a](docs/제품-기획.md) | |
| **마지막** | 푸시 · 트레이 · 딥링크 · 테넌트 격리 통합 테스트 · 배포(S3 드라이버 · prod compose). 푸시 · 데스크톱 알림 스위치는 14단계 설정 창에 더한다 | |

### 알려진 빚

- **컨트롤러 · 서비스의 실 DB 검증은 계약 검증 스크립트가 담당한다.** 서버 단위 테스트 373개는 순수 로직 · 가드 · 권한 규칙만 덮는다. 이 경계는 의도한 것이다 — 단위 테스트로 DB 동작을 증명하려 하면 §6 의 실수를 반복한다. **계약 검증은 CI 에서 push 마다 돈다 — 15종 589 케이스**(13-2 시점, `서버 통합` 잡) + DB 없이 도는 정적 검사 둘(`check:migrations` · `check:sql-time`). 헬퍼는 `server/scripts/lib/` 에 모여 있다. **남은 빚은 러너가 아니라 단언 규율이다** — `undefined === undefined` 는 어떤 프레임워크로 바꿔도 통과한다. 같은 종류가 다시 나오면 그때 장치를 만든다. (늘어 온 경과는 [진행 기록](docs/진행-기록.md) 부록)
- **AI 큐의 실패 갈래와 「모델이 바뀌면 캐시가 적중하지 않음」이 계약 검증에 없다(13-1).** 리스 만료 복구 · 5xx 5회 소진 · fatal 즉시 포기를 `check:ai` 로 재현하려면 실패를 주입할 수 있는 fake LLM 어댑터가 필요한데, 지금 `fake` 는 항상 즉시 성공만 한다 — 인덱싱 큐의 같은 자리(§4 «12 실제 태우기» 이후에도 남은 빚)와 같은 모양이다. 단위 테스트(`classifyFailure` · `shouldGiveUp`)가 대신 덮는다.
- **`local`(Ollama) LLM 경로를 실측하지 못했다(13-1).** `llm.config.ts` 의 `qwen2.5-coder:7b` 는 문서만 보고 고른 기본값이다. Ollama 가 없는 PC 에서 13단계를 이어받으면 먼저 설치하고 실제로 태워 볼 것.
- `npm run db:up` · `db:setup` 은 **Windows + WSL 전용**(PowerShell). Mac/Linux 는 `db:up:docker` 를 써야 한다.
- **비공개 채널에 다른 사람을 넣는 방법이 없다.** 생성자는 채널 생성 시 자동으로 멤버가 되지만(`ChannelsService.create()`), 채널 멤버 추가·제거 API 가 아직 없어 비공개 채널은 사실상 "나만 보는 채널"이다. 여럿이 쓰는 비공개 채널이 필요해지는 단계에서 함께 설계한다.
- **앱 테스트에 통합 테스트가 없다.** `app/test/` 에 **288개**(인메모리 drift 로 실제 DB 동작까지 덮는 단위 테스트 + 9-3 부터 붙은 위젯 테스트). **화면 자체를 도는 통합 테스트는 없다** — UI 리디자인(2026-08-22)이 심은 라우터 결함이 열흘 뒤 11단계 화면 확인에서야 드러났고, 그 뒤 `test/router_shell_test.dart` 로 라우트 트리 구조만 검사한다. 멘션 입력창의 커스텀 `TextEditingController`(커서 · IME)도 실기기 확인에만 기댄다.
- **`prisma migrate dev` 는 이 환경(비대화형)에서 거부된다.** 위 HNSW 드리프트를 감지해 확인을 물으려 하기 때문이다. `npx prisma migrate diff --from-schema-datasource ... --to-schema-datamodel ... --script` 로 SQL 을 만들어 손질한 뒤 `prisma:deploy` 로 적용한다.
- **`adb shell input text` 는 한글을 넣지 못한다**(NullPointerException). 실기기 검증 문구는 영문으로 쓸 것.
- **소켓 토큰 갱신 경로가 자동 검증되지 않는다.** 액세스 토큰 만료(15분)를 기다려야 재현되므로 테스트에 넣지 않았다. 실기기로 한 번 확인했다.

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

### 단계별 설계 스펙 (`docs/superpowers/specs/`)

| 스펙 | 내용 |
|---|---|
| [실시간 최소](docs/superpowers/specs/2026-08-14-실시간-최소-design.md) | 4단계 소켓 계약 — 룸 · 이벤트 · 인증 · 오류 처리 · 범위에서 뺀 것과 그 이유. **`thread:*` 룸을 쓰지 않기로 한 후속 결정이 각주로 붙어 있다** |
| [앱 슬라이스 1](docs/superpowers/specs/2026-08-14-앱-슬라이스1-인증-design.md) | 5단계 분해(4조각) · 검증 플랫폼 사정 · 인증 흐름 |

그 뒤로는 단계마다 스펙이 하나씩 있다(이슈 보드 · 저장소 연동 · GitHub OAuth · 열람 · 커밋 · 마크다운 ·
UI 리디자인 · PR · 인덱싱 · AI · AI 패널). **범위에서 뺀 것과 그 이유**가 거기 있다.

계획 문서 `docs/superpowers/plans/` 도 있지만 **실행이 끝난 기록**이다. 현재 상태는
계획이 아니라 이 문서와 스펙을 봐야 한다.

작업을 끝내면 `docs/전환-계획.md` 의 체크박스, **`docs/진행-기록.md` 에 그 단계의 절**,
이 문서의 §5 표를 갱신한다. **이 문서에는 경과를 쓰지 않는다** — 새 단계에서 나온 판단이
앞으로도 유효하면 §3 «반복해서 쓰는 판단» 에, 코드에서 겪은 함정이면 §2 에 한 줄로 올린다.
(2026-09-14 에 경과가 쌓여 1,745줄이 됐던 것을 나눴다.)
