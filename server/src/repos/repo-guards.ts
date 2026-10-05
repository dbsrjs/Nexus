import {
  BadRequestException,
  NotFoundException,
  ServiceUnavailableException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { randomBytes } from 'crypto';
import { resolveGithubOauth, type GithubOauthConfig } from '../config/oauth.config';
import { OauthService } from '../oauth/oauth.service';
import { PrismaService } from '../prisma/prisma.service';

/**
 * 저장소 기능이 공통으로 거는 문지기 — 수동 등록(`repos.service`) · 자동 등록
 * (`repo-connect.service`) · 열람(`repo-access.service`) · GitHub 저장소 목록 컨트롤러가
 * 같은 확인을 같은 문구로 각자 들고 있었다. 한 곳이 문구나 조건을 바꾸면 나머지가 남는다.
 */

/** GitHub OAuth 설정. 없으면 503 — 서버는 떠 있고 이 기능만 멈춘다. */
export function requireGithubConfig(config: ConfigService): GithubOauthConfig {
  const cfg = resolveGithubOauth(config);
  if (!cfg) {
    throw new ServiceUnavailableException(
      'GitHub 연결이 설정되지 않았습니다. 서버 관리자가 .env 를 채워야 합니다.',
    );
  }
  return cfg;
}

/** 이 사용자의 GitHub 토큰. 연결이 없으면 400 — 빈 결과로 감추면 연결부터 하라는 것을 모른다. */
export async function requireGithubToken(
  oauth: OauthService,
  userId: string,
): Promise<string> {
  const token = await oauth.githubTokenFor(userId);
  if (!token) throw new BadRequestException('GitHub 계정을 먼저 연결해야 합니다');
  return token;
}

/** 못 보는 채널에 저장소를 붙이면 그 채널로 이벤트가 새 나간다. 비우면 확인하지 않는다. */
export async function requireLinkableChannel(
  prisma: PrismaService,
  spaceId: string,
  channelId?: string,
): Promise<void> {
  if (!channelId) return;

  const channel = await prisma.channel.findFirst({
    // DM 에는 저장소를 잇지 않는다 — 웹훅이 DM 에 게시될 이유가 없다(17단계 D7 · D13).
    where: { id: channelId, spaceId, kind: 'text' },
    select: { id: true },
  });
  if (!channel) throw new NotFoundException('채널을 찾을 수 없습니다');
}

/** 웹훅 서명 시크릿. 등록 · 재발급 · 자동 등록이 같은 모양을 쓴다. */
export function newWebhookSecret(): string {
  return `whsec_${randomBytes(24).toString('hex')}`;
}
