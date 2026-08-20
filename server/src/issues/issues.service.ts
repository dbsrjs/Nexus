import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { IssueStatus, Prisma } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { RealtimeEmitter } from '../realtime/realtime-emitter';
import { formatIssueKey } from './issue-key';
import { needsRenumber, POSITION_STEP, positionBetween } from './position';
import { resolveClosedAt } from './issue-status';
import { CreateIssueDto } from './dto/create-issue.dto';
import { ListIssuesDto } from './dto/list-issues.dto';
import { MoveIssueDto } from './dto/move-issue.dto';
import { UpdateIssueDto } from './dto/update-issue.dto';

/** 컬럼 하나가 한 번에 주는 최대 건수. 넘치면 truncated 로 알린다. */
export const COLUMN_LIMIT = 200;

export const ISSUE_INCLUDE = {
  assignee: { select: { id: true, name: true, avatarUrl: true } },
} satisfies Prisma.IssueInclude;

export type IssueRow = Prisma.IssueGetPayload<{ include: typeof ISSUE_INCLUDE }>;

/**
 * `position` 은 Decimal 이라 JSON 으로 나가면 정밀도가 깎인다. 문자열로 준다 —
 * 앱은 정렬에만 쓰고 산술을 하지 않는다.
 */
export function toView(row: IssueRow) {
  return { ...row, position: row.position.toString() };
}

export type IssueView = ReturnType<typeof toView>;

/**
 * 이슈 보드. 스페이스에 속한다.
 *
 * 모든 메서드가 `spaceId` 를 첫 인자로 받아 WHERE 에 넣는다 — SpaceGuard 를
 * 지났더라도 다른 스페이스의 이슈 id 를 넘기면 404 여야 한다
 * (docs/백엔드-설계.md §2 격리 규칙 2·4).
 */
@Injectable()
export class IssuesService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly realtime: RealtimeEmitter,
  ) {}

  /**
   * 목록은 평평하게 준다. 상태별로 묶지 않는 이유는 앱이 이것을 drift 에 행
   * 단위로 넣기 때문이다 — 서버가 묶어 주면 캐시에 넣을 때 다시 풀어야 한다.
   *
   * 커서를 두지 않고 **컬럼별 상한 + truncated** 로 간다. 정렬 키가
   * (status, position) 복합이라 커서는 컬럼마다 따로 이어야 하는데, Phase 0
   * 규모에서 그 복잡도를 살 이유가 없다. 조용히 자르지 않는 것이 핵심이다.
   */
  async list(
    spaceId: string,
    dto: ListIssuesDto,
  ): Promise<{ issues: IssueView[]; truncated: IssueStatus[] }> {
    const base: Prisma.IssueWhereInput = {
      spaceId,
      ...(dto.assigneeId ? { assigneeId: dto.assigneeId } : {}),
      ...(dto.sprintId ? { sprintId: dto.sprintId } : {}),
      ...(dto.q
        ? { title: { contains: dto.q, mode: 'insensitive' as const } }
        : {}),
    };

    const columns = dto.status ? [dto.status] : Object.values(IssueStatus);
    const issues: IssueRow[] = [];
    const truncated: IssueStatus[] = [];

    for (const status of columns) {
      // 상한보다 한 건 더 받아 "잘렸는지"를 개수로 안다.
      const rows = await this.prisma.issue.findMany({
        where: { ...base, status },
        orderBy: [{ position: 'asc' }, { createdAt: 'asc' }],
        take: COLUMN_LIMIT + 1,
        include: ISSUE_INCLUDE,
      });
      if (rows.length > COLUMN_LIMIT) {
        truncated.push(status);
        rows.length = COLUMN_LIMIT;
      }
      issues.push(...rows);
    }

    return { issues: issues.map(toView), truncated };
  }

  /**
   * 새 이슈는 컬럼 **맨 위**에 놓는다. 방금 만든 것이 보이지 않으면 만든
   * 사람은 실패했다고 믿는다.
   *
   * 키 발급과 행 삽입은 한 트랜잭션이다. 사이에서 끊기면 연번만 올라가 번호에
   * 구멍이 남는데, 구멍은 견딜 수 있어도 중복은 못 견딘다.
   */
  async create(
    spaceId: string,
    reporterId: string,
    dto: CreateIssueDto,
  ): Promise<IssueView> {
    if (dto.parentId) await this.requireEpicCandidate(spaceId, dto.parentId);

    const status = dto.status ?? IssueStatus.backlog;

    const created = await this.prisma.$transaction(async (tx) => {
      // 스페이스 행을 잠가 동시 생성을 직렬화한다.
      const [seqRow] = await tx.$queryRaw<{ issue_seq: number; slug: string }[]>`
        UPDATE spaces SET issue_seq = issue_seq + 1
        WHERE id = ${spaceId}
        RETURNING issue_seq, slug
      `;
      if (!seqRow) throw new NotFoundException('스페이스를 찾을 수 없습니다');

      const top = await tx.issue.findFirst({
        where: { spaceId, status },
        orderBy: { position: 'asc' },
        select: { position: true },
      });

      return tx.issue.create({
        data: {
          spaceId,
          key: formatIssueKey(seqRow.slug, seqRow.issue_seq),
          title: dto.title.trim(),
          description: dto.description ?? null,
          status,
          ...(dto.priority ? { priority: dto.priority } : {}),
          assigneeId: dto.assigneeId ?? null,
          sprintId: dto.sprintId ?? null,
          parentId: dto.parentId ?? null,
          storyPoints: dto.storyPoints ?? null,
          reporterId,
          position: positionBetween(null, top?.position ?? null),
        },
        include: ISSUE_INCLUDE,
      });
    });

    const view = toView(created);
    this.realtime.toSpace(spaceId, 'issue:created', view);
    return view;
  }

  async get(spaceId: string, issueId: string): Promise<IssueView> {
    return toView(await this.requireIssue(spaceId, issueId));
  }

  /**
   * `status` 를 주면 **컬럼만** 옮긴다 — 대상 컬럼 맨 위로 간다.
   * 자리까지 정하려면 `move()` 다. 메뉴는 이웃을 모르므로, 그때 서버가 맨
   * 위를 고르는 것이 규칙이어야 앱이 이웃을 지어내지 않는다.
   */
  async update(
    spaceId: string,
    issueId: string,
    dto: UpdateIssueDto,
  ): Promise<IssueView> {
    const current = await this.requireIssue(spaceId, issueId);
    const closedAt = resolveClosedAt(current.status, dto.status, new Date());

    let position: Prisma.Decimal | undefined;
    if (dto.status && dto.status !== current.status) {
      const top = await this.prisma.issue.findFirst({
        where: { spaceId, status: dto.status },
        orderBy: { position: 'asc' },
        select: { position: true },
      });
      position = positionBetween(null, top?.position ?? null);
    }

    const updated = await this.prisma.issue.update({
      where: { id: issueId },
      data: {
        ...(dto.title !== undefined ? { title: dto.title.trim() } : {}),
        ...(dto.description !== undefined
          ? { description: dto.description }
          : {}),
        ...(dto.status !== undefined ? { status: dto.status } : {}),
        ...(dto.priority !== undefined ? { priority: dto.priority } : {}),
        ...(dto.assigneeId !== undefined ? { assigneeId: dto.assigneeId } : {}),
        ...(dto.sprintId !== undefined ? { sprintId: dto.sprintId } : {}),
        ...(dto.storyPoints !== undefined
          ? { storyPoints: dto.storyPoints }
          : {}),
        ...(closedAt !== undefined ? { closedAt } : {}),
        ...(position !== undefined ? { position } : {}),
      },
      include: ISSUE_INCLUDE,
    });

    const view = toView(updated);
    this.realtime.toSpace(spaceId, 'issue:updated', view);
    return view;
  }

  /**
   * 드래그가 쓴다. 두 이웃 사이 중간값을 받는다.
   *
   * 이웃은 모두 `dto.status` 컬럼에 있어야 한다 — 다른 컬럼의 카드를 기준으로
   * 자리를 정하면 순서가 뜻을 잃는다.
   *
   * `renumbered` 는 재귀 깊이를 1로 묶는다. 재채번 뒤에도 자리가 나지 않는
   * 것은 계산이 틀렸다는 뜻이라, 조용히 반복하면 스택이 터질 때까지 돈다.
   */
  async move(
    spaceId: string,
    issueId: string,
    dto: MoveIssueDto,
    renumbered = false,
  ): Promise<IssueView> {
    const current = await this.requireIssue(spaceId, issueId);

    const prev = dto.afterId
      ? await this.requireNeighbour(spaceId, dto.afterId, dto.status)
      : null;
    const next = dto.beforeId
      ? await this.requireNeighbour(spaceId, dto.beforeId, dto.status)
      : null;

    if (prev && next && !prev.position.lessThan(next.position)) {
      throw new BadRequestException('기준 이슈 두 개의 순서가 뒤바뀌었습니다');
    }

    const position = positionBetween(
      prev?.position ?? null,
      next?.position ?? null,
    );

    if (needsRenumber(position, prev?.position ?? null, next?.position ?? null)) {
      if (renumbered) {
        throw new BadRequestException('정렬 자리를 만들지 못했습니다');
      }
      await this.renumber(spaceId, dto.status);
      return this.move(spaceId, issueId, dto, true);
    }

    const closedAt = resolveClosedAt(current.status, dto.status, new Date());

    const updated = await this.prisma.issue.update({
      where: { id: issueId },
      data: {
        status: dto.status,
        position,
        ...(closedAt !== undefined ? { closedAt } : {}),
      },
      include: ISSUE_INCLUDE,
    });

    const view = toView(updated);
    this.realtime.toSpace(spaceId, 'issue:updated', view);
    return view;
  }

  /** 에픽 → 스토리는 한 단계만이다. 부모가 이미 자식이면 거부한다. */
  private async requireEpicCandidate(spaceId: string, parentId: string) {
    const parent = await this.prisma.issue.findFirst({
      where: { id: parentId, spaceId },
      select: { parentId: true },
    });
    if (!parent) throw new NotFoundException('상위 이슈를 찾을 수 없습니다');
    if (parent.parentId) {
      throw new BadRequestException('에픽은 한 단계까지만 묶을 수 있습니다');
    }
  }

  private async requireIssue(
    spaceId: string,
    issueId: string,
  ): Promise<IssueRow> {
    const issue = await this.prisma.issue.findFirst({
      where: { id: issueId, spaceId },
      include: ISSUE_INCLUDE,
    });
    // 403 이 아니라 404 다 — 403 은 "그 이슈가 존재한다"를 알려 준다.
    if (!issue) throw new NotFoundException('이슈를 찾을 수 없습니다');
    return issue;
  }

  private async requireNeighbour(
    spaceId: string,
    neighbourId: string,
    status: IssueStatus,
  ) {
    const neighbour = await this.prisma.issue.findFirst({
      where: { id: neighbourId, spaceId },
      select: { id: true, position: true, status: true },
    });
    if (!neighbour) throw new NotFoundException('기준 이슈를 찾을 수 없습니다');
    if (neighbour.status !== status) {
      throw new BadRequestException('기준 이슈가 다른 컬럼에 있습니다');
    }
    return neighbour;
  }

  /** 자릿수가 소진된 컬럼을 1000 간격으로 다시 매긴다. */
  private async renumber(spaceId: string, status: IssueStatus) {
    const rows = await this.prisma.issue.findMany({
      where: { spaceId, status },
      orderBy: [{ position: 'asc' }, { createdAt: 'asc' }],
      select: { id: true },
    });
    await this.prisma.$transaction(
      rows.map((row, i) =>
        this.prisma.issue.update({
          where: { id: row.id },
          data: { position: POSITION_STEP.times(i) },
        }),
      ),
    );
  }
}
