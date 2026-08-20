import { Module } from '@nestjs/common';
import { IssuesService } from './issues.service';
import { IssuesController } from './issues.controller';
import { SpacesModule } from '../spaces/spaces.module';
import { RealtimeEmitterModule } from '../realtime/realtime-emitter.module';

/**
 * 이슈 · 라벨 · 댓글을 함께 둔다(messages 가 reactions · mentions 를 품은 것과
 * 같다 — 라벨과 댓글은 이슈 없이는 뜻이 없다). **스프린트는 9-3 에서 별도
 * 모듈로 만든다** — 자기 수명주기와 번다운을 갖는 독립된 것이라, 이슈에
 * 종속시키면 이 모듈이 부푼다.
 */
@Module({
  imports: [SpacesModule, RealtimeEmitterModule],
  controllers: [IssuesController],
  providers: [IssuesService],
  exports: [IssuesService],
})
export class IssuesModule {}
