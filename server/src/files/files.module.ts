import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { FilesController } from './files.controller';
import { FilesService } from './files.service';
import { MinioService } from './minio.service';
import { RealtimeModule } from '../realtime/realtime.module';

/**
 * Files module — MinIO-backed upload/download with 영구 보관 (retained) metadata.
 * PrismaService is injected from the global PrismaModule (do not import it here).
 * RealtimeModule is imported so a freshly-attached file can re-emit message:edited
 * (so other users see an inline image without reloading).
 */
@Module({
  imports: [ConfigModule, RealtimeModule],
  controllers: [FilesController],
  providers: [FilesService, MinioService],
  exports: [FilesService, MinioService],
})
export class FilesModule {}
