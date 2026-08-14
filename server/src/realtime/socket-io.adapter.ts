import { INestApplicationContext } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { IoAdapter } from '@nestjs/platform-socket.io';
import type { ServerOptions } from 'socket.io';

/**
 * 소켓에도 REST 와 같은 CORS 화이트리스트를 적용한다.
 *
 * @WebSocketGateway 데코레이터 옵션은 정적이라 ConfigService 를 읽을 수 없다.
 * 무조건 허용(origin: true)으로 두면 저장소를 공개하고 운영에 올리는 순간
 * 그대로 위험이 된다 (docs/백엔드-설계.md §6, main.ts 의 CORS 주석과 같은 이유).
 *
 * Redis 어댑터를 붙이는 것도 나중에 여기다 (스펙 §6).
 */
export class SocketIoAdapter extends IoAdapter {
  private readonly origins: string[];

  constructor(app: INestApplicationContext) {
    super(app);
    this.origins = (app.get(ConfigService).get<string>('CORS_ORIGINS') ?? '')
      .split(',')
      .map((o) => o.trim())
      .filter(Boolean);
  }

  createIOServer(port: number, options?: ServerOptions) {
    return super.createIOServer(port, {
      ...options,
      cors: { origin: this.origins, credentials: true },
    });
  }
}
