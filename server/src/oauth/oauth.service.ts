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
    const key = resolveOauthTokenKey(this.config);
    if (!cfg || !key || !code) return false;

    const userId = verifyState(state, this.stateSecret);
    if (!userId) return false;

    const token = await this.github.exchangeCode(cfg, code);
    if (!token) return false;

    const user = await this.github.fetchUser(cfg, token.accessToken);
    if (!user) return false;

    // 같은 GitHub 계정을 다시 연결하면 갈아 끼운다. providerUserId 가
    // 유니크라 다른 Nexus 계정이 같은 GitHub 을 잡고 있으면 그쪽에서 옮겨 온다.
    await this.prisma.oauthAccount.upsert({
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
    });

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
    const key = resolveOauthTokenKey(this.config);
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
    const key = resolveOauthTokenKey(this.config);
    if (!key) return null;

    const row = await this.prisma.oauthAccount.findFirst({
      where: { userId, provider: OauthProvider.github },
    });
    if (!row?.accessToken) return null;

    return decryptToken(row.accessToken, key);
  }

  private requireConfig(): GithubOauthConfig {
    const cfg = resolveGithubOauth(this.config);
    const key = resolveOauthTokenKey(this.config);

    if (!cfg || !key) {
      throw new ServiceUnavailableException(
        'GitHub 연결이 설정되지 않았습니다. 서버 관리자가 .env 를 채워야 합니다.',
      );
    }
    return cfg;
  }
}
