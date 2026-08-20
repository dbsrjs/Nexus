import { Injectable, Logger } from '@nestjs/common';
import { Prisma, Repo, RepoProvider, User } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { RealtimeEmitter } from '../realtime/realtime-emitter';
import { describeGithubEvent } from './event-message';

/**
 * 같은 배달을 두 번 처리하지 않기 위해 보는 창.
 *
 * GitHub 은 응답이 늦으면 **몇 초 안에** 재시도한다. `repo_events` 에 배달 id
 * 컬럼을 더하는 대신 payload 안에 넣어 두고 최근 것만 뒤진다 — 마이그레이션
 * 없이 끝나고, 창을 넘긴 중복은 이벤트가 두 번 보이는 정도라 채널이 깨지지 않는다.
 */
const DUPLICATE_WINDOW_MS = 10 * 60 * 1000;

/** 봇의 이메일. 로그인 경로로는 만들 수 없는 도메인이라 사람과 겹치지 않는다. */
const BOT_EMAIL: Record<RepoProvider, string> = {
  github: 'github@bot.nexus.invalid',
  gitlab: 'gitlab@bot.nexus.invalid',
};

const BOT_NAME: Record<RepoProvider, string> = {
  github: 'GitHub',
  gitlab: 'GitLab',
};

@Injectable()
export class WebhooksService {
  private readonly logger = new Logger(WebhooksService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly realtime: RealtimeEmitter,
  ) {}

  /**
   * 서명이 검증된 뒤에 불린다.
   *
   * 돌려주는 값은 로그용이다 — **웹훅 응답은 언제나 200 이어야 한다.**
   * 우리가 안 쓰는 이벤트에 실패를 돌려주면 GitHub 이 재시도하고 저장소
   * 설정 화면이 빨갛게 된다.
   */
  async handle(
    repo: Repo,
    event: string,
    deliveryId: string | null,
    payload: unknown,
  ): Promise<{ stored: boolean; posted: boolean; duplicate: boolean }> {
    const described = describeGithubEvent(event, payload);
    // 모르는 이벤트는 적재도 하지 않는다 — 쓰지 않을 payload 로 테이블을
    // 불릴 이유가 없다.
    if (!described) return { stored: false, posted: false, duplicate: false };

    if (deliveryId && (await this.alreadyHandled(repo.id, deliveryId))) {
      return { stored: false, posted: false, duplicate: true };
    }

    const author = repo.linkedChannelId
      ? await this.botUser(repo.provider)
      : null;

    // **적재와 게시를 한 트랜잭션으로 묶는다.** 사이에서 끊기면 "이벤트는
    // 왔는데 채널에는 없는" 상태가 되는데, GitHub 은 200 을 받았으므로 다시
    // 보내지 않는다 — 재시도로도 낫지 않는다.
    const message = await this.prisma.$transaction(async (tx) => {
      let created: { id: string; channelId: string } | null = null;

      if (repo.linkedChannelId && author) {
        created = await tx.message.create({
          data: {
            spaceId: repo.spaceId,
            channelId: repo.linkedChannelId,
            authorId: author.id,
            body: described.body,
          },
          select: { id: true, channelId: true },
        });
      }

      await tx.repoEvent.create({
        data: {
          spaceId: repo.spaceId,
          repoId: repo.id,
          type: described.type,
          // 배달 id 를 payload 안에 함께 둔다(위 주석 참고).
          payload: {
            deliveryId,
            event,
            raw: payload,
          } as Prisma.InputJsonValue,
          messageId: created?.id ?? null,
          occurredAt: new Date(),
        },
      });

      return created;
    });

    if (message) {
      // 기존 메시지 경로와 같은 이벤트를 쓴다. `repo:event` 를 따로 만들지
      // 않는 이유는 받는 쪽이 없기 때문이다 — 저장소 전용 화면이 생기면 그때다.
      const full = await this.prisma.message.findUnique({
        where: { id: message.id },
        include: {
          author: { select: { id: true, name: true, avatarUrl: true } },
        },
      });
      if (full) this.realtime.toChannel(message.channelId, 'message:new', full);
    }

    return { stored: true, posted: message !== null, duplicate: false };
  }

  private async alreadyHandled(
    repoId: string,
    deliveryId: string,
  ): Promise<boolean> {
    const since = new Date(Date.now() - DUPLICATE_WINDOW_MS);
    const seen = await this.prisma.repoEvent.findFirst({
      where: {
        repoId,
        createdAt: { gte: since },
        payload: { path: ['deliveryId'], equals: deliveryId },
      },
      select: { id: true },
    });
    return seen !== null;
  }

  /**
   * 이벤트 메시지의 작성자.
   *
   * **스페이스 멤버가 아니다.** 멤버 목록도 멘션 자동완성도 `space_members`
   * 를 보므로 거기 끼지 않는다 — 사용자 행이 있다는 것과 그 스페이스의
   * 사람이라는 것은 다르다.
   *
   * **로그인할 수 없다.** 비밀번호 해시 자리에 bcrypt 형식이 아닌 값을 넣어
   * 어떤 입력과도 맞지 않게 한다. 봇이 사람처럼 로그인되면 그 계정으로
   * 아무 데나 들어갈 수 있다.
   */
  private async botUser(provider: RepoProvider): Promise<User> {
    const email = BOT_EMAIL[provider];

    const existing = await this.prisma.user.findUnique({ where: { email } });
    if (existing) return existing;

    this.logger.log(`${BOT_NAME[provider]} 봇 계정을 만듭니다`);
    return this.prisma.user.create({
      data: {
        email,
        name: BOT_NAME[provider],
        passwordHash: 'bot:no-login',
      },
    });
  }
}
