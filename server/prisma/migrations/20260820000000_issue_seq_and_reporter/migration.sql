-- 이슈 키 채번 카운터와 작성자.
--
-- prisma migrate diff 가 만든 SQL 에서 pgvector HNSW 인덱스를 지우는
-- `DROP INDEX "repo_index_chunks_embedding_hnsw_idx"` 를 걷어냈다. Prisma 가
-- 표현하지 못해 수동 관리하는 인덱스를 드리프트로 오인한 것이다(7-1 · 7-3 에
-- 이어 세 번째).

-- AlterTable
ALTER TABLE "issues" ADD COLUMN     "reporter_id" TEXT;

-- AlterTable
ALTER TABLE "spaces" ADD COLUMN     "issue_seq" INTEGER NOT NULL DEFAULT 0;

-- AddForeignKey
ALTER TABLE "issues" ADD CONSTRAINT "issues_reporter_id_fkey" FOREIGN KEY ("reporter_id") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;
