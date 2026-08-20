import { ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';
import { Prisma, SpaceRole } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { RealtimeEmitter } from '../realtime/realtime-emitter';
import { hasAtLeast } from '../spaces/space-role';
import { CreateIssueCommentDto } from './dto/create-comment.dto';

const COMMENT_INCLUDE = {
  author: { select: { id: true, name: true, avatarUrl: true } },
} satisfies Prisma.IssueCommentInclude;

/**
 * 이슈 댓글과 이슈 삭제. `messages/` 가 `reactions.service.ts` 를 품은 것과
 * 같은 이유로 `issues/` 안에 둔다 — 댓글은 이슈 없이는 뜻이 없다.
 *
 * **커서를 두지 않는다.** 이슈 하나에 댓글이 수백 건이면 그건 이슈가 아니라
 * 채널이다. 핀 목록과 같은 판단이다.
 */
@Injectable()
export class IssueCommentsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly realtime: RealtimeEmitter,
  ) {}

  /** 오래된 것부터. 대화가 아니라 기록이라 위에서 아래로 읽는다. */
  async list(spaceId: string, issueId: string) {
    await this.requireIssue(spaceId, issueId);

    return this.prisma.issueComment.findMany({
      where: { spaceId, issueId },
      orderBy: { createdAt: 'asc' },
      include: COMMENT_INCLUDE,
    });
  }

  async create(
    spaceId: string,
    issueId: string,
    authorId: string,
    dto: CreateIssueCommentDto,
  ) {
    await this.requireIssue(spaceId, issueId);

    return this.prisma.issueComment.create({
      data: { spaceId, issueId, authorId, body: dto.body.trim() },
      include: COMMENT_INCLUDE,
    });
  }

  /**
   * 이슈를 **하드 삭제**한다. 메시지가 소프트 삭제인 것과 일부러 다르다 —
   * 메시지는 대화의 기록이라 "지워졌다"는 사실이 맥락이지만, 이슈는 할 일이라
   * 취소된 것이 흔적으로 남을 이유가 없다. 잘못 만든 이슈가 보드에 영원히
   * 남으면 보드가 못 쓰게 된다.
   *
   * 자식(에픽의 스토리)은 `parentId` 가 `SetNull` 이라 남는다 — **부모를 지워도
   * 할 일은 사라지지 않는 것**이 맞다.
   */
  async remove(
    spaceId: string,
    issueId: string,
    actorId: string,
    actorRole: SpaceRole,
  ): Promise<void> {
    const issue = await this.requireIssue(spaceId, issueId);

    // 만든 사람은 자기 실수를 치울 수 있어야 하고, 남의 이슈는 admin 만 지운다.
    const mine = issue.reporterId === actorId;
    if (!mine && !hasAtLeast(actorRole, SpaceRole.admin)) {
      throw new ForbiddenException('이 이슈를 지울 권한이 없습니다');
    }

    await this.prisma.issue.delete({ where: { id: issueId } });
    this.realtime.toSpace(spaceId, 'issue:deleted', { spaceId, issueId });
  }

  private async requireIssue(spaceId: string, issueId: string) {
    const issue = await this.prisma.issue.findFirst({
      where: { id: issueId, spaceId },
      select: { id: true, reporterId: true },
    });
    // 403 이 아니라 404 다 — 403 은 "그 이슈가 존재한다"를 알려 준다.
    if (!issue) throw new NotFoundException('이슈를 찾을 수 없습니다');
    return issue;
  }
}
