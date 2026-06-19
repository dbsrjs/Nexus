import { Module } from '@nestjs/common';
import { GitlabController } from './gitlab.controller';
import { GitlabService } from './gitlab.service';

/**
 * Read-only GitLab integration module.
 *
 * PrismaModule is @Global, so PrismaService is injected directly without
 * importing it here. ConfigModule is global too (GITLAB_URL / GITLAB_TOKEN).
 */
@Module({
  controllers: [GitlabController],
  providers: [GitlabService],
  exports: [GitlabService],
})
export class GitlabModule {}
