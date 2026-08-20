import { Injectable, Logger } from '@nestjs/common';
import type { GithubOauthConfig } from '../config/oauth.config';

export interface GithubToken {
  accessToken: string;
  scope: string | null;
}

export interface GithubUser {
  id: number;
  login: string;
  avatarUrl: string | null;
}

/**
 * GitHub 으로 나가는 HTTP 호출만 한다. DB 도 소켓도 모른다.
 *
 * 주소를 `GithubOauthConfig` 에서 받는 이유는 검증 때문이다 — 가짜 GitHub 을
 * 물려야 `check:oauth` 가 진짜 GitHub 없이 돈다 (설계 §10).
 *
 * **실패는 던지지 않고 `null` 로 준다.** 호출부(콜백)가 할 수 있는 일이
 * 오류 페이지를 그리는 것뿐이라, 실패 종류를 나눠도 쓰이지 않는다.
 */
@Injectable()
export class GithubOauthClient {
  private readonly logger = new Logger(GithubOauthClient.name);

  authorizeUrl(cfg: GithubOauthConfig, state: string): string {
    const query = new URLSearchParams({
      client_id: cfg.clientId,
      redirect_uri: cfg.callbackUrl,
      // 비공개 저장소 조회와 웹훅 관리(admin:repo_hook)가 여기 포함된다 (설계 §1).
      scope: 'repo',
      state,
    });

    return `${cfg.oauthBase}/login/oauth/authorize?${query.toString()}`;
  }

  async exchangeCode(cfg: GithubOauthConfig, code: string): Promise<GithubToken | null> {
    try {
      const res = await fetch(`${cfg.oauthBase}/login/oauth/access_token`, {
        method: 'POST',
        headers: {
          'content-type': 'application/json',
          // 없으면 GitHub 이 form 인코딩으로 답한다.
          accept: 'application/json',
        },
        body: JSON.stringify({
          client_id: cfg.clientId,
          client_secret: cfg.clientSecret,
          code,
          redirect_uri: cfg.callbackUrl,
        }),
      });

      const json = (await res.json()) as {
        access_token?: string;
        scope?: string;
        error?: string;
      };

      // GitHub 은 code 재사용·만료에도 **200** 을 주고 body 에 error 를 담는다.
      if (!res.ok || !json.access_token) {
        this.logger.warn(`토큰 교환 실패: ${res.status} ${json.error ?? ''}`);
        return null;
      }

      return { accessToken: json.access_token, scope: json.scope ?? null };
    } catch (err) {
      this.logger.error('토큰 교환 중 오류', err as Error);
      return null;
    }
  }

  async fetchUser(cfg: GithubOauthConfig, accessToken: string): Promise<GithubUser | null> {
    try {
      const res = await fetch(`${cfg.apiBase}/user`, {
        headers: {
          authorization: `Bearer ${accessToken}`,
          accept: 'application/vnd.github+json',
        },
      });

      if (!res.ok) {
        this.logger.warn(`사용자 조회 실패: ${res.status}`);
        return null;
      }

      const json = (await res.json()) as {
        id?: number;
        login?: string;
        avatar_url?: string;
      };
      if (typeof json.id !== 'number' || !json.login) return null;

      return { id: json.id, login: json.login, avatarUrl: json.avatar_url ?? null };
    } catch (err) {
      this.logger.error('사용자 조회 중 오류', err as Error);
      return null;
    }
  }
}
