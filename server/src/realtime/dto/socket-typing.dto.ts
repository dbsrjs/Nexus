import { IsOptional, IsUUID } from 'class-validator';

/** `typing` — 지금 쓰는 중(17단계 D21). 스레드면 `parentId`. */
export class SocketTypingDto {
  @IsUUID()
  spaceId!: string;

  @IsUUID()
  channelId!: string;

  @IsOptional()
  @IsUUID()
  parentId?: string;
}
