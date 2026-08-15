import { Injectable, NotFoundException } from '@nestjs/common';
import { Reaction, SpaceMember } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { ChannelsService } from '../channels/channels.service';
import { RealtimeEmitter } from '../realtime/realtime-emitter';

/**
 * 화면이 그리기 좋은 모양으로 접은 리액션.
 *
 * 원본 행을 그대로 내보내지 않는 이유: 클라이언트가 매번 "몇 개인지"와
 * "내가 눌렀는지"를 다시 세야 한다. 그 계산은 서버가 한 번만 하면 된다.
 */
export interface ReactionSummary {
  emoji: string;
  count: number;
  /** 요청한 사람이 이미 누른 이모지인지. 토글 UI 가 이 값만 보면 된다. */
  mine: boolean;
}

@Injectable()
export class ReactionsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly channels: ChannelsService,
    private readonly realtime: RealtimeEmitter,
  ) {}

  /**
   * POST /api/spaces/:spaceId/messages/:id/reactions
   *
   * **멱등이다.** 이미 누른 이모지를 다시 눌러도 오류가 아니라 같은 결과를
   * 돌려준다 — 앱의 전송 큐가 재시도할 수 있어야 하기 때문이다(6-2).
   */
  async add(messageId: string, member: SpaceMember, emoji: string) {
    const message = await this.requireVisibleMessage(messageId, member);

    await this.prisma.reaction.upsert({
      where: {
        messageId_userId_emoji: { messageId, userId: member.userId, emoji },
      },
      create: {
        spaceId: member.spaceId,
        messageId,
        userId: member.userId,
        emoji,
      },
      update: {},
    });

    return this.publish(messageId, message.channelId, member);
  }

  /**
   * DELETE /api/spaces/:spaceId/messages/:id/reactions/:emoji
   *
   * 없는 것을 지워도 오류가 아니다. 같은 이유로 멱등이다.
   */
  async remove(messageId: string, member: SpaceMember, emoji: string) {
    const message = await this.requireVisibleMessage(messageId, member);

    await this.prisma.reaction.deleteMany({
      where: { messageId, userId: member.userId, emoji, spaceId: member.spaceId },
    });

    return this.publish(messageId, message.channelId, member);
  }

  /** 메시지 여러 건의 리액션을 한 번에 접는다. 목록 조회의 N+1 을 막는다. */
  async summarizeMany(
    messageIds: string[],
    member: SpaceMember,
  ): Promise<Map<string, ReactionSummary[]>> {
    if (messageIds.length === 0) return new Map();

    const rows = await this.prisma.reaction.findMany({
      where: { messageId: { in: messageIds }, spaceId: member.spaceId },
      orderBy: { createdAt: 'asc' },
    });

    const byMessage = new Map<string, Reaction[]>();
    for (const row of rows) {
      const list = byMessage.get(row.messageId);
      if (list) list.push(row);
      else byMessage.set(row.messageId, [row]);
    }

    const result = new Map<string, ReactionSummary[]>();
    for (const [id, list] of byMessage) {
      result.set(id, fold(list, member.userId));
    }
    return result;
  }

  /** 바뀐 리액션을 채널에 알리고, 요청자에게도 돌려준다. */
  private async publish(
    messageId: string,
    channelId: string,
    member: SpaceMember,
  ) {
    const rows = await this.prisma.reaction.findMany({
      where: { messageId, spaceId: member.spaceId },
      orderBy: { createdAt: 'asc' },
    });

    // **소켓에는 mine 을 담지 않는다.** 받는 사람마다 답이 다른 값이라
    // 브로드캐스트에 실으면 틀린 정보가 된다. 각자 userId 로 계산한다.
    this.realtime.toChannel(channelId, 'reaction:changed', {
      spaceId: member.spaceId,
      channelId,
      messageId,
      reactions: rows.map((r) => ({
        emoji: r.emoji,
        userId: r.userId,
      })),
    });

    return fold(rows, member.userId);
  }

  /**
   * 메시지를 찾고 그 채널을 볼 수 있는지 확인한다.
   *
   * 리액션에 **전송 권한이 아니라 열람 권한**을 요구하는 이유: 공지처럼 읽기
   * 전용인 채널에서도 반응은 남길 수 있어야 한다.
   */
  private async requireVisibleMessage(messageId: string, member: SpaceMember) {
    const message = await this.prisma.message.findFirst({
      where: { id: messageId, spaceId: member.spaceId },
      select: { id: true, channelId: true, deletedAt: true },
    });
    if (!message || message.deletedAt) {
      throw new NotFoundException('메시지를 찾을 수 없습니다');
    }

    await this.channels.assertCanView(message.channelId, member);
    return message;
  }
}

/**
 * 행 목록 → 이모지별 요약. 처음 눌린 순서를 유지한다.
 *
 * 테스트를 위해 내보낸다 — 개수와 mine 판정은 화면에 그대로 드러나는 계산이라
 * 실 DB 검증(`npm run check:reactions`)과 별개로 경계를 고정해 둘 값이 있다.
 */
export function fold(
  rows: Pick<Reaction, 'emoji' | 'userId'>[],
  userId: string,
): ReactionSummary[] {
  const order: string[] = [];
  const counts = new Map<string, { count: number; mine: boolean }>();

  for (const row of rows) {
    const entry = counts.get(row.emoji);
    if (entry) {
      entry.count += 1;
      entry.mine ||= row.userId === userId;
    } else {
      order.push(row.emoji);
      counts.set(row.emoji, { count: 1, mine: row.userId === userId });
    }
  }

  return order.map((emoji) => ({ emoji, ...counts.get(emoji)! }));
}
