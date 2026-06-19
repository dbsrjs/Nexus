import { ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';
import { Role } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { PaginationDto } from '../common/dto/pagination.dto';

/**
 * Channel access + listing logic.
 *
 * Visibility rule (per 설계서 §4, §6): a user may view a channel/DM when either
 *  - they are a member of it, OR
 *  - a ChannelPermission row for their global role grants can_view.
 * DMs are membership-only (no role permission rows expected for DMs).
 */
@Injectable()
export class ChannelsService {
  constructor(private prisma: PrismaService) {}

  /**
   * Channel ids the user may VIEW. Used by the controller (list) and the
   * realtime gateway (which rooms to join on connect).
   */
  async viewableChannelIds(userId: string, role: Role): Promise<string[]> {
    const [memberships, permitted] = await Promise.all([
      this.prisma.channelMember.findMany({
        where: { userId },
        select: { channelId: true },
      }),
      this.prisma.channelPermission.findMany({
        where: { role, canView: true },
        select: { channelId: true },
      }),
    ]);

    const ids = new Set<string>();
    for (const m of memberships) ids.add(m.channelId);
    for (const p of permitted) ids.add(p.channelId);
    return [...ids];
  }

  /**
   * Channels/DMs the current user may view, with their own membership meta
   * (last_read_at) when present. Ordered: channels first, then DMs, by name.
   */
  async listForUser(userId: string, role: Role) {
    const ids = await this.viewableChannelIds(userId, role);

    return this.prisma.channel.findMany({
      where: { id: { in: ids } },
      orderBy: [{ kind: 'asc' }, { name: 'asc' }],
      include: {
        members: {
          where: { userId },
          select: { lastReadAt: true },
        },
      },
    });
  }

  /** Throws unless the user may view the channel. Returns the channel. */
  async assertCanView(channelId: string, userId: string, role: Role) {
    const channel = await this.prisma.channel.findUnique({ where: { id: channelId } });
    if (!channel) {
      throw new NotFoundException('채널을 찾을 수 없습니다.');
    }
    if (!(await this.canView(channelId, userId, role))) {
      throw new ForbiddenException('이 채널을 볼 권한이 없습니다.');
    }
    return channel;
  }

  /** Throws unless the user may send to the channel. */
  async assertCanSend(channelId: string, userId: string, role: Role): Promise<void> {
    const channel = await this.prisma.channel.findUnique({ where: { id: channelId } });
    if (!channel) {
      throw new NotFoundException('채널을 찾을 수 없습니다.');
    }
    if (!(await this.canView(channelId, userId, role))) {
      throw new ForbiddenException('이 채널을 볼 권한이 없습니다.');
    }
    if (!(await this.canSend(channelId, userId, role))) {
      throw new ForbiddenException('이 채널에 메시지를 보낼 권한이 없습니다.');
    }
  }

  private async isMember(channelId: string, userId: string): Promise<boolean> {
    const member = await this.prisma.channelMember.findUnique({
      where: { channelId_userId: { channelId, userId } },
      select: { userId: true },
    });
    return member !== null;
  }

  async canView(channelId: string, userId: string, role: Role): Promise<boolean> {
    if (await this.isMember(channelId, userId)) return true;
    const perm = await this.prisma.channelPermission.findUnique({
      where: { channelId_role: { channelId, role } },
      select: { canView: true },
    });
    return perm?.canView ?? false;
  }

  async canSend(channelId: string, userId: string, role: Role): Promise<boolean> {
    const perm = await this.prisma.channelPermission.findUnique({
      where: { channelId_role: { channelId, role } },
      select: { canSend: true, canView: true },
    });
    if (perm) {
      // An explicit role policy is authoritative for sending.
      return perm.canView && perm.canSend;
    }
    // No role policy (e.g. DMs): members may send, others may not.
    return this.isMember(channelId, userId);
  }

  /**
   * Cursor-paginated messages for a channel (newest first, id cursor).
   * Caller must have already passed assertCanView.
   */
  async listMessages(channelId: string, query: PaginationDto) {
    const limit = query.limit ?? 30;
    const items = await this.prisma.message.findMany({
      where: { channelId },
      orderBy: { createdAt: 'desc' },
      take: limit + 1,
      ...(query.cursor
        ? { cursor: { id: query.cursor }, skip: 1 }
        : {}),
      include: {
        author: {
          select: { id: true, name: true, initial: true, color: true },
        },
        // id/name/ext only — NOT sizeBytes (BigInt is not JSON-serializable).
        files: {
          select: { id: true, name: true, ext: true },
        },
      },
    });

    const hasMore = items.length > limit;
    const page = hasMore ? items.slice(0, limit) : items;
    return {
      items: page,
      nextCursor: hasMore ? page[page.length - 1].id : null,
    };
  }
}
