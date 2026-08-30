---
name: nexus-pc-handoff
description: Use when pausing Nexus work to switch between the two workstations, or when picking work back up on a different PC — server/.env, DB accounts, .superpowers/sdd/ artifacts, and build caches never travel with git.
---

# Nexus PC 간 인수인계

## Overview

Nexus 작업은 집 PC 와 회사 PC 두 곳을 오간다. **DB 는 PC 마다 따로다**
([[nexus-local-db-wsl]]과 같은 문제) — git 으로 옮겨지지 않는 것들이 있어,
미완 상태로 그냥 덮어두면 다음 PC 에서 그 자리부터 다시 헤매게 된다.

## 작업을 중단하고 넘길 때 — 세 가지를 함께 한다

1. **`feat/*` 브랜치를 origin 에 push 한다.** 로컬 커밋만으로는 안 넘어간다.
2. **`docs/<단계>-인수인계.md` 를 쓴다.** 계획 문서("무엇을 만들지")로는 이
   역할을 못 한다 — 아래 골격을 따른다. `docs/10-2a-인수인계.md` 가 실제
   사용된 예시다.
3. **저장소 `CLAUDE.md` 의 상태 줄이 그 문서를 가리키게 한다.** 세션 시작 시
   자동으로 읽히는 유일한 파일이라 여기 링크가 없으면 다음 세션이 못 찾는다.

## 인수인계 문서 골격

```markdown
# <단계> — 인수인계

> <날짜>. 브랜치 `<브랜치명>`.
> 다른 PC 에서 이어받을 때 이 문서부터 읽는다.

## 1. 어디까지 됐나
(작업 표 · 확인한 것 · 확인 못 한 것)

## 2. 다른 PC 에서 이어받는 절차
### 2.1 브랜치 (git fetch && git checkout)
### 2.2 DB · 서버 (CLAUDE.md §1 과 같다)
### 2.3 .env (`npm run env:setup` 뒤에 남는 것만 적는다 — 아래 참고)
### 2.4 검증 (관련 check:* 를 돌려 상태 확인 — [[nexus-verify]] 참고)

## 3. 바로 다음에 할 일

## 4. 되돌리면 안 되는 결정들
(리뷰가 잡아 고친 것 — 이유를 모르고 되돌리면 같은 구멍이 다시 열린다)

## 5. 확인한 것과 확인하지 못한 것

## 6. 이 PC 에만 있고 옮겨지지 않는 것
```

## 절대 옮겨지지 않는 것 — §2.3/§6 채울 때 빠뜨리기 쉬운 목록

- `server/.env` — **다만 대부분은 옮기지 않고 만들어 낸다.** `npm run env:setup` 이
  시크릿 셋(`JWT_SECRET` · `JWT_REFRESH_SECRET` · `OAUTH_TOKEN_KEY`)을 이 PC 에서
  새로 만들고, `.env.example` 에만 있던 키를 덧붙인다. 채워진 값은 건드리지 않는다.
  **인수인계 문서에 적을 것은 그러고도 남는 셋뿐이다** — `GITHUB_CLIENT_ID` ·
  `GITHUB_CLIENT_SECRET`(OAuth App 을 PC 마다 따로 등록해도 된다. 콜백이 양쪽 다
  localhost 다) · `PUBLIC_BASE_URL`(터널 주소라 어차피 띄울 때마다 바뀐다).
  검증용 `GITHUB_OAUTH_BASE` · `GITHUB_API_BASE` 는 [[nexus-verify]] 가 다룬다
- DB 의 계정·스페이스·메시지·저장소 웹훅 등록 (시드로 새로 만든다)
- `.superpowers/sdd/` 의 작업 브리프·보고서·리뷰 diff (git 에 안 올라간다 —
  필요하면 계획 문서에서 다시 뽑는다)
- `app/.dart_tool/` 빌드 캐시, `app/pubspec.lock`(SDK 버전 차이로 뒤집힌다 —
  커밋하지 않고 `git restore` 한다)

## 화면 확인용 계정이 필요하면

시드 계정(`dbsrjs1224@gmail.com`)은 비밀번호를 복구할 수 없다 —
`design@example.com` / `design-check-1234` 를 쓴다(로컬 DB 전용, 재시드해도
살아있다).

## 관련

배경은 저장소 `CLAUDE.md` "0. 먼저 알아야 할 것"과 §1 "셋업"이 원본이다.
검증 절차는 [[nexus-verify]], DB 문제는 [[nexus-local-db-wsl]] 참고.
