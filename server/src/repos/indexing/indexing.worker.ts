import { Injectable, Logger, OnModuleInit } from '@nestjs/common';
import { Cron, CronExpression } from '@nestjs/schedule';
import { IndexQueueService } from './index-queue.service';
import { IndexingService } from './indexing.service';

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
  /** 한 프로세스에서 한 번에 하나만 돈다. 겹치면 같은 작업을 두 번 잡는다. */
  private running = false;

  constructor(
    private readonly queue: IndexQueueService,
    private readonly indexing: IndexingService,
  ) {}

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
    void this.drain();
  }

  /**
   * 도는 중에 깨우기가 왔는가. `lease()` 가 「비었다」를 본 직후 적재된
   * 작업의 `kick()` 이 `running` 에 막혀 버려지면 30초 크론까지 밀린다 —
   * 13-2 에서 `AiWorker` 의 같은 모양이 계약 검증을 간헐적으로 깨뜨려 찾았다.
   */
  private wanted = false;

  private async drain(): Promise<void> {
    if (this.running) {
      this.wanted = true;
      return;
    }
    this.running = true;
    try {
      // 한 번 깨면 있는 만큼 비운다. 저장소가 여럿이어도 한 회차에 끝난다.
      do {
        this.wanted = false;
        for (;;) {
          const job = await this.queue.lease();
          if (!job) break;
          await this.indexing.runOne(job);
        }
      } while (this.wanted);
    } catch (err) {
      // 인덱싱이 실패해도 서버는 계속 떠 있어야 한다. 다음 회차에 다시 시도한다.
      this.logger.error('인덱싱 워커 실패', err as Error);
    } finally {
      this.running = false;
    }
  }
}
