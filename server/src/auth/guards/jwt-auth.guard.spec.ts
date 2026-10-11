import { ExecutionContext } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { JwtAuthGuard } from './jwt-auth.guard';

/**
 * 전역 가드가 HTTP 밖(소켓 메시지)에서 passport 를 부르지 않는지.
 *
 * NestJS 12 로 올리며 전역 가드가 게이트웨이 메시지에도 걸리게 됐고, passport 가 소켓
 * 컨텍스트에서 `headers.authorization` 을 읽으려다 던져 rooms:sync · read 가 전부 막혔다
 * (check:realtime 이 잡았다). 소켓 인증은 핸드셰이크 미들웨어가 맡는다.
 */
describe('JwtAuthGuard', () => {
  function contextOf(type: string): ExecutionContext {
    return {
      getType: () => type,
      getHandler: () => () => undefined,
      getClass: () => class {},
    } as unknown as ExecutionContext;
  }

  it('소켓 메시지는 passport 를 부르지 않고 통과시킨다', async () => {
    const reflector = new Reflector();
    const peek = jest.spyOn(reflector, 'getAllAndOverride');
    const guard = new JwtAuthGuard(reflector);

    // passport 로 넘어가면 Promise 가 거부된다 — 기다려서 실패로 받는다
    await expect(Promise.resolve(guard.canActivate(contextOf('ws')))).resolves.toBe(true);
    expect(peek).not.toHaveBeenCalled();
  });

  it('@Public() 인 HTTP 경로는 통과시킨다', () => {
    const reflector = new Reflector();
    jest.spyOn(reflector, 'getAllAndOverride').mockReturnValue(true);
    const guard = new JwtAuthGuard(reflector);

    expect(guard.canActivate(contextOf('http'))).toBe(true);
  });
});
