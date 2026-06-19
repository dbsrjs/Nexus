import { Issue, IssueComment, IssueStatus } from '@prisma/client';
import { CreateIssueDto } from './dto/create-issue.dto';
import { UpdateIssueDto } from './dto/update-issue.dto';
import { CreateIssueCommentDto } from './dto/create-comment.dto';

/**
 * DI token for the active issue provider. IssuesModule binds this to
 * {@link NativeIssueProvider} by default; a future Redmine provider can be
 * swapped in without touching the controller/service (design doc §1, §8).
 */
export const ISSUE_PROVIDER = Symbol('ISSUE_PROVIDER');

export type IssueWithRelations = Issue & {
  comments?: IssueComment[];
};

/**
 * Abstraction over the issue backend (native Prisma board today, Redmine
 * later). The controller depends only on this contract.
 */
export interface IssueProvider {
  /** All issues, optionally narrowed to one board column. */
  list(status?: IssueStatus): Promise<Issue[]>;

  /** Single issue with its comments, or throws NotFound. */
  get(id: string): Promise<IssueWithRelations>;

  /** Create a new issue; `creatorId` is the acting user. */
  create(dto: CreateIssueDto, creatorId: string): Promise<Issue>;

  /** Patch status/assignee/etc. of an existing issue. */
  update(id: string, dto: UpdateIssueDto): Promise<Issue>;

  /** Append a comment authored by `authorId`. */
  comment(
    id: string,
    dto: CreateIssueCommentDto,
    authorId: string,
  ): Promise<IssueComment>;
}
