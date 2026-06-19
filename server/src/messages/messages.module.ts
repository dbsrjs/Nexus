import { Module } from '@nestjs/common';
import { MessagesService } from './messages.service';
import { MessagesController } from './messages.controller';
import { ChannelsModule } from '../channels/channels.module';
import { RealtimeModule } from '../realtime/realtime.module';
import { NotificationsModule } from '../notifications/notifications.module';

/**
 * Message create/edit + edit history. Depends on ChannelsModule (access
 * checks), RealtimeModule (push message:new / message:edited) and
 * NotificationsModule (persist notifications for other channel members).
 */
@Module({
  imports: [ChannelsModule, RealtimeModule, NotificationsModule],
  controllers: [MessagesController],
  providers: [MessagesService],
  exports: [MessagesService],
})
export class MessagesModule {}
