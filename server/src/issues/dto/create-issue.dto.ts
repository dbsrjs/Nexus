import { Type } from 'class-transformer';
import {
  IsEnum,
  IsNotEmpty,
  IsOptional,
  IsString,
  MaxLength,
  ValidateIf,
} from 'class-validator';
import { IssuePriority, IssueStatus } from '@prisma/client';

/**
 * Body for POST /api/issues. `key` is optional — the native provider
 * auto-generates a sequential key (e.g. ISSUE-1) when omitted.
 */
export class CreateIssueDto {
  @IsOptional()
  @IsString()
  @MaxLength(40)
  key?: string;

  @IsString()
  @IsNotEmpty()
  @MaxLength(300)
  title!: string;

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
