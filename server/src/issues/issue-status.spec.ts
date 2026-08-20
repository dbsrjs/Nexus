import { IssueStatus } from '@prisma/client';
import { resolveClosedAt } from './issue-status';

const NOW = new Date('2026-08-20T00:00:00.000Z');

/**
 * closedAt 은 번다운의 유일한 입력이다 — 상태 전이 이력 테이블을 두지 않기로
 * 했으므로(설계 §3), 상태를 바꾸는 모든 경로가 같은 규칙을 타야 한다.
 */
describe('resolveClosedAt', () => {
  it('done 이 되면 지금 시각을 찍는다', () => {
    expect(resolveClosedAt(IssueStatus.doing, IssueStatus.done, NOW)).toEqual(NOW);
  });

  it('done 에서 벗어나면 비운다', () => {
    expect(resolveClosedAt(IssueStatus.done, IssueStatus.doing, NOW)).toBeNull();
  });

  it('done 안에서 자리만 바뀌면 건드리지 않는다', () => {
    // 다시 찍으면 닫힌 시각이 밀려 번다운이 틀어진다.
    expect(resolveClosedAt(IssueStatus.done, IssueStatus.done, NOW)).toBeUndefined();
  });

  it('done 과 무관한 전이는 건드리지 않는다', () => {
    expect(
      resolveClosedAt(IssueStatus.backlog, IssueStatus.doing, NOW),
    ).toBeUndefined();
  });

  it('상태를 바꾸지 않으면 건드리지 않는다', () => {
    expect(resolveClosedAt(IssueStatus.done, undefined, NOW)).toBeUndefined();
  });
});
