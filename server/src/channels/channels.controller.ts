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
import { ChannelsService } from './channels.service';
import { MessagesService } from '../messages/messages.service';
import { CreateChannelDto } from './dto/create-channel.dto';
import { UpdateChannelDto } from './dto/update-channel.dto';
import { MarkReadDto } from './dto/mark-read.dto';
import { CreateMessageDto } from '../messages/dto/create-message.dto';
import { PaginationDto } from '../common/dto/pagination.dto';
import { SpaceGuard } from '../spaces/guards/space.guard';
import { SpaceRoleGuard } from '../spaces/guards/space-role.guard';
import { MinRole } from '../spaces/decorators/min-role.decorator';
import { CurrentSpaceMember } from '../spaces/decorators/current-space-member.decorator';

/**
 * 채널과 그 채널의 메시지 (docs/백엔드-설계.md §4).
 *
 * 메시지 목록·전송이 여기 있는 이유는 URL 이 `/channels/:channelId/messages` 라서다.
 * 실제 로직은 MessagesService 가 갖는다.
 */
@Controller('spaces/:spaceId/channels')
@UseGuards(SpaceGuard, SpaceRoleGuard)
export class ChannelsController {
  constructor(
    private readonly channels: ChannelsService,
    private readonly messages: MessagesService,
  ) {}

  /** GET — 내가 볼 수 있는 채널 + 안 읽은 수 */
  @Get()
  list(@CurrentSpaceMember() member: SpaceMember) {
    return this.channels.listForMember(member);
  }

  @Get(':channelId')
  findOne(
    @Param('channelId', new ParseUUIDPipe()) channelId: string,
    @CurrentSpaceMember() member: SpaceMember,
  ) {
    return this.channels.assertCanView(channelId, member);
  }

  @Post()
  @MinRole('admin')
  create(
    @Param('spaceId', new ParseUUIDPipe()) spaceId: string,
    @Body() dto: CreateChannelDto,
  ) {
    return this.channels.create(spaceId, dto);
  }

  @Patch(':channelId')
  @MinRole('admin')
  update(
    @Param('spaceId', new ParseUUIDPipe()) spaceId: string,
    @Param('channelId', new ParseUUIDPipe()) channelId: string,
    @Body() dto: UpdateChannelDto,
  ) {
    return this.channels.update(spaceId, channelId, dto);
  }

  /** GET — 채널 메시지 (최신순 커서 페이지네이션, 스레드 답글 제외) */
  @Get(':channelId/messages')
  listMessages(
    @Param('channelId', new ParseUUIDPipe()) channelId: string,
    @Query() query: PaginationDto,
    @CurrentSpaceMember() member: SpaceMember,
  ) {
    return this.messages.listForChannel(channelId, member, query);
  }

  /** POST — 메시지 전송 */
  @Post(':channelId/messages')
  createMessage(
    @Param('channelId', new ParseUUIDPipe()) channelId: string,
    @Body() dto: CreateMessageDto,
    @CurrentSpaceMember() member: SpaceMember,
  ) {
    return this.messages.create(channelId, member, dto);
  }

  /** POST — 읽음 위치 저장 */
  @Post(':channelId/read')
  @HttpCode(HttpStatus.OK)
  markRead(
    @Param('channelId', new ParseUUIDPipe()) channelId: string,
    @Body() dto: MarkReadDto,
    @CurrentSpaceMember() member: SpaceMember,
  ) {
    return this.channels.markRead(channelId, member, dto);
  }

  /** POST — 공개 채널 참여 */
  @Post(':channelId/join')
  @HttpCode(HttpStatus.OK)
  join(
    @Param('channelId', new ParseUUIDPipe()) channelId: string,
    @CurrentSpaceMember() member: SpaceMember,
  ) {
    return this.channels.join(channelId, member);
  }
}
