import { Module } from '@nestjs/common';
import { IssuesController } from './issues.controller';
import { IssuesService } from './issues.service';
import { NativeIssueProvider } from './native-issue.provider';
import { ISSUE_PROVIDER } from './issue-provider.interface';

/**
 * Issues feature module. Binds the {@link ISSUE_PROVIDER} token to the native
 * Prisma provider by default; to switch to Redmine later, replace `useClass`
 * here with a RedmineIssueProvider — controller/service stay untouched.
 */
@Module({
  controllers: [IssuesController],
  providers: [
    IssuesService,
    NativeIssueProvider,
    { provide: ISSUE_PROVIDER, useClass: NativeIssueProvider },
  ],
  exports: [IssuesService],
})
export class IssuesModule {}
