-- AlterTable
ALTER TABLE "ai_runs" ADD COLUMN     "attempts" INTEGER NOT NULL DEFAULT 0,
ADD COLUMN     "input" JSONB NOT NULL,
ADD COLUMN     "lease_until" TIMESTAMP(3),
ADD COLUMN     "started_at" TIMESTAMP(3);

-- CreateIndex
CREATE INDEX "ai_runs_state_created_at_idx" ON "ai_runs"("state", "created_at");
