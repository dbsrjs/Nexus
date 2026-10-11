import { ExecutionContext, Injectable } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { AuthGuard } from '@nestjs/passport';
import { IS_PUBLIC_KEY } from '../../common/decorators/public.decorator';

/**
 * Guards routes with the passport-jwt strategy. On success it populates
 * request.user = { id, email, role } (see JwtStrategy.validate).
 *
 * Registered globally as APP_GUARD, so every route requires a valid JWT
 * unless the handler/controller is marked with @Public().
 */
@Injectable()
export class JwtAuthGuard extends AuthGuard('jwt') {
  constructor(private readonly reflector: Reflector) {
    super();
  }

  canActivate(context: ExecutionContext) {
    // 소켓은 핸드셰이크 미들웨어가 이미 인증했다(realtime.gateway.ts). NestJS 12 부터 전역
    // 가드가 게이트웨이 메시지에도 걸리는데, passport 는 HTTP 요청의 헤더를 읽으려다
    // 던져 모든 소켓 메시지(rooms:sync · read · typing)가 막혔다. HTTP 만 여기서 본다.
    if (context.getType() !== 'http') return true;
    const isPublic = this.reflector.getAllAndOverride<boolean>(IS_PUBLIC_KEY, [
      context.getHandler(),
      context.getClass(),
    ]);
    if (isPublic) return true;
    return super.canActivate(context);
  }
}
