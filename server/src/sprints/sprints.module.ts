import { Module } from '@nestjs/common';
import { SprintsService } from './sprints.service';
import { SprintsController } from './sprints.controller';
import { SpacesModule } from '../spaces/spaces.module';

/**
 * 이슈와 별도 모듈이다 — 스프린트는 자기 수명주기와 번다운을 갖는 독립된
 * 것이라, `issues/` 에 넣으면 그 모듈이 부푼다(설계 §1).
 */
@Module({
  imports: [SpacesModule],
  controllers: [SprintsController],
  providers: [SprintsService],
  exports: [SprintsService],
})
export class SprintsModule {}
