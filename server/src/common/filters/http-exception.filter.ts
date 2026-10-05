import {
  ArgumentsHost,
  Catch,
  ExceptionFilter,
  HttpException,
  HttpStatus,
  Logger,
} from '@nestjs/common';
import { Request, Response } from 'express';

/**
 * Global HTTP exception filter. Produces a consistent error envelope:
 *   { statusCode, message, error, path, timestamp }
 */
@Catch()
export class HttpExceptionFilter implements ExceptionFilter {
  private readonly logger = new Logger(HttpExceptionFilter.name);

  catch(exception: unknown, host: ArgumentsHost): void {
    const ctx = host.switchToHttp();
    const response = ctx.getResponse<Response>();
    const request = ctx.getRequest<Request>();

    const status =
      exception instanceof HttpException
        ? exception.getStatus()
        : HttpStatus.INTERNAL_SERVER_ERROR;

    let message: string | string[] = 'Internal server error';
    let error = 'InternalServerError';

    if (exception instanceof HttpException) {
      const res = exception.getResponse();
      if (typeof res === 'string') {
        message = res;
      } else if (res && typeof res === 'object') {
        const body = res as Record<string, unknown>;
        message = (body.message as string | string[]) ?? exception.message;
        error = (body.error as string) ?? exception.name;

        // **`Retry-After` 는 헤더로 내보낸다.** 이 필터는 본문을 일정한
        // 봉투로 다시 빚으므로 커스텀 필드가 그대로 사라진다 — 10-2b 가
        // 본문에 실었다고 믿고 있었는데 10-3a 의 계약 검증이 그것을 잡았다.
        // 헤더는 HTTP 표준(RFC 9110 §10.2.3)이라 클라이언트가 읽기도 쉽다.
        const retryAfter = body.retryAfter;
        if (typeof retryAfter === 'number' && Number.isFinite(retryAfter)) {
          response.setHeader('Retry-After', String(retryAfter));
        }
      }
    } else if (exception instanceof Error) {
      // **원문을 응답에 싣지 않는다.** HttpException 이 아닌 Error 는 의도하지 않은
      // 실패다 — Prisma 오류는 테이블 · 컬럼 · DB 호스트를, 설정 오류는 키 길이를
      // 담고 있다. 공개 경로(OAuth 콜백 · 웹훅)마다 감싸 막아 왔는데(10-2a), 새
      // 경로가 그것을 잊으면 곧바로 샌다. 여기서 한 번에 접고 원인은 로그로만 남긴다.
      this.logger.error(exception.message, exception.stack);
    } else {
      this.logger.error(`Error 가 아닌 예외: ${String(exception)}`);
    }

    response.status(status).json({
      statusCode: status,
      message,
      error,
      path: request.url,
      timestamp: new Date().toISOString(),
    });
  }
}
