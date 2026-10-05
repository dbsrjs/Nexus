import { Controller, Get, UseGuards } from '@nestjs/common';
import { SpaceMember } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { SpaceGuard } from '../spaces/guards/space.guard';
import { CurrentSpaceMember } from '../spaces/decorators/current-space-member.decorator';
import { PresenceService } from './presence.service';

/**
 * 프레즌스의 처음 값(17단계 D19). 이벤트만으로는 앱을 켠 순간의 상태를 모른다.
 * **이 스페이스 멤버만** 싣는다 — 함께 쓰지 않는 사람의 상태는 새지 않는다.
 */
@Controller('spaces/:spaceId/presence')
@UseGuards(SpaceGuard)
export class PresenceController {
  constructor(
    private readonly prisma: PrismaService,
    private readonly presence: PresenceService,
  ) {}

  @Get()
  async get(@CurrentSpaceMember() member: SpaceMember) {
    const members = await this.prisma.spaceMember.findMany({
      where: { spaceId: member.spaceId },
      select: { userId: true },
    });
    return { users: this.presence.snapshot(members.map((m) => m.userId)) };
  }
}
