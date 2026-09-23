# Nexus — 백엔드 (server)

개발자 커뮤니케이션 허브의 NestJS 백엔드. **Space 단위 멀티테넌트**로 동작한다.

설계 기준: [`../docs/백엔드-설계.md`](../docs/백엔드-설계.md) ·
진행 상황: [`../docs/전환-계획.md`](../docs/전환-계획.md) · 단계별 경과: [`../docs/진행-기록.md`](../docs/진행-기록.md)

## 스택

- NestJS 10 (TypeScript) · Node.js 22
- Prisma 5 + PostgreSQL 16+ (**pgvector** — 코드 임베딩 · HNSW 인덱스)
- Socket.IO (실시간 대화 · 이슈 · AI 완료 알림)
- JWT + argon2 — 리프레시 토큰 회전 · 재사용 탐지
- 첨부: `StorageDriver` 추상화 — **지금 구현은 로컬 디스크 하나**(S3 호환 드라이버는 배포 때)
- LLM · 임베딩: `gemini` · `local`(Ollama) · `fake` 를 env 로 고른다

**Redis 는 쓰지 않는다.** 인덱싱 · AI 작업 큐는 Postgres 테이블(`FOR UPDATE SKIP LOCKED`)이고,
서버가 한 대라 소켓 어댑터도 필요 없다. `.env.example` 의 `REDIS_URL` 은 자리만 남아 있다.

## 현재 상태 — 13-2 까지

대화(스레드 · 답장 · 멘션 · 리액션 · 핀) · 첨부 · 이슈 · 스프린트 · GitHub 연동(웹훅 · 계정 연결 ·
열람 · 커밋 · PR) · 저장소 인덱싱 · AI 패널이 동작한다. 남은 것은 AI 멀티턴 · 알림 · 프레즌스 · DM.

**미이관 모듈은 컴파일 대상에서 빠져 있다.** `src/permissions` `src/notifications`
`src/gitlab` 은 옛 스키마를 참조해 `tsconfig.json` · `tsconfig.build.json` 의 `exclude` 에
들어 있다. 소스는 참고용이다. `src/realtime/redis-io.adapter.ts` 도 다중 인스턴스가 될
때까지 개별 제외돼 있다.

되살리는 절차: 두 tsconfig 의 `exclude` 에서 해당 경로를 지우고 →
`spaceId` 기준으로 코드를 고친 뒤 → `app.module.ts` 의 `imports` 에 넣는다.

## 실행 방법

사전 준비: **Node.js 22**, **PostgreSQL 16+ with pgvector** — WSL2 또는 Docker (아래 참조).

```bash
# 저장소 루트에서
npm --prefix server install

# 1. 환경변수 — server/.env 를 만들고 시크릿 셋(JWT 둘 · OAUTH_TOKEN_KEY)을 채운다.
#    이미 채워진 값은 건드리지 않아 여러 번 돌려도 안전하다
npm run env:setup

# 2. DB
npm run db:setup       # (새 PC에서 1회) WSL 안에 Postgres + pgvector. Docker 라면 건너뛴다
npm run db:up          # WSL Postgres 기동 + 세션 유지. Docker 라면 npm run db:up:docker

# 3. 스키마 적용
npm --prefix server run prisma:generate   # 빠뜨리면 시드가 'SpaceRole' 없음으로 실패한다
npm --prefix server run prisma:deploy     # migrate deploy

# 4. 시드 (내 계정 1개 + 스페이스 1개 + 채널 5개)
npm run db:seed

# 5. 개발 서버 (watch)
npm run server:dev
```

서버는 `http://localhost:3000/api`.

시드 비밀번호는 `SEED_PASSWORD` 환경변수로 지정한다. 지정하지 않으면 임의로
생성해 한 번 출력하므로 그때 저장해 두어야 한다.

### 선택 기능을 켜는 값

`env:setup` 이 만들어 낼 수 없는 값은 끝에 목록으로 알려 준다. 기능별로 필요한 것만 채운다.

| 기능 | `.env` 값 |
|---|---|
| GitHub 계정 연결 · 웹훅 자동 등록 | `GITHUB_CLIENT_ID` · `GITHUB_CLIENT_SECRET` · `PUBLIC_BASE_URL`(터널 주소) |
| 저장소 인덱싱 | `EMBEDDING_PROVIDER` (`gemini` 면 `GEMINI_API_KEY`, `local` 이면 Ollama — 아래) |
| AI 패널 | `LLM_PROVIDER` (`gemini` · `local` · `fake`) |

비워 두면 해당 API 가 **503** 으로 답하고 나머지는 그대로 돈다. 계약 검증을 돌릴 때의
값(`GITHUB_*_BASE` · `fake` provider)은 [CLAUDE.md §1](../CLAUDE.md) 의 명령 표에 있다.

### WSL2 로 Postgres 를 쓸 때 (Docker 없는 환경)

`npm run db:setup` 은 **1회만** 실행하면 되고, 여러 번 돌려도 안전하다.
`server/scripts/db-setup-wsl.sh` 가 WSL 안에서 하는 일:
설치(`postgresql` + 해당 메이저 버전의 `pgvector`) → `listen_addresses = '*'` ·
`pg_hba.conf` 설정 → `nexus` 역할·DB 생성 → `ALTER ROLE nexus SUPERUSER`
(마이그레이션이 `CREATE EXTENSION vector` 를 실행하므로 필요하다).

WSL 이 없다면 먼저 `wsl --install -d Ubuntu`.

**함정 두 가지** — 둘 다 실제로 걸렸던 것이다.

| 증상 | 원인 · 해결 |
|---|---|
| `P1001: Can't reach database server` (Node 로는 붙는데 Prisma 만 실패) | Windows 에서 `localhost` 가 `::1` 로 먼저 해석되는데 WSL 포워딩은 IPv4 만 동작한다. `DATABASE_URL` 에 **`127.0.0.1`** 을 쓴다 |
| 잘 되다가 갑자기 `ECONNREFUSED` | WSL2 는 배포판의 **마지막 세션이 닫히면 배포판을 정지**시킨다. Postgres 도 함께 죽는다. `npm run db:up` 이 세션을 하나 잡아 둔다 (`.wslconfig` 의 `vmIdleTimeout` 은 VM 만 잡고 배포판은 못 잡는다) |

WSL 배포판에 systemd 가 켜져 있으면(`/etc/wsl.conf` 의 `[boot] systemd=true`)
배포판이 뜰 때 Postgres 가 자동 기동된다.

## npm 스크립트 (`server/` 안)

| 스크립트 | 설명 |
|---|---|
| `npm run build` | `nest build` |
| `npm run start:dev` | `nest start --watch` |
| `npm start` | `node dist/main` (프로덕션) |
| `npm run typecheck` | 타입 검사만 (`tsc --noEmit`) |
| `npm run prisma:generate` | `prisma generate` |
| `npm run prisma:migrate` | `prisma migrate dev` — **이 환경(비대화형)에서는 거부된다.** `nexus-migration` 스킬 절차를 쓴다 |
| `npm run prisma:deploy` | `prisma migrate deploy` |
| `npm run seed` | `ts-node prisma/seed.ts` |
| `npm test` | Jest 단위 테스트 — 순수 로직 · 가드 · 권한 규칙 |
| `npm run lint` | ESLint |

**계약 검증**은 저장소 루트에서 돌린다(`npm run check:*`, 15종). **실서버 · 실DB · 실소켓**을
쓰고, 전부 자체 계정 · 자체 스페이스를 만들어 쓰므로 기존 데이터를 건드리지 않는다.
GitHub 이 필요한 것은 가짜 GitHub(4599)을 스스로 띄운다. 목록과 필요한 `.env` 는
[CLAUDE.md §1 «자주 쓰는 명령»](../CLAUDE.md). CI 가 push 마다 전부 돈다.

> **단위 테스트로 DB 동작을 증명하려 하지 말 것.** Prisma 를 스텁으로 대체해 22개를
> 통과시킨 코드에서 실 DB 를 붙이자마자 버그 두 개가 나왔다(BigInt 직렬화, raw SQL
> 캐스팅). 스키마·쿼리가 걸린 변경은 반드시 `check:*` 로 확인한다.

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
  `HttpException` 이 아닌 `Error` 의 message 는 **그대로 실리므로**, 공개 경로(OAuth
  콜백 · 웹훅)의 throw 는 감싸서 접는다. 커스텀 필드는 버려지니 `Retry-After` 같은 헤더로 보낸다.
- **인증 사용자**: `@CurrentUser()`. 담기는 값은 `{ id, email }` 뿐이다.
- **raw SQL 의 시각**: 시각 컬럼은 `timestamp without time zone` 에 UTC 로 저장된다.
  `now()` 대신 `(now() at time zone 'utc')` — `npm run check:sql-time` 이 잡는다.

## 디렉터리

```
src/
├─ main.ts            # 부트스트랩 (api prefix, ValidationPipe, CORS 화이트리스트, 쿠키, rawBody)
├─ app.module.ts      # 루트 모듈 — 켜져 있는 모듈의 목차
├─ config/            # jwt.config.ts — 시크릿 해석의 유일한 지점
├─ auth/              # 가입 · 로그인 · 리프레시 회전 · 재사용 탐지 · JWT 전략
├─ users/             # /api/me (전역 사용자 목록은 두지 않는다 — 테넌트 격리)
├─ spaces/            # 스페이스 CRUD · 멤버 · 초대 · SpaceGuard · SpaceRoleGuard
├─ categories/        # 채널 그룹
├─ channels/          # 채널 · 가시성 규칙 · 읽음 마커
├─ messages/          # 메시지 목록 · 전송 · 수정 이력 · 소프트 삭제 · 핀
│                    #   + reactions.service.ts (리액션 요약 · 멱등 추가/제거)
│                    #   + 스레드 답글(parent_id) · 답장 인용(quoted_message_id)
│                    #   + mentions.service.ts (<@id> 파싱 · 안 읽은 멘션 수)
├─ storage/           # StorageDriver — 바이트를 어디에 둘지만 안다
│                    #   URL 을 만드는 메서드가 없다: 서명 URL 은 SpaceGuard 를
│                    #   지나지 않아 스페이스 밖에서도 열린다
├─ attachments/       # 업로드 · 스트리밍 다운로드 · 썸네일 · 파일 목록 · 고아 정리(24h)
├─ issues/            # 이슈 · 라벨 · 댓글 · 칸반 정렬(position) · 채번
├─ sprints/           # 스프린트 · 번다운
├─ oauth/             # GitHub 계정 연결 · state · 토큰 암호화(OAUTH_TOKEN_KEY)
├─ repos/             # 웹훅 수신(서명 검증) · 저장소 연결 · 열람 · 커밋 · PR 프록시
│  └─ indexing/       # 트리 순회 · 거르기 · 청킹 · 벡터 검색 · 큐 워커
├─ embedding/         # 임베딩 어댑터 (gemini · local · fake)
├─ llm/               # LLM 어댑터 (gemini · local · fake)
├─ ai/                # POST /ai/ask · 프리셋 · 컨텍스트 조립 · ai_runs 큐 · 러너 · 캐시
├─ realtime/          # 소켓 게이트웨이 · 룸 계산 · 이벤트 발신
├─ prisma/            # PrismaModule + PrismaService
└─ common/            # 예외 필터, 데코레이터, 공통 DTO, slug, bigint 직렬화
prisma/
├─ schema.prisma      # 전체 데이터 모델
├─ migrations/        # pgvector 확장 · HNSW 인덱스 포함
│                    #   ⚠ 자동 생성 SQL 을 그대로 믿지 말 것 — Prisma 가 표현하지
│                    #     못하는 HNSW 인덱스를 드리프트로 보고 DROP 을 끼워 넣는다
│                    #     (npm run check:migrations 가 잡는다)
└─ seed.ts
scripts/              # env-setup · WSL DB 스크립트 · 계약 검증(check-*.mjs) + lib/
docker-compose.yml    # pgvector/postgres (redis · minio 는 프로필 뒤 — 기본으로 뜨지 않는다)
```

## 인덱싱을 진짜로 돌리려면 — Ollama 와 모델이 필요하다

`EMBEDDING_PROVIDER=fake` 는 **검증 전용**이다(해시 벡터라 의미를 모른다).
실제로 쓰려면 `local` 이고, 그러면 이 PC 에 Ollama 데몬과 모델이 있어야 한다.

```bash
# winget install Ollama.Ollama   (한 번만)
ollama pull embeddinggemma              # 622MB. 100개+ 언어 · 768차원 · 2,048 토큰
```

`.env` 는 `EMBEDDING_PROVIDER=local` 이면 된다(`EMBEDDING_MODEL` 을 비우면
`embeddinggemma` 가 기본이다). 데몬은 트레이 앱이 띄우고, 안 떠 있으면
`ollama serve`. 확인: `curl http://127.0.0.1:11434/api/tags`.

**`nomic-embed-text` 계열을 쓰지 말 것** — v1.5 는 한국어를 못 하고, v2-moe 는
컨텍스트가 **512 토큰**이라 1,000자를 넘으면 **오류 없이 뒤를 버린다**(잘린
앞부분만 임베딩된다). 둘 다 실측으로 걸렀다 — 근거는 [진행 기록 «12 실제 태우기»](../docs/진행-기록.md).

**모델을 바꾸면 전체 재인덱싱이 필요하다** — 문서 벡터와 질의 벡터가 같은
모델에서 나와야 한다. `POST /spaces/:spaceId/repos/:repoId/index` 가 전체
재인덱싱이다(`baseSha=null` 이라 `planFor` 가 `first` 로 떨어진다).
2026-09-17 부터는 인덱스에 쓴 모델(`repos.indexed_embedding_model`)을 기록해,
모델이 다르면 **다음 인덱싱이 compare 없이 전체로 떨어진다.** 그 사이 벡터 검색과
AI 코드 질문은 **503** 으로 막힌다 — 섞인 순위를 조용히 내보내지 않는다. 막힌 검색은
전체 재인덱싱을 스스로 걸어 두므로 push 를 기다릴 필요는 없다(13-2).

**속도**: 이 저장소 전체가 이 PC 의 CPU 로 **약 1시간**이다(분당 33청크).
임베딩이 병목이라 GPU 가 있는 PC 에서는 크게 빨라진다.

## 실제 GitHub 에 웹훅을 붙이는 법 — PC 를 옮기면 다시 해야 한다

**저장소 등록은 DB 에 있고 DB 는 PC 마다 따로다.** 아래 절차는 새 PC 에서
그대로 반복한다. 등록된 저장소도, 웹훅 시크릿도 옮겨지지 않는다.

```bash
# 1) 터널 — GitHub 이 이 PC 에 닿을 주소를 만든다
#    winget install Cloudflare.cloudflared  (한 번만)
cloudflared tunnel --url http://localhost:3000
#    → https://<임의의-말>.trycloudflare.com 이 로그에 찍힌다

# 2) 저장소 등록 — 응답의 webhookSecret 을 적어 둔다(다시 볼 수 없다)
curl -X POST http://127.0.0.1:3000/api/spaces/<spaceId>/repos   -H "authorization: Bearer <accessToken>" -H "content-type: application/json"   -d '{"provider":"github","fullPath":"소유자/이름","linkedChannelId":"<channelId>"}'
```

3) GitHub 저장소 → Settings → Webhooks → Add webhook

| 칸 | 값 |
|---|---|
| Payload URL | `https://<터널>/api/webhooks/github/<repoId>` |
| Content type | **`application/json`** — 기본값 `form` 이면 서명이 안 맞는다 |
| Secret | 2번에서 받은 `whsec_…` |

**함정 셋을 실제로 겪었다.**

- **터널을 다시 띄우면 주소가 바뀐다.** 무료 quick tunnel 은 매번 새 도메인이라
  GitHub 쪽 Payload URL 도 함께 고쳐야 한다. 안 고치면 **530**(터널 없음)이 뜬다
- `Add webhook` 직후 GitHub 이 **ping** 을 보낸다. 우리는 모르는 이벤트로
  200 을 주므로 **초록 체크가 뜨는 것이 정상**이다(적재는 하지 않는다)
- 시크릿을 잃어버리면 `POST /spaces/:spaceId/repos/:repoId/secret` 으로 재발급한다.
  **옛 시크릿은 그 순간부터 401** 이므로 GitHub 쪽도 함께 고친다
