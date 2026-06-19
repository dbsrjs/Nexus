import { Module } from '@nestjs/common';
import { NotificationsController } from './notifications.controller';
import { NotificationsService } from './notifications.service';

/**
 * Notifications module. Exports NotificationsService so other feature modules
 * (messages, issues, notices …) can call create() to push notifications.
 * PrismaService is injected from the global PrismaModule.
 */
@Module({
  controllers: [NotificationsController],
  providers: [NotificationsService],
  exports: [NotificationsService],
})
export class NotificationsModule {}
