import { Controller, Get, Param, UseGuards } from '@nestjs/common';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import {
  CurrentUser,
  AuthUser,
} from '../common/decorators/current-user.decorator';
import { UsersService } from './users.service';

/**
 * Routes:
 *   GET /api/me            current authenticated user (design doc §4)
 *   GET /api/users         directory listing
 *   GET /api/users/:id     basic user lookup
 *
 * Empty @Controller() keeps these at the /api root so `me` is /api/me.
 */
@Controller()
@UseGuards(JwtAuthGuard)
export class UsersController {
  constructor(private readonly users: UsersService) {}

  @Get('me')
  me(@CurrentUser() user: AuthUser) {
    return this.users.findMe(user.id);
  }

  @Get('users')
  list() {
    return this.users.list();
  }

  @Get('users/:id')
  findOne(@Param('id') id: string) {
    return this.users.findById(id);
  }
}
