import { readPushCommits } from './push-commits';

/** 실제 웹훅 payload 의 모양(실측으로 확인한 필드만). */
function pushPayload(overrides: Record<string, unknown> = {}) {
  return {
    ref: 'refs/heads/main',
    before: 'aaa',
    after: 'bbb',
    commits: [
      {
        id: 'c1',
        message: 'feat: 첫 커밋\n\n본문',
        timestamp: '2026-08-21T00:00:00Z',
        author: { name: 'dbsrjs', username: 'dbsrjs' },
        added: ['a.ts'],
        removed: [],
        modified: ['b.ts', 'c.ts'],
      },
    ],
    ...overrides,
  };
}

describe('readPushCommits', () => {
  it('커밋을 요약으로 바꾼다', () => {
    const view = readPushCommits({ raw: pushPayload() });

    expect(view.ref).toBe('main');
    expect(view.commits).toHaveLength(1);
    expect(view.commits[0].sha).toBe('c1');
    expect(view.commits[0].authorName).toBe('dbsrjs');
  });

  it('메시지를 자르지 않는다 — 상세에서 본문까지 읽혀야 한다', () => {
    const view = readPushCommits({ raw: pushPayload() });

    expect(view.commits[0].message).toBe('feat: 첫 커밋\n\n본문');
  });

  it('changedCount 는 added + removed + modified 다', () => {
    const view = readPushCommits({ raw: pushPayload() });

    expect(view.commits[0].changedCount).toBe(3);
  });

  it('refs/heads/ 를 벗긴다', () => {
    const view = readPushCommits({ raw: pushPayload({ ref: 'refs/heads/feat/x' }) });

    expect(view.ref).toBe('feat/x');
  });

  it('push 가 아닌 payload 는 빈 목록이다', () => {
    // PR · 이슈 · 릴리스가 여기로 온다. 던지지 않는다.
    const view = readPushCommits({ raw: { action: 'opened', pull_request: {} } });

    expect(view.commits).toEqual([]);
    expect(view.ref).toBeNull();
  });

  it('모양이 깨져도 던지지 않는다', () => {
    // 남이 보내는 것이라 우리가 모양을 강제할 수 없다(10-1 과 같은 판단).
    expect(readPushCommits(null).commits).toEqual([]);
    expect(readPushCommits({ raw: { commits: 'nope' } }).commits).toEqual([]);
    expect(readPushCommits({ raw: { commits: [{}] } }).commits).toEqual([]);
  });

  it('id 가 없는 커밋은 버린다 — sha 없이는 열 수 없다', () => {
    const view = readPushCommits({
      raw: pushPayload({ commits: [{ message: 'x' }, { id: 'c2', message: 'y' }] }),
    });

    expect(view.commits.map((c) => c.sha)).toEqual(['c2']);
  });
});
