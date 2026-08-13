import { SpaceRole } from '@prisma/client';
import { IsIn, IsInt, IsOptional, Max, Min } from 'class-validator';

/** 초대로 부여할 수 있는 역할. owner 는 초대로 넘길 수 없다. */
const INVITABLE_ROLES: SpaceRole[] = ['guest', 'member', 'admin'];

export class CreateInviteDto {
  @IsOptional()
  @IsIn(INVITABLE_ROLES, {
    message: '초대로 부여할 수 있는 역할은 guest · member · admin 입니다',
  })
  role?: SpaceRole;

  /** 유효 기간(시간). 비우면 만료 없음. */
  @IsOptional()
  @IsInt()
  @Min(1)
  @Max(24 * 90)
  expiresInHours?: number;

  /** 사용 가능 횟수. 비우면 무제한. */
  @IsOptional()
  @IsInt()
  @Min(1)
  @Max(1000)
  maxUses?: number;
}
