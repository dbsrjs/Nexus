import { Logger, Module } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { LocalDiskDriver } from './local-disk.driver';
import { S3Driver } from './s3.driver';
import { resolveS3Config } from './storage.config';
import { StorageDriver } from './storage.driver';

/**
 * 첨부를 어디에 둘지 고르는 유일한 지점.
 *
 * 개발은 로컬 디스크, 배포는 S3 호환 스토리지다. 바뀌는 것은 이 팩토리 하나이고
 * 컨트롤러 · 서비스 · 앱은 그대로다 — DB 의 `storage_key` 도 같은 문자열이
 * 로컬에서는 경로, S3 에서는 오브젝트 키가 된다.
 *
 * 배포는 `.env` 의 `STORAGE_DRIVER=s3` 와 `STORAGE_ENDPOINT` 등 넷(storage.config.ts).
 * 개발 루프는 여전히 local 이다 — S3 를 띄우는 것이 새 PC 셋업 비용이 되지 않게(8-1).
 */
@Module({
  providers: [
    {
      provide: StorageDriver,
      useFactory: (config: ConfigService): StorageDriver => {
        // `??` 는 `STORAGE_DRIVER=` 처럼 자리만 잡은 빈 값을 통과시켜 부팅이 멈췄다(CLAUDE.md §2) — `||`.
        const kind = config.get<string>('STORAGE_DRIVER')?.trim() || 'local';
        if (kind !== 'local' && kind !== 's3') {
          // 조용히 로컬로 떨어지면 배포에서 파일이 서버 디스크에 쌓인다.
          throw new Error(`STORAGE_DRIVER=${kind} 는 지원하지 않습니다 (local · s3)`);
        }
        new Logger('StorageModule').log(`스토리지 드라이버: ${kind}`);
        return kind === 's3'
          ? new S3Driver(resolveS3Config(config))
          : new LocalDiskDriver(config);
      },
      inject: [ConfigService],
    },
  ],
  exports: [StorageDriver],
})
export class StorageModule {}
