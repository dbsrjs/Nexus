import {
  Body,
  Controller,
  Delete,
  Get,
  HttpCode,
  HttpStatus,
  Param,
  Patch,
  Post,
  UseGuards,
} from '@nestjs/common';
import { SpaceMember } from '@prisma/client';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { SpacesService } from './spaces.service';
import { SpaceGuard } from './guards/space.guard';
import { SpaceRoleGuard } from './guards/space-role.guard';
import { MinRole } from './decorators/min-role.decorator';
import { CurrentSpaceMember } from './decorators/current-space-member.decorator';
import { CreateSpaceDto } from './dto/create-space.dto';
import { UpdateSpaceDto } from './dto/update-space.dto';
import { CreateInviteDto } from './dto/create-invite.dto';
import { UpdateMemberRoleDto } from './dto/update-member-role.dto';

/**
 * 스페이스 CRUD · 멤버 · 초대 (docs/백엔드-설계.md §4).
 *
 * `:spaceId` 가 있는 라우트에는 전부 SpaceGuard 를 건다. 목록·생성은
 * 스페이스에 속하지 않으므로 붙이지 않는다.
 */
@Controller('spaces')
export class SpacesController {
  constructor(private readonly spaces: SpacesService) {}

  /** GET /api/spaces — 내가 속한 스페이스 목록 */
  @Get()
  list(@CurrentUser('id') userId: string) {
    return this.spaces.listForUser(userId);
  }

  /** POST /api/spaces */
  @Post()
  create(@CurrentUser('id') userId: string, @Body() dto: CreateSpaceDto) {
    return this.spaces.create(userId, dto);
  }

  /** GET /api/spaces/:spaceId */
  @Get(':spaceId')
  @UseGuards(SpaceGuard)
  findOne(@Param('spaceId') spaceId: string) {
    return this.spaces.findOne(spaceId);
  }

  /** PATCH /api/spaces/:spaceId (admin+) */
  @Patch(':spaceId')
  @UseGuards(SpaceGuard, SpaceRoleGuard)
  @MinRole('admin')
  update(@Param('spaceId') spaceId: string, @Body() dto: UpdateSpaceDto) {
    return this.spaces.update(spaceId, dto);
  }

  /** GET /api/spaces/:spaceId/members */
  @Get(':spaceId/members')
  @UseGuards(SpaceGuard)
  listMembers(@Param('spaceId') spaceId: string) {
    return this.spaces.listMembers(spaceId);
  }

  /** PATCH /api/spaces/:spaceId/members/:userId (admin+) */
  @Patch(':spaceId/members/:userId')
  @UseGuards(SpaceGuard, SpaceRoleGuard)
  @MinRole('admin')
  updateMemberRole(
    @Param('spaceId') spaceId: string,
    @Param('userId') targetUserId: string,
    @CurrentSpaceMember() actor: SpaceMember,
    @Body() dto: UpdateMemberRoleDto,
  ) {
    return this.spaces.updateMemberRole(spaceId, actor, targetUserId, dto.role);
  }

  /** DELETE /api/spaces/:spaceId/members/:userId (admin+) */
  @Delete(':spaceId/members/:userId')
  @UseGuards(SpaceGuard, SpaceRoleGuard)
  @MinRole('admin')
  @HttpCode(HttpStatus.NO_CONTENT)
  removeMember(
    @Param('spaceId') spaceId: string,
    @Param('userId') targetUserId: string,
    @CurrentSpaceMember() actor: SpaceMember,
  ) {
    return this.spaces.removeMember(spaceId, actor, targetUserId);
  }

  /** POST /api/spaces/:spaceId/invites (admin+) */
  @Post(':spaceId/invites')
  @UseGuards(SpaceGuard, SpaceRoleGuard)
  @MinRole('admin')
  createInvite(
    @Param('spaceId') spaceId: string,
    @CurrentUser('id') userId: string,
    @Body() dto: CreateInviteDto,
  ) {
    return this.spaces.createInvite(spaceId, userId, dto);
  }
}
