import { ForbiddenException, NotFoundException } from '@nestjs/common';
import { SpaceMember, SpaceRole } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { RealtimeEmitter } from '../realtime/realtime-emitter';
import { ChannelsService } from './channels.service';

/**
 * 채널 가시성 규칙 (docs/백엔드-설계.md §6).
 *
 * | 채널 | 볼 수 있는 사람 |
 * |---|---|
 * | 공개   | 스페이스 멤버 전원 (역할별 can_view=false 로 예외 차단) |
 * | 비공개 | channel_members 에 있는 사람만 |
 *
 * 이 규칙이 뚫리면 **비공개 채널의 메시지가 새는** 종류의 버그가 된다.
 * 실서버 검증(`check:realtime`)에도 케이스가 있지만, 분기가 네 갈래라
 * 단위로 못 박아 둔다.
 */
type Channel = { id: string; isPrivate: boolean } | null;
type Permission = { canView: boolean; canSend: boolean } | null;

function serviceWith(options: {
  channel: Channel;
  isChannelMember?: boolean;
  permission?: Permission;
}) {
  const prisma = {
    channel: { findFirst: jest.fn().mockResolvedValue(options.channel) },
    channelMember: {
      findUnique: jest
        .fn()
        .mockResolvedValue(options.isChannelMember ? { userId: 'user-1' } : null),
    },
    channelPermission: {
      findUnique: jest.fn().mockResolvedValue(options.permission ?? null),
    },
  } as unknown as PrismaService;

  const realtime = {
    toSpace: jest.fn(),
    toUser: jest.fn(),
    toChannel: jest.fn(),
  } as unknown as RealtimeEmitter;

  return new ChannelsService(prisma, realtime);
}

const member: SpaceMember = {
  spaceId: 'space-a',
  userId: 'user-1',
  role: SpaceRole.member,
  nickname: null,
  joinedAt: new Date(),
};

const publicChannel = { id: 'ch-1', isPrivate: false };
const privateChannel = { id: 'ch-2', isPrivate: true };

describe('채널 가시성', () => {
  it('공개 채널은 채널 멤버가 아니어도 볼 수 있다', async () => {
    const service = serviceWith({ channel: publicChannel });
    await expect(service.canView('ch-1', member)).resolves.toBe(true);
  });

  it('★ 비공개 채널은 채널 멤버가 아니면 볼 수 없다', async () => {
    const service = serviceWith({ channel: privateChannel, isChannelMember: false });
    await expect(service.canView('ch-2', member)).resolves.toBe(false);
  });

  it('비공개 채널이라도 채널 멤버면 볼 수 있다', async () => {
    const service = serviceWith({ channel: privateChannel, isChannelMember: true });
    await expect(service.canView('ch-2', member)).resolves.toBe(true);
  });

  it('★ 다른 스페이스의 채널 id 는 보이지 않는다', async () => {
    // findFirst 에 spaceId 조건이 걸려 있어 null 이 돌아온다.
    const service = serviceWith({ channel: null });
    await expect(service.canView('ch-other', member)).resolves.toBe(false);
  });

  it('역할에 can_view=false 예외가 걸리면 공개 채널도 가린다', async () => {
    const service = serviceWith({
      channel: publicChannel,
      permission: { canView: false, canSend: false },
    });
    await expect(service.canView('ch-1', member)).resolves.toBe(false);
  });

  it('권한 행이 없으면 공개 채널은 기본 허용이다 — 새 채널이 아무에게도 안 보이면 안 된다', async () => {
    const service = serviceWith({ channel: publicChannel, permission: null });
    await expect(service.canView('ch-1', member)).resolves.toBe(true);
  });
});

describe('전송 권한', () => {
  it('볼 수 있으면 기본적으로 보낼 수 있다', async () => {
    const service = serviceWith({ channel: publicChannel });
    await expect(service.canSend('ch-1', member)).resolves.toBe(true);
  });

  it('★ 읽기 전용(can_send=false) 예외를 지킨다', async () => {
    const service = serviceWith({
      channel: publicChannel,
      permission: { canView: true, canSend: false },
    });
    await expect(service.canSend('ch-1', member)).resolves.toBe(false);
  });

  it('볼 수 없으면 보낼 수도 없다', async () => {
    const service = serviceWith({ channel: privateChannel, isChannelMember: false });
    await expect(service.canSend('ch-2', member)).resolves.toBe(false);
  });
});

describe('오류 코드 — 존재를 흘리지 않는다', () => {
  it('★ 볼 수 없는 채널은 403 이 아니라 404', async () => {
    const service = serviceWith({ channel: privateChannel, isChannelMember: false });
    await expect(service.assertCanView('ch-2', member)).rejects.toBeInstanceOf(
      NotFoundException,
    );
  });

  it('볼 수는 있는데 보낼 수 없으면 403 — 이미 존재를 아는 상태다', async () => {
    const service = serviceWith({
      channel: publicChannel,
      permission: { canView: true, canSend: false },
    });
    await expect(service.assertCanSend('ch-1', member)).rejects.toBeInstanceOf(
      ForbiddenException,
    );
  });
});
