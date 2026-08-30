import { Module } from '@nestjs/common';
import { ReposService } from './repos.service';
import { ReposController } from './repos.controller';
import { WebhooksService } from './webhooks.service';
import { WebhooksController } from './webhooks.controller';
import { SpacesModule } from '../spaces/spaces.module';
import { RealtimeEmitterModule } from '../realtime/realtime-emitter.module';
import { OauthModule } from '../oauth/oauth.module';
import { GithubReposController } from './github-repos.controller';
import { RepoConnectService } from './repo-connect.service';
import { RepoBrowseService } from './repo-browse.service';
import { RepoAccessService } from './repo-access.service';
import { RepoEventsController } from './repo-events.controller';
import { PullsController } from './pulls.controller';
import { PullsService } from './pulls.service';

/**
 * 저장소 연동. 웹훅 수신은 `SpaceGuard` 를 지나지 않으므로(부르는 쪽이
 * GitHub 이다) 컨트롤러를 둘로 나눈다 — 한쪽은 스페이스 밑, 한쪽은 밖이다.
 *
 * `GithubReposController`(10-2b)는 셋째다. **스페이스 밑도 아니다** —
 * 토큰이 사람에게 붙어 있어 사용자 단위 자원이다. 그럼에도 이 모듈에 두는
 * 이유는 자동 등록이 같은 의존(`OauthService` · `GithubOauthClient`)을 쓰기
 * 때문이다. oauth 모듈에 두면 저장소 코드가 두 모듈로 갈린다.
 */
@Module({
  imports: [SpacesModule, RealtimeEmitterModule, OauthModule],
  controllers: [
    ReposController,
    WebhooksController,
    GithubReposController,
    RepoEventsController,
    PullsController,
  ],
  providers: [
    ReposService,
    WebhooksService,
    RepoConnectService,
    RepoBrowseService,
    RepoAccessService,
    PullsService,
  ],
  exports: [ReposService],
})
export class ReposModule {}
