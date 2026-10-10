import { Module } from '@nestjs/common';
import { JwtModule } from '@nestjs/jwt';
import { ChannelsModule } from '../channels/channels.module';
import { SpacesModule } from '../spaces/spaces.module';
import { RealtimeEmitterModule } from '../realtime/realtime-emitter.module';
import { VoiceController } from './voice.controller';
import { VoiceService } from './voice.service';

/**
 * 음성 채널(20단계). 시크릿은 서명 · 검증 때 넘긴다 — 모듈 등록에 박지 않는다(realtime.module 과 같은 이유).
 * 판정은 ChannelsService 에 묻고, 상태는 RealtimeEmitter 로 알린다.
 */
@Module({
  imports: [JwtModule.register({}), ChannelsModule, SpacesModule, RealtimeEmitterModule],
  controllers: [VoiceController],
  providers: [VoiceService],
  exports: [VoiceService],
})
export class VoiceModule {}
