-- 14단계 사용자 설정 — 프로필 사진
--
-- 손으로 썼다. `migrate diff` 가 수동 관리하는 HNSW 인덱스를 드리프트로 오인해
-- DROP 을 끼워 넣는 일을 원천적으로 피한다(CLAUDE.md §2).

ALTER TABLE "users" ADD COLUMN "avatar_key" TEXT;

-- 설계 D9: `PATCH /api/me` 가 임의 URL 을 받던 자리를 걷는다. 앱은 이 값을
-- 그린 적이 없어 비워도 보이는 것이 바뀌지 않는다. 이제 이 칸은 서버가 만든
-- `/users/<id>/avatar?v=…` 만 담는다.
UPDATE "users" SET "avatar_url" = NULL;
