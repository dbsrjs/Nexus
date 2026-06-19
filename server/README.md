# ONE 워크스페이스 — 백엔드 (server)

사내 메신저 통합 솔루션의 NestJS 백엔드. 온프렘 환경에서 PostgreSQL · Redis · MinIO와 함께 동작합니다.

설계 기준: [`../docs/백엔드-설계.md`](../docs/백엔드-설계.md)

## 스택

- NestJS 10 (TypeScript)
- Prisma 5 + PostgreSQL
- Redis (프레즌스 · Socket.IO 어댑터 · 큐)
- Socket.IO (실시간 채팅 · 알림 · 보드)
- JWT + argon2 (자체 이메일/비밀번호 인증)
- MinIO (S3 호환, 파일 영구 보관)

## 사전 준비

- Node.js 18+ 와 npm
- Docker / Docker Compose (postgres · redis · minio 기동용)

## 실행 방법

```bash
# 1. 인프라 기동 (postgres + redis + minio)
docker compose up -d

# 2. 환경변수 준비
cp .env.example .env   # 필요 시 값 수정

# 3. 의존성 설치
npm install

# 4. DB 스키마 적용 (마이그레이션)
npx prisma migrate dev

# 5. 시드 데이터 (디자인 목업 이식)
npm run seed

# 6. 개발 서버 기동 (watch)
npm run start:dev
```

서버는 기본적으로 `http://localhost:3000/api` 에서 동작합니다.
MinIO 콘솔: `http://localhost:9001` (minioadmin / minioadmin).

## npm 스크립트

| 스크립트 | 설명 |
|---|---|
| `npm run build` | `nest build` |
| `npm run start:dev` | `nest start --watch` |
| `npm start` | `node dist/main` (프로덕션) |
| `npm run prisma:generate` | `prisma generate` |
| `npm run prisma:migrate` | `prisma migrate dev` |
| `npm run seed` | `ts-node prisma/seed.ts` |

## 프로젝트 규약 (모든 모듈 공통)

- **Prisma 접근**: `PrismaService`를 주입해 사용합니다.
  ```ts
  import { PrismaService } from '../prisma/prisma.service';

  constructor(private prisma: PrismaService) {}
  ```
  `PrismaModule`은 `@Global()`이므로 각 모듈에서 따로 import할 필요는 없습니다.
- **검증/DTO**: 모든 입력은 `class-validator` 데코레이터가 달린 DTO로 받습니다.
  전역 `ValidationPipe({ whitelist: true, transform: true })`가 적용되어,
  DTO에 없는 필드는 제거되고 타입은 자동 변환됩니다.
- **페이지네이션**: 커서 기반(`?cursor=&limit=`). 공통 `PaginationDto`
  (`src/common/dto/pagination.dto.ts`)를 상속/조합해 사용합니다.
- **에러 응답**: 전역 `HttpExceptionFilter`가 일관된 에러 envelope를 반환합니다.
- **인증 사용자**: 컨트롤러에서 `@CurrentUser()` 데코레이터로 접근합니다.

## 디렉터리

```
src/
├─ main.ts            # 부트스트랩 (api prefix, ValidationPipe, CORS)
├─ app.module.ts      # 루트 모듈 (ConfigModule, PrismaModule, 기능 모듈 wiring 지점)
├─ prisma/            # PrismaModule + PrismaService (canonical 접근 패턴)
└─ common/            # 예외 필터, 데코레이터, 공통 DTO
prisma/
└─ schema.prisma      # 전체 데이터 모델
docker-compose.yml    # postgres + redis + minio
```
