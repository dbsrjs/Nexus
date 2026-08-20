import { Controller, Get, Header, Query } from '@nestjs/common';
import { Public } from '../common/decorators/public.decorator';
import { OauthService } from './oauth.service';
import { CALLBACK_FAILURE_HTML, CALLBACK_SUCCESS_HTML } from './callback-page';

/**
 * GET /api/auth/github/callback — **브라우저가 온다.**
 *
 * `@Public()` 인 이유는 GitHub 이 리다이렉트로 보낸 브라우저에 우리 JWT 가
 * 실릴 수 없어서다. 요청자가 누구인지는 `state` 서명이 말해 준다 (설계 §3).
 *
 * 주소를 `/api/auth/github/callback` 으로 둔 것은 `.env.example` 이 이미
 * 그렇게 적고 있기 때문이다.
 */
@Controller('auth/github')
export class OauthCallbackController {
  constructor(private readonly oauth: OauthService) {}

  @Public()
  @Get('callback')
  @Header('content-type', 'text/html; charset=utf-8')
  async callback(
    @Query('code') code?: string,
    @Query('state') state?: string,
  ): Promise<string> {
    const ok = await this.oauth.completeGithub(code, state);

    // 실패해도 상태 코드는 200 이다. 이 응답을 읽는 것은 사람의 브라우저이고,
    // 왜 실패했는지를 나눠 알려 주면 공격자에게 힌트가 된다.
    return ok ? CALLBACK_SUCCESS_HTML : CALLBACK_FAILURE_HTML;
  }
}
