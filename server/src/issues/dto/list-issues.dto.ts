import { IssueStatus } from '@prisma/client';
import {
  IsEnum,
  IsIn,
  IsOptional,
  IsString,
  IsUUID,
  MaxLength,
} from 'class-validator';

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

  /**
   * `none` 을 주면 **백로그**(스프린트에 없는 것)만 본다.
   * `sprintId` 로는 "비어 있는 것"을 고를 수 없어 따로 둔다.
   */
  @IsOptional()
  @IsIn(['none'])
  sprint?: 'none';

  /**
   * 이슈 키 정확 일치(`NEXUS-12`). 딥링크로 상세에 곧장 들어왔는데 캐시가
   * 비어 있을 때, 앱이 한 건만 받아 오는 길이다 — 라우트는 사람이 읽는 키로
   * 잡고 API 는 id 로 유지한다(설계 §6-1).
   */
  @IsOptional()
  @IsString()
  @MaxLength(40)
  key?: string;

  /** 제목 부분 일치. 대소문자를 가리지 않는다. */
  @IsOptional()
  @IsString()
  @MaxLength(80)
  q?: string;
}
