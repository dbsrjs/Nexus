import { IsDateString, IsOptional, IsString } from 'class-validator';

/**
 * Query for GET /api/attendance. Defaults to the caller's records; `userId`
 * lets a lead/admin view a teammate. `from`/`to` bound the date range
 * (YYYY-MM-DD, inclusive).
 */
export class ListAttendanceDto {
  @IsOptional()
  @IsString()
  userId?: string;

  @IsOptional()
  @IsDateString()
  from?: string;

  @IsOptional()
  @IsDateString()
  to?: string;
}
