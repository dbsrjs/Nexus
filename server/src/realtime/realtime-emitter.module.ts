import { Module } from '@nestjs/common';
import { RealtimeEmitter } from './realtime-emitter';

/**
 * 의존성이 없는 모듈이다. 이벤트를 쏘고 싶은 모듈(channels · messages · spaces)이
 * 이것만 import 하면 되므로, RealtimeModule 을 향한 역방향 의존이 생기지 않는다.
 */
@Module({
  providers: [RealtimeEmitter],
  exports: [RealtimeEmitter],
})
export class RealtimeEmitterModule {}
