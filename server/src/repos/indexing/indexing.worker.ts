import { Injectable, Logger, OnModuleInit } from '@nestjs/common';
import { Cron, CronExpression } from '@nestjs/schedule';
import { IndexQueueService } from './index-queue.service';
import { IndexingService } from './indexing.service';
import { DrainLoop } from '../../common/drain-loop';

/**
 * 큐를 비우는 쪽.
 *
 * **`OrphanCleanupService` 와 같은 모양이다**(부팅 1회 + `@Cron`, 실패해도
 * 서버는 떠 있다). 새로 들이는 것이 없다는 것이 DB 큐를 고른 근거였다 (설계 §2).
 *
 * **깨우기(`kick`)는 최적화가 아니다.** 30초를 기다릴 수 없는 계약 검증이
 * 성립하는 조건이기도 하다.
 */
@Injectable()
export class IndexingWorker implements OnModuleInit {
  private readonly logger = new Logger(IndexingWorker.name);
  /** 한 프로세스에서 한 번에 하나만 돈다(`DrainLoop`). 겹치면 같은 작업을 두 번 잡는다. */
  private readonly loop: DrainLoop;

  constructor(
    private readonly queue: IndexQueueService,
    private readonly indexing: IndexingService,
  ) {
    this.loop = new DrainLoop(
      () => this.step(),
      // 인덱싱이 실패해도 서버는 계속 떠 있어야 한다. 다음 회차에 다시 시도한다.
      (err) => this.logger.error('인덱싱 워커 실패', err as Error),
    );
  }

  async onModuleInit(): Promise<void> {
    // 서버가 꺼져 있는 동안 쌓인 것을 30초 더 들고 있을 이유가 없다.
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

  /** 하나를 꺼내 인덱싱한다. 꺼낼 것이 없으면 false — 한 번 깨면 있는 만큼 비운다. */
  private async step(): Promise<boolean> {
    const job = await this.queue.lease();
    if (!job) return false;
    await this.indexing.runOne(job);
    return true;
  }
}
