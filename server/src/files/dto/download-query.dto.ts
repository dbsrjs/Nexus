import { Transform } from 'class-transformer';
import { IsBoolean, IsOptional } from 'class-validator';

/**
 * GET /api/files/:id query options.
 *   ?url=true  → return a presigned download URL (JSON) instead of streaming.
 */
export class DownloadQueryDto {
  @IsOptional()
  @Transform(({ value }) => value === true || value === 'true' || value === '1')
  @IsBoolean()
  url?: boolean = false;
}
