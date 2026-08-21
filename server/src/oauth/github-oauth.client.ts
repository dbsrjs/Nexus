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
 * 고를 수 있는 저장소 한 건. **`canWebhook` 을 함께 준다** — admin 이 아니면
 * 훅을 걸 수 없는데, 모르고 고르면 눌러 봐야 403 이다 (설계 §6).
 */
export interface GithubRepoView {
  id: number;
  fullName: string;
  private: boolean;
  defaultBranch: string | null;
  pushedAt: string | null;
  canWebhook: boolean;
}

export interface GithubBranch {
  name: string;
  protected: boolean;
}

/** contents API 는 **경로가 파일이냐 디렉터리냐에 따라 다른 모양**을 준다. */
export interface GithubContentFile {
  type: 'file';
  name: string;
  path: string;
  size: number;
  /** 1MB 를 넘으면 GitHub 이 본문을 주지 않는다 — 그때 `null` 이다. */
  contentBase64: string | null;
}

export interface GithubContentDir {
  type: 'dir';
  entries: Array<{
    name: string;
    path: string;
    type: 'file' | 'dir';
    size: number | null;
  }>;
}

/**
 * 실패를 상태 코드째로 준다.
 *
 * `exchangeCode()` · `fetchUser()` 가 실패를 `null` 로 접은 것과 다르다 —
 * 그쪽 호출부(공개 콜백)는 오류 페이지를 그리는 것 말고 할 일이 없었지만,
 * 이쪽은 403(권한 없음) · 404(훅이 이미 없음) · 429(잠시 뒤 재시도)를 서로
 * 다르게 다뤄야 한다. 접으면 그 분기가 사라진다.
 */
export type GithubResult<T> =
  | { ok: true; value: T }
  | { ok: false; status: number; retryAfter?: number };

/** GitHub 의 저장소 JSON. 우리가 쓰는 것만 적는다. */
interface RawRepo {
  id?: number;
  full_name?: string;
  private?: boolean;
  default_branch?: string;
  pushed_at?: string;
  permissions?: { admin?: boolean };
}

function toRepoView(raw: RawRepo): GithubRepoView | null {
  if (typeof raw.id !== 'number' || !raw.full_name) return null;

  return {
    id: raw.id,
    fullName: raw.full_name,
    private: raw.private === true,
    defaultBranch: raw.default_branch ?? null,
    pushedAt: raw.pushed_at ?? null,
    // permissions 가 없으면 모른다는 뜻이다. 모르면 고를 수 없게 한다 —
    // 눌러 봐야 403 인 버튼보다 낫다.
    canWebhook: raw.permissions?.admin === true,
  };
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

  /**
   * 내 저장소 목록. **검색을 서버에 두지 않는다** — `/user/repos` 에는 검색
   * 파라미터가 없고 `/search/repositories` 는 rate limit 도 응답 모양도
   * 다르다(`permissions` 를 주지 않아 `canWebhook` 을 채울 수 없다).
   * 앱이 받아 온 페이지 안에서 이름으로 거른다 (설계 §6).
   */
  async listRepos(
    cfg: GithubOauthConfig,
    token: string,
    page: number,
  ): Promise<GithubResult<GithubRepoView[]>> {
    const query = new URLSearchParams({
      sort: 'updated',
      affiliation: 'owner,collaborator,organization_member',
      per_page: '100',
      page: String(page),
    });

    const res = await this.call<RawRepo[]>(
      `${cfg.apiBase}/user/repos?${query.toString()}`,
      token,
    );
    if (!res.ok) return res;

    const views: GithubRepoView[] = [];
    for (const raw of res.value) {
      const view = toRepoView(raw);
      if (view) views.push(view);
    }
    return { ok: true, value: views };
  }

  async listBranches(
    cfg: GithubOauthConfig,
    token: string,
    fullName: string,
  ): Promise<GithubResult<GithubBranch[]>> {
    const res = await this.call<Array<{ name?: string; protected?: boolean }>>(
      `${cfg.apiBase}/repos/${fullName}/branches?per_page=100`,
      token,
    );
    if (!res.ok) return res;

    const branches: GithubBranch[] = [];
    for (const raw of res.value) {
      if (!raw.name) continue;
      branches.push({ name: raw.name, protected: raw.protected === true });
    }
    return { ok: true, value: branches };
  }

  /**
   * 경로 하나를 받는다. **디렉터리면 배열, 파일이면 객체**가 오므로 그것으로
   * 갈린다 — 우리 `tree` 와 `blob` 이 같은 호출을 쓴다 (설계 §1).
   */
  async getContents(
    cfg: GithubOauthConfig,
    token: string,
    fullName: string,
    path: string,
    ref: string,
  ): Promise<GithubResult<GithubContentFile | GithubContentDir>> {
    // 경로 세그먼트마다 인코딩한다. 통째로 encodeURIComponent 하면 `/` 가
    // %2F 가 되어 GitHub 이 다른 경로로 읽는다.
    const encoded = path
      .split('/')
      .filter(Boolean)
      .map(encodeURIComponent)
      .join('/');
    const query = new URLSearchParams({ ref });

    const res = await this.call<unknown>(
      `${cfg.apiBase}/repos/${fullName}/contents/${encoded}?${query.toString()}`,
      token,
    );
    if (!res.ok) return res;

    // 디렉터리 — 배열이 온다.
    if (Array.isArray(res.value)) {
      const entries: GithubContentDir['entries'] = [];
      for (const raw of res.value as Array<Record<string, unknown>>) {
        const name = raw.name;
        const p = raw.path;
        const t = raw.type;
        if (typeof name !== 'string' || typeof p !== 'string') continue;
        // GitHub 은 submodule · symlink 도 준다. 우리는 둘만 다룬다.
        if (t !== 'file' && t !== 'dir') continue;
        entries.push({
          name,
          path: p,
          type: t,
          size: t === 'file' && typeof raw.size === 'number' ? raw.size : null,
        });
      }
      return { ok: true, value: { type: 'dir', entries } };
    }

    const raw = res.value as Record<string, unknown>;
    if (raw.type !== 'file' || typeof raw.path !== 'string') {
      // submodule · symlink 를 열려고 한 경우. 파일이 아니다.
      return { ok: false, status: 422 };
    }

    const content = raw.content;
    return {
      ok: true,
      value: {
        type: 'file',
        name: typeof raw.name === 'string' ? raw.name : '',
        path: raw.path,
        size: typeof raw.size === 'number' ? raw.size : 0,
        // 1MB 초과면 GitHub 이 빈 문자열을 준다 — 없는 것으로 친다.
        contentBase64:
          typeof content === 'string' && content.length > 0 ? content : null,
      },
    };
  }

  /**
   * 숫자 id 로 한 건.
   *
   * **`connect` 가 이것을 반드시 부른다.** 클라이언트가 준 이름을 그대로
   * 믿으면 남의 저장소 경로로 행을 만들 수 있고, `permissions` 도 여기서만
   * 확인된다.
   */
  async getRepo(
    cfg: GithubOauthConfig,
    token: string,
    repoId: number,
  ): Promise<GithubResult<GithubRepoView>> {
    const res = await this.call<RawRepo>(
      `${cfg.apiBase}/repositories/${repoId}`,
      token,
    );
    if (!res.ok) return res;

    const view = toRepoView(res.value);
    // 모양이 예상과 다르면 GitHub 이 422 를 준 것과 같게 다룬다.
    if (!view) return { ok: false, status: 422 };
    return { ok: true, value: view };
  }

  /**
   * 훅을 건다. **`content_type` 을 `json` 으로 박는다** — GitHub 기본값은
   * `form` 이고 그러면 서명이 맞지 않는다(10-1 에서 실제로 겪었다).
   */
  async createHook(
    cfg: GithubOauthConfig,
    token: string,
    fullName: string,
    url: string,
    secret: string,
  ): Promise<GithubResult<number>> {
    const res = await this.call<{ id?: number }>(
      `${cfg.apiBase}/repos/${fullName}/hooks`,
      token,
      {
        method: 'POST',
        body: JSON.stringify({
          name: 'web',
          active: true,
          events: ['push', 'pull_request'],
          config: { url, content_type: 'json', secret },
        }),
      },
    );
    if (!res.ok) return res;
    if (typeof res.value.id !== 'number') return { ok: false, status: 422 };

    return { ok: true, value: res.value.id };
  }

  /**
   * 주소만 갈아 끼운다. **시크릿은 건드리지 않는다** — 주소가 바뀐 것과
   * 시크릿을 새로 파는 것은 다른 일이다 (설계 §7).
   */
  async updateHookUrl(
    cfg: GithubOauthConfig,
    token: string,
    fullName: string,
    hookId: string,
    url: string,
  ): Promise<GithubResult<void>> {
    return this.call<void>(`${cfg.apiBase}/repos/${fullName}/hooks/${hookId}`, token, {
      method: 'PATCH',
      body: JSON.stringify({ config: { url, content_type: 'json' } }),
    });
  }

  async deleteHook(
    cfg: GithubOauthConfig,
    token: string,
    fullName: string,
    hookId: string,
  ): Promise<GithubResult<void>> {
    return this.call<void>(`${cfg.apiBase}/repos/${fullName}/hooks/${hookId}`, token, {
      method: 'DELETE',
    });
  }

  /** 인증 헤더와 오류 해석이 같아 한 곳에 모은다. */
  private async call<T>(
    url: string,
    token: string,
    init: RequestInit = {},
  ): Promise<GithubResult<T>> {
    try {
      const res = await fetch(url, {
        ...init,
        headers: {
          authorization: `Bearer ${token}`,
          accept: 'application/vnd.github+json',
          'content-type': 'application/json',
          ...(init.headers ?? {}),
        },
      });

      if (!res.ok) {
        // 429 의 Retry-After 는 초 단위 정수다. 없으면 붙이지 않는다.
        const raw = res.headers.get('retry-after');
        const retryAfter = raw && /^\d+$/.test(raw) ? Number(raw) : undefined;
        this.logger.warn(`GitHub 호출 실패: ${res.status} ${url}`);
        return { ok: false, status: res.status, retryAfter };
      }

      // 204(훅 삭제)는 본문이 없다.
      if (res.status === 204) return { ok: true, value: undefined as T };

      return { ok: true, value: (await res.json()) as T };
    } catch (err) {
      this.logger.error(`GitHub 호출 중 오류: ${url}`, err as Error);
      // 네트워크 자체가 실패한 것은 GitHub 의 응답이 아니다. 0 으로 표시해
      // 호출부가 "GitHub 이 거절했다"와 구분할 수 있게 한다.
      return { ok: false, status: 0 };
    }
  }
}
