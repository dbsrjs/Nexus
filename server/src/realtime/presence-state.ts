/** 소켓 하나가 알린 상태(17단계 D16). 오프라인은 소켓이 없다는 뜻이라 여기 없다. */
export type SocketPresence = 'online' | 'away';
export type Presence = SocketPresence | 'offline';

/**
 * 사용자 하나의 상태(17단계 설계 D15) — 소켓 중 하나라도 `online` 이면 온라인, 소켓은 있는데
 * 모두 `away` 면 자리비움, 소켓이 없으면 오프라인. 휴대폰이 잠겨도 데스크톱 앞에 있으면 있다.
 */
export function combinePresence(sockets: Iterable<SocketPresence>): Presence {
  let any = false;
  for (const s of sockets) {
    if (s === 'online') return 'online';
    any = true;
  }
  return any ? 'away' : 'offline';
}
