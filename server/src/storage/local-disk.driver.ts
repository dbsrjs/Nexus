import { Injectable, Logger, NotFoundException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { createReadStream, createWriteStream } from 'fs';
import { mkdir, rm, stat } from 'fs/promises';
import { dirname, join, normalize, resolve, sep } from 'path';
import { Readable } from 'stream';
import { pipeline } from 'stream/promises';
import { StorageDriver } from './storage.driver';

/**
 * 개발용 드라이버. 파일을 서버 옆 디렉터리에 그대로 둔다.
 *
 * MinIO 컨테이너를 개발 루프에 들이지 않기 위한 선택이다 — WSL 배포판은 마지막
 * 세션이 닫히면 정지하므로(CLAUDE.md §2), 함께 죽는 것을 하나 더 만들지 않는다.
 * S3 구현은 배포 직전에 붙이고, 그때 같은 검증 스크립트를 한 번 돌려 확인한다.
 *
 * **여기 쌓인 파일은 PC 마다 따로다.** DB 와 같다 — git 으로 옮겨지지 않는다.
 */
@Injectable()
export class LocalDiskDriver extends StorageDriver {
  readonly name = 'local';

  private readonly logger = new Logger(LocalDiskDriver.name);
  private readonly root: string;

  constructor(config: ConfigService) {
    super();
    // **빈 문자열을 미설정으로 친다.** `.env` 에 `STORAGE_LOCAL_DIR=` 를 자리만
    // 잡아 둔 경우가 흔한데, `??` 로 받으면 `''` 이 통과해 `resolve('')` 가
    // 프로세스 작업 디렉터리가 된다 — 첨부가 서버 소스 옆에 흩어진다.
    const configured = config.get<string>('STORAGE_LOCAL_DIR')?.trim();
    this.root = resolve(configured || join(process.cwd(), 'storage'));
    this.logger.log(`첨부 저장 위치: ${this.root}`);
  }

  async put(key: string, body: Readable | Buffer, _mime?: string): Promise<void> {
    const path = this.pathFor(key);
    await mkdir(dirname(path), { recursive: true });

    if (Buffer.isBuffer(body)) {
      await pipeline(Readable.from(body), createWriteStream(path));
      return;
    }
    await pipeline(body, createWriteStream(path));
  }

  async get(key: string): Promise<Readable> {
    const path = this.pathFor(key);
    if (!(await this.exists(key))) {
      // DB 에는 행이 있는데 파일이 없는 경우다. 조용히 빈 응답을 주면 원인을
      // 찾기 어려우므로 드러낸다.
      throw new NotFoundException('첨부 파일을 찾을 수 없습니다');
    }
    return createReadStream(path);
  }

  async delete(key: string): Promise<void> {
    // 없는 것을 지워도 오류가 아니다 — 정리 작업이 여러 번 돌 수 있다.
    await rm(this.pathFor(key), { force: true });
  }

  async exists(key: string): Promise<boolean> {
    try {
      const info = await stat(this.pathFor(key));
      return info.isFile();
    } catch {
      return false;
    }
  }

  /**
   * 키를 실제 경로로 바꾼다.
   *
   * **루트 밖으로 나가는 키를 막는다.** 키는 서버가 만들지만(`buildStorageKey`),
   * 이 검사가 없으면 DB 가 오염됐을 때 한 행이 곧바로 임의 파일 읽기가 된다.
   */
  private pathFor(key: string): string {
    const path = resolve(this.root, normalize(key));
    if (path !== this.root && !path.startsWith(this.root + sep)) {
      throw new NotFoundException('첨부 파일을 찾을 수 없습니다');
    }
    return path;
  }
}
