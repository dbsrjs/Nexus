import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  ParseUUIDPipe,
  Patch,
  Post,
  UseGuards,
} from '@nestjs/common';
import { SpaceMember } from '@prisma/client';
import { MessagesService } from './messages.service';
import { ReactionsService } from './reactions.service';
import { UpdateMessageDto } from './dto/update-message.dto';
import { CreateReactionDto } from './dto/create-reaction.dto';
import { SpaceGuard } from '../spaces/guards/space.guard';
import { CurrentSpaceMember } from '../spaces/decorators/current-space-member.decorator';

/**
 * 채널을 거치지 않고 메시지 id 로 직접 접근하는 라우트 (docs/백엔드-설계.md §4).
 * 채널 하위 라우트(목록 · 전송)는 ChannelsController 에 있다.
 */
@Controller('spaces/:spaceId/messages')
@UseGuards(SpaceGuard)
export class MessagesController {
  constructor(
    private readonly messages: MessagesService,
    private readonly reactions: ReactionsService,
  ) {}

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

  /** 리액션 추가. 이미 누른 것을 다시 눌러도 같은 결과다(멱등). */
  @Post(':messageId/reactions')
  addReaction(
    @Param('messageId', new ParseUUIDPipe()) messageId: string,
    @Body() dto: CreateReactionDto,
    @CurrentSpaceMember() member: SpaceMember,
  ) {
    return this.reactions.add(messageId, member, dto.emoji);
  }

  /**
   * 리액션 제거. 이모지는 경로에 실리므로 클라이언트가 인코딩해 보낸다.
   *
   * DELETE 에 본문을 싣지 않는 이유: 프록시·클라이언트에 따라 조용히 버려진다.
   */
  @Delete(':messageId/reactions/:emoji')
  removeReaction(
    @Param('messageId', new ParseUUIDPipe()) messageId: string,
    @Param('emoji') emoji: string,
    @CurrentSpaceMember() member: SpaceMember,
  ) {
    return this.reactions.remove(messageId, member, emoji);
  }
}
