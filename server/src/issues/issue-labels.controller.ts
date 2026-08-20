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
import { IssueLabelsService } from './issue-labels.service';
import { CreateIssueLabelDto } from './dto/label.dto';

/**
 * 라벨은 스페이스가 공유하는 어휘라 이슈 밑이 아니라 스페이스 밑에 둔다
 * (docs/백엔드-설계.md §4 — `/spaces/:spaceId/labels`).
 *
 * 만들기가 `member`, 지우기가 `admin` 인 이유는 성격이 다르기 때문이다 —
 * 라벨을 하나 더 만드는 것은 일하는 사람의 일이지만, **지우는 것은 그 라벨이
 * 붙은 모든 이슈에서 함께 떨어지는 일**이다.
 */
@Controller('spaces/:spaceId/labels')
@UseGuards(SpaceGuard, SpaceRoleGuard)
export class IssueLabelsController {
  constructor(private readonly labels: IssueLabelsService) {}

  @Get()
  list(@Param('spaceId', new ParseUUIDPipe()) spaceId: string) {
    return this.labels.list(spaceId);
  }

  @Post()
  @MinRole('member')
  create(
    @Param('spaceId', new ParseUUIDPipe()) spaceId: string,
    @Body() dto: CreateIssueLabelDto,
  ) {
    return this.labels.create(spaceId, dto);
  }

  @Delete(':labelId')
  @MinRole('admin')
  @HttpCode(HttpStatus.NO_CONTENT)
  remove(
    @Param('spaceId', new ParseUUIDPipe()) spaceId: string,
    @Param('labelId', new ParseUUIDPipe()) labelId: string,
  ) {
    return this.labels.remove(spaceId, labelId);
  }
}
