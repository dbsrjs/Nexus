import { Injectable, NotFoundException } from '@nestjs/common';
import { Prisma, User } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { UpdateMeDto } from './dto/update-me.dto';

/** passwordHash 를 절대 내보내지 않는 투영. */
const publicUserSelect = {
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
  constructor(private prisma: PrismaService) {}

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

  /** PATCH /api/me */
  updateMe(id: string, dto: UpdateMeDto): Promise<PublicUser> {
    return this.prisma.user.update({
      where: { id },
      data: {
        ...(dto.name !== undefined ? { name: dto.name.trim() } : {}),
        ...(dto.avatarUrl !== undefined ? { avatarUrl: dto.avatarUrl } : {}),
        ...(dto.globalStatus !== undefined
          ? { globalStatus: dto.globalStatus }
          : {}),
      },
      select: publicUserSelect,
    });
  }

  /** 인증 내부용 — 해시를 포함한 전체 레코드. */
  findByEmail(email: string): Promise<User | null> {
    return this.prisma.user.findUnique({ where: { email } });
  }
}
