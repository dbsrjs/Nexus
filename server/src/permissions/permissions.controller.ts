import {
  Body,
  Controller,
  Delete,
  Get,
  HttpCode,
  HttpStatus,
  Param,
  ParseUUIDPipe,
  Post,
  Put,
  UseGuards,
} from '@nestjs/common';
import { SpaceMember } from '@prisma/client';
import { SpaceGuard } from '../spaces/guards/space.guard';
import { SpaceRoleGuard } from '../spaces/guards/space-role.guard';
import { MinRole } from '../spaces/decorators/min-role.decorator';
import { CurrentSpaceMember } from '../spaces/decorators/current-space-member.decorator';
import { PermissionsService } from './permissions.service';
import { ChannelMembersService } from './channel-members.service';
import { SetPermissionDto } from './dto/set-permission.dto';
import { AddChannelMembersDto } from './dto/add-channel-members.dto';

/**
 * 채널별 권한과 비공개 채널 명단(16단계 설계 §1 16-2).
 *
 * 권한은 채널 구조라 **admin+**(§3-9). 명단 읽기는 열람 권한이고(읽기 라우트에 `@MinRole`
 * 을 걸지 않는다), 들이기 · 빼기의 역할 조건은 서비스가 본다 — 본인 나가기는 누구나라
 * 라우트 하나에 역할을 박을 수 없다.
 */
@Controller('spaces/:spaceId/channels/:channelId')
@UseGuards(SpaceGuard, SpaceRoleGuard)
export class PermissionsController {
  constructor(
    private readonly permissions: PermissionsService,
    private readonly members: ChannelMembersService,
  ) {}

  @Get('permissions')
  @MinRole('admin')
  listPermissions(
    @Param('channelId', new ParseUUIDPipe()) channelId: string,
    @CurrentSpaceMember() member: SpaceMember,
  ) {
    return this.permissions.list(channelId, member);
  }

  @Put('permissions/:role')
  @MinRole('admin')
  setPermission(
    @Param('channelId', new ParseUUIDPipe()) channelId: string,
    @Param('role') role: string,
    @Body() dto: SetPermissionDto,
    @CurrentSpaceMember() member: SpaceMember,
  ) {
    return this.permissions.set(channelId, member, role, dto);
  }

  @Delete('permissions/:role')
  @MinRole('admin')
  @HttpCode(HttpStatus.NO_CONTENT)
  resetPermission(
    @Param('channelId', new ParseUUIDPipe()) channelId: string,
    @Param('role') role: string,
    @CurrentSpaceMember() member: SpaceMember,
  ) {
    return this.permissions.reset(channelId, member, role);
  }

  @Get('members')
  listMembers(
    @Param('channelId', new ParseUUIDPipe()) channelId: string,
    @CurrentSpaceMember() member: SpaceMember,
  ) {
    return this.members.list(channelId, member);
  }

  @Post('members')
  @HttpCode(HttpStatus.OK)
  addMembers(
    @Param('channelId', new ParseUUIDPipe()) channelId: string,
    @Body() dto: AddChannelMembersDto,
    @CurrentSpaceMember() member: SpaceMember,
  ) {
    return this.members.add(channelId, member, dto.userIds);
  }

  @Delete('members/:userId')
  @HttpCode(HttpStatus.NO_CONTENT)
  removeMember(
    @Param('channelId', new ParseUUIDPipe()) channelId: string,
    @Param('userId') userId: string,
    @CurrentSpaceMember() member: SpaceMember,
  ) {
    return this.members.remove(channelId, member, userId);
  }
}
