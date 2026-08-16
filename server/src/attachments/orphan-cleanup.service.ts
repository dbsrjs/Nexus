import { Injectable, Logger, OnModuleInit } from '@nestjs/common';
import { Cron, CronExpression } from '@nestjs/schedule';
import { AttachmentsService } from './attachments.service';

/**
 * 연결되지 못한 첨부를 주기적으로 지운다.
 *
 * **이것이 시스템의 유일한 자동 삭제다**(설계 §3). 메시지에 연결된 첨부는
 * 무엇으로도 만료되지 않는다 — 오브젝트 스토리지에 수명주기 규칙을 걸지 않는
 * 것이 "무기한 보관"의 실질적 보장이고, 이 작업은 그 예외가 아니라
 * **아무에게도 보이지 않는 파일**만 걷어낸다.
 *
 * 한 시간마다 도는 이유: 지우는 기준은 24시간이므로 정확한 시각이 중요하지
 * 않다. 자주 돌수록 최대 지연만 줄어든다.
 *
 * 인스턴스가 여러 개가 되면 이 작업이 중복으로 돈다. 삭제가 멱등이라 결과는
 * 같지만, 그때는 한 인스턴스만 돌도록 잠금을 두어야 한다(Redis 어댑터를
 * 되살리는 시점과 같은 문제다).
 */
@Injectable()
export class OrphanCleanupService implements OnModuleInit {
  private readonly logger = new Logger(OrphanCleanupService.name);

  constructor(private readonly attachments: AttachmentsService) {}

  /**
   * 부팅 때도 한 번 돈다.
   *
   * 서버가 며칠 꺼져 있었으면 그동안 쌓인 것을 한 시간 더 들고 있을 이유가
   * 없다. 겸사겸사 이 경로를 손으로 확인할 수 있는 유일한 계기이기도 하다 —
   * 24시간을 기다릴 수 없어 검증 스크립트에는 넣지 못했다.
   */
  async onModuleInit(): Promise<void> {
    await this.run();
  }

  @Cron(CronExpression.EVERY_HOUR)
  async run(): Promise<void> {
    try {
      await this.attachments.cleanupOrphans();
    } catch (error) {
      // 정리가 실패해도 서버는 계속 떠 있어야 한다. 다음 회차에 다시 시도한다.
      this.logger.error('고아 첨부 정리 실패', error as Error);
    }
  }
}
