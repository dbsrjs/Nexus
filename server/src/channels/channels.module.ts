import { Module } from '@nestjs/common';
import { ChannelsService } from './channels.service';
import { ChannelsController } from './channels.controller';

/**
 * Channels + DM listing, visibility/permission checks, and message paging.
 * Exports ChannelsService so MessagesModule and the realtime gateway can
 * reuse access checks and the per-user viewable-channel set.
 */
@Module({
  controllers: [ChannelsController],
  providers: [ChannelsService],
  exports: [ChannelsService],
})
export class ChannelsModule {}
