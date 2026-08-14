import { Module } from '@nestjs/common';
import { SpacesService } from './spaces.service';
import { SpacesController } from './spaces.controller';
import { InvitesController } from './invites.controller';
import { SpaceGuard } from './guards/space.guard';
import { SpaceRoleGuard } from './guards/space-role.guard';
import { RealtimeEmitterModule } from '../realtime/realtime-emitter.module';

/**
 * 이후 모든 기능 모듈이 SpaceGuard 에 의존한다. 가드를 여기서 export 해
 * 각 모듈이 @UseGuards(SpaceGuard) 로 가져다 쓴다 (PrismaModule 이 @Global 이라
 * 가드가 PrismaService 를 주입받는 데 별도 배선이 필요 없다).
 */
@Module({
  imports: [RealtimeEmitterModule],
  controllers: [SpacesController, InvitesController],
  providers: [SpacesService, SpaceGuard, SpaceRoleGuard],
  exports: [SpacesService, SpaceGuard, SpaceRoleGuard],
})
export class SpacesModule {}
