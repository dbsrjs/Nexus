import { Inject, Injectable, NotFoundException, forwardRef } from '@nestjs/common';
import { Channel, ChannelKind, Notification, Prisma, SpaceMember } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { RealtimeEmitter } from '../realtime/realtime-emitter';
import { ChannelsService } from '../channels/channels.service';
import { dmPeerOf } from '../channels/dm-key';
import { parseMentions } from '../messages/mentions.service';
import { PaginationDto } from '../common/dto/pagination.dto';
import {
  NotificationPrefs,
  NotificationReasons,
  NotificationType,
  pickNotificationType,
} from './notification-type';
import { UpdateNotificationSettingsDto } from './dto/update-notification-settings.dto';
import { cursorArgs, pageOf } from '../common/pagination';
import { USER_SUMMARY_SELECT } from '../users/user-summary';

/** 메시지 하나로 만들 알림 한 건 — 트랜잭션 전에 계산해 둔다. */
export interface PlannedNotification {
  userId: string;
  type: NotificationType;
}

/** 목록 · 소켓이 같은 모양으로 내보내는 알림 한 줄(18단계 설계 §1). */
export interface NotificationItem {
  id: string;
  type: string;
  read: boolean;
  createdAt: Date;
  channelId: string;
  messageId: string;
  /** 답글이면 부모 id — 앱이 스레드로 연다. */
  threadId: string | null;
  actor: { id: string; name: string; avatarUrl: string | null };
  channel: { name: string; kind: ChannelKind };
  /** 지금 본문. 소프트 삭제됐으면 ''(N16). */
  body: string;
  deleted: boolean;
}

/** 사용자의 알림 스위치(N9 · N10). */
export interface NotificationSettings {
  mentions: boolean;
  broadcast: boolean;
  dms: boolean;
  replies: boolean;
}

/** 알림 한 줄을 그리는 데 필요한 메시지 쪽 값. 목록은 이것을 include 로 읽는다. */
const MESSAGE_SELECT = {
  select: {
    id: true,
    body: true,
    deletedAt: true,
    parentId: true,
    author: { select: USER_SUMMARY_SELECT },
  },
} as const;

const CHANNEL_SELECT = { select: { name: true, kind: true } } as const;

type MessageView = Prisma.MessageGetPayload<typeof MESSAGE_SELECT>;

const SETTINGS_SELECT = {
  notifyMentions: true,
  notifyBroadcast: true,
  notifyDms: true,
  notifyReplies: true,
} satisfies Prisma.UserSelect;

/**
 * 인앱 알림(18단계). 만드는 것은 메시지 전송이 부르고(같은 트랜잭션), 읽는 것은 알림함이 부른다.
 *
 * **가시성 판정은 하지 않는다** — 볼 수 있는 사람 · 채널은 `ChannelsService` 에게 묻는다
 * (16단계 검토 — 규칙을 서비스마다 따로 들면 새 규칙이 한쪽에만 걸린다).
 */
@Injectable()
export class NotificationsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly realtime: RealtimeEmitter,
    // ChannelsService.markRead 가 이 서비스를 부르고(N12), 이 서비스는 가시성을 그쪽에 묻는다.
    @Inject(forwardRef(() => ChannelsService))
    private readonly channels: ChannelsService,
  ) {}

  // ──────────────────────────────────────────────
  // 만들기 — 메시지 전송이 부른다
  // ──────────────────────────────────────────────

  /**
   * 메시지 하나로 누구에게 어떤 알림을 만들지(N1~N4 · N7 · N9). **트랜잭션 전에 부른다** —
   * 읽기만 하므로 메시지 트랜잭션을 길게 잡지 않는다.
   *
   * 받는 사람은 **그 채널을 지금 볼 수 있는 사람**과의 교집합이다(N3). 비공개 채널 밖의
   * 사람을 멘션해도 그 사람의 알림함으로 본문이 새면 안 된다.
   */
  async plan(input: {
    spaceId: string;
    channel: Pick<Channel, 'id' | 'kind' | 'key'>;
    authorId: string;
    body: string;
    /** 답글이면 부모 메시지 작성자(N4). */
    parentAuthorId: string | null;
  }): Promise<PlannedNotification[]> {
    const viewers = await this.channels.viewerIds(input.channel.id, input.spaceId);
    const parsed = parseMentions(input.body);

    const reasons = new Map<string, NotificationReasons>();
    const add = (userId: string | null, reason: NotificationType) => {
      // 자기 글은 알리지 않는다. 볼 수 없는 사람에게는 만들지 않는다(N3).
      if (!userId || userId === input.authorId || !viewers.has(userId)) return;
      const r = reasons.get(userId) ?? {
        mention: false,
        broadcast: false,
        dm: false,
        reply: false,
      };
      r[reason] = true;
      reasons.set(userId, r);
    };

    for (const userId of parsed.userIds) add(userId, 'mention');
    if (parsed.channel || parsed.everyone) {
      for (const userId of viewers) add(userId, 'broadcast');
    }
    if (input.channel.kind === ChannelKind.dm) {
      add(dmPeerOf(input.channel.key, input.authorId), 'dm');
    }
    add(input.parentAuthorId, 'reply');

    if (reasons.size === 0) return [];
    const userIds = [...reasons.keys()];

    const [users, mutedRows] = await Promise.all([
      this.prisma.user.findMany({
        where: { id: { in: userIds } },
        select: { id: true, ...SETTINGS_SELECT },
      }),
      this.prisma.channelMember.findMany({
        where: { channelId: input.channel.id, userId: { in: userIds }, muted: true },
        select: { userId: true },
      }),
    ]);
    const muted = new Set(mutedRows.map((r) => r.userId));

    const planned: PlannedNotification[] = [];
    for (const user of users) {
      const type = pickNotificationType(
        reasons.get(user.id)!,
        prefsOf(user),
        muted.has(user.id),
      );
      if (type) planned.push({ userId: user.id, type });
    }
    return planned;
  }

  /**
   * 계획한 알림을 만든다. **메시지 생성과 같은 트랜잭션에서 부른다**(N6) — 사이에서 끊기면
   * 메시지만 남고 알림은 재시도로도 생기지 않는다.
   */
  async createFor(
    tx: Prisma.TransactionClient,
    planned: PlannedNotification[],
    context: { spaceId: string; channelId: string; messageId: string; actorId: string },
  ): Promise<Notification[]> {
    if (planned.length === 0) return [];
    return tx.notification.createManyAndReturn({
      data: planned.map((p) => ({
        spaceId: context.spaceId,
        userId: p.userId,
        type: p.type,
        channelId: context.channelId,
        messageId: context.messageId,
        actorId: context.actorId,
      })),
    });
  }

  /**
   * 커밋 뒤에 받는 사람마다 `notification:new` 를 쏜다(N18). **사용자 룸으로 한 명씩** —
   * 스페이스 룸에 실으면 남의 알림이 보인다(§3-6).
   */
  emitCreated(
    rows: Notification[],
    message: MessageView,
    channel: Pick<Channel, 'name' | 'kind'>,
  ): void {
    for (const row of rows) {
      this.realtime.toUser(row.userId, 'notification:new', {
        spaceId: row.spaceId,
        notification: toItem(row, message, channel),
      });
    }
  }

  // ──────────────────────────────────────────────
  // 읽기 — 알림함
  // ──────────────────────────────────────────────

  /**
   * GET /api/spaces/:spaceId/notifications — 최신순 커서 페이지(N15).
   *
   * **지금 볼 수 없는 채널의 알림은 뺀다.** 비공개 명단에서 빠지면 그 채널의 본문도 더는
   * 보이면 안 된다. 행은 지우지 않는다 — 다시 들어오면 다시 보인다.
   */
  async list(member: SpaceMember, query: PaginationDto) {
    const { limit, args } = cursorArgs(query);
    const where = await this.visibleWhere(member);

    const rows = await this.prisma.notification.findMany({
      where,
      orderBy: [{ createdAt: 'desc' }, { id: 'desc' }],
      ...args,
      include: { message: MESSAGE_SELECT, channel: CHANNEL_SELECT },
    });

    const { page, nextCursor } = pageOf(rows, limit);

    return {
      items: page.flatMap((row) =>
        row.message && row.channel ? [toItem(row, row.message, row.channel)] : [],
      ),
      nextCursor,
    };
  }

  /** GET .../notifications/unread-count — 목록과 같은 규칙(볼 수 있는 채널만)으로 센다. */
  async unreadCount(member: SpaceMember): Promise<{ count: number }> {
    const where = await this.visibleWhere(member);
    const count = await this.prisma.notification.count({
      where: { ...where, read: false },
    });
    return { count };
  }

  /**
   * POST .../notifications/:id/read — 멱등(N13). 남의 알림 · 다른 스페이스 · 볼 수 없는
   * 채널의 알림은 404 다(목록에도 없는 것이다).
   */
  async markRead(member: SpaceMember, id: string): Promise<NotificationItem> {
    const where = await this.visibleWhere(member);
    const row = await this.prisma.notification.findFirst({
      where: { ...where, id },
      include: { message: MESSAGE_SELECT, channel: CHANNEL_SELECT },
    });
    if (!row || !row.message || !row.channel) {
      throw new NotFoundException('알림을 찾을 수 없습니다');
    }

    if (!row.read) {
      await this.prisma.notification.update({ where: { id }, data: { read: true } });
      this.emitRead(member, [id]);
    }
    return toItem({ ...row, read: true }, row.message, row.channel);
  }

  /**
   * POST .../notifications/read-all — 그 스페이스의 내 알림 전부(N13). 볼 수 없는 채널의 것도
   * 함께 읽는다 — 「모두」 다. 돌려주는 수는 이번에 읽음으로 바뀐 수다.
   */
  async markAllRead(member: SpaceMember): Promise<{ count: number }> {
    const { count } = await this.prisma.notification.updateMany({
      where: { userId: member.userId, spaceId: member.spaceId, read: false },
      data: { read: true },
    });
    if (count > 0) this.emitRead(member, null);
    return { count };
  }

  /**
   * 채널의 읽음 위치가 움직였다 — 그 채널의 **최상위 메시지** 알림 중 그 시각까지의 것을
   * 읽음으로(N12). `ChannelsService.markRead` 가 부른다(REST · 소켓 둘 다 그 길을 탄다).
   *
   * 스레드 답글의 알림은 건드리지 않는다 — 스레드에는 읽음 위치가 없어(7-2), 채널을 읽었다고
   * 답글을 읽은 것이 아니다.
   */
  async markChannelReadThrough(
    member: SpaceMember,
    channelId: string,
    lastReadAt: Date,
  ): Promise<void> {
    const rows = await this.prisma.notification.findMany({
      where: {
        userId: member.userId,
        spaceId: member.spaceId,
        channelId,
        read: false,
        message: { parentId: null, createdAt: { lte: lastReadAt } },
      },
      select: { id: true },
    });
    if (rows.length === 0) return;

    const ids = rows.map((r) => r.id);
    await this.prisma.notification.updateMany({
      where: { id: { in: ids }, userId: member.userId },
      data: { read: true },
    });
    this.emitRead(member, ids);
  }

  /** 내 기기 전부에(N14). `ids: null` 은 그 스페이스 전부. */
  private emitRead(member: SpaceMember, ids: string[] | null): void {
    this.realtime.toUser(member.userId, 'notification:read', {
      spaceId: member.spaceId,
      ids,
    });
  }

  /**
   * 내 알림 중 **지금 볼 수 있는 채널**의 것(N15). 채널마다 묻지 않고 볼 수 있는 id 집합을
   * 한 번에 받는다(`viewableChannelIds` — 소켓 룸 계산과 같은 판정).
   */
  private async visibleWhere(
    member: SpaceMember,
  ): Promise<Prisma.NotificationWhereInput> {
    const viewable = await this.channels.viewableChannelIds(member);
    return {
      userId: member.userId,
      spaceId: member.spaceId,
      channelId: { in: viewable },
    };
  }

  // ──────────────────────────────────────────────
  // 스위치 — 설정 창
  // ──────────────────────────────────────────────

  /** GET /api/me/notification-settings */
  async getSettings(userId: string): Promise<NotificationSettings> {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: SETTINGS_SELECT,
    });
    if (!user) throw new NotFoundException('사용자를 찾을 수 없습니다');
    return settingsOf(user);
  }

  /**
   * PATCH /api/me/notification-settings — 부분 갱신(N10). 바꾼 뒤로 **만들어지는** 알림에만
   * 듣는다 — 이미 온 알림은 남는다(N8).
   */
  async updateSettings(
    userId: string,
    dto: UpdateNotificationSettingsDto,
  ): Promise<NotificationSettings> {
    const user = await this.prisma.user.update({
      where: { id: userId },
      data: {
        ...(dto.mentions !== undefined ? { notifyMentions: dto.mentions } : {}),
        ...(dto.broadcast !== undefined ? { notifyBroadcast: dto.broadcast } : {}),
        ...(dto.dms !== undefined ? { notifyDms: dto.dms } : {}),
        ...(dto.replies !== undefined ? { notifyReplies: dto.replies } : {}),
      },
      select: SETTINGS_SELECT,
    });
    return settingsOf(user);
  }
}

type SettingsRow = Prisma.UserGetPayload<{ select: typeof SETTINGS_SELECT }>;

function settingsOf(user: SettingsRow): NotificationSettings {
  return {
    mentions: user.notifyMentions,
    broadcast: user.notifyBroadcast,
    dms: user.notifyDms,
    replies: user.notifyReplies,
  };
}

/** 컬럼 이름(설정 응답)과 알림 종류 이름을 잇는다. */
function prefsOf(user: SettingsRow): NotificationPrefs {
  return {
    mention: user.notifyMentions,
    broadcast: user.notifyBroadcast,
    dm: user.notifyDms,
    reply: user.notifyReplies,
  };
}

/**
 * 알림 한 줄. 본문은 저장하지 않고 **지금 메시지에서** 꺼낸다(N16) — 수정은 따라가고,
 * 소프트 삭제된 본문은 내보내지 않는다(§3-5).
 */
function toItem(
  row: Notification,
  message: MessageView,
  channel: Pick<Channel, 'name' | 'kind'>,
): NotificationItem {
  return {
    id: row.id,
    type: row.type,
    read: row.read,
    createdAt: row.createdAt,
    channelId: row.channelId!,
    messageId: message.id,
    threadId: message.parentId,
    actor: message.author,
    channel: { name: channel.name, kind: channel.kind },
    body: message.deletedAt ? '' : message.body,
    deleted: message.deletedAt !== null,
  };
}
