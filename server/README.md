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

## 현재 상태 — 전환 2단계까지

멀티테넌시 골격까지 올라와 있다.

| 영역 | 상태 |
|---|---|
| 스키마 (전체 26개 모델) | ✅ 재작성 완료 |
| auth — 가입 · 로그인 · 리프레시 회전 · 로그아웃 | ✅ |
| spaces — CRUD · 멤버 · 초대 · `SpaceGuard` | ✅ |
| channels · messages · realtime · attachments · issues · repos · ai | ⬜ 3단계 이후 |

**미이관 모듈은 컴파일 대상에서 빠져 있다.** `src/channels` `src/messages`
`src/realtime` `src/permissions` `src/notifications` `src/files` `src/issues`
`src/gitlab` `src/ai` 는 새 스키마를 참조하지 못해 `tsconfig.json` ·
`tsconfig.build.json` 의 `exclude` 에 들어 있다. 소스는 참고용으로 남겨 두었다.

되살리는 절차: 두 tsconfig 의 `exclude` 에서 해당 경로를 지우고 →
`spaceId` 기준으로 코드를 고친 뒤 → `app.module.ts` 의 `imports` 에 다시 넣는다.

## 사전 준비

- Node.js 18+ 와 npm
- Docker / Docker Compose (postgres · redis · minio 기동용)

## 실행 방법

```bash
# 1. 인프라 기동 (pgvector 포함 postgres + redis + minio)
docker compose up -d

# 2. 환경변수 준비 — JWT_SECRET 은 반드시 채워야 한다 (미설정 시 부팅 거부)
cp .env.example .env
node -e "console.log(require('crypto').randomBytes(48).toString('base64url'))"

# 3. 의존성 설치
npm install

# 4. DB 스키마 적용
npx prisma migrate dev

# 5. 시드 (내 계정 1개 + 스페이스 1개 + 채널 5개)
npm run seed

# 6. 개발 서버 (watch)
npm run start:dev
```

서버는 `http://localhost:3000/api`. MinIO 콘솔은 `http://localhost:9001`.

시드 비밀번호는 `SEED_PASSWORD` 환경변수로 지정한다. 지정하지 않으면 임의로
생성해 한 번 출력하므로 그때 저장해 두어야 한다.

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
├─ prisma/            # PrismaModule + PrismaService
└─ common/            # 예외 필터, 데코레이터, 공통 DTO
prisma/
├─ schema.prisma      # 전체 데이터 모델
├─ migrations/        # init (pgvector 확장 · HNSW 인덱스 포함)
└─ seed.ts
docker-compose.yml    # pgvector/postgres + redis + minio
```
