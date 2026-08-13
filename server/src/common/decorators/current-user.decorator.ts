import { createParamDecorator, ExecutionContext } from '@nestjs/common';

/**
 * JWT 전략이 request.user 에 실어 주는 값.
 *
 * 역할(role)은 여기 없다. 역할은 전역이 아니라 스페이스마다 다르므로
 * SpaceGuard 가 채우는 req.spaceMember 에서 읽는다 (docs/백엔드-설계.md §2).
 */
export interface AuthUser {
  id: string;
  email: string;
}

/**
 * 인증된 사용자(또는 그 필드 하나)를 반환하는 파라미터 데코레이터.
 *
 *   @CurrentUser() user: AuthUser
 *   @CurrentUser('id') userId: string
 */
export const CurrentUser = createParamDecorator(
  (
    data: keyof AuthUser | undefined,
    ctx: ExecutionContext,
  ): AuthUser | string | undefined => {
    const request = ctx.switchToHttp().getRequest();
    const user: AuthUser | undefined = request.user;
    if (!user) {
      return undefined;
    }
    return data ? user[data] : user;
  },
);
