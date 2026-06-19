import { Module } from '@nestjs/common';
import { AiController } from './ai.controller';

/**
 * AI 모듈 (스텁). 엔드포인트만 노출하고 실제 구현은 Phase 2로 보류.
 */
@Module({
  controllers: [AiController],
})
export class AiModule {}
