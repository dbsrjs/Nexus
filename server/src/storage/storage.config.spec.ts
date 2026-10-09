import { ConfigService } from '@nestjs/config';
import { S3ServiceException } from '@aws-sdk/client-s3';
import { resolveS3Config } from './storage.config';
import { isNotFound } from './s3.driver';

function fakeConfig(values: Record<string, string>): ConfigService {
  return { get: (key: string) => values[key] } as unknown as ConfigService;
}

const full = {
  STORAGE_ENDPOINT: 'https://acct.r2.cloudflarestorage.com',
  STORAGE_BUCKET: 'nexus-attachments',
  STORAGE_ACCESS_KEY: 'ak',
  STORAGE_SECRET_KEY: 'sk',
};

describe('resolveS3Config', () => {
  it('넷이 차 있으면 읽고, 리전은 auto 가 기본이다(R2)', () => {
    expect(resolveS3Config(fakeConfig(full))).toEqual({
      endpoint: full.STORAGE_ENDPOINT,
      bucket: full.STORAGE_BUCKET,
      accessKey: 'ak',
      secretKey: 'sk',
      region: 'auto',
    });
  });

  it('빈 값을 이름과 함께 알린다 — 첫 업로드가 아니라 부팅에서 드러나게', () => {
    expect(() =>
      resolveS3Config(
        fakeConfig({ ...full, STORAGE_SECRET_KEY: '', STORAGE_BUCKET: ' ' }),
      ),
    ).toThrow(/STORAGE_BUCKET, STORAGE_SECRET_KEY/);
  });

  it('스킴 없는 옛 형식(호스트만)을 거부한다', () => {
    expect(() =>
      resolveS3Config(fakeConfig({ ...full, STORAGE_ENDPOINT: 'localhost' })),
    ).toThrow(/스킴/);
  });
});

describe('isNotFound', () => {
  const s3Error = (name: string, status: number) =>
    new S3ServiceException({
      name,
      $fault: 'client',
      $metadata: { httpStatusCode: status },
    });

  it('GetObject 의 NoSuchKey · HeadObject 의 NotFound · 이름 모를 404 를 「없다」로 본다', () => {
    expect(isNotFound(s3Error('NoSuchKey', 404))).toBe(true);
    expect(isNotFound(s3Error('NotFound', 404))).toBe(true);
    expect(isNotFound(s3Error('Unknown', 404))).toBe(true);
  });

  it('권한 오류는 「없다」가 아니다 — 썸네일 판단이 조용히 틀어진다', () => {
    expect(isNotFound(s3Error('AccessDenied', 403))).toBe(false);
    expect(isNotFound(new Error('network'))).toBe(false);
  });
});
