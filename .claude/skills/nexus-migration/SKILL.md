---
name: nexus-migration
description: Use when adding or changing a Prisma migration for the Nexus server after editing schema.prisma — prisma migrate dev is rejected non-interactively in this environment, and auto-generated SQL has repeatedly dropped the pgvector HNSW index.
---

# Nexus Prisma 마이그레이션 생성

## Overview

`prisma migrate dev` 는 이 환경(비대화형)에서 **거부된다** — pgvector HNSW
인덱스처럼 Prisma 가 표현하지 못해 수동 관리하는 객체를 드리프트로 오인해
확인을 물으려 하기 때문이다. `migrate diff` 로 SQL 을 직접 뽑아 손질한 뒤
적용한다.

## 절차

```bash
# 1) diff 로 SQL 생성 (schema.prisma 를 먼저 고친 상태)
npx prisma migrate diff \
  --from-schema-datasource server/prisma/schema.prisma \
  --to-schema-datamodel server/prisma/schema.prisma \
  --script > server/prisma/migrations/<타임스탬프>_<이름>/migration.sql

# 2) 생성된 SQL을 반드시 읽는다 (아래 "필수 확인" 참고)

# 3) 적용
npm --prefix server run prisma:deploy
npm --prefix server run prisma:generate
```

## 필수 확인 — 생성된 SQL 을 커밋 전에 반드시 읽는다

**`DROP INDEX ..._hnsw_idx` 가 섞여 있는지 확인한다.** pgvector HNSW 인덱스는
Prisma 스키마로 표현할 수 없어 수동으로 관리하는데, 자동 생성기가 이걸
드리프트로 오인해 삭제 구문을 끼워 넣는다. **이 프로젝트에서 이미 네 번
일어났다**(7-1 · 7-3 · 9-1 · 9-2a). `npm run check:migrations` 가 CI 에서
이걸 잡지만, PR 을 만들기 전에 로컬에서 먼저 걸러야 한다.

발견하면: 그 `DROP INDEX` / 관련 `CREATE INDEX` 줄을 SQL 에서 지운다(HNSW
인덱스는 건드리지 않는다). 나머지 변경만 적용한다.

## 적용 후 검증 (Postgres MCP 사용 가능하면)

```sql
-- HNSW 인덱스가 살아있는지 직접 확인
SELECT indexname FROM pg_indexes WHERE indexname LIKE '%hnsw%';
```

`postgres-nexus` MCP 서버가 붙어 있으면 임시 스크립트 없이 바로 이 쿼리를
돌려 확인할 수 있다.

## 로컬 실행이 막히면

`prisma migrate dev` 를 직접 시도하면 확인 프롬프트에서 멈춘다(비대화형이라
응답할 수 없다) — 그 경우 프로세스를 죽이고 위 diff 방식으로 다시 간다.
`--no-verify` 류 우회 플래그를 찾지 않는다.

## 관련

이 함정의 배경과 반복 이력은 저장소 `CLAUDE.md` §2("이 환경의 함정")과
§5("알려진 빚")이 원본이다.
