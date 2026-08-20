import { Module } from '@nestjs/common';
import { ReposService } from './repos.service';
import { ReposController } from './repos.controller';
import { WebhooksService } from './webhooks.service';
import { WebhooksController } from './webhooks.controller';
import { SpacesModule } from '../spaces/spaces.module';
import { RealtimeEmitterModule } from '../realtime/realtime-emitter.module';

/**
 * 저장소 연동. 웹훅 수신은 `SpaceGuard` 를 지나지 않으므로(부르는 쪽이
 * GitHub 이다) 컨트롤러를 둘로 나눈다 — 한쪽은 스페이스 밑, 한쪽은 밖이다.
 */
@Module({
  imports: [SpacesModule, RealtimeEmitterModule],
  controllers: [ReposController, WebhooksController],
  providers: [ReposService, WebhooksService],
  exports: [ReposService],
})
export class ReposModule {}
