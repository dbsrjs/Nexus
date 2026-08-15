/*
  답장(인용)을 위한 quoted_message_id.

  `parent_id` 와 다른 개념이다 — 스레드 답글은 채널 타임라인에서 빠지지만
  답장은 흐름 안에 남는다. 그래서 컬럼을 나눈다.

  onDelete: SetNull 인 이유: 메시지는 소프트 삭제가 원칙이라 이 경로는 평소
  타지 않는다. 보관 정책이 바뀌어 하드 삭제가 생기더라도 답장 자체는 남고
  링크만 끊긴다.

  주의 — `prisma migrate diff` 가 만든 초안에는
  `DROP INDEX "repo_index_chunks_embedding_hnsw_idx"` 가 들어 있었다.
  pgvector HNSW 인덱스는 Prisma 가 표현하지 못해 **수동 관리**하는 것이라
  스키마에 없다는 이유로 매번 드리프트로 잡힌다(7-1 에서도 같은 일이 있었다).
  지우면 AI 코드 질의의 벡터 검색이 순차 스캔으로 떨어지므로 삭제 구문을 빼고,
  혹시 사라졌더라도 되살아나도록 맨 끝에서 다시 만든다.
*/

-- AlterTable
ALTER TABLE "messages" ADD COLUMN     "quoted_message_id" TEXT;

-- CreateIndex
CREATE INDEX "messages_quoted_message_id_idx" ON "messages"("quoted_message_id");

-- AddForeignKey
ALTER TABLE "messages" ADD CONSTRAINT "messages_quoted_message_id_fkey" FOREIGN KEY ("quoted_message_id") REFERENCES "messages"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- pgvector HNSW 인덱스 유지 (위 주석 참고 — Prisma 가 관리하지 못한다)
CREATE INDEX IF NOT EXISTS "repo_index_chunks_embedding_hnsw_idx"
  ON "repo_index_chunks"
  USING hnsw ("embedding" vector_cosine_ops);
