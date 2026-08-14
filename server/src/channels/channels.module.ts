import { Module, forwardRef } from '@nestjs/common';
import { ChannelsService } from './channels.service';
import { ChannelsController } from './channels.controller';
import { MessagesModule } from '../messages/messages.module';
import { SpacesModule } from '../spaces/spaces.module';
import { RealtimeEmitterModule } from '../realtime/realtime-emitter.module';

/**
 * 채널 · 가시성 검사 · 읽음 마커.
 *
 * ChannelsService 는 4단계에서 소켓 게이트웨이가 "어느 룸에 join 할지" 정하는 데도
 * 쓰인다. 그래서 export 한다.
 */
@Module({
  imports: [forwardRef(() => MessagesModule), SpacesModule, RealtimeEmitterModule],
  controllers: [ChannelsController],
  providers: [ChannelsService],
  exports: [ChannelsService],
})
export class ChannelsModule {}
