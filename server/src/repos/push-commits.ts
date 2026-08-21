/**
 * `repo_events.payload` 에서 커밋을 읽는다.
 *
 * **GitHub 을 부르지 않는다.** push payload 는 커밋 목록과 각 커밋의
 * `added` · `removed` · `modified` 를 이미 들고 있다 (설계 §0) — 실측으로
 * 27개까지 잘리지 않는 것을 확인했다.
 *
 * **던지지 않는다.** 남이 보낸 것을 우리가 저장해 둔 것이라 모양을 강제할 수
 * 없다. 10-1 의 `describeGithubEvent` 와 같은 판단이다.
 */
export interface CommitSummary {
  sha: string;

  /** **자르지 않는다** — 목록은 화면이 한 줄로 자르고, 상세는 본문까지 읽는다. */
  message: string;
  authorName: string | null;
  committedAt: string | null;

  /**
   * 바뀐 파일 수. **브랜치 이력(GitHub 목록 API)에서는 `null`** 이다 — 그쪽은
   * 파일 수를 주지 않고, 채우려고 커밋마다 상세를 부르면 스무 번 왕복이 된다.
   */
  changedCount: number | null;
}

export interface PushView {
  /** `refs/heads/` 를 벗긴 브랜치. push 가 아니면 `null`. */
  ref: string | null;
  commits: CommitSummary[];
}

export function readPushCommits(payload: unknown): PushView {
  const raw = asRecord(asRecord(payload)?.raw);
  if (!raw) return { ref: null, commits: [] };

  const list = Array.isArray(raw.commits) ? raw.commits : [];
  const commits: CommitSummary[] = [];

  for (const item of list) {
    const commit = asRecord(item);
    const sha = str(commit?.id);
    // sha 가 없으면 열 수 없다 — 목록에 두면 눌러 봐야 실패하는 줄이 된다.
    if (!commit || !sha) continue;

    commits.push({
      sha,
      message: str(commit.message) ?? '',
      authorName: str(asRecord(commit.author)?.name),
      committedAt: str(commit.timestamp),
      changedCount:
        count(commit.added) + count(commit.removed) + count(commit.modified),
    });
  }

  const ref = str(raw.ref)?.replace(/^refs\/heads\//, '') ?? null;
  return { ref: commits.length > 0 ? ref : null, commits };
}

function count(value: unknown): number {
  return Array.isArray(value) ? value.length : 0;
}

function asRecord(value: unknown): Record<string, unknown> | null {
  return typeof value === 'object' && value !== null && !Array.isArray(value)
    ? (value as Record<string, unknown>)
    : null;
}

function str(value: unknown): string | null {
  return typeof value === 'string' && value.length > 0 ? value : null;
}
