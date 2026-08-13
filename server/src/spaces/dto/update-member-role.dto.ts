import { SpaceRole } from '@prisma/client';
import { IsIn } from 'class-validator';

/**
 * owner 는 여기서 부여할 수 없다. 소유권 이전은 별도 흐름이어야 하고,
 * owner 가 스페이스당 1명이라는 불변식을 이 엔드포인트로 깨서는 안 된다
 * (docs/백엔드-설계.md §6).
 */
const ASSIGNABLE_ROLES: SpaceRole[] = ['guest', 'member', 'admin'];

export class UpdateMemberRoleDto {
  @IsIn(ASSIGNABLE_ROLES, {
    message: '부여할 수 있는 역할은 guest · member · admin 입니다',
  })
  role!: SpaceRole;
}
