import {
  Injectable,
  Logger,
  ServiceUnavailableException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { OauthProvider } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { RealtimeEmitter } from '../realtime/realtime-emitter';
import { resolveJwtSecrets } from '../config/jwt.config';
import {
  GithubOauthConfig,
  resolveGithubOauth,
  resolveOauthTokenKey,
} from '../config/oauth.config';
import { GithubOauthClient } from './github-oauth.client';
import { signState, verifyState } from './oauth-state';
import { decryptToken, encryptToken } from './token-crypto';

export interface ConnectionView {
  provider: OauthProvider;
  login: string;
  avatarUrl: string | null;
  connectedAt: Date;
}

/**
 * GitHub 계정 연결 (설계 스펙 §2~§5).
 *
 * **토큰은 이 클래스 밖으로 나가지 않는다.** 유일한 예외가
 * `githubTokenFor()` 인데, 그것도 서버 안(10-2b 의 저장소 서비스)에서만 쓴다.
 */
@Injectable()
export class OauthService {
  private readonly logger = new Logger(OauthService.name);
  private readonly stateSecret: string;

  constructor(
    private readonly prisma: PrismaService,
    private readonly config: ConfigService,
    private readonly github: GithubOauthClient,
    private readonly realtime: RealtimeEmitter,
  ) {
    // JWT 시크릿을 state 서명에 재사용한다. 토큰 암호화 키와 달리 이쪽은
    // 회전해도 잃을 것이 5분짜리 진행 중 연결뿐이다.
    this.stateSecret = resolveJwtSecrets(config).accessSecret;
  }

  /** 연결을 시작한다. 설정이 없으면 **503** 이다 — 400 은 요청 탓이라는 뜻이다. */
  start(userId: string): { authorizeUrl: string } {
    const cfg = this.requireConfig();
    const state = signState(userId, this.stateSecret);

    return { authorizeUrl: this.github.authorizeUrl(cfg, state) };
  }

  /**
   * 콜백을 끝낸다. **성공 여부만 돌려준다** — 실패 종류를 브라우저에
   * 알려 줄 이유가 없다(공격자에게 힌트가 된다).
   */
  async completeGithub(code: string | undefined, state: string | undefined): Promise<boolean> {
    const cfg = resolveGithubOauth(this.config);
    const key = this.tokenKeyOrNull();
    if (!cfg || !key || !code) return false;

    const userId = verifyState(state, this.stateSecret);
    if (!userId) return false;

    const token = await this.github.exchangeCode(cfg, code);
    if (!token) return false;

    const user = await this.github.fetchUser(cfg, token.accessToken);
    if (!user) return false;

    // 사용자당 GitHub 연결은 하나로 못 박는다. `@@unique([provider,
    // providerUserId])` 만으로는 같은 사용자가 계정 A 를 붙였다가 계정 B 로
    // 다시 붙이는 경우를 막지 못한다 — upsert 의 where 가 GitHub 계정
    // 기준이라 행이 둘 남고, githubTokenFor() 의 findFirst 가 어느 행을
    // 줄지는 DB 가 정하게 된다(10-2b 의 저장소 서비스가 엉뚱한 계정 토큰으로
    // GitHub 을 부를 위험). 그래서 upsert 전에 이 사용자의 기존 github 행을
    // 먼저 지운다.
    //
    // 걷어내기와 upsert 는 **한 트랜잭션**이다 — 사이에서 끊기면 사용자는
    // 연결을 잃고도 그 사실을 모른다.
    //
    // 조건은 `{ userId, provider: 'github' }` 뿐이다. 지금 붙이려는 그
    // GitHub 계정이 이미 남의 것이면(다른 사용자가 providerUserId 를 잡고
    // 있으면) 그 행은 이 delete 대상이 아니다 — 그 행을 가져오는 것은
    // 아래 upsert 의 `update: { userId }` 가 담당하는 기존 동작이고, 그대로
    // 둔다.
    await this.prisma.$transaction([
      this.prisma.oauthAccount.deleteMany({
        where: { userId, provider: OauthProvider.github },
      }),
      this.prisma.oauthAccount.upsert({
        where: {
          provider_providerUserId: {
            provider: OauthProvider.github,
            providerUserId: String(user.id),
          },
        },
        create: {
          userId,
          provider: OauthProvider.github,
          providerUserId: String(user.id),
          accessToken: encryptToken(token.accessToken, key),
          scope: token.scope,
        },
        update: {
          userId,
          accessToken: encryptToken(token.accessToken, key),
          scope: token.scope,
        },
      }),
    ]);

    this.realtime.toUser(userId, 'oauth:connected', {
      provider: 'github',
      login: user.login,
    });

    this.logger.log(`GitHub 연결: user=${userId} login=${user.login}`);
    return true;
  }

  /**
   * 연결 목록. **토큰은 실리지 않는다** (설계 §4).
   *
   * `login` 은 DB 에 없다 — `oauth_accounts` 에 컬럼이 없어서다. 지금은
   * 토큰으로 GitHub 에 물어본다. 실패하면 그 연결은 목록에서 빠진다:
   * 화면에는 "연결 안 됨"으로 보이고, 다시 연결하면 회복된다.
   */
  async list(userId: string): Promise<ConnectionView[]> {
    const rows = await this.prisma.oauthAccount.findMany({
      where: { userId },
      orderBy: { createdAt: 'asc' },
    });

    const cfg = resolveGithubOauth(this.config);
    const key = this.tokenKeyOrNull();
    if (!cfg || !key) return [];

    const views: ConnectionView[] = [];
    for (const row of rows) {
      const token = row.accessToken ? decryptToken(row.accessToken, key) : null;
      // 복호화 실패(키 교체)를 "연결 없음"으로 취급한다.
      if (!token) continue;

      const user = await this.github.fetchUser(cfg, token);
      if (!user) continue;

      views.push({
        provider: row.provider,
        login: user.login,
        avatarUrl: user.avatarUrl,
        connectedAt: row.createdAt,
      });
    }
    return views;
  }

  /**
   * 연결을 끊는다. **이미 걸린 웹훅은 건드리지 않는다** (설계 §5) —
   * 채널에 커밋이 안 뜨는 것이 "계정 연결을 해제했다"의 결과여서는 안 된다.
   */
  async disconnect(userId: string): Promise<void> {
    await this.prisma.oauthAccount.deleteMany({
      where: { userId, provider: OauthProvider.github },
    });
  }

  /** 서버 안에서만 쓴다. 10-2b 의 저장소 서비스가 이것으로 GitHub 을 부른다. */
  async githubTokenFor(userId: string): Promise<string | null> {
    const key = this.tokenKeyOrNull();
    if (!key) return null;

    const row = await this.prisma.oauthAccount.findFirst({
      where: { userId, provider: OauthProvider.github },
    });
    if (!row?.accessToken) return null;

    return decryptToken(row.accessToken, key);
  }

  private requireConfig(): GithubOauthConfig {
    const cfg = resolveGithubOauth(this.config);
    const key = this.tokenKeyOrNull();

    if (!cfg || !key) {
      throw new ServiceUnavailableException(
        'GitHub 연결이 설정되지 않았습니다. 서버 관리자가 .env 를 채워야 합니다.',
      );
    }
    return cfg;
  }

  /**
   * `OAUTH_TOKEN_KEY` 해석을 감싼다. `resolveOauthTokenKey()` 는 키가
   * **없으면** `null` 을, 길이가 **틀리면** throw 한다 — "안 쓴다"와
   * "설정 실수"를 가르기 위해서다(Task 1 의 의도). 그런데 그 Error 의
   * message 에는 지금 몇 바이트인지까지 들어 있고, 전역 예외 필터는
   * `HttpException` 이 아닌 Error 를 그대로 응답 바디에 싣는다 — 콜백은
   * `@Public()` 이라 **인증 없이 누구나** 그 세부를 받아 볼 수 있게 된다.
   *
   * 여기서 throw 를 `null` 로 접어 호출부(완결 실패 · 목록 누락 · 503)가
   * 다시 던지지 않게 하고, 대신 서버 로그에는 남긴다 — 설정 실수가 조용히
   * 묻히면 안 되는 것은 운영자 쪽 사정이지 요청자에게 알려 줄 일이 아니다.
   */
  private tokenKeyOrNull(): Buffer | null {
    try {
      return resolveOauthTokenKey(this.config);
    } catch (err) {
      this.logger.warn(
        `OAUTH_TOKEN_KEY 설정이 잘못됐습니다: ${(err as Error).message}`,
      );
      return null;
    }
  }
}
