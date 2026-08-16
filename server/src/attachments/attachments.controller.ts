import {
  Controller,
  Get,
  Param,
  ParseUUIDPipe,
  Post,
  Query,
  Res,
  UploadedFile,
  UseGuards,
  UseInterceptors,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { SpaceMember } from '@prisma/client';
import type { Response } from 'express';
import { CurrentSpaceMember } from '../spaces/decorators/current-space-member.decorator';
import { SpaceGuard } from '../spaces/guards/space.guard';
import { AttachmentsService, MAX_UPLOAD_BYTES } from './attachments.service';
import { ListAttachmentsDto } from './dto/list-attachments.dto';

/**
 * 첨부 (docs/백엔드-설계.md §4).
 *
 * 다운로드가 `GET /attachments/:id` **한 곳뿐**인 것이 이 설계의 핵심이다.
 * 서명 URL 을 발급하지 않으므로 모든 읽기가 `SpaceGuard` 를 지나고, 스토리지
 * 구현을 바꿔도 클라이언트가 보는 주소가 변하지 않는다.
 */
@Controller('spaces/:spaceId')
@UseGuards(SpaceGuard)
export class AttachmentsController {
  constructor(private readonly attachments: AttachmentsService) {}

  /**
   * 파일 하나를 올린다. 아직 어느 메시지에도 붙지 않은 상태다.
   *
   * 바이너리 파트 이름은 `file` 이다. 메시지를 보낼 때 받은 id 를
   * `attachmentIds` 로 넘기면 연결된다.
   */
  @Post('channels/:channelId/attachments')
  @UseInterceptors(
    FileInterceptor('file', { limits: { fileSize: MAX_UPLOAD_BYTES } }),
  )
  upload(
    @Param('channelId', new ParseUUIDPipe()) channelId: string,
    @UploadedFile() file: Express.Multer.File,
    @CurrentSpaceMember() member: SpaceMember,
  ) {
    return this.attachments.upload(channelId, member, file);
  }

  /** 스페이스의 파일 목록. 볼 수 있는 채널의 것만 나온다. */
  @Get('attachments')
  list(
    @Query() query: ListAttachmentsDto,
    @CurrentSpaceMember() member: SpaceMember,
  ) {
    return this.attachments.listForSpace(member, query);
  }

  /**
   * 바이트를 그대로 흘려보낸다.
   *
   * `Content-Disposition` 은 `inline` 이다 — 이미지 미리보기가 주 용도라
   * `attachment` 로 두면 볼 때마다 파일이 내려받아진다. 이름은 RFC 5987 의
   * `filename*` 로 싣는다(한글 파일명이 깨지지 않는다).
   */
  @Get('attachments/:attachmentId')
  async download(
    @Param('attachmentId', new ParseUUIDPipe()) attachmentId: string,
    @CurrentSpaceMember() member: SpaceMember,
    @Res({ passthrough: false }) res: Response,
  ): Promise<void> {
    const { row, stream } = await this.attachments.openStream(
      attachmentId,
      member,
    );

    res.setHeader('Content-Type', row.mime ?? 'application/octet-stream');
    res.setHeader('Content-Length', row.sizeBytes.toString());
    res.setHeader(
      'Content-Disposition',
      `inline; filename*=UTF-8''${encodeURIComponent(row.name)}`,
    );
    // 첨부는 바뀌지 않는다(같은 id 는 언제나 같은 바이트다). private 인 이유는
    // 열람 권한이 사람마다 다르기 때문이다 — 공용 캐시에 담기면 안 된다.
    res.setHeader('Cache-Control', 'private, max-age=31536000, immutable');

    stream.on('error', () => res.destroy());
    stream.pipe(res);
  }
}
