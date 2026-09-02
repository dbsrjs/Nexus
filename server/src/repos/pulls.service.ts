import { BadRequestException, Injectable } from '@nestjs/common';
import { GithubOauthClient } from '../oauth/github-oauth.client';
import { toGithubHttpError } from './github-error';
import { RepoAccessService } from './repo-access.service';
import type { PullDetail } from './pull-view';

/**
 * PR 열람. **DB 사본을 두지 않고 GitHub 을 프록시한다**(설계 §0).
 *
 * `pull_requests` 테이블은 스키마에 있지만 쓰지 않는다 — 사본을 두면 연결 전
 * PR 이 안 보이는 백필 문제가 생기고, 웹훅을 놓치면 행이 영영 어긋난다.
 */
@Injectable()
export class PullsService {
  constructor(
    private readonly access: RepoAccessService,
    private readonly github: GithubOauthClient,
  ) {}

  async list(
    spaceId: string,
    userId: string,
    repoId: string,
    state: string,
    page: number,
  ) {
    // **open · closed 만 받는다.** 머지된 PR 은 closed 로 조회된다 — GitHub 이
    // 그렇게 나누고, 목록에서 머지 여부로 거를 방법이 없다.
    if (state !== 'open' && state !== 'closed') {
      throw new BadRequestException('state 는 open 또는 closed 입니다');
    }

    const { repo, cfg, token } = await this.access.ready(spaceId, userId, repoId);
    const res = await this.github.listPulls(cfg, token, repo.fullPath, state, page);
    if (!res.ok) throw toGithubHttpError(res.status, res.retryAfter);

    return {
      pulls: res.value.items,
      // 꽉 찼으면 다음 장이 있다고 본다(커밋 목록과 같다). **모양이 깨진
      // 항목을 걸러내기 전 개수로 판단한다** — 그러지 않으면 30건 중 하나만
      // 깨져도 29가 되어 다음 장이 조용히 사라진다.
      nextPage: res.value.hasMore ? page + 1 : null,
    };
  }

  /** 상세 — **리뷰 상태를 접어 함께 준다**(설계 §2). */
  async detail(
    spaceId: string,
    userId: string,
    repoId: string,
    num: number,
  ): Promise<PullDetail> {
    const { repo, cfg, token } = await this.access.ready(spaceId, userId, repoId);

    const pull = await this.github.getPull(cfg, token, repo.fullPath, num);
    if (!pull.ok) throw toGithubHttpError(pull.status, pull.retryAfter);

    const review = await this.github.getPullReview(cfg, token, repo.fullPath, num);
    // **리뷰를 못 받아도 상세는 준다.** 리뷰는 곁가지라, 그것 때문에 PR 이
    // 통째로 안 열리면 손해가 더 크다.
    return { ...pull.value, review: review.ok ? review.value : null };
  }

  async files(spaceId: string, userId: string, repoId: string, num: number) {
    const { repo, cfg, token } = await this.access.ready(spaceId, userId, repoId);

    const res = await this.github.listPullFiles(cfg, token, repo.fullPath, num);
    if (!res.ok) throw toGithubHttpError(res.status, res.retryAfter);
    return res.value;
  }
}
