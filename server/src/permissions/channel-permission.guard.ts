import {
  BadRequestException,
  CanActivate,
  ExecutionContext,
  ForbiddenException,
  Injectable,
} from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { Role } from '@prisma/client';
import { AuthUser } from '../common/decorators/current-user.decorator';
import {
  CHANNEL_ACTION_KEY,
  CHANNEL_PARAM_KEY,
  ChannelActionType,
} from './channel-action.decorator';
import { PermissionsService } from './permissions.service';

/**
 * Enforces channel-level can_view / can_send for the authenticated user's role.
 *
 * - Resolves the channel id from the route param named by @ChannelParam(...)
 *   (default: 'channelId', falling back to 'id').
 * - Resolves the required action from @ChannelAction(...) (default: 'view').
 * - admin always passes (full access).
 *
 * Must run after JwtAuthGuard so request.user is populated.
 */
@Injectable()
export class ChannelPermissionGuard implements CanActivate {
  constructor(
    private readonly reflector: Reflector,
    private readonly permissions: PermissionsService,
  ) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const request = context.switchToHttp().getRequest();
    const user: AuthUser | undefined = request.user;
    if (!user) {
      throw new ForbiddenException('Authentication required');
    }

    const role = user.role as Role;
    // Admin bypasses channel-level checks.
    if (role === Role.admin) {
      return true;
    }

    const paramName =
      this.reflector.getAllAndOverride<string | undefined>(CHANNEL_PARAM_KEY, [
        context.getHandler(),
        context.getClass(),
      ]) ?? 'channelId';

    const channelId: string | undefined =
      request.params?.[paramName] ?? request.params?.id;

    if (!channelId) {
      throw new BadRequestException('Channel id missing from route');
    }

    const action: ChannelActionType =
      this.reflector.getAllAndOverride<ChannelActionType | undefined>(
        CHANNEL_ACTION_KEY,
        [context.getHandler(), context.getClass()],
      ) ?? 'view';

    const allowed =
      action === 'send'
        ? await this.permissions.canSend(channelId, role)
        : await this.permissions.canView(channelId, role);

    if (!allowed) {
      throw new ForbiddenException(
        action === 'send'
          ? 'You cannot send messages in this channel'
          : 'You cannot view this channel',
      );
    }

    return true;
  }
}
