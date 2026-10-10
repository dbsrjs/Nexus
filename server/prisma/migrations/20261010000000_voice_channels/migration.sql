-- 20단계 설계 V1 — 음성 채널은 채널의 한 종류다. 가시성 · 카테고리 · 정렬을 그대로 쓴다.
--
-- 자동 생성기가 끼워 넣은 `DROP INDEX "repo_index_chunks_embedding_hnsw_idx"` 는 지웠다 —
-- Prisma 가 표현하지 못해 수동 관리하는 pgvector 인덱스다(CLAUDE.md §2).

-- AlterEnum
ALTER TYPE "ChannelKind" ADD VALUE 'voice';
