import { Module } from '@nestjs/common';
import { JwtModule } from '@nestjs/jwt';
import { ConfigModule } from '@nestjs/config';
import { RealtimeGateway } from './realtime.gateway';
import { ChannelsModule } from '../channels/channels.module';

/**
 * Realtime (Socket.IO) module. Owns the shared gateway that authenticates
 * the JWT on handshake and manages channel rooms. Exports RealtimeGateway so
 * MessagesModule (and later notifications/issues) can push live events.
 *
 * JwtModule is registered (not global) so the gateway can verify handshake
 * tokens; the auth phase configures its own JwtModule independently.
 */
@Module({
  imports: [ConfigModule, JwtModule.register({}), ChannelsModule],
  providers: [RealtimeGateway],
  exports: [RealtimeGateway],
})
export class RealtimeModule {}
