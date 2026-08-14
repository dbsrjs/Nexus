import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { JwtModule } from '@nestjs/jwt';
import { RealtimeGateway } from './realtime.gateway';
import { RealtimeEmitterModule } from './realtime-emitter.module';
import { RoomsService } from './rooms.service';
import { ChannelsModule } from '../channels/channels.module';

/**
 * 게이트웨이는 룸을 계산하려고 ChannelsService 를 쓴다(Task 2 에서 추가).
 * 반대 방향(ChannelsModule → 소켓)은 RealtimeEmitterModule 로만 흐르므로
 * 순환이 생기지 않는다.
 *
 * JwtModule.register({}) — 시크릿은 verifyAsync 호출 시 넘긴다. 모듈 등록
 * 시점에 박으면 resolveJwtSecrets() 가 유일한 해석 지점이라는 규칙이 깨진다.
 */
@Module({
  imports: [ConfigModule, JwtModule.register({}), RealtimeEmitterModule, ChannelsModule],
  providers: [RealtimeGateway, RoomsService],
})
export class RealtimeModule {}
