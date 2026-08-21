import {
  Body,
  Controller,
  Delete,
  Get,
  HttpCode,
  HttpStatus,
  Param,
  ParseUUIDPipe,
  Post,
  Query,
  UseGuards,
} from '@nestjs/common';
import { SpaceGuard } from '../spaces/guards/space.guard';
import { SpaceRoleGuard } from '../spaces/guards/space-role.guard';
import { MinRole } from '../spaces/decorators/min-role.decorator';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { ReposService } from './repos.service';
import { RepoConnectService } from './repo-connect.service';
import { RepoBrowseService } from './repo-browse.service';
import { CreateRepoDto } from './dto/repo.dto';
import { ConnectRepoDto } from './dto/connect-repo.dto';

/**
 * 저장소 등록 (docs/백엔드-설계.md §4).
 *
 * **쓰기가 `admin` 이다.** 이슈와 다른 이유는 성격이다 — 저장소를 채널에
 * 붙이는 것은 그 채널에 남의 서비스가 글을 쓰게 하는 일이라, 스페이스의
 * 뼈대를 바꾸는 것에 가깝다.
 */
@Controller('spaces/:spaceId/repos')
@UseGuards(SpaceGuard, SpaceRoleGuard)
export class ReposController {
  constructor(
    private readonly repos: ReposService,
    private readonly connectService: RepoConnectService,
    private readonly browse: RepoBrowseService,
  ) {}

  @Get()
  list(@Param('spaceId', new ParseUUIDPipe()) spaceId: string) {
    return this.repos.list(spaceId);
  }

  /** 응답에만 `webhookSecret` 이 실린다. 목록에는 없다. */
  @Post()
  @MinRole('admin')
  create(
    @Param('spaceId', new ParseUUIDPipe()) spaceId: string,
    @Body() dto: CreateRepoDto,
  ) {
    return this.repos.create(spaceId, dto);
  }

  /** 시크릿을 잃어버렸을 때. 옛 시크릿은 그 순간부터 401 이 된다. */
  @Post(':repoId/secret')
  @MinRole('admin')
  rotate(
    @Param('spaceId', new ParseUUIDPipe()) spaceId: string,
    @Param('repoId', new ParseUUIDPipe()) repoId: string,
  ) {
    return this.repos.rotateSecret(spaceId, repoId);
  }

  /**
   * 자동 등록(10-2b). **수동 등록(`POST /`)과 합치지 않는다** — 요청 필드도
   * 응답도 실패 조건도 다르고, 특히 **수동은 `webhookSecret` 을 돌려줘야
   * 하지만 자동은 돌려줄 이유가 없다** (설계 §7).
   */
  @Post('connect')
  @MinRole('admin')
  connect(
    @Param('spaceId', new ParseUUIDPipe()) spaceId: string,
    @CurrentUser('id') userId: string,
    @Body() dto: ConnectRepoDto,
  ) {
    return this.connectService.connect(spaceId, userId, dto);
  }

  /** 훅을 다시 건다 — 주소가 바뀌었거나 등록에 실패했던 행. */
  @Post(':repoId/webhook')
  @MinRole('admin')
  reattach(
    @Param('spaceId', new ParseUUIDPipe()) spaceId: string,
    @Param('repoId', new ParseUUIDPipe()) repoId: string,
    @CurrentUser('id') userId: string,
  ) {
    return this.connectService.reattach(spaceId, userId, repoId);
  }

  /**
   * 열람 셋(10-3a). **`@MinRole` 을 걸지 않는다** — 저장소를 붙이는 것은
   * admin 이지만 보는 것은 이슈 열람과 같은 무게다 (설계 §2).
   */
  @Get(':repoId/branches')
  branches(
    @Param('spaceId', new ParseUUIDPipe()) spaceId: string,
    @Param('repoId', new ParseUUIDPipe()) repoId: string,
    @CurrentUser('id') userId: string,
  ) {
    return this.browse.branches(spaceId, userId, repoId);
  }

  /** `ref` 를 비우면 기본 브랜치, `path` 를 비우면 루트다. */
  @Get(':repoId/tree')
  tree(
    @Param('spaceId', new ParseUUIDPipe()) spaceId: string,
    @Param('repoId', new ParseUUIDPipe()) repoId: string,
    @CurrentUser('id') userId: string,
    @Query('ref') ref = '',
    @Query('path') path = '',
  ) {
    return this.browse.tree(spaceId, userId, repoId, ref, path);
  }

  /** `path` 는 필수다 — 루트는 파일이 아니다. */
  @Get(':repoId/blob')
  blob(
    @Param('spaceId', new ParseUUIDPipe()) spaceId: string,
    @Param('repoId', new ParseUUIDPipe()) repoId: string,
    @CurrentUser('id') userId: string,
    @Query('ref') ref = '',
    @Query('path') path = '',
  ) {
    return this.browse.blob(spaceId, userId, repoId, ref, path);
  }

  /** 브랜치 이력(10-3b). `ref` 를 비우면 기본 브랜치다. */
  @Get(':repoId/commits')
  commits(
    @Param('spaceId', new ParseUUIDPipe()) spaceId: string,
    @Param('repoId', new ParseUUIDPipe()) repoId: string,
    @CurrentUser('id') userId: string,
    @Query('ref') ref = '',
    @Query('cursor') cursor = '',
  ) {
    return this.browse.commits(spaceId, userId, repoId, ref, cursor);
  }

  /**
   * 커밋 하나 — 메시지와 **바뀐 파일 목록**. diff 본문은 주지 않는다.
   *
   * **`:sha` 에 `ParseUUIDPipe` 를 걸지 않는다** — sha 는 uuid 가 아니다.
   */
  @Get(':repoId/commits/:sha')
  commit(
    @Param('spaceId', new ParseUUIDPipe()) spaceId: string,
    @Param('repoId', new ParseUUIDPipe()) repoId: string,
    @Param('sha') sha: string,
    @CurrentUser('id') userId: string,
  ) {
    return this.browse.commitDetail(spaceId, userId, repoId, sha);
  }

  /** **GitHub 훅을 먼저 떼고 우리 행을 지운다.** */
  @Delete(':repoId')
  @MinRole('admin')
  @HttpCode(HttpStatus.NO_CONTENT)
  async remove(
    @Param('spaceId', new ParseUUIDPipe()) spaceId: string,
    @Param('repoId', new ParseUUIDPipe()) repoId: string,
    @CurrentUser('id') userId: string,
  ): Promise<void> {
    const target = await this.repos.findForDetach(spaceId, repoId);
    await this.connectService.detachHook(userId, target);
    await this.repos.remove(spaceId, repoId);
  }
}
