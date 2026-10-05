import { Module, forwardRef } from '@nestjs/common';
import { NotificationsService } from './notifications.service';
import {
  NotificationSettingsController,
  NotificationsController,
} from './notifications.controller';
import { ChannelsModule } from '../channels/channels.module';
import { SpacesModule } from '../spaces/spaces.module';
import { RealtimeEmitterModule } from '../realtime/realtime-emitter.module';

/**
 * 인앱 알림(18단계). ChannelsModule 과 서로를 참조한다 — 알림은 가시성을 채널에 묻고(N3 · N15),
 * 채널의 읽음 위치가 움직이면 알림이 따라 읽힌다(N12). 채널 ↔ 메시지와 같은 사정이라 같은
 * 방법(forwardRef)으로 끊는다.
 */
@Module({
  imports: [forwardRef(() => ChannelsModule), SpacesModule, RealtimeEmitterModule],
  controllers: [NotificationsController, NotificationSettingsController],
  providers: [NotificationsService],
  exports: [NotificationsService],
})
export class NotificationsModule {}
