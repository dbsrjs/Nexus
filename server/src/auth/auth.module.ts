import { Module } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { JwtModule } from '@nestjs/jwt';
import { PassportModule } from '@nestjs/passport';
import { AuthController } from './auth.controller';
import { AuthService } from './auth.service';
import { JwtStrategy } from './jwt.strategy';
import { RefreshTokenService } from './refresh-token.service';
import { resolveJwtSecrets } from '../config/jwt.config';

@Module({
  imports: [
    PassportModule.register({ defaultStrategy: 'jwt' }),
    JwtModule.registerAsync({
      imports: [ConfigModule],
      inject: [ConfigService],
      // 시크릿 해석은 resolveJwtSecrets 한 곳에서만 한다. 폴백 상수는 없다 —
      // JWT_SECRET 이 없으면 여기서 부팅이 중단된다.
      useFactory: (config: ConfigService) => {
        const secrets = resolveJwtSecrets(config);
        return {
          secret: secrets.accessSecret,
          signOptions: { expiresIn: secrets.accessTtl },
        };
      },
    }),
  ],
  controllers: [AuthController],
  providers: [AuthService, JwtStrategy, RefreshTokenService],
  exports: [AuthService, RefreshTokenService, JwtModule, PassportModule],
})
export class AuthModule {}
