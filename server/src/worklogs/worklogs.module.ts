import { Module } from '@nestjs/common';
import { WorklogsController } from './worklogs.controller';
import { WorklogsService } from './worklogs.service';

/** Worklogs (업무일지) feature module. */
@Module({
  controllers: [WorklogsController],
  providers: [WorklogsService],
  exports: [WorklogsService],
})
export class WorklogsModule {}
