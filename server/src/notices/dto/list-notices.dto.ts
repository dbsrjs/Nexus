import { IsOptional, IsString } from 'class-validator';
import { PaginationDto } from '../../common/dto/pagination.dto';

/**
 * Query for GET /api/notices. Optional `team` filter; pinned notices always
 * surface first. Extends shared cursor pagination.
 */
export class ListNoticesDto extends PaginationDto {
  @IsOptional()
  @IsString()
  team?: string;
}
