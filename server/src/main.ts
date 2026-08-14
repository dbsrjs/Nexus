import 'reflect-metadata';
import { NestFactory } from '@nestjs/core';
import { Logger, ValidationPipe } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import cookieParser from 'cookie-parser';
import type { Request, Response, NextFunction } from 'express';
import { AppModule } from './app.module';
import { enableBigIntSerialization } from './common/bigint-serializer';
import { SocketIoAdapter } from './realtime/socket-io.adapter';

// 모듈 로딩보다 먼저 걸어 둔다. 이게 없으면 bigint 컬럼이 섞인 응답이 전부 500 이다.
enableBigIntSerialization();

async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  const config = app.get(ConfigService);
  const logger = new Logger('Bootstrap');

  app.setGlobalPrefix('api');

  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      forbidNonWhitelisted: true,
      transform: true,
    }),
  );

  // 리프레시 토큰 HttpOnly 쿠키를 읽기 위해 필요하다 (auth.controller.ts).
  app.use(cookieParser());

  // CORS 는 환경변수 화이트리스트로만 연다. 이전의 무조건 enableCors() 는
  // 저장소를 공개하고 운영에 올리는 순간 그대로 위험이 된다 (docs/백엔드-설계.md §6).
  // 네이티브 앱은 CORS 대상이 아니므로 여기서 막히지 않는다.
  const origins = (config.get<string>('CORS_ORIGINS') ?? '')
    .split(',')
    .map((o) => o.trim())
    .filter(Boolean);

  if (origins.length > 0) {
    app.enableCors({ origin: origins, credentials: true });
    logger.log(`CORS 허용 오리진: ${origins.join(', ')}`);
  } else {
    logger.warn(
      'CORS_ORIGINS 가 비어 있습니다 — 브라우저에서 오는 요청은 모두 차단됩니다. ' +
        '네이티브 앱만 쓸 때는 정상입니다.',
    );
  }

  // 소켓에도 같은 CORS 화이트리스트를 적용한다.
  app.useWebSocketAdapter(new SocketIoAdapter(app));

  // API 응답은 브라우저가 캐싱하지 않도록 한다. (이게 없으면 GET 응답이
  // HTTP 캐시되어 새 데이터가 생겨도 화면이 옛 응답을 그대로 보여준다.)
  app.use((_req: Request, res: Response, next: NextFunction) => {
    res.setHeader('Cache-Control', 'no-store');
    next();
  });

  // NOTE: Redis 어댑터는 인스턴스가 2개 이상이 될 때 SocketIoAdapter 에 붙인다.

  const port = config.get<string>('PORT') ? Number(config.get<string>('PORT')) : 3000;
  await app.listen(port);
  logger.log(`Nexus server listening on http://localhost:${port}/api`);
}

bootstrap();
