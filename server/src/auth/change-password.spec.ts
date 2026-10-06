import { BadRequestException } from '@nestjs/common';
import * as argon2 from 'argon2';
import { AuthService } from './auth.service';

const CURRENT = 'current-password-1';

async function setup(passwordHash: string | null) {
  const calls: string[] = [];
  const tx = {
    user: {
      update: jest.fn(async (_args: { data: { passwordHash: string } }) => {
        calls.push('update');
        return { id: 'u-1', email: 'a@x.io' };
      }),
    },
    refreshToken: {
      updateMany: jest.fn(async () => void calls.push('revokeAll')),
    },
  };
  const prisma = {
    user: {
      findUnique: jest
        .fn()
        .mockResolvedValue({ id: 'u-1', email: 'a@x.io', passwordHash }),
      update: tx.user.update,
    },
    // 해시 교체와 세션 끊기는 한 트랜잭션이다 — 사이에서 끊기면 옛 세션이 산다.
    $transaction: jest.fn(async (fn: (t: typeof tx) => Promise<unknown>) => {
      calls.push('begin');
      const out = await fn(tx);
      calls.push('commit');
      return out;
    }),
  };
  const refreshTokens = {
    startFamily: jest.fn(() => {
      calls.push('startFamily');
      return { id: 'r-1', familyId: 'f-new', expiresAt: new Date() };
    }),
    persist: jest.fn(async () => void calls.push('persist')),
  };
  const jwt = { signAsync: jest.fn().mockResolvedValue('signed') };
  const config = {
    get: (key: string) => (key === 'JWT_SECRET' ? 'x'.repeat(40) : undefined),
  };
  const service = new AuthService(
    prisma as never,
    jwt as never,
    refreshTokens as never,
    config as never,
  );
  return { service, prisma, refreshTokens, calls };
}

describe('AuthService.changePassword', () => {
  it('★ 현재 비밀번호가 틀리면 400 이다 - 401 은 앱이 리프레시로 오인한다', async () => {
    const { service, prisma } = await setup(await argon2.hash(CURRENT));
    await expect(
      service.changePassword('u-1', 'wrong-password', 'new-password-12'),
    ).rejects.toBeInstanceOf(BadRequestException);
    expect(prisma.user.update).not.toHaveBeenCalled();
  });

  it('비밀번호가 없는 계정은 400 이다 - 확인할 현재 비밀번호가 없다', async () => {
    const { service } = await setup(null);
    await expect(
      service.changePassword('u-1', 'anything', 'new-password-12'),
    ).rejects.toBeInstanceOf(BadRequestException);
  });

  it('새 비밀번호가 지금과 같으면 400 이다', async () => {
    const { service } = await setup(await argon2.hash(CURRENT));
    await expect(service.changePassword('u-1', CURRENT, CURRENT)).rejects.toBeInstanceOf(
      BadRequestException,
    );
  });

  it('★ 해시 교체와 모든 세션 끊기를 한 트랜잭션으로 한 뒤 새 세션을 준다', async () => {
    const { service, prisma, calls } = await setup(await argon2.hash(CURRENT));
    const tokens = await service.changePassword('u-1', CURRENT, 'new-password-12');

    // 새 세션을 먼저 만들고 전부 끊으면 방금 만든 것까지 끊긴다.
    expect(calls).toEqual([
      'begin',
      'update',
      'revokeAll',
      'commit',
      'startFamily',
      'persist',
    ]);
    const hash = prisma.user.update.mock.calls[0][0].data.passwordHash as string;
    await expect(argon2.verify(hash, 'new-password-12')).resolves.toBe(true);
    expect(tokens.accessToken).toBe('signed');
  });
});
