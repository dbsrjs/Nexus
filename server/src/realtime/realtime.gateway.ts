import { Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { JwtService } from '@nestjs/jwt';
import {
  ConnectedSocket,
  MessageBody,
  OnGatewayConnection,
  OnGatewayDisconnect,
  OnGatewayInit,
  SubscribeMessage,
  WebSocketGateway,
} from '@nestjs/websockets';
import type { Server, Socket } from 'socket.io';
import { validate } from 'class-validator';
import { plainToInstance } from 'class-transformer';
import { resolveJwtSecrets } from '../config/jwt.config';
import { RealtimeEmitter } from './realtime-emitter';
import { RoomsService } from './rooms.service';
import { isPinnedRoom, room } from './rooms';
import { SocketReadDto } from './dto/socket-read.dto';
import { ChannelsService } from '../channels/channels.service';

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
    private readonly rooms: RoomsService,
    private readonly channels: ChannelsService,
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

  /**
   * Nest 는 이 메서드가 돌려주는 Promise 를 await 하지 않는다
   * (WebSocketsController.subscribeConnectionEvent). syncRooms 가 리젝트되면
   * try/catch 없이는 unhandled rejection 이 되어 Node 가 프로세스 전체를
   * 종료시킨다 — 한 사용자의 접속 시점 DB 순간 장애가 접속 중인 전원의
   * 연결을 끊는 결과다.
   *
   * 실패해도 연결은 끊지 않는다. 룸이 비면 그 소켓은 실시간 이벤트를 못
   * 받을 뿐이고 앱이 rooms:sync 로 다시 부르면 회복된다. 끊으면 재연결
   * 폭풍이 된다(docs/백엔드-설계.md §7).
   */
  async handleConnection(client: AuthedSocket): Promise<void> {
    client.join(room.user(client.data.userId));
    try {
      const joined = await this.syncRooms(client);
      this.logger.log(
        `소켓 ${client.id} 연결: user=${client.data.userId}, ` +
          `스페이스 ${joined.spaceIds.length} · 채널 ${joined.channelIds.length}`,
      );
    } catch (err) {
      this.logger.error(`연결 시 룸 조인 실패 (user=${client.data.userId})`, err as Error);
    }
  }

  handleDisconnect(client: AuthedSocket): void {
    this.logger.log(`소켓 ${client.id} 연결 해제 (user=${client.data?.userId})`);
  }

  /**
   * 클라이언트가 룸 재계산을 요청한다. 연결 직후에도 서버가 스스로 부른다.
   *
   * ack 으로 룸 목록을 돌려주는 이유: 앱이 "지금 어떤 채널을 실시간으로 받고
   * 있는지" 를 알아야 REST 로 다시 물어볼 대상을 정할 수 있다.
   */
  @SubscribeMessage('rooms:sync')
  async handleRoomsSync(@ConnectedSocket() client: AuthedSocket) {
    try {
      const joined = await this.syncRooms(client);
      return { ok: true, spaces: joined.spaceIds, channels: joined.channelIds };
    } catch (err) {
      this.logger.error(`rooms:sync 실패 (user=${client.data.userId})`, err as Error);
      return { ok: false, error: 'rooms_sync_failed' };
    }
  }

  /**
   * 읽음 위치를 저장한다. REST POST /read 와 같은 ChannelsService.markRead 를
   * 지나가므로 두 경로의 동작이 갈릴 수 없다.
   *
   * 잘못된 페이로드로 **연결을 끊지 않는다.** 앱이 룸을 재계산하는 사이의 경합
   * 으로도 생길 수 있는 일이고, 끊으면 재연결 폭풍이 된다.
   */
  @SubscribeMessage('read')
  async handleRead(
    @ConnectedSocket() client: AuthedSocket,
    @MessageBody() body: unknown,
  ) {
    const dto = plainToInstance(SocketReadDto, body ?? {});
    const errors = await validate(dto, {
      whitelist: true,
      forbidNonWhitelisted: true,
    });
    if (errors.length > 0) {
      return { ok: false, error: 'invalid_payload' };
    }

    // 소켓에 역할을 담지 않으므로 매번 DB 에서 읽는다. 클라이언트가 보낸
    // spaceId · channelId 를 그대로 믿지 않는다.
    const member = await this.rooms.findMember(client.data.userId, dto.spaceId);
    if (!member) {
      return { ok: false, error: 'not_a_member' };
    }

    try {
      await this.channels.markRead(dto.channelId, member, {
        lastReadMessageId: dto.lastReadMessageId,
      });
      return { ok: true };
    } catch (err) {
      // assertCanView 의 404 뿐 아니라 DB/인프라 오류도 여기로 온다. 클라이언트에는
      // 이유를 세분해 알리지 않는다 — 채널 존재 여부를 흘리게 된다(403 대신 404 를
      // 쓰는 것과 같은 이유). 대신 서버 로그에 남긴다: 읽음 저장 실패가 조용히
      // 지나가는 게 이 태스크가 없애려던 사고(전환 계획 §3.5-3)와 같은 양상이다.
      this.logger.error(
        `읽음 저장 실패 (user=${client.data.userId}, space=${dto.spaceId}, channel=${dto.channelId})`,
        err as Error,
      );
      return { ok: false, error: 'read_failed' };
    }
  }

  /**
   * 룸을 **전체 교체**한다. 차집합을 계산하면 상태가 어긋날 여지가 생기는데,
   * 스페이스 수가 한 자릿수인 이 프로젝트에서 아낄 것이 없다.
   *
   * socket.id 룸(Socket.IO 가 자동으로 넣는다)과 개인 룸은 떠나지 않는다.
   * socket.id 룸을 떠나면 그 소켓에 개별 emit 이 안 된다.
   */
  private async syncRooms(client: AuthedSocket) {
    const next = await this.rooms.computeRooms(client.data.userId);

    for (const name of [...client.rooms]) {
      if (!isPinnedRoom(name, client.id)) {
        client.leave(name);
      }
    }

    for (const spaceId of next.spaceIds) client.join(room.space(spaceId));
    for (const channelId of next.channelIds) client.join(room.channel(channelId));

    return next;
  }
}
