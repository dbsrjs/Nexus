import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { GithubOauthClient } from '../oauth/github-oauth.client';
import { resolveBlobBody } from './blob-content';
import { readPushCommits } from './push-commits';
import { RepoAccessService } from './repo-access.service';
import { toGithubHttpError } from './github-error';

/**
 * 저장소 열람. **코드 사본을 두지 않고 GitHub 을 프록시한다**(설계 §1).
 *
 * **캐시하지 않는다**(설계 §3) — 방금 push 한 것을 확인하려고 여는 순간이
 * 정확히 캐시가 옛것을 보여주는 순간이다.
 *
 * `RepoConnectService` 와 파일을 가른 이유는 성격이다 — 그쪽은 쓰기(훅 등록)이고
 * 여기는 읽기뿐이다.
 */
@Injectable()
export class RepoBrowseService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly github: GithubOauthClient,
    private readonly access: RepoAccessService,
  ) {}

  async branches(spaceId: string, userId: string, repoId: string) {
    const { repo, cfg, token } = await this.access.ready(spaceId, userId, repoId);

    const res = await this.github.listBranches(cfg, token, repo.fullPath);
    if (!res.ok) throw toGithubHttpError(res.status, res.retryAfter);

    return {
      branches: res.value,
      // 앱이 첫 화면에서 무엇을 고를지 알아야 한다.
      defaultBranch: repo.defaultBranch ?? null,
    };
  }

  async tree(
    spaceId: string,
    userId: string,
    repoId: string,
    ref: string,
    path: string,
  ) {
    const { repo, cfg, token } = await this.access.ready(spaceId, userId, repoId);
    const useRef = ref || repo.defaultBranch || '';

    const res = await this.github.getContents(cfg, token, repo.fullPath, path, useRef);
    if (!res.ok) throw toGithubHttpError(res.status, res.retryAfter);
    if (res.value.type !== 'dir') {
      throw new BadRequestException('그 경로는 디렉터리가 아닙니다');
    }

    return {
      ref: useRef,
      path,
      // **폴더가 먼저, 그 안에서 이름순.** GitHub 이 주는 순서는 정해져 있지
      // 않아 그대로 두면 화면마다 다르게 보인다.
      entries: [...res.value.entries].sort((a, b) => {
        if (a.type !== b.type) return a.type === 'dir' ? -1 : 1;
        return a.name.localeCompare(b.name);
      }),
    };
  }

  async blob(
    spaceId: string,
    userId: string,
    repoId: string,
    ref: string,
    path: string,
  ) {
    // 루트는 파일이 아니다.
    if (!path) throw new BadRequestException('path 가 필요합니다');

    const { repo, cfg, token } = await this.access.ready(spaceId, userId, repoId);
    const useRef = ref || repo.defaultBranch || '';

    const res = await this.github.getContents(cfg, token, repo.fullPath, path, useRef);
    if (!res.ok) throw toGithubHttpError(res.status, res.retryAfter);
    if (res.value.type !== 'file') {
      throw new BadRequestException('그 경로는 파일이 아닙니다');
    }

    const file = res.value;
    const body = resolveBlobBody(file.contentBase64, file.size);

    // **GitHub 원본을 그대로 흘리지 않는다** — `download_url` 같은 값은
    // 토큰이 있어야 열리는 주소다 (설계 §2).
    return { path: file.path, size: file.size, ...body };
  }

  /**
   * push 이벤트의 커밋들. **GitHub 을 부르지 않는다** — payload 에 이미 있다
   * (설계 §0). 토큰도 필요 없어 연결이 끊긴 뒤에도 지난 기록은 열린다.
   */
  async eventCommits(spaceId: string, eventId: string) {
    const event = await this.prisma.repoEvent.findFirst({
      where: { id: eventId, spaceId },
      select: {
        type: true,
        payload: true,
        repo: { select: { id: true, fullPath: true } },
      },
    });
    if (!event) throw new NotFoundException('이벤트를 찾을 수 없습니다');

    const view = readPushCommits(event.payload);
    return {
      type: event.type,
      repoId: event.repo.id,
      repoFullPath: event.repo.fullPath,
      ref: view.ref,
      commits: view.commits,
    };
  }

  /** 브랜치 이력. 커서는 GitHub 의 page 번호를 그대로 쓴다. */
  async commits(
    spaceId: string,
    userId: string,
    repoId: string,
    ref: string,
    cursor: string,
  ) {
    const { repo, cfg, token } = await this.access.ready(spaceId, userId, repoId);
    const useRef = ref || repo.defaultBranch || '';
    const page = Number(cursor) > 0 ? Number(cursor) : 1;

    const res = await this.github.listCommits(cfg, token, repo.fullPath, useRef, page);
    if (!res.ok) throw toGithubHttpError(res.status, res.retryAfter);

    return {
      ref: useRef,
      commits: res.value,
      // per_page=30 이 꽉 찼으면 다음 장이 있다고 본다(10-2b 의 저장소 목록과 같다).
      nextCursor: res.value.length === 30 ? String(page + 1) : null,
    };
  }

  /** 커밋 하나 — 메시지와 **바뀐 파일 목록**. diff 본문은 주지 않는다(설계 §3). */
  async commitDetail(spaceId: string, userId: string, repoId: string, sha: string) {
    const { repo, cfg, token } = await this.access.ready(spaceId, userId, repoId);

    const res = await this.github.getCommit(cfg, token, repo.fullPath, sha);
    if (!res.ok) throw toGithubHttpError(res.status, res.retryAfter);

    return { ...res.value.summary, files: res.value.files };
  }
}
