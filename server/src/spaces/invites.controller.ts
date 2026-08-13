import { Controller, HttpCode, HttpStatus, Param, Post } from '@nestjs/common';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { SpacesService } from './spaces.service';

/**
 * 초대 수락은 아직 그 스페이스의 멤버가 아닌 사람이 호출하므로
 * `/api/spaces/:spaceId` 밖에 둔다 (docs/백엔드-설계.md §4).
 * 인증은 필요하다 — 로그인한 계정을 스페이스에 넣는 동작이다.
 */
@Controller('invites')
export class InvitesController {
  constructor(private readonly spaces: SpacesService) {}

  /** POST /api/invites/:code/accept */
  @Post(':code/accept')
  @HttpCode(HttpStatus.OK)
  accept(@CurrentUser('id') userId: string, @Param('code') code: string) {
    return this.spaces.acceptInvite(userId, code);
  }
}
