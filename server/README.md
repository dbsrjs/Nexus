# Nexus — 백엔드 (server)

개발자 커뮤니케이션 허브의 NestJS 백엔드. **Space 단위 멀티테넌트**로 동작한다.

설계 기준: [`../docs/백엔드-설계.md`](../docs/백엔드-설계.md)
진행 순서: [`../docs/전환-계획.md`](../docs/전환-계획.md) §6

## 스택

- NestJS 10 (TypeScript)
- Prisma 5 + PostgreSQL (**pgvector** 확장 — AI 코드 검색용)
- Redis (프레즌스 · Socket.IO 어댑터 · 큐)
- Socket.IO (실시간 채팅 · 알림 · 보드)
- JWT + argon2 — 리프레시 토큰 회전 · 재사용 탐지
- S3 호환 스토리지 (개발: MinIO / 운영: Cloudflare R2)

## 현재 상태 — 전환 3단계까지

REST로 대화가 되는 데까지 올라와 있다. 실시간은 아직이다.

| 영역 | 상태 |
|---|---|
| 스키마 (전체 26개 모델) | ✅ 재작성 완료 |
| auth — 가입 · 로그인 · 리프레시 회전 · 로그아웃 | ✅ |
| spaces — CRUD · 멤버 · 초대 · `SpaceGuard` | ✅ |
| categories · channels · messages — 목록 · 전송 · 수정 · 소프트 삭제 · 읽음 마커 | ✅ |
| 마이그레이션 · 시드 · 종단 확인 (실제 Postgres 18 + pgvector 0.8.1) | ✅ 38개 케이스 통과 |
| realtime (소켓) | ⬜ 4단계 |
| 스레드 · 리액션 · 멘션 · 핀 · DM · 첨부 · 이슈 · repos · ai | ⬜ 7단계 이후 |

**미이관 모듈은 컴파일 대상에서 빠져 있다.** `src/realtime` `src/permissions`
`src/notifications` `src/files` `src/issues` `src/gitlab` `src/ai` 는 새 스키마를
참조하지 못해 `tsconfig.json` · `tsconfig.build.json` 의 `exclude` 에 들어 있다.
소스는 참고용으로 남겨 두었다.

되살리는 절차: 두 tsconfig 의 `exclude` 에서 해당 경로를 지우고 →
`spaceId` 기준으로 코드를 고친 뒤 → `app.module.ts` 의 `imports` 에 다시 넣는다.

## 사전 준비

- Node.js 18+ 와 npm
- **PostgreSQL 16+ with pgvector** — Docker 또는 WSL2 (아래 참조)

## 실행 방법

```bash
# 1. DB 기동
npm run db:up          # 루트에서. WSL 안의 Postgres 를 띄우고 유지한다
                       # Docker 를 쓴다면: npm run db:up:docker

# 2. 환경변수 준비 — JWT_SECRET 은 반드시 채워야 한다 (미설정 시 부팅 거부)
cp .env.example .env
node -e "console.log(require('crypto').randomBytes(48).toString('base64url'))"

# 3. 의존성 설치
npm install

# 4. DB 스키마 적용
npx prisma migrate deploy

# 5. 시드 (내 계정 1개 + 스페이스 1개 + 채널 5개)
npm run seed

# 6. 개발 서버 (watch)
npm run start:dev
```

서버는 `http://localhost:3000/api`.

시드 비밀번호는 `SEED_PASSWORD` 환경변수로 지정한다. 지정하지 않으면 임의로
생성해 한 번 출력하므로 그때 저장해 두어야 한다.

### WSL2 로 Postgres 를 쓸 때 (Docker 없는 환경)

```bash
# WSL 안에서 1회 설치
sudo apt-get install -y postgresql postgresql-18-pgvector
```

설치 후 `postgresql.conf` 의 `listen_addresses = '*'`, `pg_hba.conf` 에
`host all all 0.0.0.0/0 scram-sha-256` 을 넣고 `nexus` 역할·DB 를 만든다.
마이그레이션이 `CREATE EXTENSION vector` 를 실행하므로 개발 DB 에서는
`ALTER ROLE nexus SUPERUSER` 가 필요하다.

**함정 두 가지** — 둘 다 실제로 걸렸던 것이다.

| 증상 | 원인 · 해결 |
|---|---|
| `P1001: Can't reach database server` (Node 로는 붙는데 Prisma 만 실패) | Windows 에서 `localhost` 가 `::1` 로 먼저 해석되는데 WSL 포워딩은 IPv4 만 동작한다. `DATABASE_URL` 에 **`127.0.0.1`** 을 쓴다 |
| 잘 되다가 갑자기 `ECONNREFUSED` | WSL2 는 배포판의 **마지막 세션이 닫히면 배포판을 정지**시킨다. Postgres 도 함께 죽는다. `npm run db:up` 이 세션을 하나 잡아 둔다 (`.wslconfig` 의 `vmIdleTimeout` 은 VM 만 잡고 배포판은 못 잡는다) |

WSL 배포판에 systemd 가 켜져 있으면(`/etc/wsl.conf` 의 `[boot] systemd=true`)
배포판이 뜰 때 Postgres 가 자동 기동된다.

## npm 스크립트

| 스크립트 | 설명 |
|---|---|
| `npm run build` | `nest build` |
| `npm run start:dev` | `nest start --watch` |
| `npm start` | `node dist/main` (프로덕션) |
| `npm run typecheck` | 타입 검사만 (`tsc --noEmit`) |
| `npm run prisma:generate` | `prisma generate` |
| `npm run prisma:migrate` | `prisma migrate dev` |
| `npm run seed` | `ts-node prisma/seed.ts` |

## 프로젝트 규약 (모든 모듈 공통)

- **테넌트 격리가 최우선이다.** 스페이스에 속한 테이블은 예외 없이 `spaceId` 를
  직접 들고 있고, 서비스 메서드는 `spaceId` 를 **첫 인자로** 받는다.
  `:spaceId` 가 있는 라우트에는 반드시 `SpaceGuard` 를 건다.
  ```ts
  @Get(':spaceId/things')
  @UseGuards(SpaceGuard)
  list(@Param('spaceId') spaceId: string) { … }
  ```
  멤버가 아니면 가드가 **403이 아니라 404**를 던진다 — 남의 테넌트는 존재
  여부조차 보이지 않아야 한다.
- **역할 검사**: `@MinRole('admin')` + `SpaceRoleGuard`. 역할은 전역이 아니라
  스페이스마다 다르므로 JWT 에 담지 않는다. `@CurrentSpaceMember()` 로 읽는다.
- **Prisma 접근**: `PrismaService` 를 주입한다. `PrismaModule` 은 `@Global()` 이라
  각 모듈에서 import 하지 않는다.
- **검증/DTO**: 모든 입력은 `class-validator` DTO 로 받는다. 전역
  `ValidationPipe({ whitelist: true, forbidNonWhitelisted: true, transform: true })`
  가 적용되어 DTO 에 없는 필드는 **400 으로 거부**된다(조용히 무시하지 않는다).
- **JWT 시크릿**: `src/config/jwt.config.ts` 의 `resolveJwtSecrets()` 한 곳에서만
  읽는다. 하드코딩 폴백은 없다 — 미설정이면 부팅이 중단된다.
- **에러 응답**: 전역 `HttpExceptionFilter` 가 일관된 envelope 를 반환한다.
- **인증 사용자**: `@CurrentUser()`. 담기는 값은 `{ id, email }` 뿐이다.

## 디렉터리

```
src/
├─ main.ts            # 부트스트랩 (api prefix, ValidationPipe, CORS 화이트리스트, 쿠키)
├─ app.module.ts      # 루트 모듈
├─ config/            # jwt.config.ts — 시크릿 해석의 유일한 지점
├─ auth/              # 가입 · 로그인 · 리프레시 회전 · 재사용 탐지 · JWT 전략
├─ users/             # /api/me (전역 사용자 목록은 두지 않는다 — 테넌트 격리)
├─ spaces/            # 스페이스 CRUD · 멤버 · 초대 · SpaceGuard · SpaceRoleGuard
├─ categories/        # 채널 그룹
├─ channels/          # 채널 · 가시성 규칙 · 읽음 마커
├─ messages/          # 메시지 목록 · 전송 · 수정 이력 · 소프트 삭제
├─ prisma/            # PrismaModule + PrismaService
└─ common/            # 예외 필터, 데코레이터, 공통 DTO, slug
prisma/
├─ schema.prisma      # 전체 데이터 모델
├─ migrations/        # init (pgvector 확장 · HNSW 인덱스 포함)
└─ seed.ts
docker-compose.yml    # pgvector/postgres + redis + minio
```
