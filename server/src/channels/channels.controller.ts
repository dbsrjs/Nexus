import { Controller, Get, Param, ParseUUIDPipe, Query } from '@nestjs/common';
import { Role } from '@prisma/client';
import { ChannelsService } from './channels.service';
import { CurrentUser, AuthUser } from '../common/decorators/current-user.decorator';
import { PaginationDto } from '../common/dto/pagination.dto';

@Controller('channels')
export class ChannelsController {
  constructor(private readonly channels: ChannelsService) {}

  /** GET /api/channels — channels/DMs the current user may view. */
  @Get()
  list(@CurrentUser() user: AuthUser) {
    return this.channels.listForUser(user.id, user.role as Role);
  }

  /** GET /api/channels/:id/messages — cursor-paginated (newest first). */
  @Get(':id/messages')
  async messages(
    @Param('id', new ParseUUIDPipe()) channelId: string,
    @Query() query: PaginationDto,
    @CurrentUser() user: AuthUser,
  ) {
    await this.channels.assertCanView(channelId, user.id, user.role as Role);
    return this.channels.listMessages(channelId, query);
  }
}
