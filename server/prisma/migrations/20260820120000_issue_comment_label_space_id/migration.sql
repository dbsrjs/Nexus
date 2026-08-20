-- issue_comments · issue_label_links 에 space_id 를 채운다.
--
-- 2단계 스키마 재작성 때 빠진 것으로, 7-1 에서 reactions · mentions 에 채운
-- 것과 같은 종류다. 설계 §2 규칙 1 은 예외를 두지 않는다 — 부모를 타고
-- 유추할 수 있어도 비정규화해 모든 쿼리 WHERE 에 강제로 넣는다.
--
-- 두 테이블 모두 행이 0건이라(기능이 아직 없었다) NOT NULL 을 바로 걸 수 있다.
--
-- prisma migrate diff 가 만든 SQL 에서 pgvector HNSW 인덱스를 지우는
-- `DROP INDEX "repo_index_chunks_embedding_hnsw_idx"` 를 걷어냈다.
-- 7-1 · 7-3 · 9-1 에 이어 **네 번째**다.

-- AlterTable
ALTER TABLE "issue_comments" ADD COLUMN     "space_id" TEXT NOT NULL;

-- AlterTable
ALTER TABLE "issue_label_links" ADD COLUMN     "space_id" TEXT NOT NULL;

-- CreateIndex
CREATE INDEX "issue_comments_space_id_idx" ON "issue_comments"("space_id");

-- CreateIndex
CREATE INDEX "issue_label_links_space_id_idx" ON "issue_label_links"("space_id");

-- AddForeignKey
ALTER TABLE "issue_label_links" ADD CONSTRAINT "issue_label_links_space_id_fkey" FOREIGN KEY ("space_id") REFERENCES "spaces"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "issue_comments" ADD CONSTRAINT "issue_comments_space_id_fkey" FOREIGN KEY ("space_id") REFERENCES "spaces"("id") ON DELETE CASCADE ON UPDATE CASCADE;
