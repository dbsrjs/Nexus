import { Inject, Injectable } from '@nestjs/common';
import { Issue, IssueComment, IssueStatus } from '@prisma/client';
import { CreateIssueDto } from './dto/create-issue.dto';
import { UpdateIssueDto } from './dto/update-issue.dto';
import { CreateIssueCommentDto } from './dto/create-comment.dto';
import {
  ISSUE_PROVIDER,
  IssueProvider,
  IssueWithRelations,
} from './issue-provider.interface';

/** Board columns in display order (design doc §3 IssueStatus). */
const BOARD_COLUMNS: IssueStatus[] = [
  IssueStatus.backlog,
  IssueStatus.doing,
  IssueStatus.review,
  IssueStatus.done,
];

export type IssueBoard = Record<IssueStatus, Issue[]>;

/**
 * Thin service that delegates persistence to the injected {@link IssueProvider}
 * and shapes results for the board UI. Swapping the provider (native→redmine)
 * requires no change here.
 */
@Injectable()
export class IssuesService {
  constructor(
    @Inject(ISSUE_PROVIDER) private readonly provider: IssueProvider,
  ) {}

  /**
   * When `status` is given, returns that single column. Otherwise returns the
   * full board grouped by status (every column present, empty arrays included).
   */
  async list(status?: IssueStatus): Promise<Issue[] | IssueBoard> {
    if (status) {
      return this.provider.list(status);
    }
    const all = await this.provider.list();
    const board = BOARD_COLUMNS.reduce((acc, col) => {
      acc[col] = [];
      return acc;
    }, {} as IssueBoard);
    for (const issue of all) {
      board[issue.status].push(issue);
    }
    return board;
  }

  get(id: string): Promise<IssueWithRelations> {
    return this.provider.get(id);
  }

  create(dto: CreateIssueDto, creatorId: string): Promise<Issue> {
    return this.provider.create(dto, creatorId);
  }

  update(id: string, dto: UpdateIssueDto): Promise<Issue> {
    return this.provider.update(id, dto);
  }

  comment(
    id: string,
    dto: CreateIssueCommentDto,
    authorId: string,
  ): Promise<IssueComment> {
    return this.provider.comment(id, dto, authorId);
  }
}
