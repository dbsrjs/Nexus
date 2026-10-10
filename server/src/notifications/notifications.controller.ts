import {
  Body,
  Controller,
  Get,
  HttpCode,
  HttpStatus,
  Param,
  ParseUUIDPipe,
  Patch,
  Post,
  Query,
  UseGuards,
} from '@nestjs/common';
import { SpaceMember } from '@prisma/client';
import { NotificationsService } from './notifications.service';
import { UpdateNotificationSettingsDto } from './dto/update-notification-settings.dto';
import { PaginationDto } from '../common/dto/pagination.dto';
import { SpaceGuard } from '../spaces/guards/space.guard';
import { CurrentSpaceMember } from '../spaces/decorators/current-space-member.decorator';
import { CurrentUser } from '../common/decorators/current-user.decorator';

/**
 * 알림함(18단계 설계 §1). **역할을 묻지 않는다** — 내 알림은 나만 보고, 남에게 번지지 않는다.
 * guest 도 멘션을 받는다.
 */
@Controller('spaces/:spaceId/notifications')
@UseGuards(SpaceGuard)
export class NotificationsController {
  constructor(private readonly notifications: NotificationsService) {}

  @Get()
  list(@Query() query: PaginationDto, @CurrentSpaceMember() member: SpaceMember) {
    return this.notifications.list(member, query);
  }

  @Get('unread-count')
  unreadCount(@CurrentSpaceMember() member: SpaceMember) {
    return this.notifications.unreadCount(member);
  }

  /** 「모두 읽음」 — 그 스페이스의 내 알림 전부. */
  @Post('read-all')
  @HttpCode(HttpStatus.OK)
  readAll(@CurrentSpaceMember() member: SpaceMember) {
    return this.notifications.markAllRead(member);
  }

  /**
   * 스레드를 열었다 — 그 스레드 답글의 내 알림을 읽음으로(N12 수정, 2026-10-11). 멱등.
   * 스레드는 읽음 위치가 없어 채널 읽음이 따라오지 않는다 — 열어 본 것을 신호로 쓴다.
   */
  @Post('read-thread/:messageId')
  @HttpCode(HttpStatus.OK)
  readThread(
    @Param('messageId', new ParseUUIDPipe()) messageId: string,
    @CurrentSpaceMember() member: SpaceMember,
  ) {
    return this.notifications.markThreadRead(member, messageId);
  }

  /** 하나 읽음. 이미 읽었어도 같은 결과다(멱등). */
  @Post(':notificationId/read')
  @HttpCode(HttpStatus.OK)
  read(
    @Param('notificationId', new ParseUUIDPipe()) id: string,
    @CurrentSpaceMember() member: SpaceMember,
  ) {
    return this.notifications.markRead(member, id);
  }
}

/**
 * 알림 스위치(N9 · N10). 사용자 설정이라 스페이스에 묶이지 않는다 — `/api/me` 아래에 둔다.
 */
@Controller('me/notification-settings')
export class NotificationSettingsController {
  constructor(private readonly notifications: NotificationsService) {}

  @Get()
  get(@CurrentUser('id') userId: string) {
    return this.notifications.getSettings(userId);
  }

  @Patch()
  update(@CurrentUser('id') userId: string, @Body() dto: UpdateNotificationSettingsDto) {
    return this.notifications.updateSettings(userId, dto);
  }
}
