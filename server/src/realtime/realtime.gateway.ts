import { Logger } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import {
  OnGatewayConnection,
  OnGatewayDisconnect,
  SubscribeMessage,
  WebSocketGateway,
  WebSocketServer,
  MessageBody,
  ConnectedSocket,
} from '@nestjs/websockets';
import { Server, Socket } from 'socket.io';
import { Role } from '@prisma/client';
import { ChannelsService } from '../channels/channels.service';

interface SocketUser {
  id: string;
  email: string;
  role: Role;
}

interface AuthedSocket extends Socket {
  data: { user?: SocketUser };
}

/**
 * Common Socket.IO gateway (설계서 §5).
 *
 * Handshake: verifies the JWT (auth.token / Authorization header / ?token=),
 * then joins the socket to a personal room (user:{id}) and to every
 * channel room (channel:{id}) the user may view.
 *
 * Server→client events emitted here: `message:new`, `message:edited`.
 * MessagesService calls emitMessageNew / emitMessageEdited.
 */
@WebSocketGateway({ cors: { origin: true, credentials: true } })
export class RealtimeGateway implements OnGatewayConnection, OnGatewayDisconnect {
  @WebSocketServer()
  server!: Server;

  private readonly logger = new Logger(RealtimeGateway.name);

  constructor(
    private readonly jwt: JwtService,
    private readonly config: ConfigService,
    private readonly channels: ChannelsService,
  ) {}

  async handleConnection(client: AuthedSocket): Promise<void> {
    const token = this.extractToken(client);
    if (!token) {
      this.logger.warn(`소켓 ${client.id} 인증 실패: 토큰 없음`);
      client.disconnect(true);
      return;
    }

    let payload: { sub?: string; email?: string; role?: Role };
    try {
      payload = await this.jwt.verifyAsync(token, {
        secret: this.config.get<string>('JWT_SECRET') ?? this.config.get<string>('JWT_ACCESS_SECRET'),
      });
    } catch {
      this.logger.warn(`소켓 ${client.id} 인증 실패: 토큰 검증 오류`);
      client.disconnect(true);
      return;
    }

    if (!payload?.sub) {
      client.disconnect(true);
      return;
    }

    const user: SocketUser = {
      id: payload.sub,
      email: payload.email ?? '',
      role: (payload.role as Role) ?? Role.member,
    };
    client.data.user = user;

    // Personal room (for targeted pushes) + every viewable channel room.
    client.join(this.userRoom(user.id));
    const channelIds = await this.channels.viewableChannelIds(user.id, user.role);
    for (const id of channelIds) {
      client.join(this.channelRoom(id));
    }

    this.logger.log(`소켓 ${client.id} 연결: user=${user.id}, 채널 ${channelIds.length}개 참여`);
  }

  handleDisconnect(client: AuthedSocket): void {
    const userId = client.data?.user?.id;
    this.logger.log(`소켓 ${client.id} 연결 해제${userId ? ` (user=${userId})` : ''}`);
  }

  /** Client→server: refresh last_read_at marker. Echoes nothing by default. */
  @SubscribeMessage('read')
  handleRead(
    @ConnectedSocket() client: AuthedSocket,
    @MessageBody() body: { channelId?: string },
  ): void {
    const user = client.data?.user;
    if (!user || !body?.channelId) return;
    // last_read_at persistence is owned by the channels phase; here we only
    // relay so other sessions of the same user can sync read state.
    this.server.to(this.userRoom(user.id)).emit('read:synced', {
      channelId: body.channelId,
      at: new Date().toISOString(),
    });
  }

  /** Client→server: lightweight typing indicator (optional, §5). */
  @SubscribeMessage('typing')
  handleTyping(
    @ConnectedSocket() client: AuthedSocket,
    @MessageBody() body: { channelId?: string },
  ): void {
    const user = client.data?.user;
    if (!user || !body?.channelId) return;
    client.to(this.channelRoom(body.channelId)).emit('typing', {
      channelId: body.channelId,
      userId: user.id,
    });
  }

  // ── Server-side emit API (called by MessagesService) ──────────────

  emitMessageNew(channelId: string, message: unknown): void {
    this.server.to(this.channelRoom(channelId)).emit('message:new', message);
  }

  emitMessageEdited(channelId: string, message: unknown): void {
    this.server.to(this.channelRoom(channelId)).emit('message:edited', message);
  }

  /** Push a freshly-created notification to a single user's personal room. */
  emitNotification(userId: string, payload: unknown): void {
    this.server.to(this.userRoom(userId)).emit('notification:new', payload);
  }

  // ── Helpers ───────────────────────────────────────────────────────

  private channelRoom(channelId: string): string {
    return `channel:${channelId}`;
  }

  private userRoom(userId: string): string {
    return `user:${userId}`;
  }

  private extractToken(client: Socket): string | null {
    const auth = client.handshake.auth as { token?: string } | undefined;
    if (auth?.token) {
      return auth.token.replace(/^Bearer\s+/i, '');
    }
    const header = client.handshake.headers?.authorization;
    if (typeof header === 'string' && header.length > 0) {
      return header.replace(/^Bearer\s+/i, '');
    }
    const queryToken = client.handshake.query?.token;
    if (typeof queryToken === 'string' && queryToken.length > 0) {
      return queryToken;
    }
    return null;
  }
}
