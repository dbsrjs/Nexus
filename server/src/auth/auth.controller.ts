import {
  Body,
  Controller,
  HttpCode,
  HttpStatus,
  Post,
  Req,
  Res,
  UnauthorizedException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import type { Request, Response } from 'express';
import { AuthService, AuthTokens } from './auth.service';
import { ClientFingerprint } from './refresh-token.service';
import { LoginDto } from './dto/login.dto';
import { RefreshDto } from './dto/refresh.dto';
import { SignupDto } from './dto/signup.dto';
import { Public } from '../common/decorators/public.decorator';

/** 웹 클라이언트의 리프레시 토큰을 담는 HttpOnly 쿠키. */
const REFRESH_COOKIE = 'nexus_refresh';

@Controller('auth')
export class AuthController {
  constructor(
    private readonly auth: AuthService,
    private readonly config: ConfigService,
  ) {}

  /** POST /api/auth/signup → { accessToken, refreshToken?, user } */
  @Public()
  @Post('signup')
  @HttpCode(HttpStatus.CREATED)
  async signup(
    @Body() dto: SignupDto,
    @Req() req: Request,
    @Res({ passthrough: true }) res: Response,
  ) {
    const { user, ...tokens } = await this.auth.signup(
      dto.email,
      dto.password,
      dto.name,
      fingerprint(req),
    );
    return { user, ...this.deliverTokens(tokens, dto.client, res) };
  }

  /** POST /api/auth/login → { accessToken, refreshToken?, user } */
  @Public()
  @Post('login')
  @HttpCode(HttpStatus.OK)
  async login(
    @Body() dto: LoginDto,
    @Req() req: Request,
    @Res({ passthrough: true }) res: Response,
  ) {
    const { user, ...tokens } = await this.auth.login(
      dto.email,
      dto.password,
      fingerprint(req),
    );
    return { user, ...this.deliverTokens(tokens, dto.client, res) };
  }

  /** POST /api/auth/refresh → { accessToken, refreshToken? } */
  @Public()
  @Post('refresh')
  @HttpCode(HttpStatus.OK)
  async refresh(
    @Body() dto: RefreshDto,
    @Req() req: Request,
    @Res({ passthrough: true }) res: Response,
  ) {
    const presented = dto.refreshToken ?? readRefreshCookie(req);
    if (!presented) {
      throw new UnauthorizedException('리프레시 토큰이 없습니다');
    }

    // 쿠키로 왔다면 웹 클라이언트다 — 명시하지 않아도 쿠키로 돌려준다.
    const mode = dto.client ?? (dto.refreshToken ? 'native' : 'web');
    const tokens = await this.auth.refresh(presented, fingerprint(req));
    return this.deliverTokens(tokens, mode, res);
  }

  /** POST /api/auth/logout — 이 세션의 리프레시 family 전체를 끊는다. */
  @Public()
  @Post('logout')
  @HttpCode(HttpStatus.NO_CONTENT)
  async logout(
    @Body() dto: RefreshDto,
    @Req() req: Request,
    @Res({ passthrough: true }) res: Response,
  ): Promise<void> {
    await this.auth.logout(dto.refreshToken ?? readRefreshCookie(req));
    res.clearCookie(REFRESH_COOKIE, { path: '/api/auth' });
  }

  /**
   * 웹이면 리프레시 토큰을 쿠키로만 내보내고 바디에서 뺀다.
   * 바디로도 함께 주면 HttpOnly 로 얻는 이점이 사라진다.
   */
  private deliverTokens(
    tokens: AuthTokens,
    client: 'web' | 'native' | undefined,
    res: Response,
  ): { accessToken: string; refreshToken?: string } {
    if (client !== 'web') {
      return {
        accessToken: tokens.accessToken,
        refreshToken: tokens.refreshToken,
      };
    }

    res.cookie(REFRESH_COOKIE, tokens.refreshToken, {
      httpOnly: true,
      sameSite: 'lax',
      secure: this.config.get<string>('COOKIE_SECURE') === 'true',
      expires: tokens.refreshExpiresAt,
      // 리프레시·로그아웃에만 전송된다. 다른 API 요청에는 실리지 않는다.
      path: '/api/auth',
    });

    return { accessToken: tokens.accessToken };
  }
}

function readRefreshCookie(req: Request): string | undefined {
  const cookies = (req as Request & { cookies?: Record<string, string> }).cookies;
  return cookies?.[REFRESH_COOKIE];
}

function fingerprint(req: Request): ClientFingerprint {
  return {
    userAgent: req.headers['user-agent'],
    ip: req.ip,
  };
}
