import { Injectable, UnauthorizedException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { PassportStrategy } from '@nestjs/passport';
import { ExtractJwt, Strategy } from 'passport-jwt';
import { AuthUser } from '../common/decorators/current-user.decorator';
import { resolveJwtSecrets } from '../config/jwt.config';

/**
 * 액세스 토큰 페이로드.
 *   sub  = 사용자 id
 *   jti  = 리프레시 토큰 행의 id (리프레시 토큰에만 있다)
 *   type = 'access' | 'refresh'
 *
 * 전역 역할(role)은 더 이상 토큰에 담지 않는다. 역할은 스페이스마다 다르므로
 * 토큰에 박아 두면 역할 변경이 토큰 만료 전까지 반영되지 않는다.
 */
export interface JwtPayload {
  sub: string;
  email: string;
  type: 'access' | 'refresh';
  jti?: string;
  fam?: string;
}

@Injectable()
export class JwtStrategy extends PassportStrategy(Strategy) {
  constructor(config: ConfigService) {
    super({
      jwtFromRequest: ExtractJwt.fromAuthHeaderAsBearerToken(),
      ignoreExpiration: false,
      secretOrKey: resolveJwtSecrets(config).accessSecret,
    });
  }

  validate(payload: JwtPayload): AuthUser {
    if (payload.type !== 'access') {
      throw new UnauthorizedException('액세스 토큰이 아닙니다');
    }
    return { id: payload.sub, email: payload.email };
  }
}
