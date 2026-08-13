import { SetMetadata } from '@nestjs/common';
import { SpaceRole } from '@prisma/client';

export const MIN_ROLE_KEY = 'space:minRole';

/**
 * 이 라우트에 필요한 최소 스페이스 역할. SpaceRoleGuard 가 강제한다.
 *
 *   @MinRole('admin')
 *
 * SpaceGuard 뒤에 와야 한다 — req.spaceMember 가 채워진 뒤에 검사한다.
 */
export const MinRole = (role: SpaceRole) => SetMetadata(MIN_ROLE_KEY, role);
