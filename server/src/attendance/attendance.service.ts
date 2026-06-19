import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { Attendance, AttendanceStatus, Prisma } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { ListAttendanceDto } from './dto/list-attendance.dto';

/** Hour-of-day (local server time) after which a check-in counts as late (지각). */
const LATE_THRESHOLD_HOUR = 9;

/** Date at UTC midnight for the given Date's calendar day (for @db.Date). */
function dateOnly(d: Date): Date {
  return new Date(`${d.toISOString().slice(0, 10)}T00:00:00.000Z`);
}

@Injectable()
export class AttendanceService {
  constructor(private prisma: PrismaService) {}

  /**
   * Attendance rows for a user (defaults to requester), optionally bounded by
   * a date range. Newest first.
   */
  list(query: ListAttendanceDto, requesterId: string): Promise<Attendance[]> {
    const dateFilter: Prisma.DateTimeFilter = {};
    if (query.from) dateFilter.gte = dateOnly(new Date(query.from));
    if (query.to) dateFilter.lte = dateOnly(new Date(query.to));

    return this.prisma.attendance.findMany({
      where: {
        userId: query.userId ?? requesterId,
        ...(query.from || query.to ? { date: dateFilter } : {}),
      },
      orderBy: { date: 'desc' },
    });
  }

  /**
   * Check in for today. Sets status to 정상(normal) before the late threshold,
   * 지각(late) after. Idempotency: re-checking-in the same day is rejected.
   * The 근무중(working)/예정(scheduled) states are lifecycle markers: rows start
   * as scheduled (schema default) and the recorded punctuality (normal/late)
   * stands once the user has checked in.
   */
  async checkIn(userId: string): Promise<Attendance> {
    const now = new Date();
    const today = dateOnly(now);

    const existing = await this.prisma.attendance.findUnique({
      where: { userId_date: { userId, date: today } },
    });
    if (existing?.checkInAt) {
      throw new BadRequestException('이미 출근 처리되었습니다.');
    }

    const status =
      now.getHours() >= LATE_THRESHOLD_HOUR
        ? AttendanceStatus.late
        : AttendanceStatus.normal;

    return this.prisma.attendance.upsert({
      where: { userId_date: { userId, date: today } },
      create: { userId, date: today, checkInAt: now, status },
      update: { checkInAt: now, status },
    });
  }

  /**
   * Check out for today. Requires a prior check-in. Keeps the punctuality
   * status (정상/지각) recorded at check-in.
   */
  async checkOut(userId: string): Promise<Attendance> {
    const now = new Date();
    const today = dateOnly(now);

    const existing = await this.prisma.attendance.findUnique({
      where: { userId_date: { userId, date: today } },
    });
    if (!existing?.checkInAt) {
      throw new NotFoundException('먼저 출근 처리를 해주세요.');
    }
    if (existing.checkOutAt) {
      throw new BadRequestException('이미 퇴근 처리되었습니다.');
    }

    return this.prisma.attendance.update({
      where: { userId_date: { userId, date: today } },
      data: { checkOutAt: now },
    });
  }
}
