import { Injectable, Logger, OnModuleInit } from '@nestjs/common';
import { Cron, CronExpression } from '@nestjs/schedule';
import { AiQueueService } from './ai-queue.service';
import { AiRunnerService } from './ai-runner.service';
import { DrainLoop } from '../common/drain-loop';

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
   * 한 프로세스에서 한 번에 하나만 돈다(`DrainLoop`). GPU 에 모델이 하나 올라가 있으므로
   * 병렬로 불러 봐야 서로 기다린다 (설계 §5).
   */
  private readonly loop: DrainLoop;

  constructor(
    private readonly queue: AiQueueService,
    private readonly runner: AiRunnerService,
  ) {
    // 필드 초기화가 아니라 생성자 안에서 만든다 — 매개변수 속성(queue · runner)이
    // 채워진 뒤여야 한다.
    this.loop = new DrainLoop(
      () => this.step(),
      // AI 가 실패해도 서버는 계속 떠 있어야 한다.
      (err) => this.logger.error('AI 워커 실패', err as Error),
    );
  }

  async onModuleInit(): Promise<void> {
    this.kick();
  }

  @Cron(CronExpression.EVERY_30_SECONDS)
  async tick(): Promise<void> {
    await this.drain();
  }

  /** 적재 직후 부른다. 기다리지 않는다 — 실패해도 크론이 받는다. */
  kick(): void {
    this.loop.kick();
  }

  private drain(): Promise<void> {
    return this.loop.drain();
  }

  /**
   * 재시도로 미룬 실행을 그 대기가 지나면 다시 깨운다. **`unref`** 라 이
   * 타이머 때문에 프로세스가 살아 있지 않는다 — 놓쳐도 크론이 받는다.
   */
  private wakeAfter(ms: number): void {
    setTimeout(() => this.kick(), ms).unref?.();
  }

  /** 하나를 꺼내 돌린다. 꺼낼 것이 없으면 false. */
  private async step(): Promise<boolean> {
    const run = await this.queue.lease();
    if (!run) return false;
    const retryIn = await this.runner.runOne(run);
    if (retryIn != null) this.wakeAfter(retryIn);
    return true;
  }
}
