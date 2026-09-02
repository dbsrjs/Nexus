import {
  BadRequestException,
  Controller,
  DefaultValuePipe,
  Get,
  ParseIntPipe,
  Query,
  ServiceUnavailableException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { resolveGithubOauth } from '../config/oauth.config';
import { GithubOauthClient } from '../oauth/github-oauth.client';
import { OauthService } from '../oauth/oauth.service';
import { toGithubHttpError } from './github-error';

/**
 * 내 GitHub 저장소 목록. **DB 에 두지 않고 프록시한다** — 원본은 GitHub 이고
 * 사본을 두면 동기화가 곧바로 숙제가 된다 (설계 §6).
 *
 * **스페이스 밑이 아니다.** 토큰이 사람에게 붙어 있어 사용자 단위 자원이라
 * `SpaceGuard` 를 걸지 않는다 — 전역 `JwtAuthGuard` 만 지난다.
 */
@Controller('me/github')
export class GithubReposController {
  constructor(
    private readonly oauth: OauthService,
    private readonly github: GithubOauthClient,
    private readonly config: ConfigService,
  ) {}

  @Get('repos')
  async repos(
    @CurrentUser('id') userId: string,
    @Query('page', new DefaultValuePipe(1), new ParseIntPipe()) page: number,
  ) {
    const cfg = resolveGithubOauth(this.config);
    if (!cfg) {
      throw new ServiceUnavailableException(
        'GitHub 연결이 설정되지 않았습니다. 서버 관리자가 .env 를 채워야 합니다.',
      );
    }

    // 페이지 번호는 GitHub 의 것을 그대로 노출한다 — 커서를 새로 만들 이유가
    // 없다. 다만 0 이하는 GitHub 이 422 를 주므로 여기서 막는다.
    if (page < 1) throw new BadRequestException('page 는 1 이상이어야 합니다');

    const token = await this.oauth.githubTokenFor(userId);
    // 연결이 없으면 빈 목록이 아니라 400 이다. 빈 목록은 "저장소가 없다"로
    // 읽혀 사용자가 연결부터 해야 한다는 것을 알 수 없다.
    if (!token) {
      throw new BadRequestException('GitHub 계정을 먼저 연결해야 합니다');
    }

    const res = await this.github.listRepos(cfg, token, page);
    if (!res.ok) throw toGithubHttpError(res.status, res.retryAfter);

    return {
      repos: res.value.items,
      page,
      // 한 장이 꽉 찼으면 다음 장이 있다고 본다. **그 판단은 클라이언트가
      // 걸러내기 전 개수로 한다**(`Paged`) — Link 헤더를 파싱하지 않는 이유는
      // 마지막 장에서 한 번 헛걸음하는 것이 전부이기 때문이다.
      hasNext: res.value.hasMore,
    };
  }
}
