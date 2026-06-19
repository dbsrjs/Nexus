import { INestApplicationContext, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { IoAdapter } from '@nestjs/platform-socket.io';
import { createAdapter } from '@socket.io/redis-adapter';
import { Redis } from 'ioredis';
import { ServerOptions, Server } from 'socket.io';

/**
 * Socket.IO adapter backed by Redis pub/sub (설계서 §1).
 *
 * Enables multi-instance fan-out: an `emit` on one server instance reaches
 * sockets connected to any other instance via the shared Redis channel.
 *
 * Graceful degradation: if Redis is unreachable, `connect()` logs a warning
 * and leaves the adapter factory unset, so `createIOServer` falls back to the
 * default in-memory adapter instead of crashing the app.
 */
export class RedisIoAdapter extends IoAdapter {
  private readonly logger = new Logger(RedisIoAdapter.name);
  private adapterConstructor: ReturnType<typeof createAdapter> | null = null;

  constructor(private readonly app: INestApplicationContext) {
    super(app);
  }

  /**
   * Try to connect pub/sub clients to Redis. Call this BEFORE app.listen().
   * Never throws — on failure we simply skip the Redis adapter.
   */
  async connect(): Promise<void> {
    const config = this.app.get(ConfigService, { strict: false });
    const url =
      config?.get<string>('REDIS_URL') ??
      process.env.REDIS_URL ??
      'redis://localhost:6379';

    // lazyConnect so we can await connect() and catch errors here rather than
    // letting ioredis retry forever in the background.
    const pubClient = new Redis(url, {
      lazyConnect: true,
      maxRetriesPerRequest: 1,
      retryStrategy: () => null, // do not auto-retry during the initial probe
    });
    const subClient = pubClient.duplicate();

    // Avoid unhandled 'error' events taking the process down post-connect.
    pubClient.on('error', (err) =>
      this.logger.warn(`Redis pub 클라이언트 오류: ${err.message}`),
    );
    subClient.on('error', (err) =>
      this.logger.warn(`Redis sub 클라이언트 오류: ${err.message}`),
    );

    try {
      await Promise.all([pubClient.connect(), subClient.connect()]);
      this.adapterConstructor = createAdapter(pubClient, subClient);
      this.logger.log(`Socket.IO Redis 어댑터 연결됨 (${url})`);
    } catch (err) {
      const message = err instanceof Error ? err.message : String(err);
      this.logger.warn(
        `Redis 연결 실패 (${url}) — 인메모리 어댑터로 폴백합니다: ${message}`,
      );
      // Tear down the half-open clients so they stop retrying.
      pubClient.disconnect();
      subClient.disconnect();
      this.adapterConstructor = null;
    }
  }

  createIOServer(port: number, options?: ServerOptions): Server {
    const server: Server = super.createIOServer(port, options);
    if (this.adapterConstructor) {
      server.adapter(this.adapterConstructor);
    }
    return server;
  }
}
