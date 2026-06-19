import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { APP_FILTER, APP_GUARD } from '@nestjs/core';
import { PrismaModule } from './prisma/prisma.module';
import { HttpExceptionFilter } from './common/filters/http-exception.filter';
import { JwtAuthGuard } from './auth/guards/jwt-auth.guard';

// ──────────────────────────────────────────────
// FEATURE MODULES
// ──────────────────────────────────────────────
import { AuthModule } from './auth/auth.module';
import { UsersModule } from './users/users.module';
import { PermissionsModule } from './permissions/permissions.module';
import { ChannelsModule } from './channels/channels.module';
import { MessagesModule } from './messages/messages.module';
import { RealtimeModule } from './realtime/realtime.module';
import { FilesModule } from './files/files.module';
import { NotificationsModule } from './notifications/notifications.module';
import { IssuesModule } from './issues/issues.module';
import { WorklogsModule } from './worklogs/worklogs.module';
import { AttendanceModule } from './attendance/attendance.module';
import { NoticesModule } from './notices/notices.module';
import { GitlabModule } from './gitlab/gitlab.module';
import { AiModule } from './ai/ai.module';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    PrismaModule,

    // ──────────────────────────────────────────────
    // FEATURE MODULES (wired by integrate phase)
    // ──────────────────────────────────────────────
    AuthModule,
    UsersModule,
    PermissionsModule,
    ChannelsModule,
    MessagesModule,
    RealtimeModule,
    FilesModule,
    NotificationsModule,
    IssuesModule,
    WorklogsModule,
    AttendanceModule,
    NoticesModule,
    GitlabModule,
    AiModule,
  ],
  providers: [
    {
      provide: APP_FILTER,
      useClass: HttpExceptionFilter,
    },
    // Global JWT auth — every route requires a valid Bearer token unless marked @Public().
    {
      provide: APP_GUARD,
      useClass: JwtAuthGuard,
    },
  ],
})
export class AppModule {}
