import { Injectable, Logger, UnauthorizedException } from '@nestjs/common';
import { createHash, randomUUID } from 'crypto';
import { RefreshToken } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';

export interface IssuedRefreshToken {
  id: string;
  familyId: string;
  expiresAt: Date;
}

export interface ClientFingerprint {
  userAgent?: string;
  ip?: string;
}

/**
 * 리프레시 토큰의 **회전(rotation)과 재사용 탐지**를 담당한다
 * (docs/백엔드-설계.md §6).
 *
 * 한 번의 로그인이 하나의 family 를 만든다. 리프레시할 때마다 이전 행을 revoke 하고
 * 같은 family 로 새 행을 만든다. 이미 revoke 된 토큰이 다시 제시되면 — 정상 클라이언트는
 * 절대 그러지 않는다 — 토큰이 탈취돼 두 곳에서 쓰이는 상황으로 보고 **family 전체를
 * 무효화**한다. 공격자와 사용자가 모두 로그아웃되지만, 그게 안전한 쪽이다.
 *
 * 저장하는 것은 원문이 아니라 SHA-256 해시다. DB가 유출돼도 토큰이 즉시 쓰이지 않는다.
 */
@Injectable()
export class RefreshTokenService {
  private readonly logger = new Logger(RefreshTokenService.name);

  constructor(private readonly prisma: PrismaService) {}

  static hash(token: string): string {
    return createHash('sha256').update(token).digest('hex');
  }

  /** 새 family 를 시작한다 (로그인 · 가입 시). */
  startFamily(ttlMs: number): IssuedRefreshToken {
    return {
      id: randomUUID(),
      familyId: randomUUID(),
      expiresAt: new Date(Date.now() + ttlMs),
    };
  }

  /** 발급한 토큰을 저장한다. 토큰 문자열이 만들어진 뒤에 호출한다. */
  async persist(
    issued: IssuedRefreshToken,
    userId: string,
    token: string,
    client: ClientFingerprint = {},
  ): Promise<void> {
    await this.prisma.refreshToken.create({
      data: {
        id: issued.id,
        userId,
        familyId: issued.familyId,
        tokenHash: RefreshTokenService.hash(token),
        expiresAt: issued.expiresAt,
        userAgent: client.userAgent?.slice(0, 255),
        ip: client.ip,
      },
    });
  }

  /**
   * 제시된 리프레시 토큰을 검증한다. 통과하면 그 행을 반환한다.
   *
   * 실패 사유별 처리:
   *   - 행 없음            → 위조되었거나 이미 정리됨. 거부.
   *   - 이미 revoke 됨     → **재사용**. family 전체 무효화 후 거부.
   *   - 만료               → 거부.
   *   - 해시 불일치        → 거부 (jti 는 맞는데 본문이 다른 경우).
   */
  async verifyUsable(tokenId: string, token: string): Promise<RefreshToken> {
    const row = await this.prisma.refreshToken.findUnique({
      where: { id: tokenId },
    });

    if (!row) {
      throw new UnauthorizedException('리프레시 토큰이 유효하지 않습니다');
    }

    if (row.tokenHash !== RefreshTokenService.hash(token)) {
      throw new UnauthorizedException('리프레시 토큰이 유효하지 않습니다');
    }

    if (row.revokedAt) {
      // 재사용 탐지 — 이 시점에서 family 를 통째로 끊는다.
      await this.revokeFamily(row.familyId);
      this.logger.warn(
        `리프레시 토큰 재사용 감지 — family ${row.familyId} 전체를 무효화했습니다 (user ${row.userId})`,
      );
      throw new UnauthorizedException(
        '리프레시 토큰이 재사용되었습니다. 다시 로그인하십시오',
      );
    }

    if (row.expiresAt.getTime() <= Date.now()) {
      throw new UnauthorizedException('리프레시 토큰이 만료되었습니다');
    }

    return row;
  }

  /** 같은 family 안에서 다음 토큰으로 넘어간다. */
  rotate(previous: RefreshToken, ttlMs: number): IssuedRefreshToken {
    return {
      id: randomUUID(),
      familyId: previous.familyId,
      expiresAt: new Date(Date.now() + ttlMs),
    };
  }

  /** 이전 행을 revoke 하고 새 행을 가리키게 한다. 한 트랜잭션에서 처리한다. */
  async commitRotation(
    previous: RefreshToken,
    next: IssuedRefreshToken,
    token: string,
    client: ClientFingerprint = {},
  ): Promise<void> {
    await this.prisma.$transaction([
      this.prisma.refreshToken.update({
        where: { id: previous.id },
        data: { revokedAt: new Date(), replacedById: next.id },
      }),
      this.prisma.refreshToken.create({
        data: {
          id: next.id,
          userId: previous.userId,
          familyId: next.familyId,
          tokenHash: RefreshTokenService.hash(token),
          expiresAt: next.expiresAt,
          userAgent: client.userAgent?.slice(0, 255),
          ip: client.ip,
        },
      }),
    ]);
  }

  /** family 전체 무효화 — 로그아웃, 그리고 재사용 탐지 시. */
  async revokeFamily(familyId: string): Promise<void> {
    await this.prisma.refreshToken.updateMany({
      where: { familyId, revokedAt: null },
      data: { revokedAt: new Date() },
    });
  }

  /** 사용자의 모든 세션 종료 (비밀번호 변경 등에서 쓴다). */
  async revokeAllForUser(userId: string): Promise<void> {
    await this.prisma.refreshToken.updateMany({
      where: { userId, revokedAt: null },
      data: { revokedAt: new Date() },
    });
  }
}
