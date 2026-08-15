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

    // 리액션은 한 번에 접어 붙인다. 메시지마다 따로 조회하면 N+1 이 된다.
    const reactions = await this.reactions.summarizeMany(
      page.map((m) => m.id),
      member,
    );

    return {
      items: page.map((message) => ({
        ...redactIfDeleted(message),
        reactions: reactions.get(message.id) ?? [],
      })),
      nextCursor: hasMore ? page[page.length - 1].id : null,
    };
  }

  /**
   * POST /api/spaces/:spaceId/channels/:id/messages
   *
   * `parentId` 가 있으면 스레드 답글이다. 답글은 채널 타임라인에 섞이지 않고
   * 부모의 `replyCount` · `lastReplyAt` 을 올린다.
   */
  async create(channelId: string, member: SpaceMember, dto: CreateMessageDto) {
    await this.channels.assertCanSend(channelId, member);

    if (dto.parentId) {
      return this.createReply(channelId, member, dto.parentId, dto.body);
    }

    const message = await this.prisma.message.create({
      data: {
        spaceId: member.spaceId,
        channelId,
        authorId: member.userId,
        body: dto.body,
      },
      include: { author: AUTHOR_SELECT },
    });

    this.realtime.toChannel(channelId, 'message:new', {
      spaceId: member.spaceId,
      channelId,
      message,
    });

    // NOTE: 멘션 알림 팬아웃은 7단계(mentions)에서 붙인다.
    return message;
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
    const [reply, updatedParent] = await this.prisma.$transaction([
      this.prisma.message.create({
        data: {
          spaceId: member.spaceId,
          channelId,
          authorId: member.userId,
          body,
          parentId,
        },
        include: { author: AUTHOR_SELECT },
      }),
      this.prisma.message.update({
        where: { id: parentId },
        data: { replyCount: { increment: 1 }, lastReplyAt: now },
        select: { id: true, replyCount: true, lastReplyAt: true },
      }),
    ]);

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
      page.map((m) => m.id),
      member,
    );

    return {
      parent: {
        ...redactIfDeleted(parent),
        reactions: (await this.reactions.summarizeMany([parent.id], member))
          .get(parent.id) ?? [],
      },
      items: page.map((message) => ({
        ...redactIfDeleted(message),
        reactions: reactions.get(message.id) ?? [],
      })),
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
