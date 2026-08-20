import { Controller, Delete, Get, HttpCode, HttpStatus, Post } from '@nestjs/common';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { OauthService } from './oauth.service';

/**
 *   POST   /api/me/connections/github/start
 *   GET    /api/me/connections
 *   DELETE /api/me/connections/github
 *
 * 사용자 단위라 스페이스 밑이 아니다 — `SpaceGuard` 를 걸 자리가 없다.
 * 빈 @Controller() 라 라우트가 /api 루트에 붙는다(UsersController 와 같다).
 */
@Controller()
export class OauthController {
  constructor(private readonly oauth: OauthService) {}

  @Post('me/connections/github/start')
  start(@CurrentUser('id') userId: string) {
    return this.oauth.start(userId);
  }

  /** 토큰은 실리지 않는다. */
  @Get('me/connections')
  list(@CurrentUser('id') userId: string) {
    return this.oauth.list(userId);
  }

  /** 내 토큰을 지우는 일이지 연동을 끝내는 일이 아니다 — 웹훅은 남는다. */
  @Delete('me/connections/github')
  @HttpCode(HttpStatus.NO_CONTENT)
  disconnect(@CurrentUser('id') userId: string) {
    return this.oauth.disconnect(userId);
  }
}
