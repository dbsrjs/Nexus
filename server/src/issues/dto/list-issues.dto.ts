import { IssueStatus } from '@prisma/client';
import { IsEnum, IsOptional, IsString, IsUUID, MaxLength } from 'class-validator';

export class ListIssuesDto {
  /** 주면 그 컬럼만. 안 주면 보드 전체. */
  @IsOptional()
  @IsEnum(IssueStatus)
  status?: IssueStatus;

  @IsOptional()
  @IsUUID()
  assigneeId?: string;

  @IsOptional()
  @IsUUID()
  sprintId?: string;

  /** 제목 부분 일치. 대소문자를 가리지 않는다. */
  @IsOptional()
  @IsString()
  @MaxLength(80)
  q?: string;
}
