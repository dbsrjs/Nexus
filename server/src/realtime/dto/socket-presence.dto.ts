import { IsIn } from 'class-validator';

/** `presence:set` — 이 소켓의 상태(17단계 D16). 오프라인은 끊는 것으로 알린다. */
export class SocketPresenceDto {
  @IsIn(['online', 'away'])
  status!: 'online' | 'away';
}
