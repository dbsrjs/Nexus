-- 12단계 인덱싱 작업 큐 (설계 §2).
--
-- **저장소마다 한 행**이라 repo_id 가 기본 키다. 부분 유니크 인덱스를 쓰지 않은
-- 이유는 Prisma 가 표현하지 못하는 손 관리 객체를 늘리지 않기 위해서다.
--
-- 생성된 SQL 에 DROP INDEX "repo_index_chunks_embedding_hnsw_idx" 가 섞여 있어
-- 걷어냈다. 이번이 다섯 번째다 — 그리고 이번 단계가 그 인덱스를 실제로 쓰는
-- 첫 작업이다.
CREATE TYPE "RepoIndexState" AS ENUM ('queued', 'running', 'done', 'failed');
CREATE TYPE "RepoIndexReason" AS ENUM ('connect', 'push', 'manual');

CREATE TABLE "repo_index_jobs" (
    "repo_id" TEXT NOT NULL,
    "space_id" TEXT NOT NULL,
    "state" "RepoIndexState" NOT NULL DEFAULT 'queued',
    "reason" "RepoIndexReason" NOT NULL,
    "head_sha" TEXT,
    "base_sha" TEXT,
    "attempts" INTEGER NOT NULL DEFAULT 0,
    "last_error" TEXT,
    "truncated" BOOLEAN NOT NULL DEFAULT false,
    "lease_until" TIMESTAMP(3),
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,
    "started_at" TIMESTAMP(3),
    "finished_at" TIMESTAMP(3),

    CONSTRAINT "repo_index_jobs_pkey" PRIMARY KEY ("repo_id")
);

CREATE INDEX "repo_index_jobs_state_created_at_idx" ON "repo_index_jobs"("state", "created_at");

ALTER TABLE "repo_index_jobs" ADD CONSTRAINT "repo_index_jobs_space_id_fkey"
  FOREIGN KEY ("space_id") REFERENCES "spaces"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "repo_index_jobs" ADD CONSTRAINT "repo_index_jobs_repo_id_fkey"
  FOREIGN KEY ("repo_id") REFERENCES "repos"("id") ON DELETE CASCADE ON UPDATE CASCADE;
