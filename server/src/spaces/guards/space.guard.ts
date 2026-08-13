import {
  CanActivate,
  ExecutionContext,
  Injectable,
  NotFoundException,
  UnauthorizedException,
} from '@nestjs/common';
import { SpaceMember } from '@prisma/client';
import { PrismaService } from '../../prisma/prisma.service';
import { AuthUser } from '../../common/decorators/current-user.decorator';

/** SpaceGuard 통과 후 요청에 실리는 값. */
export interface SpaceScopedRequest {
  user?: AuthUser;
  params: Record<string, string>;
  spaceMember?: SpaceMember;
}

/**
 * URL 의 `:spaceId` 에 대한 요청자의 멤버십을 검증하고 `req.spaceMember` 에 실어 준다.
 * 이후 컨트롤러·서비스는 이 값을 신뢰한다 (docs/백엔드-설계.md §2 격리 규칙 3).
 *
 * **멤버가 아니면 403이 아니라 404를 던진다.** 403은 "그 스페이스가 존재한다"는
 * 사실을 알려 준다. 남의 테넌트는 존재 여부조차 보이지 않아야 한다.
 */
@Injectable()
export class SpaceGuard implements CanActivate {
  constructor(private readonly prisma: PrismaService) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const request = context.switchToHttp().getRequest<SpaceScopedRequest>();
    const user = request.user;

    if (!user) {
      throw new UnauthorizedException('인증이 필요합니다');
    }

    const spaceId = request.params?.spaceId;
    if (!spaceId) {
      // 라우트에 :spaceId 가 없는데 이 가드를 붙인 것은 배선 실수다.
      throw new Error('SpaceGuard 가 :spaceId 없는 라우트에 적용되었습니다');
    }

    const member = await this.prisma.spaceMember.findUnique({
      where: { spaceId_userId: { spaceId, userId: user.id } },
    });

    if (!member) {
      throw new NotFoundException('스페이스를 찾을 수 없습니다');
    }

    request.spaceMember = member;
    return true;
  }
}
