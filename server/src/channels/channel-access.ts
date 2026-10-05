/**
 * 채널을 볼 수 있는가 · 보낼 수 있는가(16단계 설계 §2). **가시성 규칙은 여기 한 곳이다** —
 * `ChannelsService` 의 `canView` · `canSend` · `viewableChannelIds` 가 전부 이것을 부른다.
 *
 * - 비공개 채널: **명단(`channel_members`)이 정한다.** `canView` 행은 보지 않는다(D22)
 * - 공개 채널: 그 역할의 `canView=false` 행이 있으면 가린다. **멤버 행보다 앞선다**(D23) —
 *   공개 채널은 한 번 읽기만 해도 `markRead` 가 행을 만들어, 행이 이기면 가림이 듣지 않았다
 * - 보내기: 볼 수 있고, 그 역할의 `canSend` 가 거짓이 아니면
 *
 * `perm` 은 guest · member 에만 있다 — admin · owner 행은 만들 수 없다(D21).
 *
 * `dmPeerPresent` 는 DM 에만 넘긴다(17단계 설계 D8) — 상대가 스페이스를 떠난 DM 은 읽기만 한다.
 */
export function channelAccess(input: {
  isPrivate: boolean;
  isMember: boolean;
  perm: { canView: boolean; canSend: boolean } | null;
  dmPeerPresent?: boolean;
}): { view: boolean; send: boolean } {
  const { isPrivate, isMember, perm, dmPeerPresent } = input;
  const view = isPrivate ? isMember : (perm?.canView ?? true);
  const send = view && (perm?.canSend ?? true) && (dmPeerPresent ?? true);
  return { view, send };
}
