import { Body, Controller, Get, Post, Query } from '@nestjs/common';
import {
  CurrentUser,
  AuthUser,
} from '../common/decorators/current-user.decorator';
import { WorklogsService } from './worklogs.service';
import { ListWorklogsDto } from './dto/list-worklogs.dto';
import { CreateWorklogDto } from './dto/create-worklog.dto';

/** Worklog (업무일지) API — design doc §4. */
@Controller('worklogs')
export class WorklogsController {
  constructor(private readonly worklogs: WorklogsService) {}

  /** GET /api/worklogs?cursor=&limit=&userId=&date= */
  @Get()
  list(@Query() query: ListWorklogsDto, @CurrentUser() user: AuthUser) {
    return this.worklogs.list(query, user.id);
  }

  /** POST /api/worklogs */
  @Post()
  create(@Body() dto: CreateWorklogDto, @CurrentUser() user: AuthUser) {
    return this.worklogs.create(dto, user.id);
  }
}
