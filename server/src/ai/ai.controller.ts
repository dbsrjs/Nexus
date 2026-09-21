import {
  Body,
  Controller,
  Get,
  Param,
  ParseUUIDPipe,
  Post,
  UseGuards,
} from '@nestjs/common';
import { SpaceGuard } from '../spaces/guards/space.guard';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { AiService } from './ai.service';
import { AiWorker } from './ai.worker';
import { SummarizeDto } from './dto/summarize.dto';

/**
 * AI 실행.
 *
 * **`@MinRole` 을 걸지 않는다** (판단 #9 — 읽기 라우트). 읽을 수 있으면
 * 요약할 수 있다. 채널 가시성은 `AiService` 가 직접 본다.
 *
 * 「채널에 붙이기」는 여기 없다 — 앱이 **평범한 메시지 전송**을 쓴다
 * (설계 §7.1).
 */
@Controller('spaces/:spaceId/ai')
@UseGuards(SpaceGuard)
export class AiController {
  constructor(
    private readonly ai: AiService,
    private readonly worker: AiWorker,
  ) {}

  @Post('summarize')
  async summarize(
    @Param('spaceId', new ParseUUIDPipe()) spaceId: string,
    @CurrentUser('id') userId: string,
    @Body() dto: SummarizeDto,
  ) {
    const result = await this.ai.summarize(spaceId, userId, dto);
    // 깨우는 것은 컨트롤러의 일이다 — 서비스가 워커를 부르면 둘이 서로를
    // 참조해 순환 의존이 된다(12단계와 같은 이유). 캐시 적중(done)이면
    // 큐에 아무것도 넣지 않았으므로 깨우지 않는다.
    if (result.state === 'queued') this.worker.kick();
    return result;
  }

  @Get('runs/:runId')
  getRun(
    @Param('spaceId', new ParseUUIDPipe()) spaceId: string,
    @Param('runId', new ParseUUIDPipe()) runId: string,
    @CurrentUser('id') userId: string,
  ) {
    return this.ai.getRun(spaceId, userId, runId);
  }
}
