import {
  Body,
  Controller,
  Delete,
  Get,
  HttpCode,
  HttpStatus,
  Param,
  ParseUUIDPipe,
  Patch,
  Post,
  Put,
  Query,
  UseGuards,
} from '@nestjs/common';
import { SpaceRole } from '@prisma/client';
import { CurrentSpaceMember } from '../spaces/decorators/current-space-member.decorator';
import {
  AuthUser,
  CurrentUser,
} from '../common/decorators/current-user.decorator';
import { SpaceGuard } from '../spaces/guards/space.guard';
import { SpaceRoleGuard } from '../spaces/guards/space-role.guard';
import { MinRole } from '../spaces/decorators/min-role.decorator';
import { IssuesService } from './issues.service';
import { IssueCommentsService } from './issue-comments.service';
import { CreateIssueDto } from './dto/create-issue.dto';
import { ListIssuesDto } from './dto/list-issues.dto';
import { MoveIssueDto } from './dto/move-issue.dto';
import { UpdateIssueDto } from './dto/update-issue.dto';
import { CreateIssueCommentDto } from './dto/create-comment.dto';

/**
 * 이슈 보드 (docs/백엔드-설계.md §4).
 *
 * 쓰기가 `member` 이상인 이유는 성격이다 — 채널·카테고리는 스페이스의 뼈대라
 * admin 이 지키지만, **이슈는 일하는 사람이 만드는 것**이다. guest 는 읽는다.
 */
@Controller('spaces/:spaceId/issues')
@UseGuards(SpaceGuard, SpaceRoleGuard)
export class IssuesController {
  constructor(
    private readonly issues: IssuesService,
    private readonly comments: IssueCommentsService,
  ) {}

  @Get()
  list(
    @Param('spaceId', new ParseUUIDPipe()) spaceId: string,
    @Query() query: ListIssuesDto,
  ) {
    return this.issues.list(spaceId, query);
  }

  @Post()
  @MinRole('member')
  create(
    @Param('spaceId', new ParseUUIDPipe()) spaceId: string,
    @Body() dto: CreateIssueDto,
    @CurrentUser() user: AuthUser,
  ) {
    return this.issues.create(spaceId, user.id, dto);
  }

  @Get(':issueId')
  get(
    @Param('spaceId', new ParseUUIDPipe()) spaceId: string,
    @Param('issueId', new ParseUUIDPipe()) issueId: string,
  ) {
    return this.issues.get(spaceId, issueId);
  }

  @Patch(':issueId')
  @MinRole('member')
  update(
    @Param('spaceId', new ParseUUIDPipe()) spaceId: string,
    @Param('issueId', new ParseUUIDPipe()) issueId: string,
    @Body() dto: UpdateIssueDto,
  ) {
    return this.issues.update(spaceId, issueId, dto);
  }

  @Put(':issueId/position')
  @MinRole('member')
  move(
    @Param('spaceId', new ParseUUIDPipe()) spaceId: string,
    @Param('issueId', new ParseUUIDPipe()) issueId: string,
    @Body() dto: MoveIssueDto,
  ) {
    return this.issues.move(spaceId, issueId, dto);
  }

  /**
   * 이슈를 지운다. **하드 삭제**다(설계 §6-1).
   *
   * `@MinRole` 을 걸지 않는 이유는 권한이 역할만으로 갈리지 않아서다 —
   * 작성자는 자기 이슈를 지울 수 있고, 남의 이슈는 admin 이상이어야 한다.
   * 서비스가 두 조건을 함께 본다.
   */
  @Delete(':issueId')
  @HttpCode(HttpStatus.NO_CONTENT)
  remove(
    @Param('spaceId', new ParseUUIDPipe()) spaceId: string,
    @Param('issueId', new ParseUUIDPipe()) issueId: string,
    @CurrentUser() user: AuthUser,
    @CurrentSpaceMember('role') role: SpaceRole,
  ) {
    return this.comments.remove(spaceId, issueId, user.id, role);
  }

  @Get(':issueId/comments')
  listComments(
    @Param('spaceId', new ParseUUIDPipe()) spaceId: string,
    @Param('issueId', new ParseUUIDPipe()) issueId: string,
  ) {
    return this.comments.list(spaceId, issueId);
  }

  @Post(':issueId/comments')
  @MinRole('member')
  createComment(
    @Param('spaceId', new ParseUUIDPipe()) spaceId: string,
    @Param('issueId', new ParseUUIDPipe()) issueId: string,
    @Body() dto: CreateIssueCommentDto,
    @CurrentUser() user: AuthUser,
  ) {
    return this.comments.create(spaceId, issueId, user.id, dto);
  }
}
