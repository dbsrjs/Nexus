import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { APP_FILTER, APP_GUARD } from '@nestjs/core';
import { ScheduleModule } from '@nestjs/schedule';
import { PrismaModule } from './prisma/prisma.module';
import { HttpExceptionFilter } from './common/filters/http-exception.filter';
import { JwtAuthGuard } from './auth/guards/jwt-auth.guard';

import { AuthModule } from './auth/auth.module';
import { UsersModule } from './users/users.module';
import { SpacesModule } from './spaces/spaces.module';
import { CategoriesModule } from './categories/categories.module';
import { ChannelsModule } from './channels/channels.module';
import { PermissionsModule } from './permissions/permissions.module';
import { MessagesModule } from './messages/messages.module';
import { AttachmentsModule } from './attachments/attachments.module';
import { IssuesModule } from './issues/issues.module';
import { SprintsModule } from './sprints/sprints.module';
import { ReposModule } from './repos/repos.module';
import { OauthModule } from './oauth/oauth.module';
import { RealtimeModule } from './realtime/realtime.module';
import { EmbeddingModule } from './embedding/embedding.module';
import { LlmModule } from './llm/llm.module';
import { AiModule } from './ai/ai.module';
import { NotificationsModule } from './notifications/notifications.module';
import { VoiceModule } from './voice/voice.module';

/**
 * 전환 3단계 시점의 모듈 구성 (docs/전환-계획.md §6).
 *
 * 단일 테넌트 시절 모듈은 전부 spaceId 기준으로 다시 쓰거나 지웠다
 * (issues 9-1 · ai 13-1 · permissions 16-2 · notifications 18 은 다시 써 편입,
 *  files 는 8-1 에서 attachments 로 다시 썼다). gitlab 은 뺐다(2026-10-10).
 */
@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    // 고아 첨부 정리(24시간)를 돌리기 위한 것. 지금은 그 작업 하나뿐이다.
    ScheduleModule.forRoot(),
    PrismaModule,

    AuthModule,
    UsersModule,
    SpacesModule,
    CategoriesModule,
    ChannelsModule,
    PermissionsModule,
    MessagesModule,
    AttachmentsModule,
    IssuesModule,
    SprintsModule,
    ReposModule,
    OauthModule,
    RealtimeModule,
    EmbeddingModule,
    LlmModule,
    AiModule,
    NotificationsModule,
    VoiceModule,
  ],
  providers: [
    {
      provide: APP_FILTER,
      useClass: HttpExceptionFilter,
    },
    // 전역 JWT 인증. @Public() 이 붙은 라우트만 예외다.
    {
      provide: APP_GUARD,
      useClass: JwtAuthGuard,
    },
  ],
})
export class AppModule {}
