/*
  리액션·멘션에 space_id 를 붙인다.

  부모 메시지를 타고 유추할 수 있지만 비정규화한다 — 모든 쿼리 WHERE 에 강제로
  넣기 위함이다(docs/백엔드-설계.md §2 테넌트 격리 규칙 1). 2단계 스키마
  재작성 때 이 두 테이블만 빠져 있었다.

  NOT NULL 을 바로 붙일 수 있는 이유: 두 테이블은 아직 쓰이지 않아 비어 있다.
  (리액션 API 가 이 커밋에서 처음 생긴다.)

  주의 — prisma migrate dev 가 자동 생성한 초안에는
  `DROP INDEX "repo_index_chunks_embedding_hnsw_idx"` 가 섞여 있었다.
  pgvector HNSW 인덱스는 Prisma 가 표현하지 못해 **수동 관리**하는 것이라
  (초기 마이그레이션 끝부분 참고) 드리프트로 오인한 것이다. 지우면 AI 코드
  질의의 벡터 검색이 순차 스캔으로 떨어진다. 삭제 대신 그대로 두고,
  혹시 지워졌더라도 되살아나도록 맨 끝에서 다시 만든다.
*/

-- AlterTable
ALTER TABLE "mentions" ADD COLUMN     "space_id" TEXT NOT NULL;

-- AlterTable
ALTER TABLE "reactions" ADD COLUMN     "space_id" TEXT NOT NULL;

-- CreateIndex
CREATE INDEX "reactions_space_id_idx" ON "reactions"("space_id");

-- AddForeignKey
ALTER TABLE "reactions" ADD CONSTRAINT "reactions_space_id_fkey" FOREIGN KEY ("space_id") REFERENCES "spaces"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "mentions" ADD CONSTRAINT "mentions_space_id_fkey" FOREIGN KEY ("space_id") REFERENCES "spaces"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- pgvector HNSW 인덱스 복구 (위 주석 참고 — Prisma 가 관리하지 못한다)
CREATE INDEX IF NOT EXISTS "repo_index_chunks_embedding_hnsw_idx"
  ON "repo_index_chunks"
  USING hnsw ("embedding" vector_cosine_ops);
