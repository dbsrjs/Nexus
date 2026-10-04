-- 16단계 설계 D31~D33 — 스프린트를 스페이스마다 켜는 선택 기능(기본 끔).
--
-- 자동 생성기가 끼워 넣은 `DROP INDEX "repo_index_chunks_embedding_hnsw_idx"` 는 지웠다 —
-- 수동 관리하는 pgvector 인덱스를 드리프트로 오인한 것이다(다섯 번째, CLAUDE.md §2).

-- AlterTable
ALTER TABLE "spaces" ADD COLUMN     "sprints_enabled" BOOLEAN NOT NULL DEFAULT false;

-- 이미 스프린트를 쓰던 스페이스는 켜 둔다 — 쓰던 것을 말없이 감추지 않는다(D33).
UPDATE "spaces" SET "sprints_enabled" = true
WHERE EXISTS (SELECT 1 FROM "sprints" WHERE "sprints"."space_id" = "spaces"."id");
