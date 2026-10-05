/**
 * DM 채널의 key(17단계 설계 D2) — `dm:<작은 id>:<큰 id>`.
 *
 * 채널의 `@@unique([spaceId, key])` 가 같은 두 사람의 DM 이 둘 생기는 것을 DB 에서 막는다.
 * 사람이 만드는 채널 key 는 DTO 가 `:` 를 받지 않아 이 모양과 겹칠 수 없다.
 * 상대 id 를 key 에 담아 두면 한쪽이 스페이스를 나가 명단 행이 지워져도 상대를 잃지 않는다.
 */
export function dmKey(a: string, b: string): string {
  return a < b ? `dm:${a}:${b}` : `dm:${b}:${a}`;
}

/** DM key 에서 나 아닌 쪽. DM key 가 아니거나 내가 없으면 null. */
export function dmPeerOf(key: string, me: string): string | null {
  const parts = key.split(':');
  if (parts.length !== 3 || parts[0] !== 'dm') return null;
  if (parts[1] === me) return parts[2];
  if (parts[2] === me) return parts[1];
  return null;
}
