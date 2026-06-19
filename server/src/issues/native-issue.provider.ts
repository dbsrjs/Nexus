import { Injectable, NotFoundException } from '@nestjs/common';
import { Issue, IssueComment, IssueSource, IssueStatus } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { CreateIssueDto } from './dto/create-issue.dto';
import { UpdateIssueDto } from './dto/update-issue.dto';
import { CreateIssueCommentDto } from './dto/create-comment.dto';
import { IssueProvider, IssueWithRelations } from './issue-provider.interface';

/**
 * Prisma-backed implementation of {@link IssueProvider}. This is the default
 * (native) board; source is always `native` here so a Redmine provider can
 * own `redmine`-sourced issues later (design doc §3 `issues.source`).
 */
@Injectable()
export class NativeIssueProvider implements IssueProvider {
  constructor(private prisma: PrismaService) {}

  async list(status?: IssueStatus): Promise<Issue[]> {
    return this.prisma.issue.findMany({
      where: {
        source: IssueSource.native,
        ...(status ? { status } : {}),
      },
      orderBy: { createdAt: 'asc' },
    });
  }

  async get(id: string): Promise<IssueWithRelations> {
    const issue = await this.prisma.issue.findUnique({
      where: { id },
      include: {
        comments: { orderBy: { createdAt: 'asc' } },
      },
    });
    if (!issue) {
      throw new NotFoundException(`Issue ${id} not found`);
    }
    return issue;
  }

  async create(dto: CreateIssueDto, _creatorId: string): Promise<Issue> {
    const key = dto.key ?? (await this.generateKey());
    return this.prisma.issue.create({
      data: {
        key,
        title: dto.title,
        description: dto.description,
        status: dto.status,
        priority: dto.priority,
        label: dto.label,
        assigneeId: dto.assigneeId ?? null,
        source: IssueSource.native,
      },
    });
  }

  async update(id: string, dto: UpdateIssueDto): Promise<Issue> {
    // Ensure it exists (and is native) before patching.
    await this.get(id);
    return this.prisma.issue.update({
      where: { id },
      data: {
        ...(dto.title !== undefined ? { title: dto.title } : {}),
        ...(dto.description !== undefined ? { description: dto.description } : {}),
        ...(dto.status !== undefined ? { status: dto.status } : {}),
        ...(dto.priority !== undefined ? { priority: dto.priority } : {}),
        ...(dto.label !== undefined ? { label: dto.label } : {}),
        ...(dto.assigneeId !== undefined ? { assigneeId: dto.assigneeId } : {}),
      },
    });
  }

  async comment(
    id: string,
    dto: CreateIssueCommentDto,
    authorId: string,
  ): Promise<IssueComment> {
    // Validate the issue exists first for a clean 404.
    await this.get(id);
    return this.prisma.issueComment.create({
      data: {
        issueId: id,
        authorId,
        body: dto.body,
      },
    });
  }

  /**
   * Generate a sequential native key like `ISSUE-1`, `ISSUE-2`. Counts only
   * auto-keyed native issues so it stays monotonic regardless of custom keys.
   */
  private async generateKey(): Promise<string> {
    const count = await this.prisma.issue.count({
      where: { source: IssueSource.native },
    });
    let n = count + 1;
    // Guard against collisions with any manually-supplied keys.
    // eslint-disable-next-line no-await-in-loop
    while (await this.prisma.issue.findUnique({ where: { key: `ISSUE-${n}` } })) {
      n += 1;
    }
    return `ISSUE-${n}`;
  }
}
