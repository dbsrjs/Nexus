import { ArrayMaxSize, ArrayMinSize, IsArray, IsUUID } from 'class-validator';

/** 비공개 채널에 들일 사람들. 한 번에 50명까지(16단계 설계 §1). */
export class AddChannelMembersDto {
  @IsArray()
  @ArrayMinSize(1)
  @ArrayMaxSize(50)
  @IsUUID('all', { each: true })
  userIds!: string[];
}
