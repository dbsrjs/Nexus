import { ConflictException, Injectable, NotFoundException } from '@nestjs/common';
import { IssueLabel } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { CreateIssueLabelDto, SetIssueLabelsDto } from './dto/label.dto';

/**
 * 이슈 라벨. 스페이스가 공유하는 어휘다.
 *
 * 만들기는 `member` 이상, 지우기는 `admin` 이상이다(컨트롤러에서 건다).
 * 성격이 다르기 때문이다 — 라벨을 하나 더 만드는 것은 일하는 사람의 일이지만,
 * **지우는 것은 그 라벨이 붙은 모든 이슈에서 함께 떨어지는 일**이다.
 */
@Injectable()
export class IssueLabelsService {
  constructor(private readonly prisma: PrismaService) {}

  list(spaceId: string): Promise<IssueLabel[]> {
    return this.prisma.issueLabel.findMany({
      where: { spaceId },
      orderBy: { name: 'asc' },
    });
  }

  async create(spaceId: string, dto: CreateIssueLabelDto): Promise<IssueLabel> {
    const name = dto.name.trim();

    // 같은 이름을 두 번 만들면 화면에서 구분할 수 없다. 스키마의 UNIQUE 를
    // 그대로 500 으로 흘리지 않고 뜻이 있는 오류로 바꾼다.
    const existing = await this.prisma.issueLabel.findFirst({
      where: { spaceId, name },
    });
    if (existing) throw new ConflictException('같은 이름의 라벨이 이미 있습니다');

    return this.prisma.issueLabel.create({
      data: { spaceId, name, color: dto.color.toLowerCase() },
    });
  }

  /** 지우면 그 라벨이 붙은 모든 이슈에서 함께 떨어진다(링크가 Cascade). */
  async remove(spaceId: string, labelId: string): Promise<void> {
    const label = await this.prisma.issueLabel.findFirst({
      where: { id: labelId, spaceId },
    });
    if (!label) throw new NotFoundException('라벨을 찾을 수 없습니다');

    await this.prisma.issueLabel.delete({ where: { id: labelId } });
  }

  /**
   * 이슈의 라벨을 통째로 교체한다.
   *
   * **한 트랜잭션이다.** 지우기와 붙이기 사이에서 끊기면 라벨이 통째로 사라진
   * 채로 남는데, 사용자는 "바꿨다"고 믿는다.
   *
   * 다른 스페이스의 라벨 id 를 섞어 보내면 404 다 — 조용히 버리면 사용자가
   * 고른 것과 저장된 것이 달라진다.
   */
  async setForIssue(
    spaceId: string,
    issueId: string,
    dto: SetIssueLabelsDto,
  ): Promise<IssueLabel[]> {
    const issue = await this.prisma.issue.findFirst({
      where: { id: issueId, spaceId },
      select: { id: true },
    });
    if (!issue) throw new NotFoundException('이슈를 찾을 수 없습니다');

    const unique = [...new Set(dto.labelIds)];
    if (unique.length > 0) {
      const found = await this.prisma.issueLabel.count({
        where: { spaceId, id: { in: unique } },
      });
      if (found !== unique.length) {
        throw new NotFoundException('라벨을 찾을 수 없습니다');
      }
    }

    await this.prisma.$transaction([
      this.prisma.issueLabelLink.deleteMany({ where: { issueId, spaceId } }),
      this.prisma.issueLabelLink.createMany({
        data: unique.map((labelId) => ({ issueId, labelId, spaceId })),
      }),
    ]);

    return this.prisma.issueLabel.findMany({
      where: { spaceId, id: { in: unique } },
      orderBy: { name: 'asc' },
    });
  }
}
