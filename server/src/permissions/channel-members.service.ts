import {
  BadRequestException,
  ConflictException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { SpaceMember, SpaceRole } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { RealtimeEmitter } from '../realtime/realtime-emitter';
import { room } from '../realtime/rooms';
import { ChannelsService } from '../channels/channels.service';
import { hasAtLeast } from '../spaces/space-role';

export interface ChannelMemberView {
  userId: string;
  name: string;
  avatarUrl: string | null;
  role: SpaceRole;
}

/**
 * 비공개 채널의 명단(16단계 설계 D17~D20).
 *
 * 공개 채널의 `channel_members` 는 읽음 · 음소거를 담는 행이지 출입 명단이 아니다 —
 * 그래서 여기 경로는 전부 **비공개 채널에만** 뜻이 있고 공개 채널은 400 이다(D19).
 */
@Injectable()
export class ChannelMembersService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly channels: ChannelsService,
    private readonly realtime: RealtimeEmitter,
  ) {}

  async list(channelId: string, member: SpaceMember): Promise<ChannelMemberView[]> {
    await this.requirePrivate(channelId, member);
    const rows = await this.prisma.channelMember.findMany({
      where: { channelId },
      orderBy: { createdAt: 'asc' },
      include: { user: { select: { id: true, name: true, avatarUrl: true } } },
    });
    const roles = await this.prisma.spaceMember.findMany({
      where: { spaceId: member.spaceId, userId: { in: rows.map((r) => r.userId) } },
      select: { userId: true, role: true },
    });
    const roleOf = new Map(roles.map((r) => [r.userId, r.role]));
    const views: ChannelMemberView[] = [];
    for (const r of rows) {
      const role = roleOf.get(r.userId);
      // 스페이스를 떠난 사람의 행은 16-1 이 지운다. 그래도 남아 있으면 보이지 않는다.
      if (!role) continue;
      views.push({ userId: r.userId, name: r.user.name, avatarUrl: r.user.avatarUrl, role });
    }
    return views;
  }

  /**
   * 들인다 — 이미 그 채널을 볼 수 있는(= 명단에 있는) **member 이상**(D17). 멱등.
   * 스페이스 멤버가 아닌 id 가 하나라도 있으면 404 로 아무도 넣지 않는다(§3-4).
   */
  async add(
    channelId: string,
    member: SpaceMember,
    userIds: string[],
  ): Promise<ChannelMemberView[]> {
    await this.requirePrivate(channelId, member);
    if (!hasAtLeast(member.role, SpaceRole.member)) {
      throw new ForbiddenException('손님은 채널에 사람을 들일 수 없습니다');
    }

    const unique = [...new Set(userIds)];
    const found = await this.prisma.spaceMember.count({
      where: { spaceId: member.spaceId, userId: { in: unique } },
    });
    if (found !== unique.length) {
      throw new NotFoundException('스페이스 멤버가 아닌 사람이 있습니다');
    }

    await this.prisma.channelMember.createMany({
      data: unique.map((userId) => ({ channelId, userId })),
      skipDuplicates: true,
    });
    // 볼 수 있는 채널이 늘었다 — 들어온 사람만 다시 계산하면 된다(D20).
    for (const userId of unique) {
      this.realtime.toUser(userId, 'rooms:invalidate', { reason: 'channel.members' });
    }
    return this.list(channelId, member);
  }

  /**
   * 뺀다 — 본인이면 누구나(나가기), 남이면 admin+(D18). **마지막 한 명은 나갈 수 없다(409)** —
   * 비공개 채널은 admin 도 명단에 있어야 본다. 아무도 없으면 영영 열 수 없다.
   */
  async remove(channelId: string, member: SpaceMember, targetUserId: string): Promise<void> {
    await this.requirePrivate(channelId, member);
    const self = targetUserId === member.userId;
    if (!self && !hasAtLeast(member.role, SpaceRole.admin)) {
      throw new ForbiddenException('다른 사람을 빼려면 관리자여야 합니다');
    }

    // 세기와 지우기를 **한 트랜잭션에서 채널 행을 잠근 채** 한다 — 둘만 남은 채널에서 둘이
    // 동시에 나가면 둘 다 「2명」을 보고 통과해 아무도 없는 채널이 됐다(16단계 리뷰).
    await this.prisma.$transaction(async (tx) => {
      await tx.$queryRaw`SELECT id FROM channels WHERE id = ${channelId} FOR UPDATE`;
      const row = await tx.channelMember.findUnique({
        where: { channelId_userId: { channelId, userId: targetUserId } },
      });
      if (!row) throw new NotFoundException('채널 멤버가 아닙니다');

      const count = await tx.channelMember.count({ where: { channelId } });
      if (count <= 1) {
        throw new ConflictException('마지막 멤버는 나갈 수 없습니다');
      }

      await tx.channelMember.delete({
        where: { channelId_userId: { channelId, userId: targetUserId } },
      });
    });
    // 룸에서 먼저 뺀다(D13a) — 그다음 앱에게 다시 계산하라고 알린다.
    this.realtime.evict(targetUserId, [room.channel(channelId)]);
    this.realtime.toUser(targetUserId, 'rooms:invalidate', { reason: 'channel.members' });
  }

  private async requirePrivate(channelId: string, member: SpaceMember) {
    const channel = await this.channels.assertStructural(channelId, member);
    if (!channel.isPrivate) {
      throw new BadRequestException('공개 채널에는 명단이 없습니다');
    }
    return channel;
  }
}
