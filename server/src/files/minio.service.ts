import {
  Injectable,
  InternalServerErrorException,
  Logger,
  OnModuleInit,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { Client as MinioClient } from 'minio';
import { Readable } from 'stream';

/**
 * Thin wrapper around the MinIO (S3-compatible) client.
 *
 * Configured from env (see server/.env.example):
 *   MINIO_ENDPOINT, MINIO_PORT, MINIO_ACCESS_KEY, MINIO_SECRET_KEY,
 *   MINIO_BUCKET, MINIO_USE_SSL
 *
 * Files are "영구 보관" (retained, no expiry) — we never set lifecycle rules.
 * The target bucket is created on init if it does not yet exist.
 */
@Injectable()
export class MinioService implements OnModuleInit {
  private readonly logger = new Logger(MinioService.name);
  private readonly client: MinioClient;
  readonly bucket: string;

  constructor(private readonly config: ConfigService) {
    const endPoint = this.config.get<string>('MINIO_ENDPOINT', 'localhost');
    const port = Number(this.config.get<string>('MINIO_PORT', '9000'));
    const useSSL =
      String(this.config.get<string>('MINIO_USE_SSL', 'false')) === 'true';
    const accessKey = this.config.get<string>('MINIO_ACCESS_KEY', 'minioadmin');
    const secretKey = this.config.get<string>('MINIO_SECRET_KEY', 'minioadmin');
    this.bucket = this.config.get<string>('MINIO_BUCKET', 'onework-files');

    this.client = new MinioClient({
      endPoint,
      port,
      useSSL,
      accessKey,
      secretKey,
    });
  }

  /**
   * Ensure the configured bucket exists (create if missing) on startup.
   * Failure here is logged but not fatal — MinIO may still be coming up in
   * an on-prem deploy; the first upload will surface a clear error if not.
   */
  async onModuleInit(): Promise<void> {
    try {
      const exists = await this.client.bucketExists(this.bucket);
      if (!exists) {
        await this.client.makeBucket(this.bucket);
        this.logger.log(`Created MinIO bucket "${this.bucket}"`);
      } else {
        this.logger.log(`MinIO bucket "${this.bucket}" is ready`);
      }
    } catch (err) {
      this.logger.error(
        `Could not verify/create MinIO bucket "${this.bucket}": ${
          (err as Error).message
        }`,
      );
    }
  }

  /** Upload a buffer under the given object key. */
  async putObject(
    objectKey: string,
    buffer: Buffer,
    size: number,
    contentType?: string,
  ): Promise<void> {
    try {
      await this.client.putObject(
        this.bucket,
        objectKey,
        buffer,
        size,
        contentType ? { 'Content-Type': contentType } : undefined,
      );
    } catch (err) {
      this.logger.error(
        `putObject failed for "${objectKey}": ${(err as Error).message}`,
      );
      throw new InternalServerErrorException('파일 저장에 실패했습니다.');
    }
  }

  /** Open a readable stream for the object (used for direct download). */
  async getObjectStream(objectKey: string): Promise<Readable> {
    try {
      return await this.client.getObject(this.bucket, objectKey);
    } catch (err) {
      this.logger.error(
        `getObject failed for "${objectKey}": ${(err as Error).message}`,
      );
      throw new InternalServerErrorException('파일을 읽을 수 없습니다.');
    }
  }

  /**
   * Build a time-limited presigned GET URL for the object.
   * @param expirySeconds default 5 minutes
   */
  async presignedGetUrl(
    objectKey: string,
    downloadName?: string,
    expirySeconds = 5 * 60,
  ): Promise<string> {
    try {
      const reqParams = downloadName
        ? {
            'response-content-disposition': `attachment; filename="${encodeURIComponent(
              downloadName,
            )}"`,
          }
        : undefined;
      return await this.client.presignedGetObject(
        this.bucket,
        objectKey,
        expirySeconds,
        reqParams,
      );
    } catch (err) {
      this.logger.error(
        `presignedGetObject failed for "${objectKey}": ${
          (err as Error).message
        }`,
      );
      throw new InternalServerErrorException(
        '다운로드 URL 생성에 실패했습니다.',
      );
    }
  }
}
