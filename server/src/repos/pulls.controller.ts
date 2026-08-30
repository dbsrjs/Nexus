import {
  Controller,
  Get,
  Param,
  ParseIntPipe,
  ParseUUIDPipe,
  Query,
  UseGuards,
} from '@nestjs/common';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { SpaceGuard } from '../spaces/guards/space.guard';
import { PullsService } from './pulls.service';

/**
 * PR 열람. `repos.controller.ts` 에 붙이지 않은 이유는 그 파일이 이미
 * **등록·관리(POST)와 열람(GET)을 함께** 들고 있어서다. 늘리는 대신 PR 은
 * 자기 파일로 시작한다.
 *
 * **`SpaceRoleGuard` 를 걸지 않는다** — 읽기다(10-3a 와 같다). 걸면 코드를
 * 볼 수 있는 사람과 저장소 설정을 바꿀 수 있는 사람이 같아진다.
 */
@Controller('spaces/:spaceId/repos/:repoId/pulls')
@UseGuards(SpaceGuard)
export class PullsController {
  constructor(private readonly pulls: PullsService) {}

  @Get()
  list(
    @Param('spaceId', new ParseUUIDPipe()) spaceId: string,
    @Param('repoId', new ParseUUIDPipe()) repoId: string,
    @CurrentUser('id') userId: string,
    @Query('state') state = 'open',
    @Query('page') page = '1',
  ) {
    const parsed = Number(page);
    return this.pulls.list(
      spaceId,
      userId,
      repoId,
      state,
      Number.isFinite(parsed) && parsed > 0 ? parsed : 1,
    );
  }

  @Get(':number')
  detail(
    @Param('spaceId', new ParseUUIDPipe()) spaceId: string,
    @Param('repoId', new ParseUUIDPipe()) repoId: string,
    @Param('number', new ParseIntPipe()) num: number,
    @CurrentUser('id') userId: string,
  ) {
    return this.pulls.detail(spaceId, userId, repoId, num);
  }

  @Get(':number/files')
  files(
    @Param('spaceId', new ParseUUIDPipe()) spaceId: string,
    @Param('repoId', new ParseUUIDPipe()) repoId: string,
    @Param('number', new ParseIntPipe()) num: number,
    @CurrentUser('id') userId: string,
  ) {
    return this.pulls.files(spaceId, userId, repoId, num);
  }
}
