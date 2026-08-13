# Nexus — 코딩 에이전트용 안내

개발자 개인을 위한 커뮤니케이션 허브. 대화 · 파일 · 이슈 · 저장소 · AI를 한곳에 모은다.
**NestJS 서버 + Flutter 앱(예정)**, Space 단위 멀티테넌트.

이 문서는 세션 시작 시 자동으로 읽힌다. 상세 설계는 `docs/` 를 볼 것.

---

## 0. 먼저 알아야 할 것

| | |
|---|---|
| **작업 브랜치** | `feat/pivot-nexus` — **`main` 은 전환 이전의 옛 코드다.** 헷갈리지 말 것 |
| **상태** | 사내 메신저 → 개인 프로젝트로 **전환 중**. 서버 3단계까지 완료, 앱은 아직 없음 |
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
npm --prefix server exec prisma migrate deploy
npm run db:seed

npm run server:dev   # http://localhost:3000/api
```

WSL 이 없으면 먼저 `wsl --install -d Ubuntu`.

### 자주 쓰는 명령

| 명령 | 설명 |
|---|---|
| `npm run db:up` / `db:down` | WSL Postgres 기동 / `wsl --shutdown` |
| `npm run db:up:docker` / `db:down:docker` | Docker 환경일 때 |
| `npm run db:seed` · `db:studio` | 시드 · Prisma Studio |
| `npm run server:dev` · `server:build` | 개발 서버 · 빌드 |
| `npm --prefix server run typecheck` | 타입 검사만 |

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

### 아직 이관하지 않은 모듈 — 빌드에서 빠져 있다

`src/realtime` `src/permissions` `src/notifications` `src/files` `src/issues`
`src/gitlab` `src/ai` 는 **옛 스키마를 참조해 컴파일되지 않는다.** 소스는 참고용으로 남겨 두고
`tsconfig.json` · `tsconfig.build.json` 의 `exclude` 로 빌드에서만 뺐다.

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

**동작이 확인된 것** — 실제 DB 로 38개 케이스 통과:
가입 · 중복 거부 · 로그인 · 리프레시 회전 · **재사용 탐지** · 스페이스 생성(한글 이름) ·
초대 발급/수락 · 타 스페이스 404 · 채널 목록/생성 · 메시지 전송/조회/최신순 ·
**커서 페이지네이션** · 수정 이력 · **소프트 삭제** · **안 읽은 수** · 읽음 마커(뒤로 안 감) ·
권한 거부(403).

**아직 없는 것**: 실시간(소켓), 스레드 · 리액션 · 멘션 · 핀 · DM, 첨부, 이슈,
저장소 연동, AI, **Flutter 앱 전체**, 테스트 · 린트 · CI.

---

## 5. 남은 작업

순서는 2026-08-14 에 개정됐다. **원안(계층을 다 쌓고 앱)은 5단계까지 화면이 없어서**,
부가 기능을 뒤로 미루고 앱을 앞으로 당겼다.

잘라내는 기준: **미루는 것은 기능이지 구조가 아니다.**
스레드 · 리액션은 나중에 붙여도 기존 코드를 안 건드리지만, 실시간을 미루면 앱 상태 계층을
REST 전제로 짰다가 다시 쓰게 된다. 그래서 **실시간은 앱보다 먼저** 한다.

| 단계 | 내용 |
|---|---|
| **4** ← 다음 | **실시간 최소** — 소켓 인증(`auth.token` 만), 룸 조인, `rooms:sync` / `rooms:invalidate`, `message:new`, 읽음 저장 |
| **5** | **Flutter 앱** — 스캐폴드 → 인증 → 셸 → 채널 → 메시지 (소켓 포함). **처음으로 눈에 보이는 앱** |
| **6** | drift 캐시 + catch-up → Phase 0 달성(실사용 가능) |
| **7~** | **기능 단위로 서버 + 앱을 함께**: 스레드 · 리액션 · 멘션 · 핀 → 첨부 → 이슈 · 스프린트 → repos(웹훅 · 열람 프록시) → PR → 인덱싱 → AI |
| 마지막 | 푸시 · 트레이 · 딥링크 · CI · 테넌트 격리 통합 테스트 |

7단계부터는 **한 기능이 서버에서 화면까지 끝나야 완료로 친다.** 그래야 "화면 없는 구간"이
다시 생기지 않는다.

### 알려진 빚

- **테스트 · 린트 · CI 가 전혀 없다.** 루트의 `server:test` · `server:lint` 는 `server/package.json` 에 대상 스크립트가 없어 **실행하면 실패한다.** Jest · ESLint 셋업은 전환 계획 §5 에 있다.
- `npm run db:up` · `db:setup` 은 **Windows + WSL 전용**(PowerShell). Mac/Linux 는 `db:up:docker` 를 써야 한다.
- GitHub OAuth 는 스키마(`oauth_accounts`)만 있고 미구현. 저장소 연동 단계에서 만든다.

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
| [docs/제품-기획.md](docs/제품-기획.md) | 방향 · 타겟 · 기능 범위 · 로드맵 |
| [docs/백엔드-설계.md](docs/백엔드-설계.md) | 멀티테넌시 · 데이터 모델 · API 계약 · 실시간 · 인증 |
| [docs/앱-설계.md](docs/앱-설계.md) | Flutter 스택 · 화면 · 상태 관리 · 오프라인 전략 |
| [docs/인프라-설계.md](docs/인프라-설계.md) | 배포 구성 · 공개 저장소 보안 체크리스트 |
| [docs/디자인-시스템.md](docs/디자인-시스템.md) | 색 · 타이포 · 간격 · 컴포넌트 (산출물은 `design-system/`) |
| [docs/전환-계획.md](docs/전환-계획.md) | **작업 목록과 진행 상황. 작업 후 여기를 갱신할 것** |
| [server/README.md](server/README.md) | 서버 셋업 · 규약 · 디렉터리 |

작업을 끝내면 `docs/전환-계획.md` 의 체크박스와 이 문서의 §4 · §5 를 갱신한다.
