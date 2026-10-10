/**
 * LiveKit 룸 이름과 참가자 상태 — DB · 네트워크 없이 판정하는 조각(20단계 설계 V4 · V6).
 */

/**
 * 룸 이름은 `<spaceId>:<channelId>` 다. 채널 id 만으로도 유일하지만, 웹훅 · 룸 목록에서 이름을
 * 거꾸로 읽을 때 **스페이스를 함께 대조**하려고 넣는다 — 이름 하나가 다른 스페이스의 채널을
 * 가리키게 만들 수 없다.
 */
export function voiceRoomName(spaceId: string, channelId: string): string {
  return `${spaceId}:${channelId}`;
}

const UUID = '[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}';
const ROOM_NAME = new RegExp(`^(${UUID}):(${UUID})$`, 'i');

/** 우리가 만든 이름이 아니면 null — LiveKit 에 다른 룸이 있어도 건드리지 않는다. */
export function parseVoiceRoomName(
  name: string | undefined | null,
): { spaceId: string; channelId: string } | null {
  const m = name ? ROOM_NAME.exec(name) : null;
  return m ? { spaceId: m[1], channelId: m[2] } : null;
}

/** ListParticipants 응답의 한 줄 — 우리가 읽는 필드만. */
export interface LiveKitParticipant {
  identity?: string;
  /** protojson 이라 기본값(JOINING)이면 필드가 빠진다. */
  state?: string;
  permission?: { can_publish?: boolean; canPublish?: boolean };
}

/**
 * 「통화 중」으로 셀 참가자. **JOINED · ACTIVE 만** 센다 — JOINING 은 아직 붙는 중이고,
 * DISCONNECTED 는 나가는 중이다. 같은 사람이 두 기기로 들어와도 identity 가 같아 한 번만 센다
 * (LiveKit 은 같은 identity 의 새 연결이 옛 연결을 밀어낸다).
 */
export function activeIdentities(participants: LiveKitParticipant[]): string[] {
  const out = new Set<string>();
  for (const p of participants) {
    if (!p.identity) continue;
    if (p.state === 'JOINED' || p.state === 'ACTIVE') out.add(p.identity);
  }
  return [...out].sort();
}

/** 참가자가 지금 말할 수 있게 되어 있는가. 응답은 snake_case 지만 camelCase 도 받는다. */
export function canPublishNow(p: LiveKitParticipant): boolean {
  return p.permission?.can_publish ?? p.permission?.canPublish ?? false;
}

/** 두 명단이 같은가 — 같으면 알리지 않는다. 둘 다 정렬돼 있다. */
export function sameIds(a: readonly string[], b: readonly string[]): boolean {
  return a.length === b.length && a.every((id, i) => id === b[i]);
}
