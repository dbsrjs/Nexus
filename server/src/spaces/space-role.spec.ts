import { SpaceRole } from '@prisma/client';
import { hasAtLeast, outranks, ROLE_RANK } from './space-role';

/**
 * 역할 서열은 `@MinRole()` 과 멤버 관리(강등·추방)가 함께 쓴다. 순위가 뒤집히면
 * 화면상으로는 "가끔 권한 오류" 로만 보이고, 반대로 뚫리는 쪽은 조용히 통과한다.
 */
describe('역할 서열', () => {
  it('guest < member < admin < owner', () => {
    expect(ROLE_RANK[SpaceRole.guest]).toBeLessThan(ROLE_RANK[SpaceRole.member]);
    expect(ROLE_RANK[SpaceRole.member]).toBeLessThan(ROLE_RANK[SpaceRole.admin]);
    expect(ROLE_RANK[SpaceRole.admin]).toBeLessThan(ROLE_RANK[SpaceRole.owner]);
  });

  describe('hasAtLeast — @MinRole 검사', () => {
    it('같은 역할은 통과시킨다', () => {
      expect(hasAtLeast(SpaceRole.admin, SpaceRole.admin)).toBe(true);
    });

    it('상위 역할은 통과시킨다', () => {
      expect(hasAtLeast(SpaceRole.owner, SpaceRole.admin)).toBe(true);
    });

    it('★ 하위 역할은 막는다', () => {
      expect(hasAtLeast(SpaceRole.member, SpaceRole.admin)).toBe(false);
      expect(hasAtLeast(SpaceRole.guest, SpaceRole.member)).toBe(false);
    });
  });

  describe('outranks — 멤버 관리에서 "나보다 낮은 사람만 건드린다"', () => {
    it('상위만 참이다', () => {
      expect(outranks(SpaceRole.admin, SpaceRole.member)).toBe(true);
      expect(outranks(SpaceRole.owner, SpaceRole.admin)).toBe(true);
    });

    it('★ 같은 역할끼리는 서로 건드릴 수 없다 — admin 이 admin 을 강등하지 못한다', () => {
      expect(outranks(SpaceRole.admin, SpaceRole.admin)).toBe(false);
    });

    it('하위가 상위를 건드릴 수 없다', () => {
      expect(outranks(SpaceRole.member, SpaceRole.admin)).toBe(false);
    });
  });

  it('모든 역할에 순위가 있다 — 역할이 추가되면 여기서 걸린다', () => {
    for (const role of Object.values(SpaceRole)) {
      expect(ROLE_RANK[role]).toBeDefined();
    }
  });
});
