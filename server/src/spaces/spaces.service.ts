import {
  BadRequestException,
  ConflictException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { randomBytes } from 'crypto';
import { Prisma, Space, SpaceMember, SpaceRole } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { RealtimeEmitter } from '../realtime/realtime-emitter';
import { room } from '../realtime/rooms';
import { channelAccess } from '../channels/channel-access';
import { CreateSpaceDto } from './dto/create-space.dto';
import { slugify, withRandomSuffix } from '../common/slug';
import { UpdateSpaceDto } from './dto/update-space.dto';
import { CreateInviteDto } from './dto/create-invite.dto';
import { outranks } from './space-role';
import { isInviteUsable } from './invite-usable';

/** 새 스페이스에 기본으로 만들어 두는 채널. 빈 화면으로 시작하지 않게 한다. */
const DEFAULT_CATEGORY = '일반';
const DEFAULT_CHANNELS = [
  { key: 'general', name: '일반', topic: '아무 이야기나' },
  { key: 'dev', name: '개발', topic: '커밋 · PR · 이슈가 흘러 들어오는 곳' },
];

const memberWithUser = {
  user: {
    select: { id: true, email: true, name: true, avatarUrl: true, globalStatus: true },
  },
} satisfies Prisma.SpaceMemberInclude;

export type SpaceMemberWithUser = Prisma.SpaceMemberGetPayload<{
  include: typeof memberWithUser;
}>;

@Injectable()
export class SpacesService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly realtime: RealtimeEmitter,
  ) {}

  /** GET /api/spaces — 내가 속한 스페이스만. */
  async listForUser(userId: string): Promise<(Space & { role: SpaceRole })[]> {
    const memberships = await this.prisma.spaceMember.findMany({
      where: { userId },
      include: { space: true },
      orderBy: { joinedAt: 'asc' },
    });

    return memberships.map((m) => ({ ...m.space, role: m.role }));
  }

  /**
   * POST /api/spaces — 스페이스 생성.
   *
   * 생성자는 owner 가 되고, 기본 카테고리·채널이 함께 만들어진다.
   * 전부 한 트랜잭션이다 — 멤버 없는 스페이스나 채널 없는 스페이스가 남으면 안 된다.
   */
  async create(userId: string, dto: CreateSpaceDto): Promise<Space> {
    let slug = dto.slug ?? slugify(dto.name, 'space');

    const taken = await this.prisma.space.findUnique({ where: { slug } });
    if (taken) {
      // 직접 고른 slug 만 거절한다. 이름에서 만든 것은 사용자가 고른 적이 없다 —
      // slug 는 전역 유일이라, 남이 「Dev」를 먼저 만들었다고 내 「Dev」가 막히면
      // 안 된다(16단계 — 앱이 이름만 받는 만들기 화면을 갖게 됐다).
      if (dto.slug) {
        throw new ConflictException('이미 사용 중인 slug 입니다');
      }
      slug = withRandomSuffix(slug);
    }

    return this.prisma.$transaction(async (tx) => {
      const space = await tx.space.create({
        data: {
          slug,
          name: dto.name.trim(),
          ownerId: userId,
          members: {
            create: { userId, role: SpaceRole.owner },
          },
          categories: {
            create: { name: DEFAULT_CATEGORY, position: 0 },
          },
        },
        include: { categories: true },
      });

      const categoryId = space.categories[0]?.id;

      await tx.channel.createMany({
        data: DEFAULT_CHANNELS.map((c, i) => ({
          spaceId: space.id,
          categoryId,
          key: c.key,
          name: c.name,
          topic: c.topic,
          position: i,
        })),
      });

      // 생성자를 기본 채널의 멤버로 넣어 둔다.
      const channels = await tx.channel.findMany({
        where: { spaceId: space.id },
        select: { id: true },
      });
      await tx.channelMember.createMany({
        data: channels.map((ch) => ({ channelId: ch.id, userId })),
      });

      const { categories: _categories, ...plain } = space;
      return plain;
    });
  }

  /** GET /api/spaces/:spaceId — SpaceGuard 가 이미 멤버십을 확인했다. */
  async findOne(spaceId: string): Promise<Space> {
    const space = await this.prisma.space.findUnique({ where: { id: spaceId } });
    if (!space) {
      throw new NotFoundException('스페이스를 찾을 수 없습니다');
    }
    return space;
  }

  /**
   * PATCH /api/spaces/:spaceId (admin+)
   *
   * 바뀌면 스페이스 룸에 `space:updated` 를 보낸다(16단계 설계 D34) — 이름 · 스프린트
   * 스위치는 모두에게 같은 값이라 브로드캐스트해도 된다(§3-6). 받은 앱은 목록을 다시 받는다.
   */
  async update(spaceId: string, dto: UpdateSpaceDto): Promise<Space> {
    const updated = await this.prisma.space.update({
      where: { id: spaceId },
      data: {
        ...(dto.name !== undefined ? { name: dto.name.trim() } : {}),
        ...(dto.iconUrl !== undefined ? { iconUrl: dto.iconUrl } : {}),
        ...(dto.sprintsEnabled !== undefined ? { sprintsEnabled: dto.sprintsEnabled } : {}),
      },
    });
    this.realtime.toSpace(spaceId, 'space:updated', { spaceId });
    return updated;
  }

  /** GET /api/spaces/:spaceId/members */
  listMembers(spaceId: string): Promise<SpaceMemberWithUser[]> {
    return this.prisma.spaceMember.findMany({
      where: { spaceId },
      include: memberWithUser,
      orderBy: { joinedAt: 'asc' },
    });
  }

  /**
   * PATCH /api/spaces/:spaceId/members/:userId — 역할 변경 (admin+).
   *
   * 세 가지를 막는다:
   *   1. 자기 역할을 스스로 바꾸는 것 (admin 이 owner 로 올라가는 경로)
   *   2. owner 의 역할 변경 (owner 는 스페이스당 1명, 이 엔드포인트로 바꾸지 않는다)
   *   3. 자기와 같거나 높은 역할을 가진 사람을 건드리는 것 (admin 이 admin 을 강등)
   */
  async updateMemberRole(
    spaceId: string,
    actor: SpaceMember,
    targetUserId: string,
    role: SpaceRole,
  ): Promise<SpaceMember> {
    if (actor.userId === targetUserId) {
      throw new ForbiddenException('자신의 역할은 변경할 수 없습니다');
    }

    const target = await this.requireMember(spaceId, targetUserId);

    if (target.role === SpaceRole.owner) {
      throw new ForbiddenException('owner 의 역할은 변경할 수 없습니다');
    }

    if (!outranks(actor.role, target.role)) {
      throw new ForbiddenException(
        '자신과 같거나 높은 역할의 멤버는 변경할 수 없습니다',
      );
    }

    const updated = await this.prisma.spaceMember.update({
      where: { spaceId_userId: { spaceId, userId: targetUserId } },
      data: { role },
    });

    // 역할은 JWT 에도 소켓에도 담지 않으므로 토큰을 다시 발급할 필요는 없다.
    // 다만 역할에 걸린 ChannelPermission 때문에 볼 수 있는 채널이 달라질 수
    // 있어, 그 사용자에게만 룸 재계산을 요청한다.
    // 새 역할로 볼 수 없게 된 채널 룸에서는 **서버가 직접** 뺀다(D13a · D25 와 같은 구멍 —
    // 16단계 리뷰). 역할로 가린 공개 채널이 있을 때 강등되면 생긴다.
    await this.evictHiddenChannels({ ...target, role });
    this.realtime.toUser(targetUserId, 'rooms:invalidate', { reason: 'member.role' });
    // 모두에게 같은 값이다(§3-6). 받은 앱은 멤버 목록을 다시 받는다.
    this.realtime.toSpace(spaceId, 'member:updated', { spaceId, userId: targetUserId, role });

    return updated;
  }

  /**
   * DELETE /api/spaces/:spaceId/members/:userId — 추방 (admin+).
   * owner 는 추방할 수 없다. 자기 자신도 이 경로로는 나갈 수 없다(탈퇴는 별도).
   */
  async removeMember(
    spaceId: string,
    actor: SpaceMember,
    targetUserId: string,
  ): Promise<void> {
    if (actor.userId === targetUserId) {
      throw new ForbiddenException('자기 자신은 이 경로로 제거할 수 없습니다');
    }

    const target = await this.requireMember(spaceId, targetUserId);

    if (target.role === SpaceRole.owner) {
      throw new ForbiddenException('owner 는 추방할 수 없습니다');
    }

    if (!outranks(actor.role, target.role)) {
      throw new ForbiddenException(
        '자신과 같거나 높은 역할의 멤버는 추방할 수 없습니다',
      );
    }

    await this.removeAndNotify(spaceId, targetUserId);
  }

  /**
   * POST /api/spaces/:spaceId/leave — 스스로 나간다(16단계 설계 D11).
   * owner 는 403 — 소유권 이전이 없어 나가면 주인 없는 스페이스가 된다.
   */
  async leave(member: SpaceMember): Promise<void> {
    if (member.role === SpaceRole.owner) {
      throw new ForbiddenException('owner 는 스페이스를 나갈 수 없습니다');
    }
    await this.removeAndNotify(member.spaceId, member.userId);
  }

  /**
   * 스페이스 멤버십과 그 스페이스의 채널 멤버십을 한 트랜잭션으로 지운다.
   * 채널 멤버십을 남기면 나간 사람이 읽음 마커 · 멘션 계산에 끼어든다.
   */
  private async dropMembership(spaceId: string, userId: string): Promise<void> {
    await this.prisma.$transaction([
      this.prisma.channelMember.deleteMany({
        where: { userId, channel: { spaceId } },
      }),
      this.prisma.spaceMember.delete({
        where: { spaceId_userId: { spaceId, userId } },
      }),
    ]);
  }

  /**
   * 멤버십을 지우고 실시간을 정리한다(설계 D12 · D13 · D13a).
   *
   * 채널 id 는 **지우기 전에** 읽어 두고, 지운 **바로 뒤에 룸에서 동기로 뺀다** — 응답과
   * 조회를 기다리는 사이에 그 스페이스로 나간 이벤트가 내보내진 소켓에 닿지 않게(16단계 리뷰).
   * 채널은 그 스페이스의 전부다 — 들어가 있지 않은 룸에서 빼는 것은 아무 일도 하지 않는다.
   */
  private async removeAndNotify(spaceId: string, userId: string): Promise<void> {
    const channels = await this.prisma.channel.findMany({
      where: { spaceId },
      select: { id: true },
    });
    await this.dropMembership(spaceId, userId);
    this.realtime.evict(userId, [room.space(spaceId), ...channels.map((c) => room.channel(c.id))]);
    this.realtime.toUser(userId, 'space:removed', { spaceId });
    this.realtime.toUser(userId, 'rooms:invalidate', { reason: 'member.left' });
    this.realtime.toSpace(spaceId, 'member:left', { spaceId, userId });
  }

  /**
   * 그 멤버가 (지금 역할로) 볼 수 없는 채널의 룸에서 서버가 직접 뺀다. 판정은 `channelAccess()`
   * 한 곳이다 — ChannelsService 는 SpacesModule 을 가져다 쓰는 쪽이라 여기서 주입하면 모듈이
   * 순환한다. 같은 순수 함수에 같은 세 가지(비공개 · 명단 · 역할 행)를 넣는다.
   */
  private async evictHiddenChannels(member: SpaceMember): Promise<void> {
    const [channels, memberships, perms] = await Promise.all([
      this.prisma.channel.findMany({
        where: { spaceId: member.spaceId },
        select: { id: true, isPrivate: true },
      }),
      this.prisma.channelMember.findMany({
        where: { userId: member.userId, channel: { spaceId: member.spaceId } },
        select: { channelId: true },
      }),
      this.prisma.channelPermission.findMany({
        where: { role: member.role, channel: { spaceId: member.spaceId } },
        select: { channelId: true, canView: true, canSend: true },
      }),
    ]);
    const joined = new Set(memberships.map((m) => m.channelId));
    const permOf = new Map(perms.map((p) => [p.channelId, p]));
    const hidden = channels.filter(
      (c) =>
        !channelAccess({
          isPrivate: c.isPrivate,
          isMember: joined.has(c.id),
          perm: permOf.get(c.id) ?? null,
        }).view,
    );
    this.realtime.evict(member.userId, hidden.map((c) => room.channel(c.id)));
  }

  /** POST /api/spaces/:spaceId/invites (admin+) */
  async createInvite(spaceId: string, createdById: string, dto: CreateInviteDto) {
    return this.prisma.invite.create({
      data: {
        spaceId,
        createdById,
        code: generateInviteCode(),
        role: dto.role ?? SpaceRole.member,
        expiresAt: dto.expiresInHours
          ? new Date(Date.now() + dto.expiresInHours * 60 * 60 * 1000)
          : null,
        maxUses: dto.maxUses ?? null,
      },
    });
  }

  /**
   * GET /api/spaces/:spaceId/invites (admin+) — **아직 쓸 수 있는 것만**(16단계 설계 D9).
   * 지난 행은 지우지 않는다 — 누가 언제 만들었는지는 남는다.
   */
  async listInvites(spaceId: string) {
    const invites = await this.prisma.invite.findMany({
      where: { spaceId },
      orderBy: { createdAt: 'desc' },
      include: { createdBy: { select: { id: true, name: true } } },
    });
    const now = new Date();
    return invites.filter((invite) => isInviteUsable(invite, now));
  }

  /**
   * DELETE /api/spaces/:spaceId/invites/:inviteId (admin+) — 행을 지운다(설계 D8).
   * 초대는 사용자가 쓴 글이 아니다. 다른 스페이스의 id 는 404.
   */
  async revokeInvite(spaceId: string, inviteId: string): Promise<void> {
    const { count } = await this.prisma.invite.deleteMany({
      where: { id: inviteId, spaceId },
    });
    if (count === 0) {
      throw new NotFoundException('초대를 찾을 수 없습니다');
    }
  }

  /**
   * POST /api/invites/:code/accept — 스페이스 밖에서 호출된다(SpaceGuard 없음).
   *
   * 사용 횟수 증가와 멤버 생성을 한 트랜잭션에서 처리하고, 증가 조건에
   * use_count 를 포함시켜 동시 요청이 max_uses 를 넘기지 못하게 한다.
   */
  async acceptInvite(userId: string, code: string): Promise<Space> {
    const invite = await this.prisma.invite.findUnique({
      where: { code },
      include: { space: true },
    });

    if (!invite) {
      throw new NotFoundException('초대 코드를 찾을 수 없습니다');
    }

    if (invite.expiresAt && invite.expiresAt.getTime() <= Date.now()) {
      throw new BadRequestException('만료된 초대 코드입니다');
    }

    const existing = await this.prisma.spaceMember.findUnique({
      where: { spaceId_userId: { spaceId: invite.spaceId, userId } },
    });
    if (existing) {
      // 이미 멤버면 사용 횟수를 소모시키지 않고 그냥 스페이스를 돌려준다.
      return invite.space;
    }

    await this.prisma.$transaction(async (tx) => {
      if (invite.maxUses !== null) {
        // 조건부 갱신 — 동시에 들어와도 한도를 넘지 않는다.
        const claimed = await tx.invite.updateMany({
          where: { id: invite.id, useCount: { lt: invite.maxUses } },
          data: { useCount: { increment: 1 } },
        });
        if (claimed.count === 0) {
          throw new BadRequestException('초대 코드의 사용 한도를 초과했습니다');
        }
      } else {
        await tx.invite.update({
          where: { id: invite.id },
          data: { useCount: { increment: 1 } },
        });
      }

      await tx.spaceMember.create({
        data: { spaceId: invite.spaceId, userId, role: invite.role },
      });
    });

    // 새 스페이스 룸에 붙어야 실시간이 온다. 기존 멤버의 멘션 자동완성에는 바로 떠야 한다.
    this.realtime.toUser(userId, 'rooms:invalidate', { reason: 'member.joined' });
    this.realtime.toSpace(invite.spaceId, 'member:joined', { spaceId: invite.spaceId, userId });

    return invite.space;
  }

  private async requireMember(
    spaceId: string,
    userId: string,
  ): Promise<SpaceMember> {
    const member = await this.prisma.spaceMember.findUnique({
      where: { spaceId_userId: { spaceId, userId } },
    });
    if (!member) {
      throw new NotFoundException('멤버를 찾을 수 없습니다');
    }
    return member;
  }
}

/** 초대 코드. 헷갈리는 글자(0/O, 1/l/I)를 뺀 알파벳을 쓴다. */
function generateInviteCode(): string {
  const alphabet = 'abcdefghjkmnpqrstuvwxyz23456789';
  const bytes = randomBytes(12);
  let code = '';
  for (const byte of bytes) {
    code += alphabet[byte % alphabet.length];
  }
  return code;
}
