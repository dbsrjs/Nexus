import { Injectable, Logger, OnModuleInit } from '@nestjs/common';
import { Cron, CronExpression } from '@nestjs/schedule';
import { AiQueueService } from './ai-queue.service';
import { AiRunnerService } from './ai-runner.service';

/**
 * 큐를 비우는 쪽. **`IndexingWorker` 와 같은 모양이다** — 새로 들이는 것이
 * 없다는 것이 DB 큐를 고른 근거였다.
 *
 * **깨우기(`kick`)는 최적화가 아니다.** 30초를 기다릴 수 없는 계약 검증이
 * 성립하는 조건이기도 하다.
 */
@Injectable()
export class AiWorker implements OnModuleInit {
  private readonly logger = new Logger(AiWorker.name);
  /**
   * 한 프로세스에서 한 번에 하나만 돈다. GPU 에 모델이 하나 올라가 있으므로
   * 병렬로 불러 봐야 서로 기다린다 (설계 §5).
   */
  private running = false;

  constructor(
    private readonly queue: AiQueueService,
    private readonly runner: AiRunnerService,
  ) {}

  async onModuleInit(): Promise<void> {
    this.kick();
  }

  @Cron(CronExpression.EVERY_30_SECONDS)
  async tick(): Promise<void> {
    await this.drain();
  }

  /** 적재 직후 부른다. 기다리지 않는다 — 실패해도 크론이 받는다. */
  kick(): void {
    void this.drain();
  }

  private async drain(): Promise<void> {
    if (this.running) return;
    this.running = true;
    try {
      for (;;) {
        const run = await this.queue.lease();
        if (!run) return;
        await this.runner.runOne(run);
      }
    } catch (err) {
      // AI 가 실패해도 서버는 계속 떠 있어야 한다.
      this.logger.error('AI 워커 실패', err as Error);
    } finally {
      this.running = false;
    }
  }
}
