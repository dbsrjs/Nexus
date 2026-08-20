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
  Query,
  UseGuards,
} from '@nestjs/common';
import { SpaceGuard } from '../spaces/guards/space.guard';
import { SpaceRoleGuard } from '../spaces/guards/space-role.guard';
import { MinRole } from '../spaces/decorators/min-role.decorator';
import { SprintsService } from './sprints.service';
import {
  CreateSprintDto,
  ListSprintsDto,
  UpdateSprintDto,
} from './dto/sprint.dto';

/**
 * 스프린트 (docs/백엔드-설계.md §4).
 *
 * 이슈와 같은 권한 규칙이다 — 열람은 스페이스 멤버 전원, 쓰기는 `member` 이상.
 * 다만 **지우기는 `admin`** 이다. 스프린트를 지우면 그 안의 이슈가 전부
 * 백로그로 돌아가, 라벨 삭제와 같이 여러 이슈에 한꺼번에 영향을 준다.
 */
@Controller('spaces/:spaceId/sprints')
@UseGuards(SpaceGuard, SpaceRoleGuard)
export class SprintsController {
  constructor(private readonly sprints: SprintsService) {}

  @Get()
  list(
    @Param('spaceId', new ParseUUIDPipe()) spaceId: string,
    @Query() query: ListSprintsDto,
  ) {
    return this.sprints.list(spaceId, query);
  }

  @Post()
  @MinRole('member')
  create(
    @Param('spaceId', new ParseUUIDPipe()) spaceId: string,
    @Body() dto: CreateSprintDto,
  ) {
    return this.sprints.create(spaceId, dto);
  }

  @Patch(':sprintId')
  @MinRole('member')
  update(
    @Param('spaceId', new ParseUUIDPipe()) spaceId: string,
    @Param('sprintId', new ParseUUIDPipe()) sprintId: string,
    @Body() dto: UpdateSprintDto,
  ) {
    return this.sprints.update(spaceId, sprintId, dto);
  }

  @Delete(':sprintId')
  @MinRole('admin')
  @HttpCode(HttpStatus.NO_CONTENT)
  remove(
    @Param('spaceId', new ParseUUIDPipe()) spaceId: string,
    @Param('sprintId', new ParseUUIDPipe()) sprintId: string,
  ) {
    return this.sprints.remove(spaceId, sprintId);
  }

  /** 닫힌 스프린트도 그릴 수 있다 — 지난 것을 되돌아보는 것이 쓸모다. */
  @Get(':sprintId/burndown')
  burndown(
    @Param('spaceId', new ParseUUIDPipe()) spaceId: string,
    @Param('sprintId', new ParseUUIDPipe()) sprintId: string,
  ) {
    return this.sprints.burndown(spaceId, sprintId);
  }
}
