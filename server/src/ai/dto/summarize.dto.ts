import { ArrayMaxSize, ArrayMinSize, IsArray, IsUUID } from 'class-validator';
import { MAX_TRANSCRIPT_MESSAGES } from '../transcript';

export class SummarizeDto {
  @IsUUID()
  channelId!: string;

  /**
   * **고른 구간이다** (설계 §7.1). 상한을 DTO 에서도 막지만
   * `AiService` 가 다시 본다 — 13-2·13-3 이 서비스를 직접 부를 수 있다.
   */
  @IsArray()
  @ArrayMinSize(1)
  @ArrayMaxSize(MAX_TRANSCRIPT_MESSAGES)
  @IsUUID('4', { each: true })
  messageIds!: string[];
}
