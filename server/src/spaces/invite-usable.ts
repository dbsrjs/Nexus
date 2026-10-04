/**
 * 초대가 아직 쓸 수 있는가 — 만료 전이고 사용 한도가 남았다(16단계 설계 D9).
 *
 * 수락(`acceptInvite`)은 만료와 한도를 따로 검사해 서로 다른 순간에 판정한다(한도는
 * 트랜잭션 안의 조건부 갱신). 이 함수는 **목록에 보일지**만 정한다.
 */
export function isInviteUsable(
  invite: { expiresAt: Date | null; maxUses: number | null; useCount: number },
  now: Date,
): boolean {
  if (invite.expiresAt && invite.expiresAt.getTime() <= now.getTime()) return false;
  if (invite.maxUses !== null && invite.useCount >= invite.maxUses) return false;
  return true;
}
