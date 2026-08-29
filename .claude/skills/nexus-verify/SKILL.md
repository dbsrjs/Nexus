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
   `check:migrations` 는 예외 — DB·서버 둘 다 필요 없다(SQL 파일만 읽는다).
3. 자체 계정·스페이스를 새로 만들어 쓰는 스크립트가 대부분이라 **비밀번호가
   필요 없다**. `check:realtime` 만 시드 비밀번호 인자를 받는다.

## 특별 취급이 필요한 것

| 스크립트 | 추가로 필요한 것 |
|---|---|
| `check:oauth`, `check:browse` | `server/.env` 에 `GITHUB_OAUTH_BASE=http://127.0.0.1:4599` · `GITHUB_API_BASE=http://127.0.0.1:4599` · `OAUTH_TOKEN_KEY` · `PUBLIC_BASE_URL` 을 채우고 **서버 재시작** — 스크립트가 가짜 GitHub(4599)을 스스로 띄운다. 값을 비운 채로 한 번 더 돌리면 "미설정 503" 분기를 확인할 수 있다(스크립트가 그 사정을 출력한다) |
| `check:attachments` | 배포 전에는 `STORAGE_DRIVER=s3` 로 **한 번 더** 돌린다 — 드라이버와 무관하게 도는 스크립트지만 실제 s3 분기는 그 값일 때만 태워진다 |
| `check:issues` | 컬럼 상한(200)과 재채번까지 태워서 다른 스크립트보다 오래 걸린다. 타임아웃을 넉넉히 잡는다 |

## 실패했을 때

- **연결 거부/타임아웃이면 먼저 전제(①②)를 의심한다.** 코드를 고치기 전에
  `npm run db:up` · `npm run server:dev` 가 살아 있는지 확인한다.
- **`check:oauth`/`check:browse` 만 실패하면 `.env` 를 의심한다** — 위 표의
  네 값이 비어 있거나 서버를 재시작 안 한 상태일 가능성이 크다.
- 새 기능을 "완료"로 보고하기 전에는 **해당 check:* 를 실제로 돌린 결과**를
  근거로 든다. 단위 테스트 통과는 이 검증을 대신하지 못한다 — 저장소
  CLAUDE.md §6("검증에 대한 교훈")이 실제로 겪은 두 사고를 기록해 뒀다.

## 관련

전체 스크립트 목록·용도는 저장소 `CLAUDE.md` §1 "자주 쓰는 명령" 표가
원본이다(스크립트가 늘 때마다 갱신된다) — 여기서는 반복되는 함정만 다룬다.
