import { Body, Controller, HttpCode, HttpStatus, Post, UseGuards } from '@nestjs/common';
import { SpaceMember } from '@prisma/client';
import { ChannelsService } from './channels.service';
import { OpenDmDto } from './dto/open-dm.dto';
import { SpaceGuard } from '../spaces/guards/space.guard';
import { CurrentSpaceMember } from '../spaces/decorators/current-space-member.decorator';

/**
 * DM 열기(17단계 설계 D3). 역할을 묻지 않는다 — 1:1 은 여럿에게 번지지 않는다(D5).
 * 있으면 그것, 없으면 만들어 **같은 모양(채널 목록 한 줄)** 으로 돌려준다.
 */
@Controller('spaces/:spaceId/dms')
@UseGuards(SpaceGuard)
export class DmsController {
  constructor(private readonly channels: ChannelsService) {}

  @Post()
  @HttpCode(HttpStatus.OK)
  open(@Body() dto: OpenDmDto, @CurrentSpaceMember() member: SpaceMember) {
    return this.channels.openDm(member, dto.userId);
  }
}
