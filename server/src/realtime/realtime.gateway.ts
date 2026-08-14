import { Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { JwtService } from '@nestjs/jwt';
import {
  OnGatewayConnection,
  OnGatewayDisconnect,
  OnGatewayInit,
  WebSocketGateway,
} from '@nestjs/websockets';
import type { Server, Socket } from 'socket.io';
import { resolveJwtSecrets } from '../config/jwt.config';
import { RealtimeEmitter } from './realtime-emitter';
import { room } from './rooms';

/** 인증을 통과한 소켓. 역할은 담지 않는다 — 스페이스마다 다르다. */
interface AuthedSocket extends Socket {
  data: { userId: string };
}

/**
 * 소켓 게이트웨이 (docs/백엔드-설계.md §5).
 *
 * 인증은 handleConnection 이 아니라 **미들웨어**에서 한다. handleConnection 안에서
 * disconnect() 하면 클라이언트는 이유 없이 끊긴 것만 보지만, 미들웨어에서
 * next(Error) 를 하면 앱이 connect_error 로 이유를 받는다. 5단계 앱은 "토큰이
 * 만료돼 재로그인" 과 "서버가 죽음" 을 구분해야 한다.
 *
 * 토큰은 handshake.auth.token 만 받는다. 쿼리스트링은 액세스 로그·프록시 로그에
 * 토큰을 남긴다 (전환 계획 §3.5).
 */
@WebSocketGateway()
export class RealtimeGateway
  implements OnGatewayInit, OnGatewayConnection, OnGatewayDisconnect
{
  private readonly logger = new Logger(RealtimeGateway.name);
  private readonly accessSecret: string;

  constructor(
    private readonly jwt: JwtService,
    config: ConfigService,
    private readonly emitter: RealtimeEmitter,
  ) {
    // 시크릿 해석은 부팅 시 한 번. 미설정이면 여기서 부팅이 중단된다.
    this.accessSecret = resolveJwtSecrets(config).accessSecret;
  }

  afterInit(server: Server): void {
    this.emitter.bind(server);

    server.use(async (socket, next) => {
      const auth = socket.handshake.auth as { token?: string } | undefined;
      const token = auth?.token?.replace(/^Bearer\s+/i, '');

      if (!token) {
        next(new Error('unauthorized'));
        return;
      }

      try {
        const payload = await this.jwt.verifyAsync<{ sub?: string }>(token, {
          secret: this.accessSecret,
        });
        if (!payload?.sub) {
          next(new Error('unauthorized'));
          return;
        }
        socket.data.userId = payload.sub;
        next();
      } catch {
        next(new Error('unauthorized'));
      }
    });
  }

  async handleConnection(client: AuthedSocket): Promise<void> {
    client.join(room.user(client.data.userId));
    this.logger.log(`소켓 ${client.id} 연결: user=${client.data.userId}`);
  }

  handleDisconnect(client: AuthedSocket): void {
    this.logger.log(`소켓 ${client.id} 연결 해제 (user=${client.data?.userId})`);
  }
}
