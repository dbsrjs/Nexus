import { IssueStatus } from '@prisma/client';

/**
 * 상태 전이가 `closedAt` 을 정한다. 클라이언트가 보내는 값은 받지 않는다 —
 * 사용자가 고칠 수 있으면 번다운이 사실이 아니게 된다.
 *
 * 반환값의 `undefined` 는 "건드리지 않는다"이고 `null` 은 "비운다"이다.
 * 이 둘을 구분해야 done 안에서 자리만 옮길 때 닫힌 시각이 밀리지 않는다.
 */
export function resolveClosedAt(
  prev: IssueStatus,
  next: IssueStatus | undefined,
  now: Date,
): Date | null | undefined {
  if (next === undefined || next === prev) return undefined;
  if (next === IssueStatus.done) return now;
  if (prev === IssueStatus.done) return null;
  return undefined;
}
