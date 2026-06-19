import {
  Controller,
  Get,
  Param,
  ParseUUIDPipe,
  Post,
  Query,
} from '@nestjs/common';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { NotificationsService } from './notifications.service';
import { ListNotificationsDto } from './dto/list-notifications.dto';

// Base path 'notifications' under the global 'api' prefix → /api/notifications/*
@Controller('notifications')
export class NotificationsController {
  constructor(private readonly notificationsService: NotificationsService) {}

  /** GET /api/notifications?cursor=&limit=&unread= */
  @Get()
  async list(
    @CurrentUser('id') userId: string,
    @Query() query: ListNotificationsDto,
  ) {
    return this.notificationsService.list(userId, query);
  }

  /** GET /api/notifications/unread-count — badge count. */
  @Get('unread-count')
  async unreadCount(@CurrentUser('id') userId: string) {
    return this.notificationsService.unreadCount(userId);
  }

  /** POST /api/notifications/read-all — mark everything read. */
  @Post('read-all')
  async markAllRead(@CurrentUser('id') userId: string) {
    return this.notificationsService.markAllRead(userId);
  }

  /** POST /api/notifications/:id/read — mark a single notification read. */
  @Post(':id/read')
  async markRead(
    @CurrentUser('id') userId: string,
    @Param('id', ParseUUIDPipe) id: string,
  ) {
    return this.notificationsService.markRead(userId, id);
  }
}
