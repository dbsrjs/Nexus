import sharp from 'sharp';
import { AvatarService, avatarPath } from './avatar.service';

function png(): Promise<Buffer> {
  return sharp({ create: { width: 20, height: 20, channels: 3, background: '#ff0000' } })
    .png()
    .toBuffer();
}

function setup(over: { prisma?: Record<string, unknown> } = {}) {
  const calls: string[] = [];
  const storage = {
    put: jest.fn(async (key: string) => void calls.push(`put ${key}`)),
    delete: jest.fn(async (key: string) => void calls.push(`delete ${key}`)),
    get: jest.fn(),
    exists: jest.fn(),
  };
  const user = {
    findUnique: jest.fn().mockResolvedValue({ id: 'u-1', avatarKey: 'avatars/u-1/old.webp' }),
    update: jest.fn(async ({ data }: { data: Record<string, unknown> }) => {
      calls.push('update');
      return { id: 'u-1', name: '가영', avatarUrl: data.avatarUrl ?? null };
    }),
  };
  const prisma = {
    user,
    spaceMember: { findFirst: jest.fn(), findMany: jest.fn().mockResolvedValue([]) },
    ...over.prisma,
  };
  const realtime = { toSpace: jest.fn(), toUser: jest.fn() };
  const service = new AvatarService(prisma as never, storage as never, realtime as never);
  return { service, storage, prisma, realtime, calls };
}

describe('avatarPath', () => {
  it('앱이 부를 주소에 버전을 싣는다 - 바꾸면 주소가 달라져 캐시가 갈린다', () => {
    expect(avatarPath('u-1', 'avatars/u-1/0123456789ab.webp')).toBe(
      '/users/u-1/avatar?v=01234567',
    );
  });
});

describe('AvatarService.canView', () => {
  it('본인은 본다', async () => {
    const { service, prisma } = setup();
    await expect(service.canView('u-1', 'u-1')).resolves.toBe(true);
    expect(prisma.spaceMember.findFirst).not.toHaveBeenCalled();
  });

  it('★ 스페이스를 함께 쓰면 본다', async () => {
    const { service, prisma } = setup();
    prisma.spaceMember.findFirst.mockResolvedValue({ spaceId: 's-1' });
    await expect(service.canView('viewer', 'u-1')).resolves.toBe(true);
    expect(prisma.spaceMember.findFirst).toHaveBeenCalledWith(
      expect.objectContaining({
        where: { userId: 'u-1', space: { members: { some: { userId: 'viewer' } } } },
      }),
    );
  });

  it('★ 함께 쓰는 스페이스가 없으면 못 본다', async () => {
    const { service, prisma } = setup();
    prisma.spaceMember.findFirst.mockResolvedValue(null);
    await expect(service.canView('stranger', 'u-1')).resolves.toBe(false);
  });
});

describe('AvatarService.upload', () => {
  it('★ 저장소 → DB → 옛 파일 지우기 순서다 - 되돌릴 수 없는 쪽을 나중에', async () => {
    const { service, calls } = setup();
    await service.upload('u-1', await png());
    expect(calls[0]).toMatch(/^put avatars\/u-1\/[0-9a-f-]+\.webp$/);
    expect(calls[1]).toBe('update');
    expect(calls[2]).toBe('delete avatars/u-1/old.webp');
  });

  it('★ DB 가 실패하면 옛 파일을 지우지 않는다', async () => {
    const { service, storage, prisma } = setup();
    prisma.user.update = jest.fn().mockRejectedValue(new Error('db down'));
    await expect(service.upload('u-1', await png())).rejects.toThrow('db down');
    expect(storage.delete).not.toHaveBeenCalledWith('avatars/u-1/old.webp');
  });

  it('옛 파일 지우기가 실패해도 올리기는 성공한다 - 화면은 새 사진이다', async () => {
    const { service, storage } = setup();
    storage.delete.mockRejectedValue(new Error('disk'));
    await expect(service.upload('u-1', await png())).resolves.toMatchObject({
      avatarUrl: expect.stringMatching(/^\/users\/u-1\/avatar\?v=/),
    });
  });

  it('바뀌면 함께 쓰는 스페이스마다 user:updated 를 보낸다', async () => {
    const { service, prisma, realtime } = setup();
    prisma.spaceMember.findMany.mockResolvedValue([{ spaceId: 's-1' }, { spaceId: 's-2' }]);
    await service.upload('u-1', await png());
    expect(realtime.toSpace).toHaveBeenCalledTimes(2);
    expect(realtime.toSpace).toHaveBeenCalledWith(
      's-1',
      'user:updated',
      expect.objectContaining({ userId: 'u-1', name: '가영' }),
    );
    expect(realtime.toUser).toHaveBeenCalledWith('u-1', 'user:updated', expect.anything());
  });
});

describe('AvatarService.remove', () => {
  it('DB 를 비운 뒤 파일을 지운다', async () => {
    const { service, calls } = setup();
    await service.remove('u-1');
    expect(calls).toEqual(['update', 'delete avatars/u-1/old.webp']);
  });

  it('사진이 없으면 지울 파일도 없다 - 그래도 성공이다', async () => {
    const { service, storage, prisma } = setup();
    prisma.user.findUnique.mockResolvedValue({ id: 'u-1', avatarKey: null });
    await expect(service.remove('u-1')).resolves.toBeDefined();
    expect(storage.delete).not.toHaveBeenCalled();
  });
});
