import { SpaceRole } from '@prisma/client';

/**
 * 역할 서열: guest < member < admin < owner (docs/백엔드-설계.md §6).
 *
 * enum 선언 순서에 기대지 않고 명시적으로 순위를 둔다. 나중에 역할이 추가돼도
 * 비교 로직이 조용히 바뀌지 않게 하기 위함이다.
 */
export const ROLE_RANK: Record<SpaceRole, number> = {
  guest: 0,
  member: 1,
  admin: 2,
  owner: 3,
};

/** role 이 minimum 이상인가. */
export function hasAtLeast(role: SpaceRole, minimum: SpaceRole): boolean {
  return ROLE_RANK[role] >= ROLE_RANK[minimum];
}

/** a 가 b 보다 상위인가. 멤버 관리에서 "자기보다 높은 사람은 못 건드린다"에 쓴다. */
export function outranks(a: SpaceRole, b: SpaceRole): boolean {
  return ROLE_RANK[a] > ROLE_RANK[b];
}
