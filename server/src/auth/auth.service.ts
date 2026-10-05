import {
  BadRequestException,
  ConflictException,
  HttpException,
  HttpStatus,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { JwtService } from '@nestjs/jwt';
import { User } from '@prisma/client';
import * as argon2 from 'argon2';
import { PrismaService } from '../prisma/prisma.service';
import { JwtSecrets, resolveJwtSecrets } from '../config/jwt.config';
import { JwtPayload } from './jwt.strategy';
import {
  ClientFingerprint,
  IssuedRefreshToken,
  RefreshTokenService,
} from './refresh-token.service';
import { FailureThrottle } from './failure-throttle';

/**
 * 비밀번호 대조 실패 한도 — 15분에 10번. argon2 가 느려도 무제한이면 사전 공격이
 * 시간 문제다. 사람이 오타로 닿을 수는 없는 수로 잡았다.
 */
const PASSWORD_MAX_FAILURES = 10;
const PASSWORD_WINDOW_MS = 15 * 60 * 1000;

/**
 * 사람이 가입할 수 없는 이메일인가. **`.invalid` 는 RFC 2606 · 6761 이 예약한 최상위
 * 도메인**이라 실제 메일함이 없다 — 서버가 만드는 봇 계정(`github@bot.nexus.invalid`)이
 * 여기 있다. 막지 않으면 웹훅이 봇보다 먼저 가입한 사람의 계정을 봇으로 쓴다.
 */
export function isReservedEmail(email: string): boolean {
  const domain = email.trim().toLowerCase().split('@').pop() ?? '';
  return domain === 'invalid' || domain.endsWith('.invalid');
}

export interface AuthTokens {
  accessToken: string;
  refreshToken: string;
  /** 리프레시 토큰 만료 시각 — 클라이언트가 쿠키 수명을 맞추는 데 쓴다. */
  refreshExpiresAt: Date;
}

export interface PublicUser {
  id: string;
  email: string;
  name: string;
  avatarUrl: string | null;
  globalStatus: User['globalStatus'];
  createdAt: Date;
}

@Injectable()
export class AuthService {
  private readonly secrets: JwtSecrets;
  private readonly passwordFailures = new FailureThrottle(
    PASSWORD_MAX_FAILURES,
    PASSWORD_WINDOW_MS,
  );

  constructor(
    private readonly prisma: PrismaService,
    private readonly jwt: JwtService,
    private readonly refreshTokens: RefreshTokenService,
    config: ConfigService,
  ) {
    // 부팅 시점에 한 번 해석한다. 미설정이면 여기서 프로세스가 죽는다.
    this.secrets = resolveJwtSecrets(config);
  }

  /**
   * POST /api/auth/signup — 계정 생성 후 바로 로그인 상태로 만든다.
   */
  async signup(
    email: string,
    password: string,
    name: string,
    client: ClientFingerprint = {},
  ): Promise<AuthTokens & { user: PublicUser }> {
    const normalizedEmail = email.trim().toLowerCase();
    if (isReservedEmail(normalizedEmail)) {
      throw new BadRequestException('사용할 수 없는 이메일입니다');
    }

    const existing = await this.prisma.user.findUnique({
      where: { email: normalizedEmail },
    });
    if (existing) {
      throw new ConflictException('이미 가입된 이메일입니다');
    }

    const user = await this.prisma.user.create({
      data: {
        email: normalizedEmail,
        passwordHash: await argon2.hash(password),
        name: name.trim(),
      },
    });

    const tokens = await this.issueNewSession(user, client);
    return { ...tokens, user: this.toPublicUser(user) };
  }

  /**
   * 이메일로 사용자를 찾아 argon2 해시와 대조한다.
   * 실패 사유를 구분하지 않는다 — 어떤 이메일이 존재하는지 흘리지 않기 위함이다.
   */
  async validateUser(email: string, password: string): Promise<User> {
    const user = await this.prisma.user.findUnique({
      where: { email: email.trim().toLowerCase() },
    });

    // OAuth 전용 계정은 passwordHash 가 없다. 비밀번호 로그인 대상이 아니다.
    if (!user?.passwordHash) {
      throw new UnauthorizedException('이메일 또는 비밀번호가 올바르지 않습니다');
    }

    let passwordOk = false;
    try {
      passwordOk = await argon2.verify(user.passwordHash, password);
    } catch {
      passwordOk = false;
    }

    if (!passwordOk) {
      throw new UnauthorizedException('이메일 또는 비밀번호가 올바르지 않습니다');
    }

    return user;
  }

  /** POST /api/auth/login */
  async login(
    email: string,
    password: string,
    client: ClientFingerprint = {},
  ): Promise<AuthTokens & { user: PublicUser }> {
    // **주소 + 이메일**로 센다. 이메일만으로 세면 남의 이메일을 열 번 틀려 그 사람을
    // 잠글 수 있고, 주소만으로 세면 공용 NAT 뒤의 사람들이 함께 잠긴다.
    const key = `login:${client.ip ?? '-'}:${email.trim().toLowerCase()}`;
    this.assertNotThrottled(key);

    let user: User;
    try {
      user = await this.validateUser(email, password);
    } catch (err) {
      // DB 장애까지 실패로 세면 장애 중에 멀쩡한 사람이 잠긴다.
      if (err instanceof UnauthorizedException) this.passwordFailures.fail(key);
      throw err;
    }
    this.passwordFailures.succeed(key);
    const tokens = await this.issueNewSession(user, client);
    return { ...tokens, user: this.toPublicUser(user) };
  }

  /**
   * POST /api/auth/refresh — 회전(rotation). 이전 토큰은 즉시 무효가 된다.
   */
  async refresh(
    refreshToken: string,
    client: ClientFingerprint = {},
  ): Promise<AuthTokens> {
    const payload = await this.verifyRefreshJwt(refreshToken);

    const row = await this.refreshTokens.verifyUsable(
      payload.jti as string,
      refreshToken,
    );

    const user = await this.prisma.user.findUnique({ where: { id: row.userId } });
    if (!user) {
      await this.refreshTokens.revokeFamily(row.familyId);
      throw new UnauthorizedException('사용자가 존재하지 않습니다');
    }

    const next = this.refreshTokens.rotate(row, this.refreshTtlMs());
    const tokens = await this.signPair(user, next);
    await this.refreshTokens.commitRotation(row, next, tokens.refreshToken, client);

    return tokens;
  }

  /**
   * POST /api/auth/password — 비밀번호를 바꾼다 (14단계 설계 D11~D14).
   *
   * **틀린 현재 비밀번호는 400 이다.** 401 은 앱의 인터셉터가 액세스 토큰 만료로
   * 보고 리프레시를 돌리며, 403 은 앱이 404 와 같은 실패로 접는다.
   *
   * 해시 교체와 **그 사용자의 리프레시 토큰 전부 끊기**를 한 트랜잭션으로 한다 —
   * 사이에서 끊기면 비밀번호는 바뀌었는데 옛 세션이 살아남는다. 그 뒤 요청한
   * 기기에만 새 family 를 준다. 다른 기기는 액세스 토큰이 만료되는 대로(최대
   * 15분) 로그인 화면으로 간다.
   */
  async changePassword(
    userId: string,
    currentPassword: string,
    newPassword: string,
    client: ClientFingerprint = {},
  ): Promise<AuthTokens> {
    // 액세스 토큰만 훔친 사람이 현재 비밀번호를 맞혀 보는 경로다 — 로그인과 같은 한도를 건다.
    const key = `password:${userId}`;
    this.assertNotThrottled(key);

    const user = await this.prisma.user.findUnique({ where: { id: userId } });
    const ok =
      !!user?.passwordHash && (await argon2.verify(user.passwordHash, currentPassword));
    if (!user || !ok) {
      this.passwordFailures.fail(key);
      throw new BadRequestException('현재 비밀번호가 맞지 않습니다');
    }
    this.passwordFailures.succeed(key);
    if (currentPassword === newPassword) {
      throw new BadRequestException('새 비밀번호가 지금과 같습니다');
    }

    const passwordHash = await argon2.hash(newPassword);
    const updated = await this.prisma.$transaction(async (tx) => {
      const saved = await tx.user.update({ where: { id: userId }, data: { passwordHash } });
      await tx.refreshToken.updateMany({
        where: { userId, revokedAt: null },
        data: { revokedAt: new Date() },
      });
      return saved;
    });

    return this.issueNewSession(updated, client);
  }

  /**
   * POST /api/auth/logout — 이 세션의 family 전체를 무효화한다.
   * 토큰이 이미 못 쓰는 상태여도 조용히 성공시킨다 (로그아웃은 실패할 이유가 없다).
   */
  async logout(refreshToken?: string): Promise<void> {
    if (!refreshToken) return;

    try {
      const payload = await this.verifyRefreshJwt(refreshToken);
      if (payload.fam) {
        await this.refreshTokens.revokeFamily(payload.fam);
      }
    } catch {
      // 위조·만료된 토큰으로 로그아웃을 시도해도 그냥 성공으로 둔다.
    }
  }

  /**
   * 한도에 닿았으면 429 + `Retry-After`. 본문 객체의 `retryAfter` 를 전역 예외 필터가
   * 헤더로 옮긴다(github-error.ts 와 같은 모양).
   */
  private assertNotThrottled(key: string): void {
    const retryAfter = this.passwordFailures.blockedFor(key);
    if (retryAfter === null) return;
    throw new HttpException(
      {
        statusCode: HttpStatus.TOO_MANY_REQUESTS,
        error: 'TooManyRequests',
        message: '시도가 너무 많습니다. 잠시 뒤 다시 시도해 주세요.',
        retryAfter,
      },
      HttpStatus.TOO_MANY_REQUESTS,
    );
  }

  private async verifyRefreshJwt(token: string): Promise<JwtPayload> {
    let payload: JwtPayload;
    try {
      payload = await this.jwt.verifyAsync<JwtPayload>(token, {
        secret: this.secrets.refreshSecret,
      });
    } catch {
      throw new UnauthorizedException('리프레시 토큰이 유효하지 않습니다');
    }

    if (payload.type !== 'refresh' || !payload.jti) {
      throw new UnauthorizedException('리프레시 토큰이 아닙니다');
    }

    return payload;
  }

  /** 새 family 를 만들고 토큰 쌍을 발급한다. */
  private async issueNewSession(
    user: User,
    client: ClientFingerprint,
  ): Promise<AuthTokens> {
    const issued = this.refreshTokens.startFamily(this.refreshTtlMs());
    const tokens = await this.signPair(user, issued);
    await this.refreshTokens.persist(issued, user.id, tokens.refreshToken, client);
    return tokens;
  }

  private async signPair(
    user: User,
    issued: IssuedRefreshToken,
  ): Promise<AuthTokens> {
    const accessToken = await this.jwt.signAsync(
      { sub: user.id, email: user.email, type: 'access' } satisfies JwtPayload,
      { secret: this.secrets.accessSecret, expiresIn: this.secrets.accessTtl },
    );

    const refreshToken = await this.jwt.signAsync(
      {
        sub: user.id,
        email: user.email,
        type: 'refresh',
        jti: issued.id,
        fam: issued.familyId,
      } satisfies JwtPayload,
      {
        secret: this.secrets.refreshSecret,
        expiresIn: this.secrets.refreshTtl,
      },
    );

    return { accessToken, refreshToken, refreshExpiresAt: issued.expiresAt };
  }

  /**
   * '7d' · '15m' 같은 표기를 밀리초로 바꾼다.
   * DB 행의 expires_at 과 JWT 의 exp 를 같은 값으로 맞추기 위해 필요하다.
   */
  private refreshTtlMs(): number {
    return parseDuration(this.secrets.refreshTtl);
  }

  toPublicUser(user: User): PublicUser {
    return {
      id: user.id,
      email: user.email,
      name: user.name,
      avatarUrl: user.avatarUrl,
      globalStatus: user.globalStatus,
      createdAt: user.createdAt,
    };
  }
}

const DURATION_UNITS: Record<string, number> = {
  s: 1000,
  m: 60 * 1000,
  h: 60 * 60 * 1000,
  d: 24 * 60 * 60 * 1000,
};

/** '15m' · '7d' · '3600'(초) 를 밀리초로. 해석 불가면 예외 — 조용히 틀린 수명을 쓰지 않는다. */
export function parseDuration(value: string): number {
  const match = /^(\d+)\s*([smhd])?$/.exec(value.trim());
  if (!match) {
    throw new Error(`토큰 수명 표기를 해석할 수 없습니다: "${value}"`);
  }
  const amount = Number(match[1]);
  const unit = match[2];
  return unit ? amount * DURATION_UNITS[unit] : amount * 1000;
}
