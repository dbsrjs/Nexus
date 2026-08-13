import { IsUUID } from 'class-validator';

export class MarkReadDto {
  /** 여기까지 읽었다는 메시지. 기준 시각은 이 메시지의 created_at 을 쓴다. */
  @IsUUID()
  lastReadMessageId!: string;
}
