import {
  Body,
  Controller,
  Get,
  Param,
  ParseUUIDPipe,
  Patch,
  Post,
  Query,
} from '@nestjs/common';
import {
  CurrentUser,
  AuthUser,
} from '../common/decorators/current-user.decorator';
import { IssuesService } from './issues.service';
import { ListIssuesDto } from './dto/list-issues.dto';
import { CreateIssueDto } from './dto/create-issue.dto';
import { UpdateIssueDto } from './dto/update-issue.dto';
import { CreateIssueCommentDto } from './dto/create-comment.dto';

/**
 * Issue board API (design doc §4). Routes are relative to the global `/api`
 * prefix set in main.ts.
 */
@Controller('issues')
export class IssuesController {
  constructor(private readonly issues: IssuesService) {}

  /** GET /api/issues?status= — single column, or full board when omitted. */
  @Get()
  list(@Query() query: ListIssuesDto) {
    return this.issues.list(query.status);
  }

  /** GET /api/issues/:id — issue with comments. */
  @Get(':id')
  get(@Param('id', ParseUUIDPipe) id: string) {
    return this.issues.get(id);
  }

  /** POST /api/issues */
  @Post()
  create(@Body() dto: CreateIssueDto, @CurrentUser() user: AuthUser) {
    return this.issues.create(dto, user.id);
  }

  /** PATCH /api/issues/:id — status/assignee/etc. */
  @Patch(':id')
  update(
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: UpdateIssueDto,
  ) {
    return this.issues.update(id, dto);
  }

  /** POST /api/issues/:id/comments */
  @Post(':id/comments')
  comment(
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: CreateIssueCommentDto,
    @CurrentUser() user: AuthUser,
  ) {
    return this.issues.comment(id, dto, user.id);
  }
}
