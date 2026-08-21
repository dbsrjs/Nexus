import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  Logger,
  NotFoundException,
  ServiceUnavailableException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { randomBytes } from 'crypto';
import { RepoProvider } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { resolveGithubOauth, type GithubOauthConfig } from '../config/oauth.config';
import { resolvePublicBaseUrl } from '../config/public-url.config';
import { GithubOauthClient } from '../oauth/github-oauth.client';
import { OauthService } from '../oauth/oauth.service';
import { ConnectRepoDto } from './dto/connect-repo.dto';
import { REPO_SELECT } from './repos.service';

/**
 * 자동 등록. **10-1 의 `ReposService` 와 파일을 가른 이유**는 그쪽이 DB 만
 * 만지고 밖으로 나가지 않는다는 성질이 읽는 사람에게 중요하기 때문이다.
 * 여기는 GitHub 호출과 실패 보정이 섞인다.
 *
 * **누구의 토큰을 쓰나 — 그 순간 요청한 사람의 것.** 저장소는 스페이스에
 * 붙는데 토큰은 사람에게 붙어 있어 어긋나지만, 등록자를 따로 기록해 두면
 * 그 사람이 연결을 해제한 순간 아무도 훅을 손볼 수 없게 된다 (설계 §7).
 */
@Injectable()
export class RepoConnectService {
  private readonly logger = new Logger(RepoConnectService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly config: ConfigService,
    private readonly oauth: OauthService,
    private readonly github: GithubOauthClient,
  ) {}

  /**
   * 저장소를 붙이고 훅을 건다.
   *
   * **순서가 DB → GitHub 이다.** 훅 URL 에 `repoId` 가 들어가 행이 먼저
   * 있어야 하고, 외부 호출을 트랜잭션에 넣을 수도 없다(느리고, 롤백해도
   * GitHub 쪽은 안 돌아온다). 8-1 이 "스토리지 먼저, DB 나중"이었던 것과
   * 방향은 반대지만 **이유는 같다 — 되돌릴 수 없는 쪽이 나중이어야 한다.**
   */
  async connect(spaceId: string, userId: string, dto: ConnectRepoDto) {
    const { cfg, token, baseUrl } = await this.requireReady(userId);

    // 1) 이름 · 권한 · 기본 브랜치를 GitHub 에게 묻는다. 클라이언트 말을
    //    믿지 않는 지점이다.
    const found = await this.github.getRepo(cfg, token, dto.githubRepoId);
    if (!found.ok) {
      if (found.status === 404) throw new NotFoundException('저장소를 찾을 수 없습니다');
      throw new BadRequestException('GitHub 에서 저장소를 확인하지 못했습니다');
    }
    const repo = found.value;

    // 눌러 봐야 403 인 것을 여기서 막는다. 앱도 회색으로 그리지만 서버가
    // 마지막 방어선이다.
    if (!repo.canWebhook) {
      throw new ForbiddenException('그 저장소에 웹훅을 걸 권한이 없습니다');
    }

    await this.requireChannel(spaceId, dto.linkedChannelId);

    // 2) 행을 만들거나 **승격**한다.
    const row = await this.upsertRow(spaceId, repo, dto.linkedChannelId);

    // 3) 훅을 건다. 실패해도 행을 지우지 않는다.
    return this.attachHook(row.id, repo.fullName, row.webhookSecret, baseUrl, cfg, token);
  }

  /**
   * 훅을 다시 건다(주소가 바뀌었을 때 · 등록에 실패했던 행 · 사람이 GitHub
   * 에서 지웠을 때).
   *
   * **시크릿은 그대로 둔다** — 주소가 바뀐 것과 시크릿을 새로 파는 것은
   * 다른 일이다 (설계 §7).
   */
  async reattach(spaceId: string, userId: string, repoId: string) {
    const { cfg, token, baseUrl } = await this.requireReady(userId);

    const row = await this.prisma.repo.findFirst({
      where: { id: repoId, spaceId, provider: RepoProvider.github },
    });
    if (!row) throw new NotFoundException('저장소를 찾을 수 없습니다');

    const secret = row.webhookSecret ?? (await this.freshSecret(row.id));

    // 훅 id 가 있으면 주소만 갈아 끼운다. GitHub 이 404 를 주면 사람이 지운
    // 것이므로 아래로 떨어져 새로 만든다.
    if (row.webhookExternalId) {
      const patched = await this.github.updateHookUrl(
        cfg,
        token,
        row.fullPath,
        row.webhookExternalId,
        hookUrl(baseUrl, row.id),
      );
      if (patched.ok) return this.view(row.id);
      if (patched.status !== 404) {
        this.logger.warn(`훅 주소 갱신 실패(${patched.status}) — 새로 만든다`);
      }
    }

    return this.attachHook(row.id, row.fullPath, secret, baseUrl, cfg, token);
  }

  /**
   * GitHub 쪽 훅을 지운다. 우리 행 삭제는 호출부(컨트롤러)가 이어서 한다.
   *
   * **토큰이 없으면 건너뛴다.** 남은 고아 훅은 우리 서버로 오지만 `repoId`
   * 가 없어 404 로 떨어지고, GitHub 이 연속 실패한 훅을 스스로 비활성화한다
   * (설계 §7).
   */
  async detachHook(
    userId: string,
    repo: {
      fullPath: string;
      provider: RepoProvider;
      webhookExternalId: string | null;
    },
  ): Promise<void> {
    if (repo.provider !== RepoProvider.github || !repo.webhookExternalId) return;

    const cfg = resolveGithubOauth(this.config);
    const token = await this.oauth.githubTokenFor(userId);
    if (!cfg || !token) return;

    const res = await this.github.deleteHook(
      cfg,
      token,
      repo.fullPath,
      repo.webhookExternalId,
    );
    // 404 는 이미 없다는 뜻이라 성공과 같다. 그 밖의 실패도 우리 행 삭제를
    // 막지 않는다 — 사용자가 떼겠다고 한 것을 남길 이유가 없다.
    if (!res.ok && res.status !== 404) {
      this.logger.warn(`GitHub 훅 삭제 실패(${res.status}) — 우리 행만 지운다`);
    }
  }

  // ── 안쪽 ────────────────────────────────────────────

  /** 설정 · 공개 주소 · 토큰이 모두 있어야 자동 등록이 가능하다. */
  private async requireReady(userId: string) {
    const cfg = resolveGithubOauth(this.config);
    if (!cfg) {
      throw new ServiceUnavailableException(
        'GitHub 연결이 설정되지 않았습니다. 서버 관리자가 .env 를 채워야 합니다.',
      );
    }

    const baseUrl = resolvePublicBaseUrl(this.config);
    // **자동 등록만 거부하고 수동 경로는 남는다.** 503 이 아니라 400 인 이유는
    // 이 서버에서 할 수 있는 일이 남아 있기 때문이다 (설계 §7).
    if (!baseUrl) {
      throw new BadRequestException(
        '서버의 공개 주소(PUBLIC_BASE_URL)가 없어 자동 등록을 할 수 없습니다. 수동 등록을 쓰십시오.',
      );
    }

    const token = await this.oauth.githubTokenFor(userId);
    if (!token) throw new BadRequestException('GitHub 계정을 먼저 연결해야 합니다');

    return { cfg, token, baseUrl };
  }

  /**
   * 새로 만들거나 **승격한다.**
   *
   * `@@unique([spaceId, provider, externalProjectId])` 인데 수동 등록은
   * 거기에 `소유자/이름` 을, 자동은 숫자 id 를 넣는다. 그대로 두면 같은
   * 저장소가 행 둘이 된다. `fullPath` 로 한 번 더 찾아 이미 있으면 그 행의
   * `externalProjectId` 를 숫자 id 로 바꾼다 — **쌓인 `repo_events` 가 그대로
   * 이어지고 채널에 올라간 옛 메시지도 살아 있다** (설계 §7).
   */
  private async upsertRow(
    spaceId: string,
    repo: { id: number; fullName: string; defaultBranch: string | null },
    linkedChannelId?: string,
  ) {
    const existing = await this.prisma.repo.findFirst({
      where: {
        spaceId,
        provider: RepoProvider.github,
        OR: [
          { externalProjectId: String(repo.id) },
          { externalProjectId: repo.fullName },
          { fullPath: repo.fullName },
        ],
      },
    });

    if (existing) {
      return this.prisma.repo.update({
        where: { id: existing.id },
        data: {
          // 승격 — 이름 변경에 견디는 값으로 바꾼다.
          externalProjectId: String(repo.id),
          fullPath: repo.fullName,
          name: repo.fullName.split('/')[1],
          defaultBranch: repo.defaultBranch ?? existing.defaultBranch,
          // 채널을 새로 지정했을 때만 바꾼다. 안 보냈다고 떼면 안 된다.
          ...(linkedChannelId ? { linkedChannelId } : {}),
          webhookSecret: existing.webhookSecret ?? newSecret(),
        },
      });
    }

    return this.prisma.repo.create({
      data: {
        spaceId,
        provider: RepoProvider.github,
        externalProjectId: String(repo.id),
        name: repo.fullName.split('/')[1],
        fullPath: repo.fullName,
        defaultBranch: repo.defaultBranch,
        linkedChannelId: linkedChannelId ?? null,
        webhookSecret: newSecret(),
      },
    });
  }

  /** 훅을 걸고 결과를 행에 남긴다. **실패해도 행을 지우지 않는다.** */
  private async attachHook(
    repoId: string,
    fullName: string,
    secret: string | null,
    baseUrl: string,
    cfg: GithubOauthConfig,
    token: string,
  ) {
    const useSecret = secret ?? (await this.freshSecret(repoId));

    const created = await this.github.createHook(
      cfg,
      token,
      fullName,
      hookUrl(baseUrl, repoId),
      useSecret,
    );

    if (!created.ok) {
      // 지우면 사용자가 재시도할 대상이 사라지고 수동으로 붙일 길도 막힌다.
      this.logger.warn(`훅 등록 실패(${created.status}) — 행은 남긴다`);
      await this.prisma.repo.update({
        where: { id: repoId },
        data: { webhookExternalId: null },
      });
      return this.view(repoId);
    }

    await this.prisma.repo.update({
      where: { id: repoId },
      data: { webhookExternalId: String(created.value) },
    });
    return this.view(repoId);
  }

  private async freshSecret(repoId: string): Promise<string> {
    const webhookSecret = newSecret();
    await this.prisma.repo.update({ where: { id: repoId }, data: { webhookSecret } });
    return webhookSecret;
  }

  /**
   * 응답 모양. **`webhookSecret` 은 실리지 않는다** — 자동 등록은 사람이
   * GitHub 설정에 붙일 일이 없어 돌려줄 이유가 없다 (설계 §7).
   */
  private async view(repoId: string) {
    const row = await this.prisma.repo.findUniqueOrThrow({
      where: { id: repoId },
      select: REPO_SELECT,
    });
    return { ...row, webhookStatus: row.webhookExternalId ? 'active' : 'failed' };
  }

  /** 못 보는 채널에 저장소를 붙이면 그 채널로 이벤트가 새 나간다. */
  private async requireChannel(spaceId: string, channelId?: string) {
    if (!channelId) return;

    const channel = await this.prisma.channel.findFirst({
      where: { id: channelId, spaceId },
      select: { id: true },
    });
    if (!channel) throw new NotFoundException('채널을 찾을 수 없습니다');
  }
}

function newSecret(): string {
  return `whsec_${randomBytes(24).toString('hex')}`;
}

/** 10-1 의 수신 라우트와 **같은 모양이어야 한다** — `webhooks.controller.ts`. */
function hookUrl(baseUrl: string, repoId: string): string {
  return `${baseUrl}/api/webhooks/github/${repoId}`;
}
