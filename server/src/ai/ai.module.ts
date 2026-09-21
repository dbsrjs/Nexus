import { Module } from '@nestjs/common';
import { SpacesModule } from '../spaces/spaces.module';
import { RealtimeEmitterModule } from '../realtime/realtime-emitter.module';
import { LlmModule } from '../llm/llm.module';
import { ReposModule } from '../repos/repos.module';
import { AiController } from './ai.controller';
import { AiService } from './ai.service';
import { AiQueueService } from './ai-queue.service';
import { AiRunnerService } from './ai-runner.service';
import { AiWorker } from './ai.worker';

/**
 * AI. **`ReposModule` 을 단방향으로 쓴다** — repos 는 ai 를 모른다.
 * 13-3 코드 질의가 `IndexingService.search()` 를 부를 자리다.
 */
@Module({
  imports: [SpacesModule, RealtimeEmitterModule, LlmModule, ReposModule],
  controllers: [AiController],
  providers: [AiService, AiQueueService, AiRunnerService, AiWorker],
})
export class AiModule {}
