import {
  BadRequestException,
  Injectable,
  Logger,
  NotFoundException,
  PayloadTooLargeException,
} from '@nestjs/common';
import { Prisma, SpaceMember } from '@prisma/client';
import { randomUUID } from 'crypto';
import { imageSize } from 'image-size';
import sharp from 'sharp';
import { Readable } from 'stream';
import { ChannelsService } from '../channels/channels.service';
import { PaginationDto } from '../common/dto/pagination.dto';
import { PrismaService } from '../prisma/prisma.service';
import { buildStorageKey, StorageDriver } from '../storage/storage.driver';

/** 한 파일의 최대 크기. 라우트의 multer 한도와 같은 값이어야 한다. */
export const MAX_UPLOAD_BYTES = 25 * 1024 * 1024;

/** 메시지 한 건에 붙일 수 있는 첨부 수. */
export const MAX_ATTACHMENTS_PER_MESSAGE = 10;

/** 연결되지 못한 첨부를 지우기까지의 시간. */
export const ORPHAN_TTL_MS = 24 * 60 * 60 * 1000;

/**
 * 썸네일 긴 변의 최대 길이.
 *
 * 목록에서 미리보기로 쓸 크기다. 화면 폭보다 넉넉하되, 원본을 대신할 만큼
 * 크지는 않게 잡는다 — 대신할 수 있으면 원본을 안 받게 되어 확대가 흐려진다.
 */
export const THUMB_MAX_EDGE = 480;

/**
 * 썸네일의 오브젝트 키. **DB 에 따로 저장하지 않고 원본 키에서 만든다.**
 *
 * 컬럼을 늘리지 않아 마이그레이션이 필요 없고, 나중에 규칙을 바꿔도 원본만
 * 있으면 다시 만들 수 있다. 파생본이므로 없으면 원본으로 떨어지면 그만이다.
 */
export function thumbKeyFor(storageKey: string): string {
  return `${storageKey}.thumb.webp`;
}

/** 썸네일을 만들 수 있는 형식. SVG 는 뺀다 — 래스터화가 외부 참조를 끌어온다. */
const THUMBNAILABLE = /^image\/(jpeg|png|webp|gif|avif|tiff|bmp)$/;

/**
 * 메시지에 실려 나가는 첨부 요약.
 *
 * `storageKey` 는 **내보내지 않는다.** 클라이언트가 알 이유가 없고, 알면
 * 스토리지 구조가 API 계약이 되어 드라이버를 못 바꾸게 된다.
 */
export interface AttachmentSummary {
  id: string;
  name: string;
  mime: string | null;
  sizeBytes: bigint;
  width: number | null;
  height: number | null;
  createdAt: Date;
}

const SUMMARY_SELECT = {
  id: true,
  name: true,
  mime: true,
  sizeBytes: true,
  width: true,
  height: true,
  createdAt: true,
} as const;

@Injectable()
export class AttachmentsService {
  private readonly logger = new Logger(AttachmentsService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly channels: ChannelsService,
    private readonly storage: StorageDriver,
  ) {}

  /**
   * POST /api/spaces/:spaceId/channels/:channelId/attachments
   *
   * **메시지보다 먼저 올라간다.** 업로드는 `messageId = null` 인 채로 끝나고,
   * 메시지를 보낼 때 연결된다 — 파일을 고른 즉시 올려 두어야 전송이 빠르고,
   * 큰 파일을 올리는 동안 본문을 계속 쓸 수 있다. 연결되지 못한 것은
   * 24시간 뒤 정리한다(`cleanupOrphans`).
   *
   * **열람이 아니라 전송 권한을 요구한다.** 첨부는 대화에 남기는 것이라
   * 읽기 전용 채널에서 올릴 수 있으면 안 된다.
   */
  async upload(
    channelId: string,
    member: SpaceMember,
    file: Express.Multer.File,
  ): Promise<AttachmentSummary> {
    await this.channels.assertCanSend(channelId, member);

    if (!file) {
      throw new BadRequestException('파일이 없습니다');
    }
    // multer 한도가 먼저 걸리지만, 한도를 한 곳에서만 믿지 않는다.
    if (file.size > MAX_UPLOAD_BYTES) {
      throw new PayloadTooLargeException('파일이 너무 큽니다');
    }
    if (file.size === 0) {
      throw new BadRequestException('빈 파일은 올릴 수 없습니다');
    }

    const name = decodeFilename(file.originalname);
    const ext = extensionOf(name);
    const id = randomUUID();
    const key = buildStorageKey(id, ext);
    const { width, height } = measureImage(file.buffer, file.mimetype);

    // **스토리지에 먼저 쓰고 DB 를 나중에 쓴다.** 순서를 뒤집으면 파일이 없는
    // 행이 남는데, 그건 고아 정리가 잡지 못한다(정리는 행 기준이다). 반대로
    // 행 없는 파일은 아래에서 곧바로 지운다.
    await this.storage.put(key, file.buffer, file.mimetype);

    // 썸네일은 **있으면 좋은 것**이다. 실패해도 업로드를 막지 않는다 —
    // 원본이 있으면 화면은 그것으로 그릴 수 있다.
    await this.makeThumbnail(key, file.buffer, file.mimetype, width, height);

    try {
      // 사용량은 첨부와 **한 트랜잭션**이다. 따로 두면 중간에 끊겼을 때
      // 실제 파일과 집계가 갈라지고, 그 차이는 지워지지 않는다.
      return await this.prisma.$transaction(async (tx) => {
        const row = await tx.attachment.create({
          data: {
            id,
            spaceId: member.spaceId,
            channelId,
            uploaderId: member.userId,
            name,
            ext,
            mime: file.mimetype ?? null,
            sizeBytes: BigInt(file.size),
            storageKey: key,
            width,
            height,
          },
          select: SUMMARY_SELECT,
        });

        await tx.space.update({
          where: { id: member.spaceId },
          data: { storageUsedBytes: { increment: BigInt(file.size) } },
        });

        return row;
      });
    } catch (error) {
      // 행을 못 만들었으면 파일도 남기지 않는다.
      await this.storage.delete(key).catch(() => undefined);
      throw error;
    }
  }

  /**
   * 이미지면 미리보기용 축소본을 만들어 둔다.
   *
   * **원본보다 작을 때만 만든다.** 이미 작은 이미지는 축소본이 더 커질 수도
   * 있고, 그러면 받는 쪽이 손해다. 없으면 다운로드가 원본으로 떨어지므로
   * 화면은 어느 쪽이든 그려진다.
   *
   * WebP 를 쓰는 이유: 투명도를 지키면서 JPEG 만큼 작다. JPEG 로 하면 투명한
   * PNG(스크린샷이 흔하다)의 배경이 검게 눌어붙는다.
   */
  private async makeThumbnail(
    key: string,
    buffer: Buffer,
    mime: string | undefined,
    width: number | null,
    height: number | null,
  ): Promise<void> {
    if (!mime || !THUMBNAILABLE.test(mime)) return;
    // 긴 변이 기준보다 작으면 줄일 것이 없다.
    if ((width ?? 0) <= THUMB_MAX_EDGE && (height ?? 0) <= THUMB_MAX_EDGE) return;

    try {
      const thumb = await sharp(buffer)
        .resize(THUMB_MAX_EDGE, THUMB_MAX_EDGE, { fit: 'inside', withoutEnlargement: true })
        .webp({ quality: 75 })
        .toBuffer();
      await this.storage.put(thumbKeyFor(key), thumb, 'image/webp');
    } catch (error) {
      // 썸네일이 없는 것과 업로드가 실패하는 것은 다르다.
      this.logger.warn(`썸네일 생성 실패 (${key}): ${String(error)}`);
    }
  }

  /**
   * GET /api/spaces/:spaceId/attachments/:id — 바이트를 그대로 흘려보낸다.
   *
   * **서명 URL 을 주지 않는다.** 그 주소는 가드를 지나지 않아 스페이스 밖에서도
   * 열린다. 여기서는 매 요청 채널 열람 권한을 다시 확인한다 — 비공개 채널에서
   * 빠진 사람은 그 순간부터 첨부도 못 연다.
   *
   * `variant: 'thumb'` 면 축소본을 준다. **없으면 원본으로 떨어진다** — 파생본은
   * 언제든 사라질 수 있고(생성 실패 · 규칙 변경), 그때 화면이 깨지면 안 된다.
   */
  async openStream(
    attachmentId: string,
    member: SpaceMember,
    variant?: 'thumb',
  ): Promise<{
    row: AttachmentSummary;
    stream: Readable;
    mime: string | null;
    /** 원본을 그대로 줄 때만 안다. 파생본은 길이를 따로 재지 않는다. */
    sizeBytes: bigint | null;
  }> {
    const row = await this.prisma.attachment.findFirst({
      where: { id: attachmentId, spaceId: member.spaceId },
      select: { ...SUMMARY_SELECT, channelId: true, storageKey: true },
    });
    // 다른 스페이스의 id 는 여기서 404 가 된다.
    if (!row) {
      throw new NotFoundException('첨부를 찾을 수 없습니다');
    }

    // 볼 수 없는 채널이면 404 다(403 이 아니다) — 403 은 그 채널의 존재를 알린다.
    await this.channels.assertCanView(row.channelId, member);

    if (variant === 'thumb') {
      const thumbKey = thumbKeyFor(row.storageKey);
      if (await this.storage.exists(thumbKey)) {
        return {
          row,
          stream: await this.storage.get(thumbKey),
          mime: 'image/webp',
          sizeBytes: null,
        };
      }
    }

    return {
      row,
      stream: await this.storage.get(row.storageKey),
      mime: row.mime,
      sizeBytes: row.sizeBytes,
    };
  }

  /**
   * GET /api/spaces/:spaceId/attachments — 스페이스의 파일 목록.
   *
   * **볼 수 있는 채널의 것만** 준다. 스페이스 전체를 훑는 화면이라 여기서
   * 거르지 않으면 비공개 채널의 파일 목록이 통째로 샌다.
   *
   * 아직 메시지에 연결되지 않은 것은 빼고 준다 — 남에게는 존재하지 않는
   * 파일이고, 24시간 뒤 사라질 수도 있다.
   */
  async listForSpace(
    member: SpaceMember,
    query: PaginationDto & { channelId?: string },
  ) {
    const viewable = await this.channels.viewableChannelIds(member);
    const channelIds = query.channelId
      ? viewable.filter((id) => id === query.channelId)
      : viewable;

    if (channelIds.length === 0) {
      return { items: [], nextCursor: null };
    }

    const limit = query.limit ?? 30;
    const rows = await this.prisma.attachment.findMany({
      where: {
        spaceId: member.spaceId,
        channelId: { in: channelIds },
        messageId: { not: null },
      },
      orderBy: { createdAt: 'desc' },
      take: limit + 1,
      ...(query.cursor ? { cursor: { id: query.cursor }, skip: 1 } : {}),
      select: { ...SUMMARY_SELECT, channelId: true, messageId: true },
    });

    const hasMore = rows.length > limit;
    const page = hasMore ? rows.slice(0, limit) : rows;

    return {
      items: page,
      nextCursor: hasMore ? page[page.length - 1].id : null,
    };
  }

  /**
   * 올려 둔 첨부를 메시지에 잇는다. 메시지 생성 **트랜잭션 안에서** 부른다.
   *
   * 조건을 좁게 잡는다 — 같은 스페이스 · 같은 채널 · 아직 연결되지 않았고 ·
   * **내가 올린 것**이어야 한다. 마지막 조건이 없으면 남이 올려 둔 첨부의 id 를
   * 추측해 자기 메시지에 붙일 수 있다.
   *
   * 하나라도 조건에 안 맞으면 메시지 자체를 만들지 않는다(400). 첨부가 조용히
   * 빠진 채로 전송되면 사용자는 보냈다고 믿는다.
   */
  async linkToMessage(
    tx: Prisma.TransactionClient,
    params: {
      messageId: string;
      channelId: string;
      member: SpaceMember;
      attachmentIds: string[];
    },
  ): Promise<void> {
    const ids = [...new Set(params.attachmentIds)];
    if (ids.length === 0) return;
    if (ids.length > MAX_ATTACHMENTS_PER_MESSAGE) {
      throw new BadRequestException(
        `첨부는 한 번에 ${MAX_ATTACHMENTS_PER_MESSAGE}개까지 보낼 수 있습니다`,
      );
    }

    const { count } = await tx.attachment.updateMany({
      where: {
        id: { in: ids },
        spaceId: params.member.spaceId,
        channelId: params.channelId,
        uploaderId: params.member.userId,
        messageId: null,
      },
      data: { messageId: params.messageId },
    });

    if (count !== ids.length) {
      throw new BadRequestException('첨부를 찾을 수 없거나 이미 사용되었습니다');
    }
  }

  /** 메시지들에 붙은 첨부를 한 번에 모은다. 목록에서 N+1 을 피한다. */
  async summarizeMany(
    messageIds: string[],
    member: SpaceMember,
  ): Promise<Map<string, AttachmentSummary[]>> {
    if (messageIds.length === 0) return new Map();

    const rows = await this.prisma.attachment.findMany({
      where: { messageId: { in: messageIds }, spaceId: member.spaceId },
      orderBy: { createdAt: 'asc' },
      select: { ...SUMMARY_SELECT, messageId: true },
    });

    const grouped = new Map<string, AttachmentSummary[]>();
    for (const { messageId, ...summary } of rows) {
      if (!messageId) continue;
      const list = grouped.get(messageId);
      if (list) list.push(summary);
      else grouped.set(messageId, [summary]);
    }
    return grouped;
  }

  /**
   * 연결되지 못한 첨부를 지운다. **시스템의 유일한 자동 삭제다**(설계 §3).
   *
   * 파일을 고르고 메시지를 안 보낸 경우가 여기 해당한다. 이것마저 남기면
   * 아무도 볼 수 없는 파일이 영원히 쌓인다.
   *
   * 메시지에 연결된 첨부는 **무엇으로도 만료되지 않는다** — 메시지를 소프트
   * 삭제해도, 채널을 지워도 남는다. 무기한 보관이 제품 특성이다.
   */
  async cleanupOrphans(now = new Date()): Promise<number> {
    const cutoff = new Date(now.getTime() - ORPHAN_TTL_MS);

    const orphans = await this.prisma.attachment.findMany({
      where: { messageId: null, createdAt: { lt: cutoff } },
      select: { id: true, spaceId: true, storageKey: true, sizeBytes: true },
    });
    if (orphans.length === 0) return 0;

    let removed = 0;
    for (const orphan of orphans) {
      // 파일을 먼저 지운다. 반대로 하면 행이 사라진 뒤 파일 삭제가 실패했을 때
      // 그 파일을 가리키는 것이 아무것도 남지 않는다.
      //
      // **파생본도 함께 지운다.** 썸네일은 DB 에 행이 없어, 여기서 안 지우면
      // 아무도 가리키지 않는 파일로 영원히 남는다.
      await this.storage.delete(orphan.storageKey);
      await this.storage.delete(thumbKeyFor(orphan.storageKey));
      await this.prisma.$transaction([
        this.prisma.attachment.delete({ where: { id: orphan.id } }),
        this.prisma.space.update({
          where: { id: orphan.spaceId },
          data: { storageUsedBytes: { decrement: orphan.sizeBytes } },
        }),
      ]);
      removed++;
    }

    this.logger.log(`고아 첨부 ${removed}건 정리`);
    return removed;
  }
}

/**
 * multipart 의 파일명을 되살린다.
 *
 * busboy 는 `filename="..."` 을 **latin1 로 읽는데** 브라우저는 UTF-8 바이트를
 * 보낸다. 그대로 두면 한글 파일명이 깨져 저장된다. ASCII 만 있는 이름은 이
 * 왕복에서 그대로다.
 */
function decodeFilename(raw: string): string {
  const name = Buffer.from(raw ?? '', 'latin1').toString('utf8');
  // 경로가 섞여 오는 클라이언트가 있다. 보이는 이름에도 남길 이유가 없다.
  return name.split(/[\\/]/).pop() || '파일';
}

function extensionOf(name: string): string | null {
  const dot = name.lastIndexOf('.');
  if (dot <= 0 || dot === name.length - 1) return null;
  const ext = name.slice(dot + 1).toLowerCase();
  // 키에 들어가는 값이라 이상한 글자는 받지 않는다.
  return /^[a-z0-9]{1,12}$/.test(ext) ? ext : null;
}

/**
 * 이미지면 크기를 재 둔다.
 *
 * 화면이 미리보기 자리를 먼저 잡으려면 크기를 알아야 한다 — 없으면 이미지가
 * 로드될 때마다 목록이 튄다. 헤더만 읽으므로 디코딩 비용이 없다.
 *
 * 실패해도 업로드를 막지 않는다. 크기를 모르는 것과 못 올리는 것은 다르다.
 */
function measureImage(
  buffer: Buffer,
  mime?: string,
): { width: number | null; height: number | null } {
  if (!mime?.startsWith('image/')) return { width: null, height: null };
  try {
    const size = imageSize(buffer);
    return { width: size.width ?? null, height: size.height ?? null };
  } catch {
    return { width: null, height: null };
  }
}
