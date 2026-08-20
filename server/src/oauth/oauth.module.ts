import { Module } from '@nestjs/common';
import { RealtimeEmitterModule } from '../realtime/realtime-emitter.module';
import { GithubOauthClient } from './github-oauth.client';
import { OauthService } from './oauth.service';
import { OauthController } from './oauth.controller';
import { OauthCallbackController } from './oauth-callback.controller';

/**
 * 컨트롤러가 둘인 이유는 repos 모듈과 같다 — **한쪽은 인증을 지나고 한쪽은
 * 지나지 않는다.** 섞으면 어느 라우트가 공개인지 읽어서 알 수 없다.
 *
 * `OauthService` 를 export 하는 것은 10-2b 가 `githubTokenFor()` 를 쓰기 때문이다.
 */
@Module({
  imports: [RealtimeEmitterModule],
  controllers: [OauthController, OauthCallbackController],
  providers: [OauthService, GithubOauthClient],
  exports: [OauthService],
})
export class OauthModule {}
