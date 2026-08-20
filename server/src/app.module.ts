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
import { MessagesModule } from './messages/messages.module';
import { AttachmentsModule } from './attachments/attachments.module';
import { IssuesModule } from './issues/issues.module';
import { RealtimeModule } from './realtime/realtime.module';

/**
 * 전환 3단계 시점의 모듈 구성 (docs/전환-계획.md §6).
 *
 * 아직 spaceId 기준으로 이관하지 않은 모듈들 — permissions ·
 * notifications · files · issues · gitlab · ai — 은 여기서 등록을 뺐고,
 * tsconfig 의 exclude 로 컴파일 대상에서도 제외했다.
 * 되살리는 절차: tsconfig(.build).json 의 exclude 에서 해당 경로를 지우고
 * 여기 imports 에 다시 넣는다.
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
    MessagesModule,
    AttachmentsModule,
    IssuesModule,
    RealtimeModule,
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
