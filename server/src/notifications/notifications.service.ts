import { ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { CreateNotificationDto } from './dto/create-notification.dto';
import { ListNotificationsDto } from './dto/list-notifications.dto';

export interface NotificationResponse {
  id: string;
  userId: string;
  type: string;
  payload: unknown;
  read: boolean;
  createdAt: Date;
}

@Injectable()
export class NotificationsService {
  constructor(private prisma: PrismaService) {}

  /**
   * Create a notification for a user. Called by other services
   * (messages, issues, notices …). Persists the row and returns it.
   *
   * NOTE: realtime delivery (Socket.IO `notification:new`, design §5) is wired
   * by the realtime/integrate phase, which can subscribe to or wrap this method
   * — kept side-effect-free here so this module owns no cross-module deps.
   */
  async create(dto: CreateNotificationDto): Promise<NotificationResponse> {
    const row = await this.prisma.notification.create({
      data: {
        userId: dto.userId,
        type: dto.type,
        payload: (dto.payload ?? undefined) as Prisma.InputJsonValue | undefined,
      },
    });
    return this.toResponse(row);
  }

  /**
   * Cursor-paginated list of the current user's notifications (newest first).
   * Optional `unread` filter returns only unread notifications.
   */
  async list(
    userId: string,
    query: ListNotificationsDto,
  ): Promise<{ items: NotificationResponse[]; nextCursor: string | null }> {
    const limit = query.limit ?? 30;

    const where: Prisma.NotificationWhereInput = { userId };
    if (query.unread) {
      where.read = false;
    }

    const rows = await this.prisma.notification.findMany({
      where,
      orderBy: { createdAt: 'desc' },
      take: limit + 1, // fetch one extra to detect a next page
      ...(query.cursor
        ? { cursor: { id: query.cursor }, skip: 1 }
        : {}),
    });

    const hasMore = rows.length > limit;
    const items = hasMore ? rows.slice(0, limit) : rows;
    const nextCursor = hasMore ? items[items.length - 1].id : null;

    return { items: items.map((r) => this.toResponse(r)), nextCursor };
  }

  /** Number of unread notifications for the user (badge count). */
  async unreadCount(userId: string): Promise<{ count: number }> {
    const count = await this.prisma.notification.count({
      where: { userId, read: false },
    });
    return { count };
  }

  /** Mark a single notification as read. Owner-only. */
  async markRead(userId: string, id: string): Promise<NotificationResponse> {
    const row = await this.prisma.notification.findUnique({ where: { id } });
    if (!row) {
      throw new NotFoundException('알림을 찾을 수 없습니다.');
    }
    if (row.userId !== userId) {
      throw new ForbiddenException('본인의 알림만 처리할 수 있습니다.');
    }
    if (row.read) {
      return this.toResponse(row);
    }
    const updated = await this.prisma.notification.update({
      where: { id },
      data: { read: true },
    });
    return this.toResponse(updated);
  }

  /** Mark all of the user's notifications as read. */
  async markAllRead(userId: string): Promise<{ updated: number }> {
    const result = await this.prisma.notification.updateMany({
      where: { userId, read: false },
      data: { read: true },
    });
    return { updated: result.count };
  }

  private toResponse(row: {
    id: string;
    userId: string;
    type: string;
    payload: unknown;
    read: boolean;
    createdAt: Date;
  }): NotificationResponse {
    return {
      id: row.id,
      userId: row.userId,
      type: row.type,
      payload: row.payload ?? null,
      read: row.read,
      createdAt: row.createdAt,
    };
  }
}
