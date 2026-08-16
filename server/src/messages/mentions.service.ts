import { Injectable } from '@nestjs/common';
import { MentionType, Prisma, SpaceMember } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';

/**
 * 본문에 저장하는 멘션 표기.
 *
 * **`@이름` 이 아니라 id 를 박는다.** 이름을 그대로 저장하면 사용자가 이름을
 * 바꾸는 순간 지난 메시지의 멘션이 낡고, 동명이인을 구분할 수 없으며, 이름에
 * 공백이 있으면 어디까지가 멘션인지 정할 수 없다.
 *
 * 화면에 보이는 이름은 렌더 시점에 멤버 목록에서 찾는다.
 */
const USER_MENTION = /<@([0-9a-fA-F-]{36})>/g;

/** 특수 멘션. 대상 사용자가 없다. */
const CHANNEL_MENTION = /(^|\s)@channel\b/;
const EVERYONE_MENTION = /(^|\s)@everyone\b/;

/** 메시지에 함께 실어 보내는 멘션 요약. 앱이 이름을 그리는 데 쓴다. */
export interface MentionSummary {
  type: MentionType;
  userId: string | null;
  /** `@channel` · `@everyone` 은 null. */
  name: string | null;
}

/** 본문에서 찾은 것. 아직 검증 전이다. */
export interface ParsedMentions {
  userIds: string[];
  channel: boolean;
  everyone: boolean;
}

/**
 * 본문을 훑어 멘션을 찾는다. **DB 를 보지 않는다** — 순수 함수라 테스트하기 쉽다.
 *
 * 같은 사람을 여러 번 멘션해도 한 번으로 친다. 알림이 여러 개 갈 이유가 없다.
 */
export function parseMentions(body: string): ParsedMentions {
  const userIds = new Set<string>();
  for (const match of body.matchAll(USER_MENTION)) {
    userIds.add(match[1].toLowerCase());
  }

  return {
    userIds: [...userIds],
    channel: CHANNEL_MENTION.test(body),
    everyone: EVERYONE_MENTION.test(body),
  };
}

@Injectable()
export class MentionsService {
  constructor(private readonly prisma: PrismaService) {}

  /**
   * 메시지에 딸린 멘션 행을 만든다. **메시지 생성과 같은 트랜잭션에서 부른다** —
   * 사이에서 끊기면 멘션 없는 메시지가 남아 뱃지가 영영 안 뜬다.
   *
   * 스페이스 멤버가 아닌 id 는 조용히 버린다. 400 으로 막지 않는 이유:
   * 본문은 사람이 쓴 글이고, 멘션 하나가 틀렸다고 메시지를 통째로 거부하면
   * 쓴 내용을 잃는다. 멘션이 안 걸릴 뿐 본문은 그대로 남는다.
   */
  async createFor(
    tx: Prisma.TransactionClient,
    params: {
      messageId: string;
      spaceId: string;
      body: string;
      authorId: string;
    },
  ): Promise<void> {
    const parsed = parseMentions(params.body);
    const rows: Prisma.MentionCreateManyInput[] = [];

    if (parsed.userIds.length > 0) {
      const members = await tx.spaceMember.findMany({
        where: { spaceId: params.spaceId, userId: { in: parsed.userIds } },
        select: { userId: true },
      });

      for (const member of members) {
        // **자기 자신을 멘션해도 행을 만들지 않는다.** 내 뱃지가 내 글로 켜지면
        // 안 읽은 멘션이라는 표시의 뜻이 사라진다.
        if (member.userId === params.authorId) continue;
        rows.push({
          spaceId: params.spaceId,
          messageId: params.messageId,
          userId: member.userId,
          type: MentionType.user,
        });
      }
    }

    // 특수 멘션은 대상이 없다. 누구에게 보일지는 읽는 쪽에서 정한다
    // (그 채널을 볼 수 있는 사람 전원).
    if (parsed.everyone) {
      rows.push({
        spaceId: params.spaceId,
        messageId: params.messageId,
        userId: null,
        type: MentionType.everyone,
      });
    } else if (parsed.channel) {
      // everyone 이 있으면 channel 은 덮인다. 둘 다 만들면 뱃지가 두 번 센다.
      rows.push({
        spaceId: params.spaceId,
        messageId: params.messageId,
        userId: null,
        type: MentionType.channel,
      });
    }

    if (rows.length > 0) {
      await tx.mention.createMany({ data: rows });
    }
  }

  /** 메시지 여러 건의 멘션을 한 번에 읽는다. 목록 조회의 N+1 을 막는다. */
  async summarizeMany(
    messageIds: string[],
    member: SpaceMember,
  ): Promise<Map<string, MentionSummary[]>> {
    if (messageIds.length === 0) return new Map();

    const rows = await this.prisma.mention.findMany({
      where: { messageId: { in: messageIds }, spaceId: member.spaceId },
      select: {
        messageId: true,
        type: true,
        userId: true,
        user: { select: { name: true } },
      },
    });

    const result = new Map<string, MentionSummary[]>();
    for (const row of rows) {
      const list = result.get(row.messageId) ?? [];
      list.push({
        type: row.type,
        userId: row.userId,
        name: row.user?.name ?? null,
      });
      result.set(row.messageId, list);
    }
    return result;
  }

  /**
   * 채널별 **안 읽은 멘션 수**.
   *
   * 안 읽은 메시지 수와 따로 세는 이유: 멘션은 "나를 불렀다"는 뜻이라 일반
   * 메시지와 무게가 다르다. 화면에서도 다른 색으로 표시한다.
   *
   * `@channel` · `@everyone` 은 **내가 쓴 것이 아닐 때만** 센다.
   */
  async unreadCounts(
    member: SpaceMember,
    channelIds: string[],
  ): Promise<Map<string, number>> {
    if (channelIds.length === 0) return new Map();

    // **LEFT JOIN 이어야 한다.** 공개 채널은 읽음 마커를 남기기 전까지
    // `channel_members` 행이 없다. INNER JOIN 으로 두면 그런 채널의 멘션이
    // 통째로 빠진다(같은 이유로 `channels.service.ts` 의 안 읽은 수도 LEFT 다).
    //
    // id 컬럼은 uuid 가 아니라 **text** 다 — `::uuid` 캐스팅 금지.
    const rows = await this.prisma.$queryRaw<
      { channel_id: string; count: bigint }[]
    >`
      SELECT m.channel_id, COUNT(*) AS count
        FROM mentions mt
        JOIN messages m ON m.id = mt.message_id
        LEFT JOIN channel_members cm
          ON cm.channel_id = m.channel_id AND cm.user_id = ${member.userId}
       WHERE mt.space_id = ${member.spaceId}
         AND m.channel_id IN (${Prisma.join(channelIds)})
         AND m.deleted_at IS NULL
         AND m.author_id <> ${member.userId}
         AND (mt.user_id = ${member.userId} OR mt.user_id IS NULL)
         AND (cm.last_read_at IS NULL OR m.created_at > cm.last_read_at)
       GROUP BY m.channel_id
    `;

    return new Map(rows.map((row) => [row.channel_id, Number(row.count)]));
  }
}
