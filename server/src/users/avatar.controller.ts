import {
  BadRequestException,
  Controller,
  Delete,
  Get,
  Param,
  ParseUUIDPipe,
  Put,
  Res,
  UploadedFile,
  UseInterceptors,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import type { Response } from 'express';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { AVATAR_MIME, AvatarImageError, MAX_AVATAR_BYTES } from './avatar-image';
import { AvatarService } from './avatar.service';

/**
 *   PUT    /api/me/avatar              multipart `file`
 *   DELETE /api/me/avatar
 *   GET    /api/users/:userId/avatar
 *
 * 열람은 이 한 곳뿐이다 — 첨부와 같이 서명 URL 을 내주지 않는다(8-1).
 * 5MB 초과는 multer 가 413 으로 막는다(첨부와 같다).
 */
@Controller()
export class AvatarController {
  constructor(private readonly avatars: AvatarService) {}

  @Put('me/avatar')
  @UseInterceptors(FileInterceptor('file', { limits: { fileSize: MAX_AVATAR_BYTES } }))
  async upload(
    @CurrentUser('id') userId: string,
    @UploadedFile() file: Express.Multer.File | undefined,
  ) {
    if (!file || file.size === 0) throw new BadRequestException('파일이 없습니다');
    // mime 은 첫 거름일 뿐이다. 진짜 판정은 sharp 가 읽을 수 있는가다.
    if (!file.mimetype?.startsWith('image/')) {
      throw new BadRequestException('이미지 파일만 올릴 수 있습니다');
    }
    try {
      return await this.avatars.upload(userId, file.buffer);
    } catch (err) {
      if (err instanceof AvatarImageError) throw new BadRequestException(err.message);
      throw err;
    }
  }

  @Delete('me/avatar')
  remove(@CurrentUser('id') userId: string) {
    return this.avatars.remove(userId);
  }

  @Get('users/:userId/avatar')
  async download(
    @CurrentUser('id') viewerId: string,
    @Param('userId', new ParseUUIDPipe()) userId: string,
    @Res({ passthrough: false }) res: Response,
  ): Promise<void> {
    const stream = await this.avatars.open(viewerId, userId);
    res.setHeader('Content-Type', AVATAR_MIME);
    // 주소에 버전이 있어 같은 주소는 언제나 같은 바이트다. private — 볼 수 있는
    // 사람이 사람마다 달라 공용 캐시에 담기면 안 된다.
    res.setHeader('Cache-Control', 'private, max-age=31536000, immutable');
    stream.on('error', () => res.destroy());
    stream.pipe(res);
  }
}
