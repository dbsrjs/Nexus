import { foldReviewState, toPullFile, toPullSummary } from './pull-view';

const OPEN = {
  number: 12,
  title: '멘션을 파서 안으로 넣는다',
  state: 'open',
  draft: false,
  user: { login: 'dbsrjs', avatar_url: 'https://avatars/1' },
  head: { ref: 'feat/x', sha: 'abc123' },
  base: { ref: 'main' },
  html_url: 'https://github.com/o/r/pull/12',
  created_at: '2026-08-01T00:00:00Z',
  merged_at: null,
  closed_at: null,
};

describe('toPullSummary', () => {
  it('열린 PR 은 open 이다', () => {
    expect(toPullSummary(OPEN)).toMatchObject({
      number: 12,
      state: 'open',
      sourceBranch: 'feat/x',
      targetBranch: 'main',
    });
  });

  it('머지된 것은 closed 가 아니라 merged 다 — 사람에게 전혀 다른 일이다', () => {
    const merged = { ...OPEN, state: 'closed', merged_at: '2026-08-02T00:00:00Z' };
    expect(toPullSummary(merged)?.state).toBe('merged');
  });

  it('머지 없이 닫힌 것은 closed 다', () => {
    const closed = { ...OPEN, state: 'closed', closed_at: '2026-08-02T00:00:00Z' };
    expect(toPullSummary(closed)?.state).toBe('closed');
  });

  it('number 가 없으면 null 이다 — 남이 보내는 값이라 모양을 강제할 수 없다', () => {
    expect(toPullSummary({ ...OPEN, number: undefined })).toBeNull();
  });

  // **포크에서 온 PR 은 head.ref 로 파일을 열 수 없다.** 그 브랜치는 포크 쪽에
  // 있어 base 저장소의 contents API 가 404 를 준다(진짜 GitHub 으로 확인했다).
  // sha 는 base 의 네트워크에서 풀린다 — 앱이 파일을 열 때 이것을 쓴다.
  it('head sha 를 싣는다 — 포크 PR 의 파일을 여는 유일한 길이다', () => {
    expect(toPullSummary(OPEN)?.headSha).toBe('abc123');
  });

  it('sha 가 없으면 null 이다', () => {
    expect(toPullSummary({ ...OPEN, head: { ref: 'feat/x' } })?.headSha).toBeNull();
  });
});

describe('foldReviewState', () => {
  it('리뷰어마다 마지막 것만 센다', () => {
    expect(
      foldReviewState([
        { user: { login: 'a' }, state: 'CHANGES_REQUESTED' },
        { user: { login: 'a' }, state: 'APPROVED' },
      ]),
    ).toBe('approved');
  });

  it('한 명이라도 변경을 요청하면 changes_requested 다', () => {
    expect(
      foldReviewState([
        { user: { login: 'a' }, state: 'APPROVED' },
        { user: { login: 'b' }, state: 'CHANGES_REQUESTED' },
      ]),
    ).toBe('changes_requested');
  });

  it('COMMENTED · DISMISSED 는 승인도 거절도 아니라 버린다', () => {
    expect(
      foldReviewState([
        { user: { login: 'a' }, state: 'COMMENTED' },
        { user: { login: 'b' }, state: 'DISMISSED' },
      ]),
    ).toBeNull();
  });

  it('리뷰가 없으면 null 이다 — pending 이 아니라 그릴 것이 없다는 뜻이다', () => {
    expect(foldReviewState([])).toBeNull();
    expect(foldReviewState(null)).toBeNull();
  });
});

describe('toPullFile', () => {
  it('patch 를 떨어뜨린다 — diff 를 그리지 않으므로 쓸 곳이 없다', () => {
    const file = toPullFile({
      filename: 'a/b.ts',
      status: 'modified',
      additions: 12,
      deletions: 3,
      patch: '@@ -1 +1 @@',
      blob_url: 'https://example',
    });
    expect(file).toEqual({
      path: 'a/b.ts',
      status: 'modified',
      additions: 12,
      deletions: 3,
      previousPath: null,
    });
  });

  it('renamed 는 이전 경로를 싣는다', () => {
    expect(
      toPullFile({ filename: 'new.ts', status: 'renamed', previous_filename: 'old.ts' }),
    ).toMatchObject({ status: 'renamed', previousPath: 'old.ts' });
  });

  it('모르는 status 는 modified 로 본다 — 목록에서 빠지는 것보다 낫다', () => {
    expect(toPullFile({ filename: 'a.ts', status: 'changed' })?.status).toBe('modified');
  });

  it('filename 이 없으면 null 이다', () => {
    expect(toPullFile({ status: 'added' })).toBeNull();
  });
});
