-- 저장소 자동 등록(10-2b)이 GitHub 에게 받은 훅 id 를 남길 자리.
-- 없으면 훅이 안 걸린 것이다 — 등록에 실패했거나 수동으로 붙인 행이다.
--
-- 자동 생성된 SQL 에 pgvector HNSW 인덱스를 지우는 구문이 섞여 있어 걷어냈다
-- (repo_index_chunks_embedding_hnsw_idx). Prisma 가 표현하지 못해 수동
-- 관리하는 인덱스를 드리프트로 오인한 것이고, 이번이 다섯 번째다.
ALTER TABLE "repos" ADD COLUMN "webhook_external_id" TEXT;
