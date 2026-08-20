import { IssueStatus } from '@prisma/client';
import { IsEnum, IsOptional, IsUUID } from 'class-validator';

/**
 * 드래그가 쓴다. `afterId` 는 "이 카드 뒤에", `beforeId` 는 "이 카드 앞에"다.
 * 둘 다 없으면 그 컬럼 맨 위. 두 이웃은 모두 `status` 컬럼에 있어야 한다 —
 * 다른 컬럼의 카드를 기준으로 자리를 정하면 순서가 뜻을 잃는다.
 */
export class MoveIssueDto {
  @IsEnum(IssueStatus)
  status!: IssueStatus;

  @IsOptional()
  @IsUUID()
  afterId?: string;

  @IsOptional()
  @IsUUID()
  beforeId?: string;
}
