/**
 * 룸 이름은 서버 여러 곳에서 만들어진다(게이트웨이 · 이미터). 문자열을 각자
 * 조립하면 오타 하나로 이벤트가 아무에게도 안 가는데, 그건 조용히 실패한다.
 */
export const room = {
  user: (userId: string) => `user:${userId}`,
  space: (spaceId: string) => `space:${spaceId}`,
  channel: (channelId: string) => `channel:${channelId}`,
};

/** 재조인 시 떠날 수 없는 룸인지. socket.id 룸과 개인 룸은 유지한다. */
export function isPinnedRoom(name: string, socketId: string): boolean {
  return name === socketId || name.startsWith('user:');
}
