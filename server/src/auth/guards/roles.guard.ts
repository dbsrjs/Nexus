import {
  CanActivate,
  ExecutionContext,
  ForbiddenException,
  Injectable,
} from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { Role } from '@prisma/client';
import { ROLES_KEY } from '../../common/decorators/roles.decorator';
import { AuthUser } from '../../common/decorators/current-user.decorator';

/**
 * Global role check. Reads @Roles(...) metadata from the handler/class and
 * enforces that request.user.role is one of the allowed roles.
 *
 * Must run after JwtAuthGuard so request.user is populated. If no @Roles
 * metadata is present, access is allowed (route is role-agnostic).
 */
@Injectable()
export class RolesGuard implements CanActivate {
  constructor(private readonly reflector: Reflector) {}

  canActivate(context: ExecutionContext): boolean {
    const required = this.reflector.getAllAndOverride<Role[] | undefined>(ROLES_KEY, [
      context.getHandler(),
      context.getClass(),
    ]);

    if (!required || required.length === 0) {
      return true;
    }

    const request = context.switchToHttp().getRequest();
    const user: AuthUser | undefined = request.user;

    if (!user) {
      throw new ForbiddenException('Authentication required');
    }

    if (!required.includes(user.role as Role)) {
      throw new ForbiddenException('Insufficient role');
    }

    return true;
  }
}
