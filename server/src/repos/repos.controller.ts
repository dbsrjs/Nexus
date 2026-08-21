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
  UseGuards,
} from '@nestjs/common';
import { SpaceGuard } from '../spaces/guards/space.guard';
import { SpaceRoleGuard } from '../spaces/guards/space-role.guard';
import { MinRole } from '../spaces/decorators/min-role.decorator';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { ReposService } from './repos.service';
import { RepoConnectService } from './repo-connect.service';
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
