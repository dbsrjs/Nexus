import { Module } from '@nestjs/common';
import { ChannelsModule } from '../channels/channels.module';
import { SpacesModule } from '../spaces/spaces.module';
import { RealtimeEmitterModule } from '../realtime/realtime-emitter.module';
import { PermissionsController } from './permissions.controller';
import { PermissionsService } from './permissions.service';
import { ChannelMembersService } from './channel-members.service';

/**
 * 채널별 권한 · 비공개 채널 명단(16단계). 단일 테넌트 시절의 옛 모듈을 지우고 다시 썼다 —
 * 전역 역할 · 없는 컬럼을 참조해 살릴 줄이 없었다. **판정은 ChannelsService 에 남는다.**
 */
@Module({
  imports: [ChannelsModule, SpacesModule, RealtimeEmitterModule],
  controllers: [PermissionsController],
  providers: [PermissionsService, ChannelMembersService],
})
export class PermissionsModule {}
