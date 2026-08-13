import { Module, forwardRef } from '@nestjs/common';
import { MessagesService } from './messages.service';
import { MessagesController } from './messages.controller';
import { ChannelsModule } from '../channels/channels.module';
import { SpacesModule } from '../spaces/spaces.module';

/**
 * ChannelsModule 과 서로를 참조한다 — 채널 컨트롤러가 메시지 목록·전송 라우트를
 * 갖고(`/channels/:id/messages`), 메시지 서비스가 채널 접근 검사를 쓴다.
 * forwardRef 로 순환을 끊는다.
 */
@Module({
  imports: [forwardRef(() => ChannelsModule), SpacesModule],
  controllers: [MessagesController],
  providers: [MessagesService],
  exports: [MessagesService],
})
export class MessagesModule {}
