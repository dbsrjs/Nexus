import {
  ConflictException,
  ForbiddenException,
  Inject,
  Injectable,
  NotFoundException,
  forwardRef,
} from '@nestjs/common';
import { Channel, Prisma, SpaceMember } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { RealtimeEmitter } from '../realtime/realtime-emitter';
import { slugify } from '../common/slug';
import { CreateChannelDto } from './dto/create-channel.dto';
import { UpdateChannelDto } from './dto/update-channel.dto';
import { MarkReadDto } from './dto/mark-read.dto';
import { MentionsService } from '../messages/mentions.service';

/** 채널 목록 한 줄. 사이드바가 필요로 하는 것만 담는다. */
export interface ChannelListItem extends Channel {
  lastReadAt: Date | null;
  lastReadMessageId: string | null;
  muted: boolean;
  unreadCount: number;
  /**
   * 안 읽은 **멘션** 수. 일반 안 읽은 수와 따로 센다 - 멘션은 "나를 불렀다"는
   * 뜻이라 무게가 다르고, 화면에서도 다른 색으로 표시한다.
   */
  mentionCount: number;
}

@Injectable()
export class ChannelsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly realtime: RealtimeEmitter,
    // MessagesModule 과는 이미 서로를 참조한다(모듈 주석 참고). 멘션 수는
    // 채널 목록의 일부라 여기서 붙이는 편이 자연스럽다.
    @Inject(forwardRef(() => MentionsService))
    private readonly mentions: MentionsService,
  ) {}

  // ──────────────────────────────────────────────
  // 가시성 규칙
  //
  // 이전 구현은 "채널 멤버이거나, 전역 역할에 canView 권한 행이 있으면" 이었다.
  // 권한 행이 없으면 아무도 못 보는 구조라, 새로 만든 채널이 아무에게도 보이지
  // 않는 상태가 기본값이었다.
  //
  // 새 규칙은 `is_private` 를 기준으로 삼는다:
  //   - 비공개 채널 → 채널 멤버만
  //   - 공개 채널   → 스페이스 멤버 전원. 단 그 역할에 대한 ChannelPermission
  //                   행이 canView=false 로 있으면 가린다 (명시적 차단)
  //
  // 전송(canSend)도 같은 방식이다. 권한 행이 있으면 그것이 우선이고,
  // 없으면 "볼 수 있으면 보낼 수 있다".
  // ──────────────────────────────────────────────

  async canView(channelId: string, member: SpaceMember): Promise<boolean> {
    const channel = await this.prisma.channel.findFirst({
      where: { id: channelId, spaceId: member.spaceId },
      select: { id: true, isPrivate: true },
    });
    if (!channel) return false;

    if (await this.isChannelMember(channelId, member.userId)) return true;
    if (channel.isPrivate) return false;

    const perm = await this.permissionFor(channelId, member);
    return perm?.canView ?? true;
  }

  async canSend(channelId: string, member: SpaceMember): Promise<boolean> {
    if (!(await this.canView(channelId, member))) return false;

    const perm = await this.permissionFor(channelId, member);
    return perm?.canSend ?? true;
  }

  /** 볼 수 없으면 404. 존재 여부 자체를 흘리지 않는다. */
  async assertCanView(channelId: string, member: SpaceMember): Promise<Channel> {
    const channel = await this.prisma.channel.findFirst({
      where: { id: channelId, spaceId: member.spaceId },
    });
    if (!channel || !(await this.canView(channelId, member))) {
      throw new NotFoundException('채널을 찾을 수 없습니다');
    }
    return channel;
  }

  /**
   * 보낼 수 없으면 403. 여기서는 채널의 존재를 이미 아는 상태이므로
   * (볼 수는 있으므로) 403이 맞다.
   */
  async assertCanSend(channelId: string, member: SpaceMember): Promise<Channel> {
    const channel = await this.assertCanView(channelId, member);
    if (!(await this.canSend(channelId, member))) {
      throw new ForbiddenException('이 채널에 메시지를 보낼 권한이 없습니다');
    }
    return channel;
  }

  // ──────────────────────────────────────────────
  // 조회
  // ──────────────────────────────────────────────

  /** 내가 볼 수 있는 채널 id 집합. 목록과 (4단계의) 소켓 룸 조인이 함께 쓴다. */
  async viewableChannelIds(member: SpaceMember): Promise<string[]> {
    const [channels, memberships, blocked] = await Promise.all([
      this.prisma.channel.findMany({
        where: { spaceId: member.spaceId },
        select: { id: true, isPrivate: true },
      }),
      this.prisma.channelMember.findMany({
        where: { userId: member.userId, channel: { spaceId: member.spaceId } },
        select: { channelId: true },
      }),
      this.prisma.channelPermission.findMany({
        where: {
          role: member.role,
          canView: false,
          channel: { spaceId: member.spaceId },
        },
        select: { channelId: true },
      }),
    ]);

    const joined = new Set(memberships.map((m) => m.channelId));
    const hidden = new Set(blocked.map((p) => p.channelId));

    return channels
      .filter((c) => joined.has(c.id) || (!c.isPrivate && !hidden.has(c.id)))
      .map((c) => c.id);
  }

  /** GET /api/spaces/:spaceId/channels — 사이드바용. 안 읽은 수를 함께 준다. */
  async listForMember(member: SpaceMember): Promise<ChannelListItem[]> {
    const ids = await this.viewableChannelIds(member);
    if (ids.length === 0) return [];

    const [channels, memberships, unread, mentions] = await Promise.all([
      this.prisma.channel.findMany({
        where: { id: { in: ids }, spaceId: member.spaceId },
        orderBy: [{ position: 'asc' }, { name: 'asc' }],
      }),
      this.prisma.channelMember.findMany({
        where: { userId: member.userId, channelId: { in: ids } },
      }),
      this.unreadCounts(member.userId, ids),
      this.mentions.unreadCounts(member, ids),
    ]);

    const membershipByChannel = new Map(memberships.map((m) => [m.channelId, m]));

    return channels.map((channel) => {
      const own = membershipByChannel.get(channel.id);
      return {
        ...channel,
        lastReadAt: own?.lastReadAt ?? null,
        lastReadMessageId: own?.lastReadMessageId ?? null,
        muted: own?.muted ?? false,
        unreadCount: unread.get(channel.id) ?? 0,
        mentionCount: mentions.get(channel.id) ?? 0,
      };
    });
  }

  /**
   * 채널별 안 읽은 메시지 수를 **한 번의 쿼리로** 센다.
   *
   * 채널마다 기준 시각(last_read_at)이 달라 groupBy 로는 표현되지 않는다.
   * 채널 수만큼 count 를 돌리면 사이드바를 그릴 때마다 N+1 이 되므로 raw 로 간다.
   * 내가 쓴 메시지와 삭제된 메시지, 스레드 답글은 세지 않는다.
   */
  private async unreadCounts(
    userId: string,
    channelIds: string[],
  ): Promise<Map<string, number>> {
    // id 컬럼은 uuid 타입이 아니라 **text** 다. Prisma 가 `String @id @default(uuid())`
    // 를 text 로 만들기 때문이다. 파라미터를 ::uuid 로 캐스팅하면
    // `operator does not exist: text = uuid` 로 실패한다.
    const rows = await this.prisma.$queryRaw<
      { channel_id: string; unread: bigint }[]
    >`
      SELECT m.channel_id, COUNT(*) AS unread
      FROM messages m
      LEFT JOIN channel_members cm
        ON cm.channel_id = m.channel_id AND cm.user_id = ${userId}
      WHERE m.channel_id IN (${Prisma.join(channelIds)})
        AND m.deleted_at IS NULL
        AND m.parent_id IS NULL
        AND m.author_id <> ${userId}
        AND (cm.last_read_at IS NULL OR m.created_at > cm.last_read_at)
      GROUP BY m.channel_id
    `;

    return new Map(rows.map((r) => [r.channel_id, Number(r.unread)]));
  }

  // ──────────────────────────────────────────────
  // 변경
  // ──────────────────────────────────────────────

  /**
   * 채널을 만들고 **생성자를 채널 멤버로 함께 넣는다.**
   *
   * 이전에는 채널 행만 만들었다. 그러면 비공개 채널은 `canView` 가 channel_members
   * 를 요구하므로 **만든 사람조차 볼 수도 쓸 수도 없는** 상태가 됐다. join 으로
   * 들어갈 수도 없다 — join 이 assertCanView 를 먼저 거치기 때문이다.
   *
   * 공개 채널도 구분 없이 넣는다. `SpacesService.create()` 가 기본 채널에,
   * `prisma/seed.ts` 가 시드 채널에 이미 같은 일을 한다. `isPrivate` 일 때만 넣으면
   * 한 코드베이스에 규칙이 둘이 된다. 공개 채널의 멤버 행은 어차피 markRead 가
   * 만들므로 미리 있다고 달라지는 것이 없다.
   */
  async create(
    spaceId: string,
    member: SpaceMember,
    dto: CreateChannelDto,
  ): Promise<Channel> {
    const key = dto.key ?? slugify(dto.name, 'channel');

    const taken = await this.prisma.channel.findUnique({
      where: { spaceId_key: { spaceId, key } },
    });
    if (taken) {
      throw new ConflictException('이미 사용 중인 채널 key 입니다');
    }

    if (dto.categoryId) {
      await this.requireCategoryInSpace(spaceId, dto.categoryId);
    }

    const position = dto.position ?? (await this.nextPosition(spaceId));

    // 한 트랜잭션으로 묶는다. 채널만 만들어지고 멤버 행이 빠지면 그것이 바로
    // 위에서 설명한, 아무도 접근할 수 없는 채널이다.
    const channel = await this.prisma.$transaction(async (tx) => {
      const created = await tx.channel.create({
        data: {
          spaceId,
          key,
          name: dto.name.trim(),
          topic: dto.topic,
          categoryId: dto.categoryId ?? null,
          isPrivate: dto.isPrivate ?? false,
          position,
        },
      });

      await tx.channelMember.create({
        data: { channelId: created.id, userId: member.userId },
      });

      return created;
    });

    this.realtime.toSpace(spaceId, 'rooms:invalidate', { reason: 'channel.created' });
    return channel;
  }

  async update(
    spaceId: string,
    channelId: string,
    dto: UpdateChannelDto,
  ): Promise<Channel> {
    const before = await this.requireChannel(spaceId, channelId);

    if (dto.categoryId) {
      await this.requireCategoryInSpace(spaceId, dto.categoryId);
    }

    const updated = await this.prisma.channel.update({
      where: { id: channelId },
      data: {
        ...(dto.name !== undefined ? { name: dto.name.trim() } : {}),
        ...(dto.topic !== undefined ? { topic: dto.topic } : {}),
        ...(dto.categoryId !== undefined ? { categoryId: dto.categoryId } : {}),
        ...(dto.isPrivate !== undefined ? { isPrivate: dto.isPrivate } : {}),
        ...(dto.position !== undefined ? { position: dto.position } : {}),
      },
    });

    if (updated.isPrivate !== before.isPrivate) {
      this.realtime.toSpace(spaceId, 'rooms:invalidate', { reason: 'channel.visibility' });
    }
    return updated;
  }

  /**
   * POST /api/spaces/:spaceId/channels/:id/read
   *
   * 이전 구현은 소켓 `read` 이벤트를 다른 클라이언트로 중계만 하고 **DB에 저장하지
   * 않았다.** 그래서 앱을 다시 켜면 읽음이 초기화됐다 (docs/전환-계획.md §3.5-3).
   * 여기서 실제로 저장한다.
   *
   * 기준 시각은 클라이언트 시계가 아니라 **그 메시지의 created_at** 이다.
   * 기기 시계가 틀어져 있어도 읽음 위치가 어긋나지 않는다.
   */
  async markRead(channelId: string, member: SpaceMember, dto: MarkReadDto) {
    await this.assertCanView(channelId, member);

    const message = await this.prisma.message.findFirst({
      where: { id: dto.lastReadMessageId, channelId, spaceId: member.spaceId },
      select: { id: true, createdAt: true },
    });
    if (!message) {
      throw new NotFoundException('메시지를 찾을 수 없습니다');
    }

    const existing = await this.prisma.channelMember.findUnique({
      where: { channelId_userId: { channelId, userId: member.userId } },
    });

    // 뒤로 되돌리지 않는다. 여러 기기에서 읽음이 엇갈려 들어와도
    // 더 최근 위치가 유지된다.
    if (existing?.lastReadAt && existing.lastReadAt >= message.createdAt) {
      return existing;
    }

    const saved = await this.prisma.channelMember.upsert({
      where: { channelId_userId: { channelId, userId: member.userId } },
      update: { lastReadAt: message.createdAt, lastReadMessageId: message.id },
      create: {
        channelId,
        userId: member.userId,
        lastReadAt: message.createdAt,
        lastReadMessageId: message.id,
      },
    });

    // 개인 룸으로 쏜다. 같은 사용자의 다른 기기가 읽음 위치를 따라온다.
    // REST 와 소켓이 이 메서드를 함께 쓰므로 두 경로의 동작이 갈릴 수 없다.
    this.realtime.toUser(member.userId, 'read:synced', {
      spaceId: member.spaceId,
      channelId,
      lastReadMessageId: saved.lastReadMessageId,
      lastReadAt: saved.lastReadAt,
    });

    return saved;
  }

  /** 채널 참여 — 공개 채널에 스스로 들어간다. */
  async join(channelId: string, member: SpaceMember) {
    await this.assertCanView(channelId, member);
    const joined = await this.prisma.channelMember.upsert({
      where: { channelId_userId: { channelId, userId: member.userId } },
      update: {},
      create: { channelId, userId: member.userId },
    });

    // 본인에게만. 다른 사람의 룸 계산은 바뀌지 않았다.
    this.realtime.toUser(member.userId, 'rooms:invalidate', { reason: 'channel.joined' });
    return joined;
  }

  // ──────────────────────────────────────────────

  private async isChannelMember(channelId: string, userId: string): Promise<boolean> {
    const row = await this.prisma.channelMember.findUnique({
      where: { channelId_userId: { channelId, userId } },
      select: { userId: true },
    });
    return row !== null;
  }

  private permissionFor(channelId: string, member: SpaceMember) {
    return this.prisma.channelPermission.findUnique({
      where: { channelId_role: { channelId, role: member.role } },
      select: { canView: true, canSend: true },
    });
  }

  private async requireChannel(spaceId: string, channelId: string): Promise<Channel> {
    const channel = await this.prisma.channel.findFirst({
      where: { id: channelId, spaceId },
    });
    if (!channel) {
      throw new NotFoundException('채널을 찾을 수 없습니다');
    }
    return channel;
  }

  private async requireCategoryInSpace(spaceId: string, categoryId: string) {
    const category = await this.prisma.category.findFirst({
      where: { id: categoryId, spaceId },
      select: { id: true },
    });
    if (!category) {
      throw new NotFoundException('카테고리를 찾을 수 없습니다');
    }
  }

  private async nextPosition(spaceId: string): Promise<number> {
    const last = await this.prisma.channel.findFirst({
      where: { spaceId },
      orderBy: { position: 'desc' },
      select: { position: true },
    });
    return (last?.position ?? -1) + 1;
  }
}
