import { Logger, Module } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { LocalDiskDriver } from './local-disk.driver';
import { StorageDriver } from './storage.driver';

/**
 * 첨부를 어디에 둘지 고르는 유일한 지점.
 *
 * 개발은 로컬 디스크, 배포는 S3 호환 스토리지다. 바뀌는 것은 이 팩토리 하나이고
 * 컨트롤러 · 서비스 · 앱은 그대로다 — DB 의 `storage_key` 도 같은 문자열이
 * 로컬에서는 경로, S3 에서는 오브젝트 키가 된다.
 *
 * S3 구현을 붙이는 절차: `S3Driver` 를 만들고 아래 분기에 넣은 뒤
 * `.env` 의 `STORAGE_DRIVER=s3`. `minio` 패키지가 이미 의존성에 있다.
 */
@Module({
  providers: [
    {
      provide: StorageDriver,
      useFactory: (config: ConfigService): StorageDriver => {
        const kind = config.get<string>('STORAGE_DRIVER') ?? 'local';
        if (kind !== 'local') {
          // 조용히 로컬로 떨어지면 배포에서 파일이 서버 디스크에 쌓인다.
          throw new Error(
            `STORAGE_DRIVER=${kind} 는 아직 구현되지 않았습니다 (8단계에서는 local 만 지원)`,
          );
        }
        new Logger('StorageModule').log(`스토리지 드라이버: ${kind}`);
        return new LocalDiskDriver(config);
      },
      inject: [ConfigService],
    },
  ],
  exports: [StorageDriver],
})
export class StorageModule {}
