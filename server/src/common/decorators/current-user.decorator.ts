import { createParamDecorator, ExecutionContext } from '@nestjs/common';

/**
 * Shape of the user attached to the request by the JWT strategy/guard
 * (added in the auth phase). Feature modules read it via @CurrentUser().
 */
export interface AuthUser {
  id: string;
  email: string;
  role: string;
}

/**
 * Param decorator that returns the authenticated user (or one of its fields).
 *
 * Usage:
 *   @CurrentUser() user: AuthUser
 *   @CurrentUser('id') userId: string
 */
export const CurrentUser = createParamDecorator(
  (data: keyof AuthUser | undefined, ctx: ExecutionContext): AuthUser | string | undefined => {
    const request = ctx.switchToHttp().getRequest();
    const user: AuthUser | undefined = request.user;
    if (!user) {
      return undefined;
    }
    return data ? user[data] : user;
  },
);
