import { Module } from '@nestjs/common';
import { PermissionsService } from './permissions.service';
import { PermissionsController } from './permissions.controller';
import { ChannelPermissionGuard } from './channel-permission.guard';

/**
 * Channel/role permission policy. Exports PermissionsService and
 * ChannelPermissionGuard for use by channels/messages and other
 * channel-scoped feature modules.
 */
@Module({
  controllers: [PermissionsController],
  providers: [PermissionsService, ChannelPermissionGuard],
  exports: [PermissionsService, ChannelPermissionGuard],
})
export class PermissionsModule {}
