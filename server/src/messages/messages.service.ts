import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { Prisma, SpaceMember } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { ChannelsService } from '../channels/channels.service';
import { PaginationDto } from '../common/dto/pagination.dto';
import { CreateMessageDto } from './dto/create-message.dto';
import { UpdateMessageDto } from './dto/update-message.dto';
import { hasAtLeast } from '../spaces/space-role';
import { RealtimeEmitter } from '../realtime/realtime-emitter';
import { ReactionsService } from './reactions.service';

/** 메시지에 함께 실어 보내는 작성자 정보. 이메일은 내보내지 않는다. */
const AUTHOR_SELECT = {
  select: { id: true, name: true, avatarUrl: true },
} as const;

/**
 * 답장이 가리키는 원본. **요약만** 싣는다.
 *
 * 원본을 통째로 중첩하면 그 원본의 인용이 또 딸려 와 끝없이 깊어진다.
 * 인용은 한 겹만 펼친다 — 화면도 그 이상은 그리지 않는다.
 */
export interface QuotedMessage {
  id: string;
  body: string;
  authorName: string;
  deleted: boolean;
}

@Injectable()
export class MessagesService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly channels: ChannelsService,
    private readonly realtime: RealtimeEmitter,
    private readonly reactions: ReactionsService,
  ) {}

  /**
   * GET /api/spaces/:spaceId/channels/:id/messages — 최신순 커서 페이지네이션.
   *
   * `parentId IS NULL` 만 본다. 스레드 답글은 채널 타임라인에 섞이지 않는다
   * (docs/백엔드-설계.md §3). 답글 조회는 스레드 기능과 함께 뒤 단계에서 붙인다.
   *
   * 삭제된 메시지는 목록에서 빼지 않고 **본문만 비워서** 내려보낸다. 빼 버리면
   * 클라이언트가 이미 렌더한 메시지를 지울 근거가 없어 화면에 남는다.
   */
  async listForChannel(
    channelId: string,
    member: SpaceMember,
    query: PaginationDto,
  ) {
    await this.channels.assertCanView(channelId, member);

    const limit = query.limit ?? 30;
    const rows = await this.prisma.message.findMany({
      where: { channelId, spaceId: member.spaceId, parentId: null },
      orderBy: { createdAt: 'desc' },
      take: limit + 1,
      ...(query.cursor ? { cursor: { id: query.cursor }, skip: 1 } : {}),
      include: { author: AUTHOR_SELECT },
    });

    const hasMore = rows.length > limit;
    const page = hasMore ? rows.slice(0, limit) : rows;

    // 리액션·인용은 한 번에 모아 붙인다. 메시지마다 따로 조회하면 N+1 이 된다.
    const reactions = await this.reactions.summarizeMany(
      page.map((m) => m.id),
      member,
    );
    const quoted = await this.loadQuoted(page, member);

    return {
      items: page.map((message) => ({
        ...redactIfDeleted(message),
        reactions: reactions.get(message.id) ?? [],
        quoted: message.quotedMessageId
          ? (quoted.get(message.quotedMessageId) ?? null)
          : null,
      })),
      nextCursor: hasMore ? page[page.length - 1].id : null,
    };
  }

  /**
   * 인용된 원본들을 한 번에 읽어 요약한다.
   *
   * `spaceId` 조건을 함께 거는 이유: 인용 id 는 클라이언트가 준 값이 아니라
   * DB 에 저장된 값이지만, 테넌트 조건은 **모든 쿼리에 넣는다**는 규칙을
   * 예외 없이 지킨다(설계 §2).
   */
  private async loadQuoted(
    messages: { quotedMessageId: string | null }[],
    member: SpaceMember,
  ): Promise<Map<string, QuotedMessage>> {
    const ids = [
      ...new Set(
        messages
          .map((m) => m.quotedMessageId)
          .filter((id): id is string => id !== null),
      ),
    ];
    if (ids.length === 0) return new Map();

    const rows = await this.prisma.message.findMany({
      where: { id: { in: ids }, spaceId: member.spaceId },
      select: {
        id: true,
        body: true,
        deletedAt: true,
        author: { select: { name: true } },
      },
    });

    return new Map(
      rows.map((row) => [
        row.id,
        {
          id: row.id,
          // 삭제된 원본의 본문은 내보내지 않는다 — 소프트 삭제의 의미가 없어진다.
          body: row.deletedAt ? '' : row.body,
          authorName: row.author.name,
          deleted: row.deletedAt !== null,
        },
      ]),
    );
  }

  /**
   * POST /api/spaces/:spaceId/channels/:id/messages
   *
   * `parentId` 가 있으면 스레드 답글이다. 답글은 채널 타임라인에 섞이지 않고
   * 부모의 `replyCount` · `lastReplyAt` 을 올린다.
   */
  async create(channelId: string, member: SpaceMember, dto: CreateMessageDto) {
    await this.channels.assertCanSend(channelId, member);

    const quotedMessageId = await this.resolveQuoted(
      channelId,
      member,
      dto.quotedMessageId,
    );

    if (dto.parentId) {
      return this.createReply(
        channelId,
        member,
        dto.parentId,
        dto.body,
        quotedMessageId,
      );
    }

    const created = await this.prisma.message.create({
      data: {
        spaceId: member.spaceId,
        channelId,
        authorId: member.userId,
        body: dto.body,
        quotedMessageId,
      },
      include: { author: AUTHOR_SELECT },
    });

    const message = await this.withQuoted(created, member);

    this.realtime.toChannel(channelId, 'message:new', {
      spaceId: member.spaceId,
      channelId,
      message,
    });

    // NOTE: 멘션 알림 팬아웃은 7단계(mentions)에서 붙인다.
    return message;
  }

  /**
   * 인용 대상을 확인한다. 없으면 null.
   *
   * **같은 채널의 메시지만** 인용할 수 있다. 다른 채널을 가리키면 볼 권한이
   * 없는 대화가 인용문으로 새어 나온다.
   *
   * 삭제된 메시지는 인용할 수 있게 둔다 — 답장을 쓰는 사이에 원본이 지워질 수
   * 있고, 그때 전송을 막으면 쓴 내용을 잃는다. 화면에는 "삭제된 메시지"로 뜬다.
   */
  private async resolveQuoted(
    channelId: string,
    member: SpaceMember,
    quotedMessageId?: string,
  ): Promise<string | null> {
    if (!quotedMessageId) return null;

    const quoted = await this.prisma.message.findFirst({
      where: { id: quotedMessageId, spaceId: member.spaceId, channelId },
      select: { id: true },
    });
    if (!quoted) {
      throw new NotFoundException('인용할 메시지를 찾을 수 없습니다');
    }
    return quoted.id;
  }

  /** 방금 만든 메시지에 인용 요약을 붙인다. 전송 응답과 소켓이 같은 모양이어야 한다. */
  private async withQuoted<T extends { quotedMessageId: string | null }>(
    message: T,
    member: SpaceMember,
  ) {
    const quoted = await this.loadQuoted([message], member);
    return {
      ...message,
      reactions: [],
      quoted: message.quotedMessageId
        ? (quoted.get(message.quotedMessageId) ?? null)
        : null,
    };
  }

  /**
   * 스레드 답글. 답글 저장과 부모 갱신은 **한 트랜잭션**이다 —
   * 사이에서 끊기면 답글은 있는데 개수가 0인 상태가 남는다.
   */
  private async createReply(
    channelId: string,
    member: SpaceMember,
    parentId: string,
    body: string,
    quotedMessageId: string | null,
  ) {
    const parent = await this.prisma.message.findFirst({
      where: { id: parentId, spaceId: member.spaceId },
      select: { id: true, channelId: true, parentId: true, deletedAt: true },
    });

    // 다른 스페이스의 id 는 여기서 404 가 된다.
    if (!parent) {
      throw new NotFoundException('메시지를 찾을 수 없습니다');
    }
    // 부모가 다른 채널이면 스레드가 채널 경계를 넘는다.
    if (parent.channelId !== channelId) {
      throw new NotFoundException('메시지를 찾을 수 없습니다');
    }
    if (parent.parentId) {
      throw new BadRequestException('답글에는 답글을 달 수 없습니다');
    }
    if (parent.deletedAt) {
      throw new BadRequestException('삭제된 메시지에는 답글을 달 수 없습니다');
    }

    const now = new Date();
    const [created, updatedParent] = await this.prisma.$transaction([
      this.prisma.message.create({
        data: {
          spaceId: member.spaceId,
          channelId,
          authorId: member.userId,
          body,
          parentId,
          quotedMessageId,
        },
        include: { author: AUTHOR_SELECT },
      }),
      this.prisma.message.update({
        where: { id: parentId },
        data: { replyCount: { increment: 1 }, lastReplyAt: now },
        select: { id: true, replyCount: true, lastReplyAt: true },
      }),
    ]);

    const reply = await this.withQuoted(created, member);

    // **채널 룸으로 보낸다.** 스레드를 연 사람만 받는 룸(thread:{id})을 따로
    // 두면, 채널을 보고 있는 사람에게 답글 수를 알릴 경로가 하나 더 필요해진다.
    // 지금 규모에서는 한 이벤트로 둘 다 처리하는 편이 단순하다.
    this.realtime.toChannel(channelId, 'thread:reply', {
      spaceId: member.spaceId,
      channelId,
      parentId,
      message: reply,
      replyCount: updatedParent.replyCount,
      lastReplyAt: updatedParent.lastReplyAt,
    });

    return reply;
  }

  /**
   * GET /api/spaces/:spaceId/messages/:id/replies — 스레드 답글.
   *
   * 채널 목록과 **같은 방향(최신순)** 이다. 화면이 `reverse: true` 로 그리는
   * 규칙과 커서 이어붙이기를 한 벌로 유지하기 위해서다.
   */
  async listReplies(
    parentId: string,
    member: SpaceMember,
    query: PaginationDto,
  ) {
    const parent = await this.requireVisibleMessage(parentId, member);
    if (parent.parentId) {
      throw new BadRequestException('답글에는 스레드가 없습니다');
    }

    const limit = query.limit ?? 30;
    const rows = await this.prisma.message.findMany({
      where: { parentId, spaceId: member.spaceId },
      orderBy: { createdAt: 'desc' },
      take: limit + 1,
      ...(query.cursor ? { cursor: { id: query.cursor }, skip: 1 } : {}),
      include: { author: AUTHOR_SELECT },
    });

    const hasMore = rows.length > limit;
    const page = hasMore ? rows.slice(0, limit) : rows;

    const reactions = await this.reactions.summarizeMany(
      [...page.map((m) => m.id), parent.id],
      member,
    );
    const quoted = await this.loadQuoted([...page, parent], member);

    const withExtras = <T extends { id: string; quotedMessageId: string | null }>(
      message: T,
    ) => ({
      ...redactIfDeleted(message as never),
      reactions: reactions.get(message.id) ?? [],
      quoted: message.quotedMessageId
        ? (quoted.get(message.quotedMessageId) ?? null)
        : null,
    });

    return {
      parent: withExtras(parent),
      items: page.map(withExtras),
      nextCursor: hasMore ? page[page.length - 1].id : null,
    };
  }

  /**
   * PATCH /api/spaces/:spaceId/messages/:id — 본인만.
   * 수정 전 본문을 MessageEdit 에 남기고 editedAt 을 찍는다. 한 트랜잭션이다.
   */
  async update(messageId: string, member: SpaceMember, dto: UpdateMessageDto) {
    const existing = await this.requireVisibleMessage(messageId, member);

    if (existing.authorId !== member.userId) {
      throw new ForbiddenException('본인이 작성한 메시지만 수정할 수 있습니다');
    }
    if (existing.deletedAt) {
      throw new ForbiddenException('삭제된 메시지는 수정할 수 없습니다');
    }

    const [, updated] = await this.prisma.$transaction([
      this.prisma.messageEdit.create({
        data: { messageId, prevBody: existing.body },
      }),
      this.prisma.message.update({
        where: { id: messageId },
        data: { body: dto.body, editedAt: new Date() },
        include: { author: AUTHOR_SELECT },
      }),
    ]);

    this.realtime.toChannel(existing.channelId, 'message:edited', {
      spaceId: member.spaceId,
      channelId: existing.channelId,
      message: updated,
    });

    return updated;
  }

  /**
   * DELETE /api/spaces/:spaceId/messages/:id — **소프트 삭제**.
   *
   * 본문만 가리고 행은 남긴다. 첨부도 남는다 — 무기한 보관이 제품 특성이라
   * 메시지를 지웠다고 파일이 사라지면 안 된다 (docs/백엔드-설계.md §3 보관 정책).
   *
   * 작성자 본인, 또는 admin 이상이 지울 수 있다.
   */
  async remove(messageId: string, member: SpaceMember) {
    const existing = await this.requireVisibleMessage(messageId, member);

    const isAuthor = existing.authorId === member.userId;
    if (!isAuthor && !hasAtLeast(member.role, 'admin')) {
      throw new ForbiddenException('이 메시지를 삭제할 권한이 없습니다');
    }

    if (existing.deletedAt) {
      return redactIfDeleted(existing);
    }

    const deleted = await this.prisma.message.update({
      where: { id: messageId },
      data: { deletedAt: new Date() },
      include: { author: AUTHOR_SELECT },
    });

    // 페이로드에 본문을 싣지 않는다. 삭제된 메시지의 본문이 소켓으로 흘러나가면
    // 소프트 삭제의 의미가 없다.
    this.realtime.toChannel(existing.channelId, 'message:deleted', {
      spaceId: member.spaceId,
      channelId: existing.channelId,
      messageId,
    });

    return redactIfDeleted(deleted);
  }

  /** GET /api/spaces/:spaceId/messages/:id/edits — 수정 이력, 최신순. */
  async listEdits(messageId: string, member: SpaceMember) {
    await this.requireVisibleMessage(messageId, member);

    return this.prisma.messageEdit.findMany({
      where: { messageId },
      orderBy: { editedAt: 'desc' },
    });
  }

  /**
   * 메시지를 찾고, 그 채널을 볼 수 있는지까지 확인한다.
   *
   * spaceId 조건이 먼저 걸리므로 다른 스페이스의 메시지 id 는 여기서 404 가 된다.
   * 같은 스페이스라도 못 보는 채널이면 assertCanView 가 404 를 던진다.
   */
  private async requireVisibleMessage(messageId: string, member: SpaceMember) {
    const message = await this.prisma.message.findFirst({
      where: { id: messageId, spaceId: member.spaceId },
      include: { author: AUTHOR_SELECT },
    });
    if (!message) {
      throw new NotFoundException('메시지를 찾을 수 없습니다');
    }

    await this.channels.assertCanView(message.channelId, member);
    return message;
  }
}

type MessageWithAuthor = Prisma.MessageGetPayload<{
  include: { author: typeof AUTHOR_SELECT };
}>;

/** 삭제된 메시지는 본문을 비워 내보낸다. 원본은 DB에 그대로 있다. */
function redactIfDeleted(message: MessageWithAuthor): MessageWithAuthor {
  return message.deletedAt ? { ...message, body: '' } : message;
}
