import { Transform } from 'class-transformer';
import { IsBoolean, IsOptional } from 'class-validator';
import { PaginationDto } from '../../common/dto/pagination.dto';

/**
 * GET /api/notifications query.
 * Inherits cursor pagination (?cursor=&limit=) and adds an optional
 * ?unread=true filter to fetch only unread notifications.
 */
export class ListNotificationsDto extends PaginationDto {
  @IsOptional()
  @Transform(({ value }) => value === true || value === 'true' || value === '1')
  @IsBoolean()
  unread?: boolean;
}
