/**
 * GitHub 의 PR JSON 을 우리 모양으로 바꾼다. **네트워크를 모른다** —
 * 그래서 단위 테스트로 전부 덮인다(`push-commits.ts` 와 같은 자리).
 */

export type PullState = 'open' | 'merged' | 'closed';
export type PullReviewState = 'approved' | 'changes_requested';

export interface PullSummary {
  number: number;
  title: string;
  state: PullState;
  draft: boolean;
  authorLogin: string | null;
  authorAvatarUrl: string | null;
  sourceBranch: string | null;
  targetBranch: string | null;
  htmlUrl: string | null;
  openedAt: string | null;
  mergedAt: string | null;
  closedAt: string | null;
}

export interface PullDetail extends PullSummary {
  body: string | null;
  additions: number | null;
  deletions: number | null;
  changedFiles: number | null;
  review: PullReviewState | null;
}

export interface PullChangedFile {
  path: string;
  status: 'added' | 'modified' | 'removed' | 'renamed';
  additions: number;
  deletions: number;
  previousPath: string | null;
}

function rec(value: unknown): Record<string, unknown> | null {
  return value && typeof value === 'object' && !Array.isArray(value)
    ? (value as Record<string, unknown>)
    : null;
}
function str(value: unknown): string | null {
  return typeof value === 'string' && value ? value : null;
}
function num(value: unknown): number | null {
  return typeof value === 'number' && Number.isFinite(value) ? value : null;
}

export function toPullSummary(raw: unknown): PullSummary | null {
  const pr = rec(raw);
  if (!pr || typeof pr.number !== 'number') return null;

  const mergedAt = str(pr.merged_at);

  return {
    number: pr.number,
    title: str(pr.title) ?? '',
    // **GitHub 의 state 를 그대로 쓰지 않는다.** 거기엔 open · closed 뿐이고
    // 머지 여부는 merged_at 에 있다. 둘은 사람에게 전혀 다른 일이다.
    state: mergedAt ? 'merged' : pr.state === 'closed' ? 'closed' : 'open',
    draft: pr.draft === true,
    authorLogin: str(rec(pr.user)?.login),
    authorAvatarUrl: str(rec(pr.user)?.avatar_url),
    sourceBranch: str(rec(pr.head)?.ref),
    targetBranch: str(rec(pr.base)?.ref),
    // **html_url 은 싣는다** — 토큰 없이 열리는 공개 주소다. diff_url ·
    // patch_url · _links 는 싣지 않는다.
    htmlUrl: str(pr.html_url),
    openedAt: str(pr.created_at),
    mergedAt,
    closedAt: str(pr.closed_at),
  };
}

/** 상세에만 있는 것들. 목록 API 는 additions 를 주지 않는다(설계 §1). */
export function toPullDetail(raw: unknown): Omit<PullDetail, 'review'> | null {
  const summary = toPullSummary(raw);
  if (!summary) return null;
  const pr = rec(raw) as Record<string, unknown>;

  return {
    ...summary,
    body: str(pr.body),
    additions: num(pr.additions),
    deletions: num(pr.deletions),
    changedFiles: num(pr.changed_files),
  };
}

/**
 * 리뷰 목록을 한 값으로 접는다.
 *
 * GitHub 은 리뷰를 **시간순으로 전부** 준다. 같은 사람이 변경을 요청했다가
 * 나중에 승인하면 두 행이 다 남아, 그대로 세면 승인과 변경 요청이 동시에 뜬다.
 * **리뷰어마다 마지막 것만 남긴다.**
 *
 * `COMMENTED` · `DISMISSED` 는 승인도 거절도 아니라 버린다. 남은 것이 없으면
 * `null` 이다 — **`pending` 이 아니다.** `pending` 은 제출하지 않은 초안이라
 * 남에게 보이지도 않는 값이고, 우리에게 `null` 은 "그릴 것이 없음"이다.
 */
export function foldReviewState(raw: unknown): PullReviewState | null {
  if (!Array.isArray(raw)) return null;

  const last = new Map<string, string>();
  for (const item of raw) {
    const review = rec(item);
    const login = str(rec(review?.user)?.login);
    const state = str(review?.state)?.toUpperCase();
    if (!login || !state) continue;
    if (state !== 'APPROVED' && state !== 'CHANGES_REQUESTED') continue;
    last.set(login, state);
  }

  const states = [...last.values()];
  if (states.includes('CHANGES_REQUESTED')) return 'changes_requested';
  if (states.includes('APPROVED')) return 'approved';
  return null;
}

export function toPullFile(raw: unknown): PullChangedFile | null {
  const file = rec(raw);
  const path = str(file?.filename);
  if (!path) return null;

  const status = ((): PullChangedFile['status'] => {
    switch (file?.status) {
      case 'added':
      case 'removed':
      case 'renamed':
        return file.status;
      // copied · changed · unchanged 는 우리 화면에서 modified 와 같이 다룬다.
      // 목록에서 빠지는 것보다 낫다.
      default:
        return 'modified';
    }
  })();

  return {
    path,
    status,
    additions: num(file?.additions) ?? 0,
    deletions: num(file?.deletions) ?? 0,
    previousPath: str(file?.previous_filename),
  };
}
