import {
  BadRequestException,
  ConflictException,
  ForbiddenException,
  Inject,
  Injectable,
  NotFoundException,
  forwardRef,
} from '@nestjs/common';
import { randomBytes } from 'crypto';
import { Channel, ChannelKind, Prisma, SpaceMember } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { RealtimeEmitter } from '../realtime/realtime-emitter';
import { room } from '../realtime/rooms';
import { slugify } from '../common/slug';
import { CreateChannelDto } from './dto/create-channel.dto';
import { UpdateChannelDto } from './dto/update-channel.dto';
import { MarkReadDto } from './dto/mark-read.dto';
import { MentionsService } from '../messages/mentions.service';
import { NotificationsService } from '../notifications/notifications.service';
import { channelAccess } from './channel-access';
import { dmKey, dmPeerOf } from './dm-key';

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
  /**
   * 내가 이 채널에 보낼 수 있는가(16단계 D26). 받는 사람마다 다르지만 목록은 원래 사람마다
   * 따로 받는다 — 브로드캐스트가 아니다. 앱은 거짓이면 입력창 대신 「읽기 전용」을 보인다.
   */
  canSend: boolean;
  /** DM 의 상대(17단계 D6). 일반 채널은 null. */
  dmUserId: string | null;
  /** 마지막 최상위 메시지 시각 — 사이드바가 DM 을 최근순으로 줄 세운다. 메시지가 없으면 null. */
  lastMessageAt: Date | null;
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
    // 읽음 위치가 움직이면 그 채널의 알림이 따라 읽힌다(18단계 N12). 알림은 가시성을 이쪽에
    // 묻으므로 서로를 참조한다.
    @Inject(forwardRef(() => NotificationsService))
    private readonly notifications: NotificationsService,
  ) {}

  // ──────────────────────────────────────────────
  // 가시성 규칙
  //
  // 이전 구현은 "채널 멤버이거나, 전역 역할에 canView 권한 행이 있으면" 이었다.
  // 권한 행이 없으면 아무도 못 보는 구조라, 새로 만든 채널이 아무에게도 보이지
  // 않는 상태가 기본값이었다.
  //
  // 새 규칙은 `is_private` 를 기준으로 삼는다 — 판정은 `channel-access.ts` 한 곳이다
  // (16단계 설계 §2). 공개 채널의 가림(canView=false)은 멤버 행보다 앞선다.
  // ──────────────────────────────────────────────

  async canView(channelId: string, member: SpaceMember): Promise<boolean> {
    return (await this.access(channelId, member))?.view ?? false;
  }

  async canSend(channelId: string, member: SpaceMember): Promise<boolean> {
    return (await this.access(channelId, member))?.send ?? false;
  }

  /** 채널 하나의 판정. 없는 채널 · 다른 스페이스의 채널이면 null. */
  private async access(channelId: string, member: SpaceMember) {
    const channel = await this.prisma.channel.findFirst({
      where: { id: channelId, spaceId: member.spaceId },
      select: { id: true, isPrivate: true, kind: true, key: true },
    });
    if (!channel) return null;

    const [isMember, perm, dmPeerPresent] = await Promise.all([
      this.isChannelMember(channelId, member.userId),
      this.permissionFor(channelId, member),
      channel.kind === ChannelKind.dm
        ? this.isDmPeerPresent(channel.key, member)
        : Promise.resolve(undefined),
    ]);
    return channelAccess({ isPrivate: channel.isPrivate, isMember, perm, dmPeerPresent });
  }

  /** DM 의 상대가 아직 이 스페이스 멤버인가(17단계 D8). */
  private async isDmPeerPresent(key: string, member: SpaceMember): Promise<boolean> {
    const peer = dmPeerOf(key, member.userId);
    if (!peer) return false;
    const row = await this.prisma.spaceMember.findUnique({
      where: { spaceId_userId: { spaceId: member.spaceId, userId: peer } },
      select: { userId: true },
    });
    return row !== null;
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
   * 채널 구조 API(설정 · 참여 · 명단 · 권한)가 쓴다 — **DM 은 없는 채널로 본다(404)**
   * (17단계 D7). 관리자도 남의 DM 이 있다는 것을 알 수 없어야 한다.
   */
  async assertStructural(channelId: string, member: SpaceMember): Promise<Channel> {
    const channel = await this.assertCanView(channelId, member);
    if (channel.kind === ChannelKind.dm) {
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

  /**
   * 이 채널을 **지금 볼 수 있는** 스페이스 멤버 id(18단계 설계 N3) — 알림을 받을 수 있는 사람.
   * 사람마다 `canView` 를 묻지 않고 쿼리 셋으로 낸다. 판정은 `channelAccess()` 한 곳이다.
   */
  async viewerIds(channelId: string, spaceId: string): Promise<Set<string>> {
    const channel = await this.prisma.channel.findFirst({
      where: { id: channelId, spaceId },
      select: { isPrivate: true },
    });
    if (!channel) return new Set();

    const [members, roster, perms] = await Promise.all([
      this.prisma.spaceMember.findMany({
        where: { spaceId },
        select: { userId: true, role: true },
      }),
      this.prisma.channelMember.findMany({
        where: { channelId },
        select: { userId: true },
      }),
      this.prisma.channelPermission.findMany({
        where: { channelId },
        select: { role: true, canView: true, canSend: true },
      }),
    ]);
    const joined = new Set(roster.map((r) => r.userId));
    const permByRole = new Map(perms.map((p) => [p.role, p]));

    return new Set(
      members
        .filter(
          (m) =>
            channelAccess({
              isPrivate: channel.isPrivate,
              isMember: joined.has(m.userId),
              perm: permByRole.get(m.role) ?? null,
            }).view,
        )
        .map((m) => m.userId),
    );
  }

  /** 내가 볼 수 있는 채널 id 집합. 목록과 (4단계의) 소켓 룸 조인이 함께 쓴다. */
  async viewableChannelIds(member: SpaceMember): Promise<string[]> {
    return [...(await this.accessMap(member)).entries()]
      .filter(([, a]) => a.view)
      .map(([id]) => id);
  }

  /**
   * 스페이스의 모든 채널에 대한 내 판정을 **쿼리 셋으로** 낸다(채널마다 묻지 않는다).
   * 판정 자체는 `channelAccess()` 한 곳이다.
   */
  private async accessMap(
    member: SpaceMember,
  ): Promise<Map<string, { view: boolean; send: boolean }>> {
    const [channels, memberships, perms] = await Promise.all([
      this.prisma.channel.findMany({
        where: { spaceId: member.spaceId },
        select: { id: true, isPrivate: true, kind: true, key: true },
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
    const permByChannel = new Map(perms.map((p) => [p.channelId, p]));

    // 내가 든 DM 의 상대가 아직 멤버인지 — 한 쿼리로 본다(17단계 D8).
    const peerOf = (c: { kind: ChannelKind; key: string }) =>
      c.kind === ChannelKind.dm ? dmPeerOf(c.key, member.userId) : null;
    const peers = channels
      .filter((c) => joined.has(c.id))
      .map(peerOf)
      .filter((id): id is string => id !== null);
    const present = new Set(
      peers.length === 0
        ? []
        : (
            await this.prisma.spaceMember.findMany({
              where: { spaceId: member.spaceId, userId: { in: peers } },
              select: { userId: true },
            })
          ).map((m) => m.userId),
    );

    return new Map(
      channels.map((c) => {
        const peer = peerOf(c);
        return [
          c.id,
          channelAccess({
            isPrivate: c.isPrivate,
            isMember: joined.has(c.id),
            perm: permByChannel.get(c.id) ?? null,
            dmPeerPresent:
              c.kind === ChannelKind.dm ? peer !== null && present.has(peer) : undefined,
          }),
        ];
      }),
    );
  }

  /** GET /api/spaces/:spaceId/channels — 사이드바용. 안 읽은 수를 함께 준다. */
  async listForMember(member: SpaceMember): Promise<ChannelListItem[]> {
    const access = await this.accessMap(member);
    const ids = [...access.entries()].filter(([, a]) => a.view).map(([id]) => id);
    if (ids.length === 0) return [];

    const [channels, memberships, unread, mentions, latest] = await Promise.all([
      this.prisma.channel.findMany({
        where: { id: { in: ids }, spaceId: member.spaceId },
        orderBy: [{ position: 'asc' }, { name: 'asc' }],
      }),
      this.prisma.channelMember.findMany({
        where: { userId: member.userId, channelId: { in: ids } },
      }),
      this.unreadCounts(member.userId, ids),
      this.mentions.unreadCounts(member, ids),
      this.prisma.message.groupBy({
        by: ['channelId'],
        where: { channelId: { in: ids }, parentId: null, deletedAt: null },
        _max: { createdAt: true },
      }),
    ]);
    const latestByChannel = new Map(latest.map((r) => [r.channelId, r._max.createdAt]));

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
        canSend: access.get(channel.id)?.send ?? false,
        dmUserId:
          channel.kind === ChannelKind.dm ? dmPeerOf(channel.key, member.userId) : null,
        lastMessageAt: latestByChannel.get(channel.id) ?? null,
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
    let key = dto.key ?? slugify(dto.name, 'channel');

    const taken = await this.prisma.channel.findUnique({
      where: { spaceId_key: { spaceId, key } },
    });
    if (taken) {
      // 직접 고른 key 만 거절한다. 앱은 이름만 받는다(16단계) — 「Dev」가 이미 있다고 두 번째
      // 「Dev」가 막히면 안 된다. 스페이스 slug 와 같은 규칙이다.
      if (dto.key) {
        throw new ConflictException('이미 사용 중인 채널 key 입니다');
      }
      key = `${key.slice(0, 31)}-${randomBytes(4).toString('hex')}`;
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
    // DM 은 채널 구조 API 에게 없는 채널이다(17단계 D7).
    if (before.kind === ChannelKind.dm) {
      throw new NotFoundException('채널을 찾을 수 없습니다');
    }

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
      if (updated.isPrivate) {
        // 공개 → 비공개 — 명단에 없는 스페이스 멤버를 그 채널 룸에서 **서버가 직접** 뺀다(D13a).
        const [members, roster] = await Promise.all([
          this.prisma.spaceMember.findMany({ where: { spaceId }, select: { userId: true } }),
          this.prisma.channelMember.findMany({ where: { channelId }, select: { userId: true } }),
        ]);
        const kept = new Set(roster.map((r) => r.userId));
        for (const m of members) {
          if (!kept.has(m.userId)) this.realtime.evict(m.userId, [room.channel(channelId)]);
        }
      }
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

    // 그 채널의 알림도 따라 읽힌다(18단계 N12) — DM 을 다 읽었는데 알림함에 「안 읽음」이
    // 남으면 거짓말이다. REST · 소켓이 모두 이 메서드를 지나므로 여기 한 곳에 둔다.
    if (saved.lastReadAt) {
      await this.notifications.markChannelReadThrough(member, channelId, saved.lastReadAt);
    }

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

  /**
   * 음소거를 켜고 끈다 (14단계 설계 D15~D17). **멱등이다.**
   *
   * 권한은 열람이다 — 남에게 번지지 않는 내 설정이다(CLAUDE.md §3-9). 공개 채널은
   * 읽음 마커를 남기기 전까지 `channel_members` 행이 없어 **upsert** 한다. 새로 만든
   * 행은 `last_read_at` 이 NULL 이라, 행이 없을 때와 안 읽은 수 · 멘션 집계가 같다
   * (둘 다 LEFT JOIN 에 `IS NULL` 로 센다).
   *
   * **`update` 에 읽음 위치를 넣지 않는다** — 음소거가 읽음 위치를 되돌리면 안 된다.
   *
   * 내 다른 기기에만 알린다. 받는 사람마다 다른 값이라 스페이스 룸에 싣지 않는다(§3-6).
   */
  async setMuted(channelId: string, member: SpaceMember, muted: boolean) {
    await this.assertCanView(channelId, member);
    await this.prisma.channelMember.upsert({
      where: { channelId_userId: { channelId, userId: member.userId } },
      update: { muted },
      create: { channelId, userId: member.userId, muted },
    });
    this.realtime.toUser(member.userId, 'channel:muted', {
      spaceId: member.spaceId,
      channelId,
      muted,
    });
    return { channelId, muted };
  }

  /** 채널 참여 — 공개 채널에 스스로 들어간다. */
  async join(channelId: string, member: SpaceMember) {
    await this.assertStructural(channelId, member);
    const joined = await this.prisma.channelMember.upsert({
      where: { channelId_userId: { channelId, userId: member.userId } },
      update: {},
      create: { channelId, userId: member.userId },
    });

    // 본인에게만. 다른 사람의 룸 계산은 바뀌지 않았다.
    this.realtime.toUser(member.userId, 'rooms:invalidate', { reason: 'channel.joined' });
    return joined;
  }

  /**
   * POST /api/spaces/:spaceId/dms — 그 사람과의 DM 을 연다(17단계 D3 · D4). 있으면 그것, 없으면
   * 만든다. **두 사람의 명단 행을 채운다** — 스페이스를 나갔다 돌아온 사람은 행이 지워져 있다.
   * 행이 새로 생긴 사람에게만 `rooms:invalidate` 를 보낸다.
   *
   * 같은 두 사람이 동시에 열면 key 유일성(D2)이 한쪽을 P2002 로 막는다 — 다시 읽는다.
   */
  async openDm(member: SpaceMember, peerId: string): Promise<ChannelListItem> {
    if (peerId === member.userId) {
      throw new BadRequestException('자기 자신과는 DM 을 열 수 없습니다');
    }
    const peer = await this.prisma.spaceMember.findUnique({
      where: { spaceId_userId: { spaceId: member.spaceId, userId: peerId } },
      select: { userId: true },
    });
    if (!peer) throw new NotFoundException('멤버를 찾을 수 없습니다');

    const where = { spaceId_key: { spaceId: member.spaceId, key: dmKey(member.userId, peerId) } };
    let channel = await this.prisma.channel.findUnique({ where });
    if (!channel) {
      try {
        channel = await this.prisma.channel.create({
          data: {
            spaceId: member.spaceId,
            key: where.spaceId_key.key,
            name: 'DM',
            kind: ChannelKind.dm,
            isPrivate: true,
          },
        });
      } catch (err) {
        if (!(err instanceof Prisma.PrismaClientKnownRequestError) || err.code !== 'P2002') {
          throw err;
        }
        channel = await this.prisma.channel.findUniqueOrThrow({ where });
      }
    }
    const channelId = channel.id;

    const existing = await this.prisma.channelMember.findMany({
      where: { channelId },
      select: { userId: true },
    });
    const had = new Set(existing.map((r) => r.userId));
    const added = [member.userId, peerId].filter((id) => !had.has(id));
    if (added.length > 0) {
      await this.prisma.channelMember.createMany({
        data: added.map((userId) => ({ channelId, userId })),
        skipDuplicates: true,
      });
      for (const userId of added) {
        this.realtime.toUser(userId, 'rooms:invalidate', { reason: 'dm.opened' });
      }
    }

    const item = (await this.listForMember(member)).find((c) => c.id === channelId);
    if (!item) throw new NotFoundException('채널을 찾을 수 없습니다');
    return item;
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
