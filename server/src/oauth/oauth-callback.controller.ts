import { Controller, Get, Header, Logger, Query } from '@nestjs/common';
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
  private readonly logger = new Logger(OauthCallbackController.name);

  constructor(private readonly oauth: OauthService) {}

  @Public()
  @Get('callback')
  @Header('content-type', 'text/html; charset=utf-8')
  async callback(
    @Query('code') code?: string,
    @Query('state') state?: string,
  ): Promise<string> {
    // completeGithub() 안의 verifyState · GithubOauthClient 는 던지지 않지만
    // this.prisma.$transaction(...) 은 DB 장애(P1001 등)에서 throw 할 수
    // 있다. 이 라우트는 @Public() 이라 브라우저가 인증 없이 바로 읽는다 —
    // 전역 예외 필터가 HttpException 이 아닌 Error 의 message 를 그대로
    // 응답 바디에 실어 주므로, 여기서 잡지 않으면 DB 호스트 · 포트 같은
    // 설정 세부가 밖으로 샌다. 어떤 예외든 실패 화면으로 접고, 원인은
    // 로그로만 남긴다 — 운영자는 알아야 하지만 브라우저는 몰라도 된다.
    let ok: boolean;
    try {
      ok = await this.oauth.completeGithub(code, state);
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
