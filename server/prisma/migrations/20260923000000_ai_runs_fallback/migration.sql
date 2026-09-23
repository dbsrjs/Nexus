-- 주 모델 대신 전환 모델이 답한 행. 캐시 조회에서 뺀다(LLM 교체, 2026-09-23).
-- 자동 생성 SQL 에 HNSW 인덱스 DROP 이 섞여 나와 지웠다(CLAUDE.md §2).
ALTER TABLE "ai_runs" ADD COLUMN "fallback" BOOLEAN NOT NULL DEFAULT false;
