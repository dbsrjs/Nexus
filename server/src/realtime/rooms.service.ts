import { Injectable } from '@nestjs/common';
import type { SpaceMember } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { ChannelsService } from '../channels/channels.service';

export interface RoomSet {
  spaceIds: string[];
  channelIds: string[];
}

@Injectable()
export class RoomsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly channels: ChannelsService,
  ) {}

  /**
   * 이 사용자가 조인해야 할 룸 집합.
   *
   * 연결 하나가 사용자의 **전 스페이스**를 담당한다. 앱은 연결을 하나만 관리하고
   * 스페이스 전환에 재연결이 없다.
   *
   * 가시성 규칙은 ChannelsService 한 곳에만 있어야 한다. 여기서 규칙을 복제하면
   * 두 곳이 어긋나는 순간 남의 메시지가 새므로, 스페이스마다
   * viewableChannelIds() 를 부른다. 스페이스 수는 한 자릿수다.
   */
  async computeRooms(userId: string): Promise<RoomSet> {
    const members = await this.prisma.spaceMember.findMany({ where: { userId } });

    const perSpace = await Promise.all(
      members.map((member) => this.channels.viewableChannelIds(member)),
    );

    return {
      spaceIds: members.map((m) => m.spaceId),
      channelIds: perSpace.flat(),
    };
  }

  /**
   * 소켓 핸들러가 권한을 확인할 때 쓴다. 소켓에 역할을 담지 않기 때문에
   * (스페이스마다 다르다) 매번 여기서 읽는다 — SpaceGuard 와 같은 이유다.
   */
  findMember(userId: string, spaceId: string): Promise<SpaceMember | null> {
    return this.prisma.spaceMember.findUnique({
      where: { spaceId_userId: { spaceId, userId } },
    });
  }
}
