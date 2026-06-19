import { Injectable, UnauthorizedException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { PassportStrategy } from '@nestjs/passport';
import { ExtractJwt, Strategy } from 'passport-jwt';
import { Role } from '@prisma/client';
import { AuthUser } from '../common/decorators/current-user.decorator';

/**
 * Access-token payload signed by AuthService.
 *   sub   = user id
 *   email = login email
 *   role  = global role
 *   type  = 'access' (refresh tokens carry type 'refresh' and are rejected here)
 */
export interface JwtPayload {
  sub: string;
  email: string;
  role: Role;
  type?: 'access' | 'refresh';
}

@Injectable()
export class JwtStrategy extends PassportStrategy(Strategy) {
  constructor(config: ConfigService) {
    super({
      jwtFromRequest: ExtractJwt.fromAuthHeaderAsBearerToken(),
      ignoreExpiration: false,
      secretOrKey: config.get<string>('JWT_SECRET') ?? 'dev-insecure-secret',
    });
  }

  /**
   * Whatever this returns becomes request.user. We expose the AuthUser shape
   * { id, email, role } consumed by @CurrentUser() across feature modules.
   */
  validate(payload: JwtPayload): AuthUser {
    if (payload.type === 'refresh') {
      throw new UnauthorizedException('Refresh token cannot be used for access');
    }
    return { id: payload.sub, email: payload.email, role: payload.role };
  }
}
