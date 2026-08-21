import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { randomBytes } from 'crypto';
import { Prisma, Repo, RepoProvider } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { CreateRepoDto } from './dto/repo.dto';

/**
 * 저장소 등록. **10-1 은 수동 등록만 한다** — GitHub 저장소 설정에서 웹훅
 * URL 과 시크릿을 사람이 직접 붙이는 방식이다. OAuth 로 자동 등록하는 길은
 * 10-2 에서 더하되, 이 길은 그때도 남긴다(설계 §7.1 이 말하는
 * "웹훅을 등록할 수 없는 환경"의 대비책이 곧 이것이다).
 */
@Injectable()
export class ReposService {
  constructor(private readonly prisma: PrismaService) {}

  /** **시크릿을 빼고 준다.** 서버가 검증에만 쓰는 값이다. */
  list(spaceId: string) {
    return this.prisma.repo.findMany({
      where: { spaceId },
      orderBy: { createdAt: 'desc' },
      select: REPO_SELECT,
    });
  }

  /**
   * 등록하고 **시크릿을 딱 한 번 돌려준다.** 그 뒤로는 목록에도 상세에도
   * 나오지 않는다 — 다시 볼 수 있게 두면 그것을 볼 수 있는 모든 경로가
   * 새는 자리가 된다. 잃어버리면 새로 발급한다.
   */
  async create(spaceId: string, dto: CreateRepoDto) {
    await this.requireChannel(spaceId, dto.linkedChannelId);

    const fullPath = dto.fullPath.trim().replace(/^\/+|\/+$/g, '');
    if (!/^[^/\s]+\/[^/\s]+$/.test(fullPath)) {
      throw new BadRequestException('저장소 경로는 소유자/이름 형식이어야 합니다');
    }

    const webhookSecret = `whsec_${randomBytes(24).toString('hex')}`;

    const repo = await this.prisma.repo.create({
      data: {
        spaceId,
        provider: dto.provider,
        // 수동 등록에는 provider 의 숫자 id 가 없다. 경로가 곧 식별자다 —
        // 저장소 이름이 바뀌면 다시 등록해야 하지만, OAuth 없이 얻을 수 있는
        // 유일한 안정 값이다.
        externalProjectId: fullPath,
        name: fullPath.split('/')[1],
        fullPath,
        defaultBranch: dto.defaultBranch ?? null,
        linkedChannelId: dto.linkedChannelId ?? null,
        webhookSecret,
      },
      select: REPO_SELECT,
    });

    return { ...repo, webhookSecret };
  }

  /** 시크릿을 새로 발급한다. 옛 시크릿으로 오는 요청은 그 순간부터 401 이다. */
  async rotateSecret(spaceId: string, repoId: string) {
    await this.requireRepo(spaceId, repoId);

    const webhookSecret = `whsec_${randomBytes(24).toString('hex')}`;
    const repo = await this.prisma.repo.update({
      where: { id: repoId },
      data: { webhookSecret },
      select: REPO_SELECT,
    });

    return { ...repo, webhookSecret };
  }

  /**
   * 지운다. 쌓인 `repo_events` 는 Cascade 로 함께 사라지지만, **채널에 올라간
   * 메시지는 남는다** — 그건 대화의 일부이고, 저장소를 떼었다고 지난 대화가
   * 사라지면 안 된다.
   *
   * **GitHub 쪽 훅은 컨트롤러가 먼저 뗀다**(10-2b). 여기서 하지 않는 이유는
   * 이 서비스가 밖으로 나가지 않는다는 성질을 지키기 위해서다.
   */
  async remove(spaceId: string, repoId: string): Promise<void> {
    await this.requireRepo(spaceId, repoId);
    await this.prisma.repo.delete({ where: { id: repoId } });
  }

  /** 훅을 떼기 위해 필요한 것만. 없으면 404 다. */
  async findForDetach(spaceId: string, repoId: string) {
    const repo = await this.prisma.repo.findFirst({
      where: { id: repoId, spaceId },
      select: { fullPath: true, provider: true, webhookExternalId: true },
    });
    if (!repo) throw new NotFoundException('저장소를 찾을 수 없습니다');
    return repo;
  }

  /** 웹훅 수신이 쓴다. **시크릿이 필요하므로 select 를 따로 둔다.** */
  findForWebhook(repoId: string, provider: RepoProvider): Promise<Repo | null> {
    return this.prisma.repo.findFirst({ where: { id: repoId, provider } });
  }

  private async requireRepo(spaceId: string, repoId: string) {
    const repo = await this.prisma.repo.findFirst({
      where: { id: repoId, spaceId },
      select: { id: true },
    });
    // 403 이 아니라 404 다 — 403 은 "그 저장소가 존재한다"를 알려 준다.
    if (!repo) throw new NotFoundException('저장소를 찾을 수 없습니다');
    return repo;
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

/** `webhookSecret` 이 빠져 있다. 등록 · 재발급 응답에서만 따로 붙인다. */
export const REPO_SELECT = {
  id: true,
  spaceId: true,
  provider: true,
  name: true,
  fullPath: true,
  defaultBranch: true,
  linkedChannelId: true,
  // 훅이 걸렸는지를 화면이 알아야 "다시 걸기"를 띄운다(10-2b). 시크릿과 달리
  // 이 값은 새는 자리가 아니다 — GitHub 쪽 훅 번호일 뿐이다.
  webhookExternalId: true,
  syncedAt: true,
  createdAt: true,
} satisfies Prisma.RepoSelect;
