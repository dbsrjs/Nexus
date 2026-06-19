import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { randomUUID } from 'crypto';
import { extname } from 'path';
import { PrismaService } from '../prisma/prisma.service';
import { MinioService } from './minio.service';
import { RealtimeGateway } from '../realtime/realtime.gateway';
import { UploadFileDto } from './dto/upload-file.dto';

/** File row shape returned to clients (BigInt size serialized as string). */
export interface FileResponse {
  id: string;
  channelId: string;
  messageId: string | null;
  uploaderId: string;
  name: string;
  ext: string | null;
  sizeBytes: string;
  storageKey: string;
  retained: boolean;
  createdAt: Date;
}

@Injectable()
export class FilesService {
  constructor(
    private prisma: PrismaService,
    private minio: MinioService,
    private realtime: RealtimeGateway,
  ) {}

  /**
   * Store an uploaded file in MinIO (영구 보관, retained=true) and persist its
   * metadata as a File row linked to the channel (and optionally a message).
   */
  async upload(
    channelId: string,
    uploaderId: string,
    file: Express.Multer.File,
    dto: UploadFileDto,
  ): Promise<FileResponse> {
    if (!file) {
      throw new BadRequestException('업로드할 파일이 없습니다.');
    }

    // Guard against orphaned rows pointing at non-existent channels/messages.
    const channel = await this.prisma.channel.findUnique({
      where: { id: channelId },
      select: { id: true },
    });
    if (!channel) {
      throw new NotFoundException('채널을 찾을 수 없습니다.');
    }

    if (dto.messageId) {
      const message = await this.prisma.message.findFirst({
        where: { id: dto.messageId, channelId },
        select: { id: true },
      });
      if (!message) {
        throw new BadRequestException(
          '해당 채널에서 메시지를 찾을 수 없습니다.',
        );
      }
    }

    // Multer/busboy decodes the multipart filename header as latin1, which mangles
    // non-ASCII (e.g. Korean) names. Re-decode the multipart filename as UTF-8.
    const originalName =
      dto.name ?? Buffer.from(file.originalname, 'latin1').toString('utf8');
    const ext = extname(originalName).replace(/^\./, '').toUpperCase() || null;
    // Object key keeps files namespaced per channel and collision-free.
    const storageKey = `channels/${channelId}/${randomUUID()}${extname(
      originalName,
    )}`;

    await this.minio.putObject(
      storageKey,
      file.buffer,
      file.size,
      file.mimetype,
    );

    const row = await this.prisma.file.create({
      data: {
        channelId,
        messageId: dto.messageId ?? null,
        uploaderId,
        name: originalName,
        ext,
        sizeBytes: BigInt(file.size),
        storageKey,
        retained: true, // 영구 보관 — 만료 없음
      },
    });

    // If the file is attached to a message, re-emit that message (now with its
    // files) so other connected clients can render the inline image in realtime —
    // the original message:new fired before the file existed.
    if (row.messageId) {
      const msg = await this.prisma.message.findUnique({
        where: { id: row.messageId },
        include: {
          author: { select: { id: true, name: true, initial: true, color: true } },
          files: { select: { id: true, name: true, ext: true } },
        },
      });
      if (msg) this.realtime.emitMessageEdited(channelId, msg);
    }

    return this.toResponse(row);
  }

  /** Look up a file row or throw 404. */
  async findOne(id: string) {
    const row = await this.prisma.file.findUnique({ where: { id } });
    if (!row) {
      throw new NotFoundException('파일을 찾을 수 없습니다.');
    }
    return row;
  }

  /** Build a presigned download URL for a file. */
  async presignedUrl(id: string): Promise<{ url: string }> {
    const row = await this.findOne(id);
    const url = await this.minio.presignedGetUrl(row.storageKey, row.name);
    return { url };
  }

  /** Open a readable stream for a file's bytes. */
  async openStream(id: string) {
    const row = await this.findOne(id);
    const stream = await this.minio.getObjectStream(row.storageKey);
    return { row, stream };
  }

  /** List files attached to a channel (newest first). */
  async listForChannel(channelId: string): Promise<FileResponse[]> {
    const rows = await this.prisma.file.findMany({
      where: { channelId },
      orderBy: { createdAt: 'desc' },
    });
    return rows.map((r) => this.toResponse(r));
  }

  /** Convert a Prisma File row into a JSON-safe response (BigInt → string). */
  toResponse(row: {
    id: string;
    channelId: string;
    messageId: string | null;
    uploaderId: string;
    name: string;
    ext: string | null;
    sizeBytes: bigint;
    storageKey: string;
    retained: boolean;
    createdAt: Date;
  }): FileResponse {
    return {
      id: row.id,
      channelId: row.channelId,
      messageId: row.messageId,
      uploaderId: row.uploaderId,
      name: row.name,
      ext: row.ext,
      sizeBytes: row.sizeBytes.toString(),
      storageKey: row.storageKey,
      retained: row.retained,
      createdAt: row.createdAt,
    };
  }
}
