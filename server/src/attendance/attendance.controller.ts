import { Controller, Get, HttpCode, HttpStatus, Post, Query } from '@nestjs/common';
import {
  CurrentUser,
  AuthUser,
} from '../common/decorators/current-user.decorator';
import { AttendanceService } from './attendance.service';
import { ListAttendanceDto } from './dto/list-attendance.dto';

/** Attendance (근태) API — design doc §4. */
@Controller('attendance')
export class AttendanceController {
  constructor(private readonly attendance: AttendanceService) {}

  /** GET /api/attendance?userId=&from=&to= */
  @Get()
  list(@Query() query: ListAttendanceDto, @CurrentUser() user: AuthUser) {
    return this.attendance.list(query, user.id);
  }

  /** POST /api/attendance/check-in */
  @Post('check-in')
  @HttpCode(HttpStatus.OK)
  checkIn(@CurrentUser() user: AuthUser) {
    return this.attendance.checkIn(user.id);
  }

  /** POST /api/attendance/check-out */
  @Post('check-out')
  @HttpCode(HttpStatus.OK)
  checkOut(@CurrentUser() user: AuthUser) {
    return this.attendance.checkOut(user.id);
  }
}
