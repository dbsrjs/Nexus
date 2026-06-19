import { ForbiddenException, Injectable } from '@nestjs/common';
import { Notice, Prisma } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { ListNoticesDto } from './dto/list-notices.dto';
import { CreateNoticeDto } from './dto/create-notice.dto';

/** Roles permitted to publish notices (design doc: lead/admin). */
const PUBLISHER_ROLES = ['lead', 'admin'];

@Injectable()
export class NoticesService {
  constructor(private prisma: PrismaService) {}

  /** Cursor-paginated notices, pinned first then newest. */
  list(query: ListNoticesDto): Promise<Notice[]> {
    const limit = query.limit ?? 30;
    const where: Prisma.NoticeWhereInput = {
      ...(query.team ? { team: query.team } : {}),
    };

    return this.prisma.notice.findMany({
      where,
      orderBy: [{ pinned: 'desc' }, { createdAt: 'desc' }],
      take: limit,
      ...(query.cursor ? { skip: 1, cursor: { id: query.cursor } } : {}),
    });
  }

  /**
   * Create a notice. Only lead/admin may publish; the role is enforced here
   * from the JWT (server-authoritative, not a front-end simulation).
   */
  create(dto: CreateNoticeDto, authorId: string, role: string): Promise<Notice> {
    if (!PUBLISHER_ROLES.includes(role)) {
      throw new ForbiddenException('공지 작성 권한이 없습니다.');
    }
    return this.prisma.notice.create({
      data: {
        authorId,
        title: dto.title,
        team: dto.team,
        pinned: dto.pinned ?? false,
        body: dto.body,
      },
    });
  }
}
