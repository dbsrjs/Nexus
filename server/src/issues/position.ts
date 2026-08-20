import { Prisma } from '@prisma/client';

/** 이웃이 하나뿐일 때 벌리는 간격. 재채번도 같은 간격을 쓴다. */
export const POSITION_STEP = new Prisma.Decimal(1000);

/**
 * 칸반 카드의 정렬 키를 정한다.
 *
 * `prev` 는 위 카드(작은 position), `next` 는 아래 카드(큰 position)다.
 * 둘 사이면 중간값 — 그래야 재정렬 쓰기가 옮긴 카드 1건으로 끝난다.
 * 카테고리가 쓰는 Int + "맨 뒤에 붙이기"와 다른 이유는 칸반이 사이 삽입을
 * 기본으로 하기 때문이다.
 */
export function positionBetween(
  prev: Prisma.Decimal | null,
  next: Prisma.Decimal | null,
): Prisma.Decimal {
  if (prev && next) return prev.plus(next).dividedBy(2);
  if (prev) return prev.plus(POSITION_STEP);
  if (next) return next.minus(POSITION_STEP);
  return new Prisma.Decimal(0);
}

/**
 * 자릿수가 소진돼 중간값이 이웃과 같아졌는지. 참이면 그 컬럼만 재채번한다.
 *
 * 조용히 같은 값을 쓰면 두 카드의 순서가 tie-break 로 넘어가 흔들린다 —
 * 전송 큐에서 시각이 동률이 됐을 때 겪은 것과 같은 종류의 버그다.
 */
export function needsRenumber(
  value: Prisma.Decimal,
  prev: Prisma.Decimal | null,
  next: Prisma.Decimal | null,
): boolean {
  if (prev?.equals(value)) return true;
  if (next?.equals(value)) return true;
  return false;
}
