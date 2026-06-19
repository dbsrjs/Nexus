import {
  Body,
  Controller,
  Get,
  Param,
  ParseUUIDPipe,
  Post,
  Query,
  Res,
  UploadedFile,
  UseInterceptors,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { Response } from 'express';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { FilesService } from './files.service';
import { UploadFileDto } from './dto/upload-file.dto';
import { DownloadQueryDto } from './dto/download-query.dto';

// No base path: routes below are absolute under the global 'api' prefix
// (set via setGlobalPrefix('api') in main.ts) →
//   POST /api/channels/:id/files, GET /api/channels/:id/files, GET /api/files/:id
@Controller()
export class FilesController {
  constructor(private readonly filesService: FilesService) {}

  /**
   * POST /api/channels/:id/files
   * Multipart upload → MinIO (영구 보관) + File row.
   * The binary part field name is "file"; extra text fields map to UploadFileDto.
   */
  @Post('channels/:id/files')
  @UseInterceptors(FileInterceptor('file'))
  async upload(
    @Param('id', ParseUUIDPipe) channelId: string,
    @CurrentUser('id') userId: string,
    @UploadedFile() file: Express.Multer.File,
    // extra multipart text fields validated by the global ValidationPipe
    @Body() dto: UploadFileDto,
  ) {
    return this.filesService.upload(channelId, userId, file, dto);
  }

  /** GET /api/channels/:id/files — list files attached to a channel. */
  @Get('channels/:id/files')
  async listForChannel(@Param('id', ParseUUIDPipe) channelId: string) {
    return this.filesService.listForChannel(channelId);
  }

  /**
   * GET /api/files/:id
   * Default: stream the bytes for download.
   * ?url=true: return a presigned download URL as JSON instead.
   */
  @Get('files/:id')
  async download(
    @Param('id', ParseUUIDPipe) id: string,
    @Query() query: DownloadQueryDto,
    @Res({ passthrough: false }) res: Response,
  ): Promise<void> {
    if (query.url) {
      const result = await this.filesService.presignedUrl(id);
      res.json(result);
      return;
    }

    const { row, stream } = await this.filesService.openStream(id);
    res.setHeader('Content-Type', 'application/octet-stream');
    res.setHeader(
      'Content-Disposition',
      `attachment; filename="${encodeURIComponent(row.name)}"`,
    );
    res.setHeader('Content-Length', row.sizeBytes.toString());
    stream.pipe(res);
  }
}
