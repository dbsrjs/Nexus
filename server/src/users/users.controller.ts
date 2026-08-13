import { Body, Controller, Get, Patch } from '@nestjs/common';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { UsersService } from './users.service';
import { UpdateMeDto } from './dto/update-me.dto';

/**
 *   GET   /api/me
 *   PATCH /api/me
 *
 * 전역 사용자 목록(GET /api/users)은 없앴다. 멀티테넌트에서 전역 디렉터리는
 * 다른 스페이스의 사용자까지 노출하는 경로다. 사람 목록은 스페이스 단위로만
 * 조회한다 — GET /api/spaces/:spaceId/members (docs/백엔드-설계.md §4).
 *
 * 빈 @Controller() 라 라우트가 /api 루트에 붙는다.
 */
@Controller()
export class UsersController {
  constructor(private readonly users: UsersService) {}

  @Get('me')
  me(@CurrentUser('id') userId: string) {
    return this.users.findMe(userId);
  }

  @Patch('me')
  updateMe(@CurrentUser('id') userId: string, @Body() dto: UpdateMeDto) {
    return this.users.updateMe(userId, dto);
  }
}
