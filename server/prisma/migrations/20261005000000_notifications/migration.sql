-- 18단계 설계 N9 · N17 — 알림이 가리키는 채널 · 메시지 · 작성자 컬럼과 사용자별 알림 스위치 넷.
--
-- 옛 notifications 행은 없다(모듈이 빌드에서 빠져 있었다) — 새 컬럼은 비워 둔 채 더한다.
--
-- 자동 생성기가 끼워 넣은 `DROP INDEX "repo_index_chunks_embedding_hnsw_idx"` 는 지웠다 —
-- 수동 관리하는 pgvector 인덱스를 드리프트로 오인한 것이다(여섯 번째, CLAUDE.md §2).

-- AlterTable
ALTER TABLE "notifications" ADD COLUMN     "actor_id" TEXT,
ADD COLUMN     "channel_id" TEXT,
ADD COLUMN     "message_id" TEXT;

-- AlterTable
ALTER TABLE "users" ADD COLUMN     "notify_broadcast" BOOLEAN NOT NULL DEFAULT true,
ADD COLUMN     "notify_dms" BOOLEAN NOT NULL DEFAULT true,
ADD COLUMN     "notify_mentions" BOOLEAN NOT NULL DEFAULT true,
ADD COLUMN     "notify_replies" BOOLEAN NOT NULL DEFAULT true;

-- CreateIndex
CREATE INDEX "notifications_user_id_space_id_created_at_idx" ON "notifications"("user_id", "space_id", "created_at");

-- CreateIndex
CREATE INDEX "notifications_channel_id_idx" ON "notifications"("channel_id");

-- AddForeignKey
ALTER TABLE "notifications" ADD CONSTRAINT "notifications_channel_id_fkey" FOREIGN KEY ("channel_id") REFERENCES "channels"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "notifications" ADD CONSTRAINT "notifications_message_id_fkey" FOREIGN KEY ("message_id") REFERENCES "messages"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "notifications" ADD CONSTRAINT "notifications_actor_id_fkey" FOREIGN KEY ("actor_id") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;

