import { createParamDecorator, ExecutionContext } from '@nestjs/common';
import { SpaceMember } from '@prisma/client';
import { SpaceScopedRequest } from '../guards/space.guard';

/**
 * SpaceGuard 가 검증해 실어 둔 멤버십을 꺼낸다.
 *
 *   @CurrentSpaceMember() member: SpaceMember
 *   @CurrentSpaceMember('role') role: SpaceRole
 */
export const CurrentSpaceMember = createParamDecorator(
  (data: keyof SpaceMember | undefined, ctx: ExecutionContext) => {
    const request = ctx.switchToHttp().getRequest<SpaceScopedRequest>();
    const member = request.spaceMember;
    if (!member) {
      return undefined;
    }
    return data ? member[data] : member;
  },
);
