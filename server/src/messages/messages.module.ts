import { Module, forwardRef } from '@nestjs/common';
import { MessagesService } from './messages.service';
import { ReactionsService } from './reactions.service';
import { MentionsService } from './mentions.service';
import { MessagesController } from './messages.controller';
import { ChannelsModule } from '../channels/channels.module';
import { SpacesModule } from '../spaces/spaces.module';
import { RealtimeEmitterModule } from '../realtime/realtime-emitter.module';

/**
 * ChannelsModule 과 서로를 참조한다 — 채널 컨트롤러가 메시지 목록·전송 라우트를
 * 갖고(`/channels/:id/messages`), 메시지 서비스가 채널 접근 검사를 쓴다.
 * forwardRef 로 순환을 끊는다.
 *
 * RealtimeEmitterModule 만 import 한다 — 게이트웨이를 직접 주입하지 않으므로
 * ChannelsModule 과의 순환이 생기지 않는다.
 */
@Module({
  imports: [forwardRef(() => ChannelsModule), SpacesModule, RealtimeEmitterModule],
  controllers: [MessagesController],
  providers: [MessagesService, ReactionsService, MentionsService],
  exports: [MessagesService, ReactionsService, MentionsService],
})
export class MessagesModule {}
