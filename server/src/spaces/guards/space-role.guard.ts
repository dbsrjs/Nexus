import {
  CanActivate,
  ExecutionContext,
  ForbiddenException,
  Injectable,
} from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { SpaceRole } from '@prisma/client';
import { MIN_ROLE_KEY } from '../decorators/min-role.decorator';
import { hasAtLeast } from '../space-role';
import { SpaceScopedRequest } from './space.guard';

/**
 * @MinRole('admin') 같은 메타데이터를 강제한다. SpaceGuard 다음에 실행되어야 한다.
 *
 * 메타데이터가 없으면 통과시킨다 (역할과 무관한 라우트).
 */
@Injectable()
export class SpaceRoleGuard implements CanActivate {
  constructor(private readonly reflector: Reflector) {}

  canActivate(context: ExecutionContext): boolean {
    const required = this.reflector.getAllAndOverride<SpaceRole | undefined>(
      MIN_ROLE_KEY,
      [context.getHandler(), context.getClass()],
    );

    if (!required) {
      return true;
    }

    const request = context.switchToHttp().getRequest<SpaceScopedRequest>();
    const member = request.spaceMember;

    if (!member) {
      // SpaceGuard 없이 이 가드만 붙인 배선 실수.
      throw new Error('SpaceRoleGuard 가 SpaceGuard 없이 적용되었습니다');
    }

    if (!hasAtLeast(member.role, required)) {
      throw new ForbiddenException('권한이 부족합니다');
    }

    return true;
  }
}
