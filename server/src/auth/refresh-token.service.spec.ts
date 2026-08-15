import { UnauthorizedException } from '@nestjs/common';
import { RefreshToken } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { RefreshTokenService } from './refresh-token.service';

/**
 * 리프레시 회전과 재사용 탐지 (docs/백엔드-설계.md §6).
 *
 * 여기가 뚫리면 탈취된 토큰이 계속 살아 있게 된다. 실서버 검증에서도 확인하지만,
 * **탐지 조건은 분기가 여럿이라** 단위 테스트로 못 박아 두는 편이 싸다.
 */
function prismaWith(row: RefreshToken | null) {
  const updateMany = jest.fn().mockResolvedValue({ count: 1 });
  const prisma = {
    refreshToken: {
      findUnique: jest.fn().mockResolvedValue(row),
      updateMany,
      update: jest.fn(),
      create: jest.fn(),
    },
    $transaction: jest.fn().mockResolvedValue([]),
  } as unknown as PrismaService;
  return { prisma, updateMany };
}

const rawToken = 'raw-refresh-token';

function rowOf(overrides: Partial<RefreshToken> = {}): RefreshToken {
  return {
    id: 'token-1',
    userId: 'user-1',
    familyId: 'family-1',
    tokenHash: RefreshTokenService.hash(rawToken),
    expiresAt: new Date(Date.now() + 60_000),
    revokedAt: null,
    replacedById: null,
    userAgent: null,
    ip: null,
    createdAt: new Date(),
    ...overrides,
  };
}

describe('RefreshTokenService', () => {
  it('원문이 아니라 해시를 저장한다 — DB 유출 시 토큰이 바로 쓰이지 않는다', () => {
    const hash = RefreshTokenService.hash(rawToken);
    expect(hash).not.toBe(rawToken);
    expect(hash).toMatch(/^[0-9a-f]{64}$/);
  });

  it('정상 토큰은 통과한다', async () => {
    const { prisma } = prismaWith(rowOf());
    const service = new RefreshTokenService(prisma);

    await expect(service.verifyUsable('token-1', rawToken)).resolves.toMatchObject({
      id: 'token-1',
    });
  });

  it('★ 이미 revoke 된 토큰이 다시 오면 family 전체를 무효화하고 거부한다', async () => {
    const { prisma, updateMany } = prismaWith(rowOf({ revokedAt: new Date() }));
    const service = new RefreshTokenService(prisma);

    await expect(service.verifyUsable('token-1', rawToken)).rejects.toBeInstanceOf(
      UnauthorizedException,
    );

    // 탈취된 토큰이 살아 있으면 안 된다. 정상 클라이언트는 회전된 토큰을 다시 쓰지 않는다.
    expect(updateMany).toHaveBeenCalledWith({
      where: { familyId: 'family-1', revokedAt: null },
      data: { revokedAt: expect.any(Date) },
    });
  });

  it('★ jti 는 맞는데 본문이 다르면 거부한다 — 해시를 실제로 대조한다', async () => {
    const { prisma } = prismaWith(rowOf());
    const service = new RefreshTokenService(prisma);

    await expect(
      service.verifyUsable('token-1', 'different-token'),
    ).rejects.toBeInstanceOf(UnauthorizedException);
  });

  it('만료된 토큰은 거부한다', async () => {
    const { prisma } = prismaWith(rowOf({ expiresAt: new Date(Date.now() - 1000) }));
    const service = new RefreshTokenService(prisma);

    await expect(service.verifyUsable('token-1', rawToken)).rejects.toBeInstanceOf(
      UnauthorizedException,
    );
  });

  it('없는 토큰은 거부한다', async () => {
    const { prisma } = prismaWith(null);
    const service = new RefreshTokenService(prisma);

    await expect(service.verifyUsable('missing', rawToken)).rejects.toBeInstanceOf(
      UnauthorizedException,
    );
  });

  it('회전은 같은 family 를 유지한다 — 한 번의 로그인이 하나의 family 다', () => {
    const { prisma } = prismaWith(null);
    const service = new RefreshTokenService(prisma);
    const previous = rowOf();

    const next = service.rotate(previous, 60_000);

    expect(next.familyId).toBe(previous.familyId);
    expect(next.id).not.toBe(previous.id);
  });

  it('새 로그인은 새 family 를 만든다', () => {
    const { prisma } = prismaWith(null);
    const service = new RefreshTokenService(prisma);

    const a = service.startFamily(60_000);
    const b = service.startFamily(60_000);

    expect(a.familyId).not.toBe(b.familyId);
  });
});
