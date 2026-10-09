import { Logger, NotFoundException, OnModuleInit } from '@nestjs/common';
import {
  DeleteObjectCommand,
  GetObjectCommand,
  HeadBucketCommand,
  HeadObjectCommand,
  PutObjectCommand,
  S3Client,
  S3ServiceException,
} from '@aws-sdk/client-s3';
import { Readable } from 'stream';
import { StorageDriver } from './storage.driver';
import type { S3StorageConfig } from './storage.config';

/**
 * 배포용 드라이버. S3 호환 스토리지(Cloudflare R2 · AWS S3 · SeaweedFS)에 둔다.
 *
 * **서명 URL 을 만들지 않는다**(storage.driver.ts) — 바이트는 언제나 서버를 지나 앱에
 * 간다. 그래서 이 드라이버는 put · get · delete · exists 넷만 SDK 로 옮긴다.
 *
 * 키는 로컬 드라이버와 같은 문자열(`2026/08/uuid.png`)을 오브젝트 키로 그대로 쓴다.
 * DB 의 `storage_key` 를 바꾸지 않고 드라이버만 갈아 끼울 수 있게 하기 위해서다.
 */
export class S3Driver extends StorageDriver implements OnModuleInit {
  readonly name = 's3';

  private readonly logger = new Logger(S3Driver.name);
  private readonly client: S3Client;
  private readonly bucket: string;

  constructor(config: S3StorageConfig, client?: S3Client) {
    super();
    this.bucket = config.bucket;
    this.client =
      client ??
      new S3Client({
        endpoint: config.endpoint,
        region: config.region,
        // 경로 방식(`endpoint/bucket/key`). R2 · SeaweedFS 는 가상 호스트 방식
        // (`bucket.endpoint`)을 쓰려면 DNS 가 따로 필요하다 — 경로 방식은 어디서나 된다.
        forcePathStyle: true,
        credentials: { accessKeyId: config.accessKey, secretAccessKey: config.secretKey },
      });
  }

  /**
   * 부팅 때 버킷에 한 번 닿아 본다.
   *
   * **실패해도 부팅을 멈추지 않는다.** 스토리지가 잠깐 안 닿는 것으로 서버가 죽으면
   * 첨부와 상관없는 대화까지 같이 멈춘다. 대신 키 · 버킷 이름 오타가 첫 업로드 때가
   * 아니라 부팅 로그에서 드러나게 한다.
   */
  async onModuleInit(): Promise<void> {
    try {
      await this.client.send(new HeadBucketCommand({ Bucket: this.bucket }));
      this.logger.log(`S3 버킷 확인: ${this.bucket}`);
    } catch (err) {
      this.logger.error(
        `S3 버킷(${this.bucket})에 닿지 못했습니다 — 첨부 업로드 · 다운로드가 실패합니다: ${describe(err)}`,
      );
    }
  }

  async put(key: string, body: Readable | Buffer, mime?: string): Promise<void> {
    // PutObject 는 길이를 모르는 스트림을 받지 못한다(서명에 길이가 들어간다).
    // 지금 부르는 쪽(첨부 · 아바타 · 썸네일)은 전부 Buffer 라 이 분기는 인터페이스를
    // 지키기 위한 것이다 — 상한이 있는 업로드라 메모리에 모아도 된다.
    const bytes = Buffer.isBuffer(body) ? body : await collect(body);
    await this.client.send(
      new PutObjectCommand({
        Bucket: this.bucket,
        Key: key,
        Body: bytes,
        ContentLength: bytes.length,
        ContentType: mime,
      }),
    );
  }

  async get(key: string): Promise<Readable> {
    try {
      const res = await this.client.send(
        new GetObjectCommand({ Bucket: this.bucket, Key: key }),
      );
      // Node 런타임에서 Body 는 Readable(IncomingMessage)이다. 없으면 빈 객체라도
      // 파일이 없는 것과 같게 다룬다.
      if (!(res.Body instanceof Readable)) {
        throw new NotFoundException('첨부 파일을 찾을 수 없습니다');
      }
      return res.Body;
    } catch (err) {
      if (isNotFound(err)) {
        // 로컬 드라이버와 같은 응답 — DB 에는 행이 있는데 오브젝트가 없는 경우다.
        throw new NotFoundException('첨부 파일을 찾을 수 없습니다');
      }
      throw err;
    }
  }

  async delete(key: string): Promise<void> {
    // S3 의 DeleteObject 는 없는 키에도 204 다 — 정리 작업이 여러 번 돌아도 된다.
    await this.client.send(new DeleteObjectCommand({ Bucket: this.bucket, Key: key }));
  }

  async exists(key: string): Promise<boolean> {
    try {
      await this.client.send(new HeadObjectCommand({ Bucket: this.bucket, Key: key }));
      return true;
    } catch (err) {
      if (isNotFound(err)) return false;
      // 권한 · 네트워크 오류를 「없다」로 접지 않는다 — 썸네일이 없다고 판단해 원본을
      // 내보내는 식으로 조용히 다르게 동작하게 된다.
      throw err;
    }
  }
}

/**
 * 없는 오브젝트인가. GetObject 는 `NoSuchKey`, HeadObject 는 본문이 없어 `NotFound`
 * 로 온다 — 구현마다 이름이 달라 상태 코드로 함께 본다.
 */
export function isNotFound(err: unknown): boolean {
  if (err instanceof S3ServiceException) {
    return (
      err.name === 'NoSuchKey' ||
      err.name === 'NotFound' ||
      err.$metadata?.httpStatusCode === 404
    );
  }
  return false;
}

function describe(err: unknown): string {
  if (err instanceof S3ServiceException) {
    return `${err.name} (HTTP ${err.$metadata?.httpStatusCode ?? '?'})`;
  }
  return err instanceof Error ? err.message : String(err);
}

async function collect(stream: Readable): Promise<Buffer> {
  const chunks: Buffer[] = [];
  for await (const chunk of stream) {
    chunks.push(Buffer.isBuffer(chunk) ? chunk : Buffer.from(chunk));
  }
  return Buffer.concat(chunks);
}
