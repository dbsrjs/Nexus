import { Injectable } from '@nestjs/common';
import { Prisma, Worklog } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { ListWorklogsDto } from './dto/list-worklogs.dto';
import { CreateWorklogDto } from './dto/create-worklog.dto';

/** Normalize an ISO date(-time) string to a UTC midnight Date for @db.Date. */
function toDateOnly(value: string): Date {
  return new Date(`${value.slice(0, 10)}T00:00:00.000Z`);
}

@Injectable()
export class WorklogsService {
  constructor(private prisma: PrismaService) {}

  /**
   * Cursor-paginated worklogs. `requesterId` is the JWT user; when the query
   * omits `userId` it scopes to the requester's own logs.
   */
  async list(query: ListWorklogsDto, requesterId: string): Promise<Worklog[]> {
    const limit = query.limit ?? 30;
    const where: Prisma.WorklogWhereInput = {
      userId: query.userId ?? requesterId,
      ...(query.date ? { date: toDateOnly(query.date) } : {}),
    };

    return this.prisma.worklog.findMany({
      where,
      orderBy: [{ date: 'desc' }, { createdAt: 'desc' }],
      take: limit,
      ...(query.cursor
        ? { skip: 1, cursor: { id: query.cursor } }
        : {}),
    });
  }

  /** Create a worklog owned by `userId` (from the JWT). */
  create(dto: CreateWorklogDto, userId: string): Promise<Worklog> {
    const date = dto.date ? toDateOnly(dto.date) : toDateOnly(new Date().toISOString());
    return this.prisma.worklog.create({
      data: {
        userId,
        date,
        tag: dto.tag,
        body: dto.body,
      },
    });
  }
}
