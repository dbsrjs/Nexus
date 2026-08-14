import { IsUUID } from 'class-validator';

/**
 * 소켓 read 페이로드. REST 의 MarkReadDto 와 달리 spaceId 를 함께 받는다 —
 * 소켓에는 :spaceId 라우트 파라미터도 SpaceGuard 도 없기 때문이다.
 */
export class SocketReadDto {
  @IsUUID()
  spaceId!: string;

  @IsUUID()
  channelId!: string;

  @IsUUID()
  lastReadMessageId!: string;
}
