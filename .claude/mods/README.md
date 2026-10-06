# Claude Code 모드

Claude Code 안에서 도는 개인용 모드(function hooks 플러그인). 앱 · 서버 빌드와는 관계없다.

| 모드 | 하는 일 |
|---|---|
| `git-band` | 입력창 위에 프로젝트 · 브랜치 · 원격 대비 앞뒤 · 변경 · CI(최신 워크플로 실행) · 마지막 커밋을 보인다. `/git-band` 로 즉시 새로 고침 |
| `ko-labels` | 슬래시 명령 설명과 `/config` 설정 이름에 한국어를 병기한다. 사전(`hooks/dictionary.ts`)에 없는 것은 원문 그대로 |

## 설치

터미널의 Claude Code 프롬프트에서(이 저장소가 마켓플레이스다 — 루트의 `.claude-plugin/marketplace.json`):

```
/plugin install git-band --marketplace dbsrjs/Nexus
/plugin install ko-labels --marketplace dbsrjs/Nexus
```

`y` 로 마켓플레이스를 추가하고 범위는 user 를 고른다.

고치면서 쓸 때는 설치 대신 폴더를 직접 올린다 — 저장하면 다시 읽힌다:

```
claude --plugin-dir .claude/mods/git-band --plugin-dir .claude/mods/ko-labels
```

## 전제

- `git-band` 의 CI 칸은 **`gh` 가 설치 · 로그인돼 있어야** 나온다. 없으면 `CI ? (gh 없음)` · `(gh 로그인 필요)` 로 이유를 보인다
- 띠에 `이전 커밋 기준` 이 붙으면 최신 CI 실행이 지금 HEAD 의 것이 아니다(아직 push 안 했거나 CI 가 안 돌았다)

## 검사

```
claude plugin validate .claude/mods/git-band
claude plugin test .claude/mods/git-band
```

`.claude-plugin/types/` 는 엔진이 로드할 때마다 새로 깔기 때문에 커밋하지 않는다(자체 `.gitignore`).
