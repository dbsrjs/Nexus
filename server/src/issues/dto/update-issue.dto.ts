import { IssuePriority, IssueStatus } from '@prisma/client';
import {
  IsEnum,
  IsInt,
  IsOptional,
  IsString,
  IsUUID,
  Max,
  MaxLength,
  Min,
  MinLength,
} from 'class-validator';

/**
 * `closedAt` 은 여기 없다. 상태 전이가 정하는 값이라 사용자가 보내는 것을
 * 받지 않는다 — 고칠 수 있으면 번다운이 사실이 아니게 된다.
 *
 * 담당자 · 스프린트 · 스토리 포인트는 **null 로 비우는 것과 안 보내는 것이
 * 다르다.** `@IsOptional()` 이 null 과 undefined 를 모두 통과시키므로 둘 다
 * 받고, 서비스가 `!== undefined` 로 구분한다.
 */
export class UpdateIssueDto {
  @IsOptional()
  @IsString()
  @MinLength(1)
  @MaxLength(200)
  title?: string;

  @IsOptional()
  @IsString()
  @MaxLength(20000)
  description?: string;

  /** 컬럼만 옮긴다 — 대상 컬럼 맨 위로 간다. 자리까지 정하려면 PUT position. */
  @IsOptional()
  @IsEnum(IssueStatus)
  status?: IssueStatus;

  @IsOptional()
  @IsEnum(IssuePriority)
  priority?: IssuePriority;

  @IsOptional()
  @IsUUID()
  assigneeId?: string | null;

  @IsOptional()
  @IsUUID()
  sprintId?: string | null;

  @IsOptional()
  @IsInt()
  @Min(0)
  @Max(100)
  storyPoints?: number | null;
}
