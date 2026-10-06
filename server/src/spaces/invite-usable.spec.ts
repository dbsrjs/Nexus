import { isInviteUsable } from './invite-usable';

describe('isInviteUsable', () => {
  const now = new Date('2026-10-04T00:00:00Z');
  const base = { expiresAt: null, maxUses: null, useCount: 0 };

  it('만료 · 한도가 없으면 쓸 수 있다', () => {
    expect(isInviteUsable(base, now)).toBe(true);
  });

  it('만료 시각이 지금이거나 지났으면 못 쓴다', () => {
    expect(isInviteUsable({ ...base, expiresAt: now }, now)).toBe(false);
    expect(isInviteUsable({ ...base, expiresAt: new Date(now.getTime() - 1) }, now)).toBe(
      false,
    );
  });

  it('만료 전이면 쓸 수 있다', () => {
    expect(isInviteUsable({ ...base, expiresAt: new Date(now.getTime() + 1) }, now)).toBe(
      true,
    );
  });

  it('사용 횟수가 한도에 닿으면 못 쓴다', () => {
    expect(isInviteUsable({ ...base, maxUses: 1, useCount: 1 }, now)).toBe(false);
    expect(isInviteUsable({ ...base, maxUses: 2, useCount: 1 }, now)).toBe(true);
  });
});
