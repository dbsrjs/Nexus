import {
  IsEnum,
  IsOptional,
  IsString,
  MaxLength,
  ValidateIf,
} from 'class-validator';
import { IssuePriority, IssueStatus } from '@prisma/client';

/**
 * Body for PATCH /api/issues/:id — partial update of status/assignee/etc.
 * `assigneeId: null` explicitly clears the assignee.
 */
export class UpdateIssueDto {
  @IsOptional()
  @IsString()
  @MaxLength(300)
  title?: string;

  @IsOptional()
  @IsString()
  description?: string;

  @IsOptional()
  @IsEnum(IssueStatus)
  status?: IssueStatus;

  @IsOptional()
  @IsEnum(IssuePriority)
  priority?: IssuePriority;

  @IsOptional()
  @IsString()
  @MaxLength(40)
  label?: string;

  @IsOptional()
  @ValidateIf((_, value) => value !== null)
  @IsString()
  assigneeId?: string | null;
}
