import { BadRequestException, Injectable } from '@nestjs/common';
import { SpaceMember, SpaceRole } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { RealtimeEmitter } from '../realtime/realtime-emitter';
import { room } from '../realtime/rooms';
import { ChannelsService } from '../channels/channels.service';
import { SetPermissionDto } from './dto/set-permission.dto';

/** 권한 행을 둘 수 있는 역할(16단계 설계 D21). admin · owner 는 늘 기본값(전부 허용)이다. */
export const OVERRIDABLE_ROLES = [SpaceRole.guest, SpaceRole.member] as const;
type OverridableRole = (typeof OVERRIDABLE_ROLES)[number];

export interface RolePermission {
  role: OverridableRole;
  canView: boolean;
  canSend: boolean;
  /** 행이 있는가. 없으면 기본값이다. */
  explicit: boolean;
}

/**
 * 채널별 권한 행(`channel_permissions`)을 읽고 쓴다(16단계 — `permissions` 재작성).
 *
 * **판정은 여기서 하지 않는다** — `ChannelsService`(→ `channelAccess()`) 한 곳이다. 이 서비스는
 * 행을 고치고, 바뀐 결과가 소켓 룸에 곧바로 반영되게 할 뿐이다.
 */
@Injectable()
export class PermissionsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly channels: ChannelsService,
    private readonly realtime: RealtimeEmitter,
  ) {}

  /** guest · member 두 줄을 늘 돌려준다. 행이 없는 역할은 기본값(보기 · 보내기). */
  async list(channelId: string, member: SpaceMember): Promise<RolePermission[]> {
    await this.channels.assertStructural(channelId, member);
    const rows = await this.prisma.channelPermission.findMany({ where: { channelId } });
    return OVERRIDABLE_ROLES.map((role) => {
      const row = rows.find((r) => r.role === role);
      return {
        role,
        canView: row?.canView ?? true,
        canSend: row?.canSend ?? true,
        explicit: row !== undefined,
      };
    });
  }

  async set(
    channelId: string,
    member: SpaceMember,
    role: string,
    dto: SetPermissionDto,
  ): Promise<RolePermission[]> {
    const target = this.requireRole(role);
    const channel = await this.channels.assertStructural(channelId, member);
    if (channel.isPrivate && !dto.canView) {
      // 비공개 채널은 명단이 정한다(D22). 둘이 겹치면 「명단에 있는데 안 보임」이 생긴다.
      throw new BadRequestException(
        '비공개 채널은 역할로 가릴 수 없습니다 — 멤버에서 빼세요',
      );
    }

    await this.prisma.channelPermission.upsert({
      where: { channelId_role: { channelId, role: target } },
      update: { canView: dto.canView, canSend: dto.canSend },
      create: { channelId, role: target, canView: dto.canView, canSend: dto.canSend },
    });

    if (!dto.canView) await this.evictRole(member.spaceId, channelId, target);
    this.realtime.toSpace(member.spaceId, 'rooms:invalidate', {
      reason: 'channel.permissions',
    });
    return this.list(channelId, member);
  }

  /** 기본값으로 — 행을 지운다. 예외로만 쓰는 행이 남지 않는다(D24). */
  async reset(channelId: string, member: SpaceMember, role: string): Promise<void> {
    const target = this.requireRole(role);
    await this.channels.assertStructural(channelId, member);
    await this.prisma.channelPermission.deleteMany({
      where: { channelId, role: target },
    });
    this.realtime.toSpace(member.spaceId, 'rooms:invalidate', {
      reason: 'channel.permissions',
    });
  }

  private requireRole(role: string): OverridableRole {
    const found = OVERRIDABLE_ROLES.find((r) => r === role);
    if (!found) {
      throw new BadRequestException('권한을 둘 수 있는 역할은 guest · member 입니다');
    }
    return found;
  }

  /**
   * 그 역할의 스페이스 멤버를 채널 룸에서 **서버가 직접** 뺀다(16단계 설계 D25 · D13a).
   * `rooms:invalidate` 만 보내면 고친 클라이언트는 계속 듣는다.
   */
  private async evictRole(
    spaceId: string,
    channelId: string,
    role: SpaceRole,
  ): Promise<void> {
    const members = await this.prisma.spaceMember.findMany({
      where: { spaceId, role },
      select: { userId: true },
    });
    for (const m of members) this.realtime.evict(m.userId, [room.channel(channelId)]);
  }
}
