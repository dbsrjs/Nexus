import { ExecutionContext, NotFoundException, UnauthorizedException } from '@nestjs/common';
import { SpaceMember, SpaceRole } from '@prisma/client';
import { PrismaService } from '../../prisma/prisma.service';
import { SpaceGuard, SpaceScopedRequest } from './space.guard';

/**
 * **이 프로젝트에서 가장 중요한 가드다.** 멀티테넌시 격리 전체가 여기 걸려 있고,
 * 뚫리면 남의 스페이스 데이터가 새는 종류의 버그가 된다.
 *
 * 특히 지키려는 것: **비멤버에게 403 이 아니라 404 를 준다.** 403 은 "그 스페이스가
 * 존재한다" 를 알려 준다 (docs/백엔드-설계.md §2).
 */
function contextWith(request: Partial<SpaceScopedRequest>): ExecutionContext {
  return {
    switchToHttp: () => ({ getRequest: () => request }),
  } as unknown as ExecutionContext;
}

function prismaWith(member: SpaceMember | null): PrismaService {
  return {
    spaceMember: { findUnique: jest.fn().mockResolvedValue(member) },
  } as unknown as PrismaService;
}

const member: SpaceMember = {
  spaceId: 'space-a',
  userId: 'user-1',
  role: SpaceRole.member,
  nickname: null,
  joinedAt: new Date(),
};

describe('SpaceGuard', () => {
  it('멤버면 통과시키고 req.spaceMember 를 채운다', async () => {
    const request: Partial<SpaceScopedRequest> = {
      user: { id: 'user-1', email: 'a@b.c' },
      params: { spaceId: 'space-a' },
    };
    const guard = new SpaceGuard(prismaWith(member));

    await expect(guard.canActivate(contextWith(request))).resolves.toBe(true);
    expect(request.spaceMember).toEqual(member);
  });

  it('★ 멤버가 아니면 403 이 아니라 404 를 던진다 — 존재 여부를 숨긴다', async () => {
    const guard = new SpaceGuard(prismaWith(null));
    const context = contextWith({
      user: { id: 'user-1', email: 'a@b.c' },
      params: { spaceId: 'space-b' },
    });

    await expect(guard.canActivate(context)).rejects.toBeInstanceOf(NotFoundException);
  });

  it('인증되지 않은 요청은 401', async () => {
    const guard = new SpaceGuard(prismaWith(member));
    const context = contextWith({ params: { spaceId: 'space-a' } });

    await expect(guard.canActivate(context)).rejects.toBeInstanceOf(
      UnauthorizedException,
    );
  });

  it('★ 조회는 반드시 (spaceId, userId) 두 값으로 한다', async () => {
    const prisma = prismaWith(member);
    const guard = new SpaceGuard(prisma);

    await guard.canActivate(
      contextWith({
        user: { id: 'user-1', email: 'a@b.c' },
        params: { spaceId: 'space-a' },
      }),
    );

    // userId 만으로 찾으면 다른 스페이스의 멤버십이 통과할 수 있다.
    expect(prisma.spaceMember.findUnique).toHaveBeenCalledWith({
      where: { spaceId_userId: { spaceId: 'space-a', userId: 'user-1' } },
    });
  });

  it(':spaceId 없는 라우트에 붙이면 배선 실수로 보고 즉시 실패한다', async () => {
    const guard = new SpaceGuard(prismaWith(member));
    const context = contextWith({
      user: { id: 'user-1', email: 'a@b.c' },
      params: {},
    });

    // 조용히 통과시키면 가드 없는 라우트가 생긴다.
    await expect(guard.canActivate(context)).rejects.toThrow(/SpaceGuard/);
  });
});
