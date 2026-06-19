import { IsDateString, IsOptional, IsString } from 'class-validator';
import { PaginationDto } from '../../common/dto/pagination.dto';

/**
 * Query for GET /api/worklogs. Defaults to the caller's own worklogs; an
 * explicit `userId` lets leads/admins view a teammate's. `date` filters to a
 * single day (YYYY-MM-DD). Extends the shared cursor pagination DTO.
 */
export class ListWorklogsDto extends PaginationDto {
  @IsOptional()
  @IsString()
  userId?: string;

  @IsOptional()
  @IsDateString()
  date?: string;
}
