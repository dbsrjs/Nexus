---
name: nexus-verify
description: Use when running or debugging Nexus's check:* contract verification scripts (check:oauth, check:browse, check:attachments, check:migrations, etc.), or before claiming a Nexus server-side feature has been verified end-to-end.
---

# Nexus 계약 검증(check:*) 실행

## Overview

`npm run check:<이름>` 은 스텁이 아니라 **실서버·실DB·실소켓**으로 계약을 검증한다.
전제 조건을 안 맞추면 "실패"가 아니라 "설명 없이 매달림/스킵"으로 나타나서 코드
버그로 오인하기 쉽다. 돌리기 전에 여기부터 확인한다.

## 공통 전제

1. `npm run db:up` — WSL Postgres 가 떠 있어야 한다.
2. `npm run server:dev` — 서버가 떠 있어야 한다(대부분의 check:* 가 요구).
   `check:migrations` · `check:sql-time` 은 예외 — DB·서버 둘 다 필요 없다(파일만 읽는다).
3. 모든 스크립트가 자체 계정·스페이스를 새로 만들어 쓰므로 **비밀번호가
   필요 없다**. (`check:realtime` 도 2026-09-17 부터 시드 비밀번호 인자를 받지 않는다.)

## 특별 취급이 필요한 것

| 스크립트 | 추가로 필요한 것 |
|---|---|
| `check:oauth`, `check:browse`, `check:pulls` | `server/.env` 에 `GITHUB_OAUTH_BASE=http://127.0.0.1:4599` · `GITHUB_API_BASE=http://127.0.0.1:4599` · `OAUTH_TOKEN_KEY` · `PUBLIC_BASE_URL` 을 채우고 **서버 재시작** — 스크립트가 가짜 GitHub(4599)을 스스로 띄운다. 값을 비운 채로 한 번 더 돌리면 "미설정 503" 분기를 확인할 수 있다(스크립트가 그 사정을 출력한다) |
| `check:indexing` | 위 GitHub 값에 더해 **`EMBEDDING_PROVIDER=fake`**. AI 케이스(13-2)는 `LLM_PROVIDER=fake` 일 때만 돌고, 아니면 건너뛴다고 찍는다 |
| `check:ai` | **`LLM_PROVIDER=fake`** 가 기본이다 — `gemini` 로 뜬 서버에서 돌리면 무료 티어 쿼터를 쓴다. 미설정 503 분기는 값을 비운 채 한 번 더 |
| `check:attachments` | 지금은 `STORAGE_DRIVER=local` 뿐이다. **`s3` 드라이버는 아직 구현되지 않아** 그 값으로는 서버가 뜨지 않는다 — 배포 단계에서 `S3Driver` 를 붙인 뒤 `s3` 로 한 번 더 돌린다 |
| `check:issues` | 컬럼 상한(200)과 재채번까지 태워서 다른 스크립트보다 오래 걸린다. 타임아웃을 넉넉히 잡는다 |

## 실패했을 때

- **연결 거부/타임아웃이면 먼저 전제(①②)를 의심한다.** 코드를 고치기 전에
  `npm run db:up` · `npm run server:dev` 가 살아 있는지 확인한다.
- **GitHub · 인덱싱 · AI 쪽만 실패하면 `.env` 를 의심한다** — 위 표의 값이
  비어 있거나 서버를 재시작 안 한 상태일 가능성이 크다.
- **「GitHub 을 부르지 않았다」 단언이 가끔 깨지면** 백그라운드 인덱싱 워커다 —
  호출 수를 재기 전에 `scripts/lib/indexing.mjs` 의 `settleIndexing()` 으로 조용하게 만든다.
- **값이 "같다"는 단언은 값이 있는지부터 본다.** 앞 단계가 실패해 둘 다
  `undefined` 면 `undefined === undefined` 로 통과한다(10-2b · 12 에서 겪었다).
- 새 기능을 "완료"로 보고하기 전에는 **해당 check:* 를 실제로 돌린 결과**를
  근거로 든다. 단위 테스트 통과는 이 검증을 대신하지 못한다 — 저장소
  CLAUDE.md §6("검증에 대한 교훈")이 실제로 겪은 두 사고를 기록해 뒀다.

## 전체 목록 — 이 표가 원본이다

2026-10-05 에 CLAUDE.md 에서 옮겼다(매 세션 읽히는 파일을 가볍게). **스크립트를 더하면
여기 한 줄, `package.json` · `.github/workflows/ci.yml` 의 목록, CLAUDE.md 의 종 수 · 개수를 함께 고친다.**

| 명령 | 덮는 것 |
|---|---|
| `npm run check:realtime` | 실서버 · 실DB · 실소켓으로 소켓 계약 검증(53개) (`db:up` · `server:dev` 실행 중이어야 함). **2026-09-17 부터 시드 비밀번호가 필요 없다** — 자체 계정 · 스페이스를 쓴다. 만료 토큰 거부 · 갱신 토큰 재연결은 서버와 같은 `JWT_SECRET` 으로 스크립트가 직접 서명해 본다 |
| `npm run check:reactions` | 리액션 계약 검증(24개). **자체 계정·스페이스를 만들어 쓰므로 비밀번호가 필요 없다** |
| `npm run check:threads` | 스레드 계약 검증(25개). 위와 같이 자체 계정을 쓴다 |
| `npm run check:quotes` | 답장(인용) 계약 검증(17개) |
| `npm run check:mentions` | 멘션 계약 검증(18개) |
| `npm run check:pins` | 핀 계약 검증(20개) |
| `npm run check:attachments` | 첨부 계약 검증(43개). **드라이버와 무관하게 돈다** — 지금 드라이버는 `local` 하나다. 배포 때 `S3Driver` 를 붙이면 `STORAGE_DRIVER=s3` 로 한 번 더 돌린다 |
| `npm run check:repos` | 저장소 웹훅 계약 검증(30개). **GitHub 없이 돈다** — 서명을 직접 만들어 보낸다 |
| `npm run check:oauth` | GitHub **연동 전체** 계약 검증(설정된 서버에서 76개) — 계정 연결(10-2a)과 저장소 목록 · 자동 등록 · 승격 · 훅 재등록/삭제(10-2b). **가짜 GitHub(4599)을 스스로 띄운다** — `.env` 에 `GITHUB_*_BASE` · `OAUTH_TOKEN_KEY` · `PUBLIC_BASE_URL` 을 넣고 서버를 재시작해야 한다. 미설정 503 분기는 그 값들을 비운 채로 한 번 더 돌려야 확인된다(스크립트가 안내를 찍는다) |
| `npm run check:browse` | 저장소 열람 계약 검증(56개) — 브랜치 · 트리 · 파일(10-3a)과 커밋(10-3b). **가짜 GitHub(4599)을 스스로 띄운다** — `check:oauth` 와 같은 `.env` 를 쓴다. 연결 · 등록이 주제인 그쪽과 섞지 않았다 |
| `npm run check:pulls` | PR 열람 계약 검증(35개) — 목록 · 상세 · 바뀐 파일(11단계). **가짜 GitHub(4599)을 스스로 띄운다** — `check:browse` 와 같은 `.env` 를 쓴다 |
| `npm run check:indexing` | 저장소 인덱싱 계약 검증(54개) — 연결 시 적재 · 거르기(바이너리 · 대용량 · 생성 파일) · 벡터 검색 순위 · 증분 재인덱싱(push 웹훅 → compare, 이름 변경(renamed) 갈래 포함) · force-push(compare 404 로 실제로 응답한 횟수까지 확인) · **임베딩 모델 변경 시 compare 없이 전체**(기록된 모델을 DB 에서 직접 바꿔 흉내 낸다 — DB 를 만지는 자리는 `scripts/lib/db.mjs` 머리에 모았다) · 기능 브랜치 무시(12단계) · **AI 코드 질문 · 인용 경로 · 모델 불일치 시 검색과 AI 503**(13-2) · 이어 묻기의 인용이 첫 답과 같음(13-3) · 큐 실패 갈래(429 `Retry-After: 0` · 리스 유효/만료, 2026-09-27). **가짜 GitHub(4599)을 스스로 띄운다** — `check:browse` 와 같은 `.env` 에 **`EMBEDDING_PROVIDER=fake` 가 더 필요하고**, AI 케이스는 `LLM_PROVIDER=fake` 일 때만 돈다(아니면 건너뛴다고 찍는다) |
| `npm run check:migrations` | 마이그레이션에 **수동 관리 객체를 지우는 구문**이 섞였는지 검사. DB 도 서버도 필요 없다 — CI 서버 잡이 매번 돈다 |
| `npm run check:sql-time` | raw SQL 이 **DB 의 시계**(`now()` · `CURRENT_TIMESTAMP`)를 쓰는지 검사. 이 스키마의 시각 컬럼은 `timestamp without time zone` 이고 **Prisma 는 거기에 UTC 를 쓰는데 `now()` 는 DB 로컬을 준다** — 개발 PC 가 `Asia/Seoul` 이라 아홉 시간이 어긋나 인덱싱 리스가 한 번도 동작하지 않았다(진행 기록 «12 실제 태우기»). **CI 가 UTC 면 로컬에서만 틀리고 CI 는 초록이라** 값이 아니라 코드를 본다. DB 도 서버도 필요 없다 |
| `npm run check:issues` | 이슈 · 스프린트 계약 검증(89개). 자체 계정을 쓴다. **컬럼 상한(200)과 재채번까지 태우므로 다른 스크립트보다 오래 걸린다** |
| `npm run check:ai` | AI 계약 검증(설정된 서버에서 89개) — LLM 캐시 · 큐 · 소켓 알림 · 멘션 치환 실증(13-1) · `/ai/ask` 의 자유 지시문 · 채널 최근 대화 · 이슈 초안 · 입력 조합 검증(13-2) · 이어 묻기 · 사슬 상한 · 캐시 분리(13-3) · **큐 실패 갈래**(5xx 재시도 · 소진 · 429 · 4xx · 빈 답 · 잘린 답 · 리스 — `FakeLlmProvider` 의 실패 주입 지시문으로, 2026-09-27). **소진 케이스가 재시도 대기만 50초라 스크립트가 약 1분 걸린다.** 저장소 컨텍스트는 `check:indexing` 이 본다. **`LLM_PROVIDER=gemini` 로 뜬 서버에서는 무료 티어 쿼터를 쓴다** — `fake` 로 돌리는 쪽이 기본이다. 미설정 503 분기는 `check:oauth` 와 같은 패턴으로 `LLM_PROVIDER` 를 비운 채 한 번 더 돌려야 확인된다(스크립트가 안내를 찍는다) |
| `npm run check:members` | 멤버 · 권한 계약 검증(97개) — 16-1: 스페이스 만들기(같은 이름 둘) · 초대 목록 · 취소 · 한도 · 수락 이벤트 · 역할 · 내보내기 · 나가기. 16-2: 채널 만들기(같은 이름 둘) · 비공개 채널 명단 · 역할별 권한(읽기 전용 · 가림 — **읽어 본 공개 채널도 가리면 404**) · 스프린트 스위치 · **가린 채널을 AI · 대화→이슈로 우회하지 못함** · 강등 · 비공개 전환. **내보내지거나 빠지거나 가려진 소켓이 `rooms:sync` 없이도 이벤트를 받지 않는지**를 매번 본다. 자체 계정을 쓴다 |
| `npm run check:dm` | DM 계약 검증(40개, 17-1) — 열기 멱등 · 같은 두 사람 동시 열기에도 하나(key 유일성) · 자기 자신 400 · 비멤버 404 · **셋째 사람(관리자 포함)이 목록 · 메시지 · 소켓으로 못 봄** · 구조 API(이름 · 공개 전환 · 참여 · 명단 · 권한 · 저장소 연결) 404 · 상대가 나간 DM 은 읽기 전용 403 · 돌아오면 같은 DM 이 살아남. 자체 계정을 쓴다 |
| `npm run check:presence` | 프레즌스 · 타이핑 계약 검증(30개, 17-2) — 함께 쓰는 사람만 받음 · 소켓 둘 중 하나만 away 면 온라인 · 끊기면 **5초 유예 뒤** 오프라인 · 유예 안 재연결은 조용히 · 처음 값 REST · typing 은 보낸 소켓 제외 · 명단 밖 · 스페이스 밖 · **읽기 전용 채널 거부** · 1초 상한. **유예를 실제로 기다려 30초쯤 걸린다** |
| `npm run check:settings` | 사용자 설정 계약 검증(48개) — 이름 변경과 `user:updated` 범위 · 아바타 올리기 · 256×256 WebP · 열람 권한(본인 · 함께 쓰는 스페이스만, 그 밖 404) · 비밀번호 변경과 다른 세션 폐기 · 채널 음소거(멱등 · 읽음 위치 보존). 자체 계정을 쓴다 |

