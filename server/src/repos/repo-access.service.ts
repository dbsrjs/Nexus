import {
  BadRequestException,
  Injectable,
  NotFoundException,
  ServiceUnavailableException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { RepoProvider } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { resolveGithubOauth } from '../config/oauth.config';
import { OauthService } from '../oauth/oauth.service';

/**
 * 저장소 · GitHub 설정 · 토큰이 모두 있어야 열람이 된다.
 *
 * 열람 서비스가 둘(`RepoBrowseService` · `PullsService`)이 되어 여기로 모았다.
 * **토큰은 그 순간 요청한 사람의 것**을 쓴다(10-2b) — 등록자를 기록해 두면
 * 그 사람이 연결을 해제한 순간 아무도 못 보게 된다.
 */
@Injectable()
export class RepoAccessService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly config: ConfigService,
    private readonly oauth: OauthService,
  ) {}

  async ready(spaceId: string, userId: string, repoId: string) {
    const repo = await this.prisma.repo.findFirst({
      where: { id: repoId, spaceId, provider: RepoProvider.github },
      select: { fullPath: true, defaultBranch: true },
    });
    // 403 이 아니라 404 다 — 403 은 "그 저장소가 존재한다"를 알려 준다.
    if (!repo) throw new NotFoundException('저장소를 찾을 수 없습니다');

    const cfg = resolveGithubOauth(this.config);
    if (!cfg) {
      throw new ServiceUnavailableException(
        'GitHub 연결이 설정되지 않았습니다. 서버 관리자가 .env 를 채워야 합니다.',
      );
    }

    const token = await this.oauth.githubTokenFor(userId);
    if (!token) throw new BadRequestException('GitHub 계정을 먼저 연결해야 합니다');

    return { repo, cfg, token };
  }
}
