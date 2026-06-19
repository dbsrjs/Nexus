import { IsEnum, IsOptional } from 'class-validator';
import { IssueStatus } from '@prisma/client';

/**
 * Query for GET /api/issues.
 * `?status=` optionally narrows to a single board column; when omitted the
 * controller returns all issues grouped by status for the board.
 */
export class ListIssuesDto {
  @IsOptional()
  @IsEnum(IssueStatus)
  status?: IssueStatus;
}
