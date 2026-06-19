import {
  Body,
  Controller,
  Param,
  Put,
  Get,
  UseGuards,
} from '@nestjs/common';
import { Role } from '@prisma/client';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../common/decorators/roles.decorator';
import { PermissionsService } from './permissions.service';
import { SetPermissionDto } from './dto/set-permission.dto';
import { RoleParamPipe } from './role-param.pipe';

/**
 * Admin-only permission matrix management (design doc §4):
 *   GET /api/admin/permissions
 *   PUT /api/admin/permissions/:channelId/:role  { canView, canSend }
 */
@Controller('admin/permissions')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles(Role.admin)
export class PermissionsController {
  constructor(private readonly permissions: PermissionsService) {}

  @Get()
  getMatrix() {
    return this.permissions.getMatrix();
  }

  @Put(':channelId/:role')
  setPermission(
    @Param('channelId') channelId: string,
    @Param('role', RoleParamPipe) role: Role,
    @Body() dto: SetPermissionDto,
  ) {
    return this.permissions.setPermission(
      channelId,
      role,
      dto.canView,
      dto.canSend,
    );
  }
}
