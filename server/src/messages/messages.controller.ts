import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  ParseUUIDPipe,
  Patch,
  UseGuards,
} from '@nestjs/common';
import { SpaceMember } from '@prisma/client';
import { MessagesService } from './messages.service';
import { UpdateMessageDto } from './dto/update-message.dto';
import { SpaceGuard } from '../spaces/guards/space.guard';
import { CurrentSpaceMember } from '../spaces/decorators/current-space-member.decorator';

/**
 * 채널을 거치지 않고 메시지 id 로 직접 접근하는 라우트 (docs/백엔드-설계.md §4).
 * 채널 하위 라우트(목록 · 전송)는 ChannelsController 에 있다.
 */
@Controller('spaces/:spaceId/messages')
@UseGuards(SpaceGuard)
export class MessagesController {
  constructor(private readonly messages: MessagesService) {}

  @Patch(':messageId')
  update(
    @Param('messageId', new ParseUUIDPipe()) messageId: string,
    @Body() dto: UpdateMessageDto,
    @CurrentSpaceMember() member: SpaceMember,
  ) {
    return this.messages.update(messageId, member, dto);
  }

  /** 소프트 삭제. 본문만 가려지고 첨부는 남는다. */
  @Delete(':messageId')
  remove(
    @Param('messageId', new ParseUUIDPipe()) messageId: string,
    @CurrentSpaceMember() member: SpaceMember,
  ) {
    return this.messages.remove(messageId, member);
  }

  @Get(':messageId/edits')
  edits(
    @Param('messageId', new ParseUUIDPipe()) messageId: string,
    @CurrentSpaceMember() member: SpaceMember,
  ) {
    return this.messages.listEdits(messageId, member);
  }
}
