import { Injectable, Logger } from '@nestjs/common';
import type { Server } from 'socket.io';
import { room } from './rooms';

/**
 * 룸에 이벤트를 쏘는 것만 한다. 다른 서비스에 의존하지 않는다.
 *
 * 룸을 계산하는 쪽(RealtimeGateway → ChannelsService)과 쏘는 쪽을 분리해
 * ChannelsModule ↔ RealtimeModule 순환을 구조로 없앤다. forwardRef 는 순환을
 * 없애는 게 아니라 초기화 순서로 미루는 것이라 쓰지 않는다.
 */
@Injectable()
export class RealtimeEmitter {
  private readonly logger = new Logger(RealtimeEmitter.name);
  private server: Server | null = null;
  private warned = false;

  /** 게이트웨이가 afterInit 에서 한 번 넣어 준다. */
  bind(server: Server): void {
    this.server = server;
  }

  toUser(userId: string, event: string, payload: unknown): void {
    this.emit(room.user(userId), event, payload);
  }

  toSpace(spaceId: string, event: string, payload: unknown): void {
    this.emit(room.space(spaceId), event, payload);
  }

  toChannel(channelId: string, event: string, payload: unknown): void {
    this.emit(room.channel(channelId), event, payload);
  }

  /**
   * 그 사용자의 소켓 전부를 주어진 룸에서 **서버가 직접** 뺀다(16단계 설계 D13a).
   *
   * `rooms:invalidate` 는 앱에게 다시 계산해 달라는 부탁일 뿐이다. 고친 클라이언트가
   * `rooms:sync` 를 부르지 않으면 내보내진 뒤에도 그 스페이스의 메시지를 받는다.
   */
  evict(userId: string, rooms: string[]): void {
    if (!this.server || rooms.length === 0) return;
    this.server.in(room.user(userId)).socketsLeave(rooms);
  }

  private emit(target: string, event: string, payload: unknown): void {
    if (!this.server) {
      // 부팅 순서상 afterInit 이 첫 요청보다 먼저다. 그래도 여기서 던지지는
      // 않는다 — 실시간이 없다고 REST 응답이 500 이 될 이유가 없다.
      if (!this.warned) {
        this.logger.warn('소켓 서버가 아직 바인딩되지 않았습니다. 이벤트를 버립니다.');
        this.warned = true;
      }
      return;
    }
    this.server.to(target).emit(event, payload);
  }
}
