import { Controller, Get, Param, ParseUUIDPipe, UseGuards } from '@nestjs/common';
import { SpaceGuard } from '../spaces/guards/space.guard';
import { RepoBrowseService } from './repo-browse.service';

/**
 * 저장소 이벤트 하나. **저장소 밑이 아니다** — 앱이 메시지에서 얻는 것은
 * `eventId` 하나이고, 그것으로 `repoId` 를 찾는 것은 서버의 일이다 (설계 §2).
 * 앱에게 저장소 id 를 먼저 알아 오라고 요구하면 왕복이 하나 는다.
 *
 * `SpaceRoleGuard` 를 걸지 않는다 — 읽기다(10-3a §2 와 같다).
 */
@Controller('spaces/:spaceId/repo-events')
@UseGuards(SpaceGuard)
export class RepoEventsController {
  constructor(private readonly browse: RepoBrowseService) {}

  @Get(':eventId')
  detail(
    @Param('spaceId', new ParseUUIDPipe()) spaceId: string,
    @Param('eventId', new ParseUUIDPipe()) eventId: string,
  ) {
    return this.browse.eventCommits(spaceId, eventId);
  }
}
