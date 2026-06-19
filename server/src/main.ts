import 'reflect-metadata';
import { NestFactory } from '@nestjs/core';
import { ValidationPipe } from '@nestjs/common';
import type { Request, Response, NextFunction } from 'express';
import { AppModule } from './app.module';
import { RedisIoAdapter } from './realtime/redis-io.adapter';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);

  app.setGlobalPrefix('api');

  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      transform: true,
    }),
  );

  app.enableCors();

  // API 응답은 브라우저가 캐싱하지 않도록 한다. (이게 없으면 GET /notifications 등이
  // HTTP 캐시되어 새 알림·메시지가 생겨도 화면이 옛 응답을 그대로 보여준다.)
  app.use((_req: Request, res: Response, next: NextFunction) => {
    res.setHeader('Cache-Control', 'no-store');
    next();
  });

  // Socket.IO Redis 어댑터 (멀티 인스턴스 fan-out, 설계서 §1).
  // Redis 미연결 시 connect() 내부에서 경고 후 인메모리 어댑터로 폴백한다.
  const redisIoAdapter = new RedisIoAdapter(app);
  await redisIoAdapter.connect();
  app.useWebSocketAdapter(redisIoAdapter);

  const port = process.env.PORT ? Number(process.env.PORT) : 3000;
  await app.listen(port);
  // eslint-disable-next-line no-console
  console.log(`ONE 워크스페이스 server listening on http://localhost:${port}/api`);
}

bootstrap();
