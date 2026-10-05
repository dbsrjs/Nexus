import { Body, Controller, Get, Header, HttpCode, HttpStatus, Logger, Post, Query, Res } from '@nestjs/common';
import type { Response } from 'express';
import { Public } from '../common/decorators/public.decorator';
import { OauthService } from './oauth.service';
import {
  CALLBACK_FAILURE_HTML,
  CALLBACK_SUCCESS_HTML,
  CONFIRM_PAGE_CSP,
  confirmPage,
} from './callback-page';
import { OauthCallbackFormDto } from './dto/oauth-callback-form.dto';

/**
 * /api/auth/github/callback — **브라우저가 온다.**
 *
 * `@Public()` 인 이유는 GitHub 이 리다이렉트로 보낸 브라우저에 우리 JWT 가
 * 실릴 수 없어서다. 요청자가 누구인지는 `state` 서명이 말해 준다 (설계 §3).
 *
 * **두 단계다(2026-10-05 보안 점검).** GitHub 이 돌려보낸 GET 은 어느 Nexus 계정에
 * 붙는지 보여 주는 확인 화면만 그리고, 사람이 [연결] 을 누른 POST 가 토큰을 교환한다.
 * `state` 가 이 브라우저가 아니라 연결을 시작한 계정에 묶여 있어, 남이 시작한 주소를
 * 열면 내 GitHub 토큰이 남의 계정에 붙던 경로를 끊는다(callback-page.ts 의 `confirmPage`).
 *
 * 주소를 `/api/auth/github/callback` 으로 둔 것은 `.env.example` 이 이미
 * 그렇게 적고 있기 때문이다.
 */
@Controller('auth/github')
export class OauthCallbackController {
  private readonly logger = new Logger(OauthCallbackController.name);

  constructor(private readonly oauth: OauthService) {}

  @Public()
  @Get('callback')
  @Header('content-type', 'text/html; charset=utf-8')
  async confirm(
    @Res({ passthrough: true }) res: Response,
    @Query('code') code?: string,
    @Query('state') state?: string,
  ): Promise<string> {
    // DB 장애는 아래 POST 와 같은 이유로 실패 화면으로 접는다 — 전역 필터가 원문을 접어도
    // 브라우저가 읽는 화면은 JSON 이 아니라 HTML 이어야 한다.
    try {
      const account = await this.oauth.previewGithub(code, state);
      if (!account || !code || !state) return CALLBACK_FAILURE_HTML;
      res.setHeader('Content-Security-Policy', CONFIRM_PAGE_CSP);
      return confirmPage(account, code, state);
    } catch (err) {
      this.logger.error(
        `GitHub 콜백 확인 화면 중 예외: ${(err as Error).message}`,
        (err as Error).stack,
      );
      return CALLBACK_FAILURE_HTML;
    }
  }

  @Public()
  @Post('callback')
  @HttpCode(HttpStatus.OK)
  @Header('content-type', 'text/html; charset=utf-8')
  async callback(@Body() form: OauthCallbackFormDto): Promise<string> {
    // completeGithub() 안의 verifyState · GithubOauthClient 는 던지지 않지만
    // this.prisma.$transaction(...) 은 DB 장애(P1001 등)에서 throw 할 수
    // 있다. 이 라우트는 @Public() 이라 브라우저가 인증 없이 바로 읽는다 —
    // 어떤 예외든 실패 화면으로 접고, 원인은 로그로만 남긴다 — 운영자는 알아야
    // 하지만 브라우저는 몰라도 된다.
    let ok: boolean;
    try {
      ok = await this.oauth.completeGithub(form.code, form.state);
    } catch (err) {
      this.logger.error(
        `GitHub 콜백 처리 중 예외: ${(err as Error).message}`,
        (err as Error).stack,
      );
      ok = false;
    }

    // 실패해도 상태 코드는 200 이다. 이 응답을 읽는 것은 사람의 브라우저이고,
    // 왜 실패했는지를 나눠 알려 주면 공격자에게 힌트가 된다.
    return ok ? CALLBACK_SUCCESS_HTML : CALLBACK_FAILURE_HTML;
  }
}
