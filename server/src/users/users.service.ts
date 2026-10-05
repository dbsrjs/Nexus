import { Injectable, NotFoundException } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { RealtimeEmitter } from '../realtime/realtime-emitter';
import { broadcastUserUpdated } from './user-events';
import { UpdateMeDto } from './dto/update-me.dto';

/** passwordHash 를 절대 내보내지 않는 투영. */
export const publicUserSelect = {
  id: true,
  email: true,
  name: true,
  avatarUrl: true,
  globalStatus: true,
  createdAt: true,
  updatedAt: true,
} satisfies Prisma.UserSelect;

export type PublicUser = Prisma.UserGetPayload<{
  select: typeof publicUserSelect;
}>;

@Injectable()
export class UsersService {
  constructor(
    private prisma: PrismaService,
    private readonly realtime: RealtimeEmitter,
  ) {}

  /** GET /api/me */
  async findMe(id: string): Promise<PublicUser> {
    const user = await this.prisma.user.findUnique({
      where: { id },
      select: publicUserSelect,
    });
    if (!user) {
      throw new NotFoundException('사용자를 찾을 수 없습니다');
    }
    return user;
  }

  /**
   * PATCH /api/me. 이름이 바뀌면 함께 쓰는 스페이스에 `user:updated` 를 보낸다 —
   * 받은 앱이 캐시의 작성자명을 고친다(14단계 설계 D4).
   */
  async updateMe(id: string, dto: UpdateMeDto): Promise<PublicUser> {
    const user = await this.prisma.user.update({
      where: { id },
      data: {
        ...(dto.name !== undefined ? { name: dto.name.trim() } : {}),
        ...(dto.globalStatus !== undefined
          ? { globalStatus: dto.globalStatus }
          : {}),
      },
      select: publicUserSelect,
    });
    if (dto.name !== undefined) {
      await broadcastUserUpdated(this.prisma, this.realtime, user);
    }
    return user;
  }
}
