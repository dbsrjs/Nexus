import { ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';
import { Role } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { ChannelsService } from '../channels/channels.service';
import { RealtimeGateway } from '../realtime/realtime.gateway';
import { NotificationsService } from '../notifications/notifications.service';
import { CreateMessageDto } from './dto/create-message.dto';
import { UpdateMessageDto } from './dto/update-message.dto';

/** Max characters of the message body kept as a notification preview. */
const PREVIEW_LEN = 120;

const AUTHOR_SELECT = {
  select: { id: true, name: true, initial: true, color: true },
} as const;

@Injectable()
export class MessagesService {
  constructor(
    private prisma: PrismaService,
    private channels: ChannelsService,
    private realtime: RealtimeGateway,
    private notifications: NotificationsService,
  ) {}

  /** POST /api/channels/:id/messages — guarded by can_send. */
  async create(channelId: string, userId: string, role: Role, dto: CreateMessageDto) {
    await this.channels.assertCanSend(channelId, userId, role);

    const message = await this.prisma.message.create({
      data: { channelId, authorId: userId, body: dto.body },
      include: { author: AUTHOR_SELECT },
    });

    this.realtime.emitMessageNew(channelId, message);

    // 같은 채널의 다른 멤버 전원에게 알림 1건씩 생성 + 실시간 푸시.
    await this.fanOutNotifications(channelId, message);

    return message;
  }

  /**
   * 메시지 작성자를 제외한 채널 멤버 each에게 'message' 알림을 persist 하고
   * RealtimeGateway 로 notification:new 를 push 한다. NotificationsService 는
   * 저장만 담당하고(순환 의존 회피), 실시간 전송 orchestration 은 여기서 수행.
   */
  private async fanOutNotifications(
    channelId: string,
    message: {
      id: string;
      body: string;
      author: { id: string; name: string };
    },
  ): Promise<void> {
    const channel = await this.prisma.channel.findUnique({
      where: { id: channelId },
      select: { name: true },
    });

    const members = await this.prisma.channelMember.findMany({
      where: { channelId, userId: { not: message.author.id } },
      select: { userId: true },
    });
    if (members.length === 0) return;

    const preview =
      message.body.length > PREVIEW_LEN
        ? `${message.body.slice(0, PREVIEW_LEN)}…`
        : message.body;

    const payloadBase = {
      channelId,
      channelName: channel?.name ?? '',
      messageId: message.id,
      authorName: message.author.name,
      preview,
    };

    for (const { userId } of members) {
      const notification = await this.notifications.create({
        userId,
        type: 'message',
        payload: payloadBase,
      });
      this.realtime.emitNotification(userId, notification);
    }
  }

  /**
   * PATCH /api/messages/:id — author only. The previous body is archived to
   * MessageEdit and editedAt is stamped, then `message:edited` is emitted.
   */
  async update(messageId: string, userId: string, dto: UpdateMessageDto) {
    const existing = await this.prisma.message.findUnique({
      where: { id: messageId },
      select: { id: true, channelId: true, authorId: true, body: true },
    });
    if (!existing) {
      throw new NotFoundException('메시지를 찾을 수 없습니다.');
    }
    if (existing.authorId !== userId) {
      throw new ForbiddenException('본인이 작성한 메시지만 수정할 수 있습니다.');
    }

    // Archive previous body + update in one transaction.
    const [, updated] = await this.prisma.$transaction([
      this.prisma.messageEdit.create({
        data: { messageId, prevBody: existing.body },
      }),
      this.prisma.message.update({
        where: { id: messageId },
        data: { body: dto.body, editedAt: new Date() },
        include: { author: AUTHOR_SELECT },
      }),
    ]);

    this.realtime.emitMessageEdited(updated.channelId, updated);
    return updated;
  }

  /** GET /api/messages/:id/edits — prior-body history, newest first. */
  async listEdits(messageId: string, userId: string, role: Role) {
    const message = await this.prisma.message.findUnique({
      where: { id: messageId },
      select: { id: true, channelId: true },
    });
    if (!message) {
      throw new NotFoundException('메시지를 찾을 수 없습니다.');
    }
    // Only users who can view the channel may read edit history.
    await this.channels.assertCanView(message.channelId, userId, role);

    return this.prisma.messageEdit.findMany({
      where: { messageId },
      orderBy: { editedAt: 'desc' },
    });
  }
}
