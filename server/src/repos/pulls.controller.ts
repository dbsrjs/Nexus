import {
  BadRequestException,
  Controller,
  Get,
  Param,
  ParseUUIDPipe,
  PipeTransform,
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
/**
 * PR 번호 · 페이지 번호. **`ParseIntPipe` 로는 부족하다** — 음수를 그대로
 * 통과시켜 `/pulls/-5` 가 GitHub 까지 갔다가 404 로 돌아왔다. 우리가 아는
 * 잘못된 입력을 남의 서버에 물어볼 이유가 없다.
 */
class ParsePositiveIntPipe implements PipeTransform<string, number> {
  transform(value: string): number {
    const parsed = Number(value);
    if (!Number.isInteger(parsed) || parsed <= 0) {
      throw new BadRequestException('1 이상의 정수여야 합니다');
    }
    return parsed;
  }
}

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
    // 비어 있으면 첫 장이다. 값이 있는데 정수가 아니면 400 — `?page=2.5` 가
    // 조용히 실려 GitHub 에 그대로 나가던 것을 막는다.
    @Query('page') page?: string,
  ) {
    const parsed = page === undefined || page === '' ? 1 : new ParsePositiveIntPipe().transform(page);
    return this.pulls.list(spaceId, userId, repoId, state, parsed);
  }

  @Get(':number')
  detail(
    @Param('spaceId', new ParseUUIDPipe()) spaceId: string,
    @Param('repoId', new ParseUUIDPipe()) repoId: string,
    @Param('number', new ParsePositiveIntPipe()) num: number,
    @CurrentUser('id') userId: string,
  ) {
    return this.pulls.detail(spaceId, userId, repoId, num);
  }

  @Get(':number/files')
  files(
    @Param('spaceId', new ParseUUIDPipe()) spaceId: string,
    @Param('repoId', new ParseUUIDPipe()) repoId: string,
    @Param('number', new ParsePositiveIntPipe()) num: number,
    @CurrentUser('id') userId: string,
  ) {
    return this.pulls.files(spaceId, userId, repoId, num);
  }
}
