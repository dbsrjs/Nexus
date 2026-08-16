import { IsOptional, IsUUID } from 'class-validator';
import { PaginationDto } from '../../common/dto/pagination.dto';

export class ListAttachmentsDto extends PaginationDto {
  /** 한 채널로 좁힌다. 없으면 볼 수 있는 채널 전체다. */
  @IsOptional()
  @IsUUID()
  channelId?: string;
}
