import { Body, Controller, Get, Post, Query, UseGuards } from '@nestjs/common';
import { Role } from '@prisma/client';
import {
  CurrentUser,
  AuthUser,
} from '../common/decorators/current-user.decorator';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../common/decorators/roles.decorator';
import { NoticesService } from './notices.service';
import { ListNoticesDto } from './dto/list-notices.dto';
import { CreateNoticeDto } from './dto/create-notice.dto';

/** Notices (공지) API — design doc §4. */
@Controller('notices')
export class NoticesController {
  constructor(private readonly notices: NoticesService) {}

  /** GET /api/notices?cursor=&limit=&team= */
  @Get()
  list(@Query() query: ListNoticesDto) {
    return this.notices.list(query);
  }

  /**
   * POST /api/notices — lead/admin only. RolesGuard enforces the role at the
   * edge; the service keeps its own server-authoritative check as defense in
   * depth.
   */
  @Post()
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(Role.lead, Role.admin)
  create(@Body() dto: CreateNoticeDto, @CurrentUser() user: AuthUser) {
    return this.notices.create(dto, user.id, user.role);
  }
}
