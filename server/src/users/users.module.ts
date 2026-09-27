import { Module } from '@nestjs/common';
import { UsersService } from './users.service';
import { UsersController } from './users.controller';
import { AvatarController } from './avatar.controller';
import { AvatarService } from './avatar.service';
import { StorageModule } from '../storage/storage.module';
import { RealtimeEmitterModule } from '../realtime/realtime-emitter.module';

@Module({
  imports: [StorageModule, RealtimeEmitterModule],
  controllers: [UsersController, AvatarController],
  providers: [UsersService, AvatarService],
  exports: [UsersService],
})
export class UsersModule {}
