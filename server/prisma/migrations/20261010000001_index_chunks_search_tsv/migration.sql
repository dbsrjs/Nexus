-- RAG 강화 — 낱말 검색 열 (2026-10-10).
--
-- **손으로 썼다.** 생성 컬럼과 GIN 인덱스는 Prisma 스키마로 표현할 수 없다 —
-- HNSW 인덱스와 같은 손 관리 객체라 check:migrations 의 목록에 함께 올렸다.
--
-- **생성 컬럼(STORED)으로 둔 이유.** 앱 쪽에서 낱말을 만들어 넣으면 이미
-- 쌓인 인덱스는 다음 전체 재인덱싱 전까지 낱말 검색에 안 걸린다. 생성
-- 컬럼은 ALTER 가 기존 행까지 채운다 — 재인덱싱 없이 바로 쓴다.
--
-- 담는 것(질의 쪽 규칙은 src/repos/indexing/lexical.ts 의 queryTermsOf):
--   · 경로를 / . - 로 나눈 조각 — 「search-guard」 로 물어도 파일이 걸린다
--   · 본문 그대로 — `searchBlocker` 가 통째 낱말 searchblocker 로 들어간다
--   · 본문의 낙타 표기를 나눈 사본 — `search` · `blocker` 로도 걸리게
-- 'simple' 사전을 쓴다. 어간 추출 사전(english)은 한국어를 모르고 식별자를
-- 망가뜨린다(`indexing` → `index`). 한국어 조사는 질의 쪽에서 떼고 앞부분
-- 일치(:*)로 찾는다.
ALTER TABLE "repo_index_chunks"
  ADD COLUMN "search_tsv" tsvector GENERATED ALWAYS AS (
    to_tsvector(
      'simple'::regconfig,
      regexp_replace("path", '[/._-]+', ' ', 'g') || ' ' ||
      "content" || ' ' ||
      regexp_replace("content", '([a-z0-9])([A-Z])', '\1 \2', 'g')
    )
  ) STORED;

-- **fastupdate = off.** 켜 두면(기본) 새 행이 GIN 의 대기 목록에 쌓였다가
-- 청소 때 합쳐지는데, 그 사이 검색이 대기 목록을 통째로 훑는다. 전체
-- 재인덱싱 직후 2,400 청크에서 낱말 검색 한 번이 10초까지 걸렸다(평가
-- 스크립트로 실측, 끄자 수 ms). 인덱싱은 임베딩이 병목이라 쓰기가 조금
-- 느려지는 것은 보이지 않는다.
CREATE INDEX "repo_index_chunks_search_tsv_idx"
  ON "repo_index_chunks"
  USING gin ("search_tsv")
  WITH (fastupdate = off);
