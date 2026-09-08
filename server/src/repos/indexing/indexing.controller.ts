import { Body, Controller, Get, Param, ParseUUIDPipe, Post, UseGuards } from '@nestjs/common';
import { SpaceGuard } from '../../spaces/guards/space.guard';
import { SpaceRoleGuard } from '../../spaces/guards/space-role.guard';
import { MinRole } from '../../spaces/decorators/min-role.decorator';
import { IndexingService } from './indexing.service';
import { IndexingWorker } from './indexing.worker';
import { SearchIndexDto } from './dto/search-index.dto';

/** 상위 K 의 기본값. 13단계가 프롬프트에 넣기 좋은 크기다. */
const DEFAULT_TOP_K = 8;

/**
 * 인덱싱 상태 · 다시 태우기 · 검색.
 *
 * **`SpaceRoleGuard` 를 읽기에 걸지 않는다**(10-3a 와 같다) — 걸면 코드를 볼 수
 * 있는 사람과 저장소 설정을 바꿀 수 있는 사람이 같아진다. **다시 태우기만
 * `admin`** 인 이유는 그것이 GitHub 할당량과 임베딩 할당량을 쓰는 일이어서다.
 *
 * **앱은 이 셋을 쓰지 않는다.** 12단계에는 화면이 없다 — 13단계 AI 가 쓸 자리다.
 */
@Controller('spaces/:spaceId/repos/:repoId/index')
@UseGuards(SpaceGuard)
export class IndexingController {
  constructor(
    private readonly indexing: IndexingService,
    private readonly worker: IndexingWorker,
  ) {}

  @Get()
  status(
    @Param('spaceId', new ParseUUIDPipe()) spaceId: string,
    @Param('repoId', new ParseUUIDPipe()) repoId: string,
  ) {
    return this.indexing.status(spaceId, repoId);
  }

  @Post()
  @UseGuards(SpaceRoleGuard)
  @MinRole('admin')
  async requeue(
    @Param('spaceId', new ParseUUIDPipe()) spaceId: string,
    @Param('repoId', new ParseUUIDPipe()) repoId: string,
  ) {
    const result = await this.indexing.requeue(spaceId, repoId);
    // 깨우는 것은 컨트롤러의 일이다 — 서비스가 워커를 부르면 둘이 서로를
    // 참조해 순환 의존이 된다(IndexingWorker 가 이미 IndexingService 를 쓴다).
    this.worker.kick();
    return result;
  }

  @Post('search')
  search(
    @Param('spaceId', new ParseUUIDPipe()) spaceId: string,
    @Param('repoId', new ParseUUIDPipe()) repoId: string,
    @Body() dto: SearchIndexDto,
  ) {
    return this.indexing.search(spaceId, repoId, dto.query, dto.topK ?? DEFAULT_TOP_K);
  }
}
