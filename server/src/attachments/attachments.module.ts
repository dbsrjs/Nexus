import { Module, forwardRef } from '@nestjs/common';
import { ChannelsModule } from '../channels/channels.module';
import { SpacesModule } from '../spaces/spaces.module';
import { StorageModule } from '../storage/storage.module';
import { AttachmentsController } from './attachments.controller';
import { AttachmentsService } from './attachments.service';
import { OrphanCleanupService } from './orphan-cleanup.service';

/**
 * 첨부. 채널 권한 검사를 그대로 쓰므로 ChannelsModule 을 참조한다.
 *
 * `MessagesModule` 이 전송 시 연결을 위해 `AttachmentsService` 를 쓴다.
 * ChannelsModule 과의 순환은 메시지 쪽과 같은 이유로 forwardRef 로 끊는다.
 */
@Module({
  imports: [forwardRef(() => ChannelsModule), SpacesModule, StorageModule],
  controllers: [AttachmentsController],
  providers: [AttachmentsService, OrphanCleanupService],
  exports: [AttachmentsService],
})
export class AttachmentsModule {}
