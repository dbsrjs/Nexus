import { Injectable, NotFoundException } from '@nestjs/common';
import { ChannelPermission, Role } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';

/**
 * Central policy for channel-level access control. Used by ChannelPermissionGuard
 * and by feature modules (channels/messages) that need to filter by view/send.
 *
 * Resolution rules:
 *  - If a ChannelPermission row exists for (channelId, role), use its can_view/can_send.
 *  - If no row exists, fall back to permissive defaults (view=true) but respect
 *    the channel's is_readonly_default for sending.
 */
@Injectable()
export class PermissionsService {
  constructor(private prisma: PrismaService) {}

  async getPermission(
    channelId: string,
    role: Role,
  ): Promise<ChannelPermission | null> {
    return this.prisma.channelPermission.findUnique({
      where: { channelId_role: { channelId, role } },
    });
  }

  async canView(channelId: string, role: Role): Promise<boolean> {
    const perm = await this.getPermission(channelId, role);
    if (perm) {
      return perm.canView;
    }
    // No explicit row: default to viewable.
    return true;
  }

  async canSend(channelId: string, role: Role): Promise<boolean> {
    const perm = await this.getPermission(channelId, role);
    if (perm) {
      return perm.canSend;
    }
    // No explicit row: sending follows the channel's readonly default.
    const channel = await this.prisma.channel.findUnique({
      where: { id: channelId },
      select: { isReadonlyDefault: true },
    });
    if (!channel) {
      throw new NotFoundException('Channel not found');
    }
    return !channel.isReadonlyDefault;
  }

  /**
   * Admin matrix: full role×channel permission grid.
   * Returns one entry per channel with a per-role breakdown, materializing
   * defaults for roles that have no explicit row.
   */
  async getMatrix() {
    const roles: Role[] = [Role.admin, Role.lead, Role.member, Role.guest];

    const channels = await this.prisma.channel.findMany({
      orderBy: { name: 'asc' },
      include: { permissions: true },
    });

    return channels.map((channel) => ({
      channelId: channel.id,
      key: channel.key,
      name: channel.name,
      kind: channel.kind,
      isReadonlyDefault: channel.isReadonlyDefault,
      roles: roles.map((role) => {
        const perm = channel.permissions.find((p) => p.role === role);
        return {
          role,
          canView: perm ? perm.canView : true,
          canSend: perm ? perm.canSend : !channel.isReadonlyDefault,
          explicit: Boolean(perm),
        };
      }),
    }));
  }

  /**
   * Upsert a single (channel, role) permission cell. Admin-only (enforced at controller).
   */
  async setPermission(
    channelId: string,
    role: Role,
    canView: boolean,
    canSend: boolean,
  ): Promise<ChannelPermission> {
    const channel = await this.prisma.channel.findUnique({
      where: { id: channelId },
      select: { id: true },
    });
    if (!channel) {
      throw new NotFoundException('Channel not found');
    }

    return this.prisma.channelPermission.upsert({
      where: { channelId_role: { channelId, role } },
      create: { channelId, role, canView, canSend },
      update: { canView, canSend },
    });
  }
}
