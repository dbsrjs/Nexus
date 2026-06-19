import { Injectable, UnauthorizedException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { JwtService } from '@nestjs/jwt';
import { User } from '@prisma/client';
import * as argon2 from 'argon2';
import { PrismaService } from '../prisma/prisma.service';
import { JwtPayload } from './jwt.strategy';

export interface AuthTokens {
  token: string;
  refreshToken: string;
}

export interface PublicUser {
  id: string;
  email: string;
  name: string;
  initial: string | null;
  color: string | null;
  team: string | null;
  title: string | null;
  role: User['role'];
  status: User['status'];
}

@Injectable()
export class AuthService {
  constructor(
    private prisma: PrismaService,
    private jwt: JwtService,
    private config: ConfigService,
  ) {}

  /**
   * Look up a user by email and verify the supplied password against the
   * stored argon2 hash. Returns the user on success, throws otherwise.
   */
  async validateUser(email: string, password: string): Promise<User> {
    const user = await this.prisma.user.findUnique({ where: { email } });
    if (!user) {
      // Same error regardless of cause — do not leak which emails exist.
      throw new UnauthorizedException('Invalid credentials');
    }

    let passwordOk = false;
    try {
      passwordOk = await argon2.verify(user.passwordHash, password);
    } catch {
      passwordOk = false;
    }

    if (!passwordOk) {
      throw new UnauthorizedException('Invalid credentials');
    }

    return user;
  }

  /**
   * POST /api/auth/login — verify credentials and issue tokens.
   * Returns { token, refreshToken, user } per design doc §4.
   */
  async login(
    email: string,
    password: string,
  ): Promise<AuthTokens & { user: PublicUser }> {
    const user = await this.validateUser(email, password);
    const tokens = await this.issueTokens(user);
    return { ...tokens, user: this.toPublicUser(user) };
  }

  /**
   * POST /api/auth/refresh — validate a refresh token and mint a fresh pair.
   */
  async refresh(refreshToken: string): Promise<AuthTokens> {
    let payload: JwtPayload;
    try {
      payload = await this.jwt.verifyAsync<JwtPayload>(refreshToken, {
        secret: this.refreshSecret(),
      });
    } catch {
      throw new UnauthorizedException('Invalid refresh token');
    }

    if (payload.type !== 'refresh') {
      throw new UnauthorizedException('Not a refresh token');
    }

    const user = await this.prisma.user.findUnique({ where: { id: payload.sub } });
    if (!user) {
      throw new UnauthorizedException('User no longer exists');
    }

    return this.issueTokens(user);
  }

  private async issueTokens(user: User): Promise<AuthTokens> {
    const base: Omit<JwtPayload, 'type'> = {
      sub: user.id,
      email: user.email,
      role: user.role,
    };

    const token = await this.jwt.signAsync({ ...base, type: 'access' });
    const refreshToken = await this.jwt.signAsync(
      { ...base, type: 'refresh' },
      {
        secret: this.refreshSecret(),
        expiresIn: this.config.get<string>('JWT_REFRESH_EXPIRES_IN') ?? '7d',
      },
    );

    return { token, refreshToken };
  }

  private refreshSecret(): string {
    return (
      this.config.get<string>('JWT_REFRESH_SECRET') ??
      this.config.get<string>('JWT_SECRET') ??
      'dev-insecure-secret'
    );
  }

  toPublicUser(user: User): PublicUser {
    return {
      id: user.id,
      email: user.email,
      name: user.name,
      initial: user.initial,
      color: user.color,
      team: user.team,
      title: user.title,
      role: user.role,
      status: user.status,
    };
  }
}
