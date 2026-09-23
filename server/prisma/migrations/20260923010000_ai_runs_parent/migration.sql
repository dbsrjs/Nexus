-- 이어 물은 앞 문답(13-3). 자동 생성 SQL 에 섞인 HNSW 인덱스 삭제 구문은 지웠다(CLAUDE.md §2).

-- AlterTable
ALTER TABLE "ai_runs" ADD COLUMN "parent_run_id" TEXT;

-- CreateIndex
CREATE INDEX "ai_runs_parent_run_id_idx" ON "ai_runs"("parent_run_id");

-- AddForeignKey
ALTER TABLE "ai_runs" ADD CONSTRAINT "ai_runs_parent_run_id_fkey" FOREIGN KEY ("parent_run_id") REFERENCES "ai_runs"("id") ON DELETE CASCADE ON UPDATE CASCADE;
