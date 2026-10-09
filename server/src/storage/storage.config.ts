import { ConfigService } from '@nestjs/config';
import { envTrimmed } from '../config/env';

export interface S3StorageConfig {
  endpoint: string;
  region: string;
  bucket: string;
  accessKey: string;
  secretKey: string;
}

/**
 * `STORAGE_DRIVER=s3` 일 때 읽는 값.
 *
 * **하나라도 비면 부팅을 멈춘다.** JWT 시크릿과 같은 이유다(jwt.config.ts) — 조용히
 * 넘어가면 첫 업로드에서야 500 으로 드러나고, 그 사이 사람은 서버가 멀쩡하다고 믿는다.
 * 리전만 기본값(`auto`)이 있다 — R2 가 요구하는 값이고 SeaweedFS 는 무시한다.
 */
export function resolveS3Config(config: ConfigService): S3StorageConfig {
  const read = (key: string) => envTrimmed(config, key);
  const values = {
    endpoint: read('STORAGE_ENDPOINT'),
    bucket: read('STORAGE_BUCKET'),
    accessKey: read('STORAGE_ACCESS_KEY'),
    secretKey: read('STORAGE_SECRET_KEY'),
  };
  const missing = Object.entries({
    STORAGE_ENDPOINT: values.endpoint,
    STORAGE_BUCKET: values.bucket,
    STORAGE_ACCESS_KEY: values.accessKey,
    STORAGE_SECRET_KEY: values.secretKey,
  })
    .filter(([, v]) => !v)
    .map(([k]) => k);
  if (missing.length > 0) {
    throw new Error(`STORAGE_DRIVER=s3 인데 값이 비어 있습니다: ${missing.join(', ')}`);
  }
  // 옛 .env.example 은 MinIO 클라이언트식으로 호스트만(`localhost`) 적고 포트 · SSL 을
  // 따로 두었다. SDK 는 전체 URL 을 받으므로 스킴이 없으면 잘못 옮긴 값이다.
  if (!/^https?:\/\//.test(values.endpoint!)) {
    throw new Error(
      `STORAGE_ENDPOINT 는 스킴을 포함한 주소여야 합니다(예: https://<계정>.r2.cloudflarestorage.com): ${values.endpoint}`,
    );
  }
  return {
    endpoint: values.endpoint!,
    bucket: values.bucket!,
    accessKey: values.accessKey!,
    secretKey: values.secretKey!,
    region: read('STORAGE_REGION') ?? 'auto',
  };
}
