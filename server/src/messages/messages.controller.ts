import {
  Body,
  Controller,
  Get,
  Param,
  ParseUUIDPipe,
  Patch,
  Post,
} from '@nestjs/common';
import { Role } from '@prisma/client';
import { MessagesService } from './messages.service';
import { CreateMessageDto } from './dto/create-message.dto';
import { UpdateMessageDto } from './dto/update-message.dto';
import { CurrentUser, AuthUser } from '../common/decorators/current-user.decorator';

@Controller()
export class MessagesController {
  constructor(private readonly messages: MessagesService) {}

  /** POST /api/channels/:id/messages — create (can_send guard in service). */
  @Post('channels/:id/messages')
  create(
    @Param('id', new ParseUUIDPipe()) channelId: string,
    @Body() dto: CreateMessageDto,
    @CurrentUser() user: AuthUser,
  ) {
    return this.messages.create(channelId, user.id, user.role as Role, dto);
  }

  /** PATCH /api/messages/:id — author-only edit. */
  @Patch('messages/:id')
  update(
    @Param('id', new ParseUUIDPipe()) messageId: string,
    @Body() dto: UpdateMessageDto,
    @CurrentUser() user: AuthUser,
  ) {
    return this.messages.update(messageId, user.id, dto);
  }

  /** GET /api/messages/:id/edits — prior-body history. */
  @Get('messages/:id/edits')
  edits(
    @Param('id', new ParseUUIDPipe()) messageId: string,
    @CurrentUser() user: AuthUser,
  ) {
    return this.messages.listEdits(messageId, user.id, user.role as Role);
  }
}
