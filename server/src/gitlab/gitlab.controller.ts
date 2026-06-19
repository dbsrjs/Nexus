import {
  Controller,
  Get,
  HttpCode,
  HttpStatus,
  Post,
  UseGuards,
} from '@nestjs/common';
import { Role } from '@prisma/client';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../common/decorators/roles.decorator';
import { GitlabService } from './gitlab.service';
import { GitlabRepoDto } from './dto/gitlab-repo.dto';
import { GitlabSyncResultDto } from './dto/sync-result.dto';

/**
 * Read-only GitLab integration endpoints (design doc §4 / §7).
 *
 * The global JWT guard already protects these routes; RolesGuard enforces the
 * per-handler @Roles(...) requirement. The manual sync trigger is admin-only.
 */
@Controller('gitlab')
export class GitlabController {
  constructor(private readonly gitlab: GitlabService) {}

  /** GET /api/gitlab/repos — synced repositories from cache. */
  @Get('repos')
  listRepos(): Promise<GitlabRepoDto[]> {
    return this.gitlab.listRepos();
  }

  /** POST /api/gitlab/sync — trigger a manual read-only sync (admin only). */
  @Post('sync')
  @HttpCode(HttpStatus.OK)
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(Role.admin)
  sync(): Promise<GitlabSyncResultDto> {
    return this.gitlab.sync();
  }
}
