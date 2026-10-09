#!/usr/bin/env node
/**
 * STORAGE_* 가 가리키는 S3 호환 스토리지에 버킷을 만든다(이미 있으면 그대로 둔다).
 *
 * 서버는 버킷을 만들지 않는다 — 운영(R2)에서는 사람이 대시보드에서 만들고 수명주기
 * 규칙이 없는지 확인해야 한다(docs/인프라-설계.md §7). 이 스크립트는 SeaweedFS 로
 * 검증할 때(CI · 손 검증)만 쓴다.
 */
import { CreateBucketCommand, HeadBucketCommand, S3Client } from '@aws-sdk/client-s3';

const need = (k) => {
  const v = process.env[k]?.trim();
  if (!v) {
    console.error(`${k} 가 비어 있습니다`);
    process.exit(1);
  }
  return v;
};

const bucket = need('STORAGE_BUCKET');
const client = new S3Client({
  endpoint: need('STORAGE_ENDPOINT'),
  region: process.env.STORAGE_REGION?.trim() || 'auto',
  forcePathStyle: true,
  credentials: {
    accessKeyId: need('STORAGE_ACCESS_KEY'),
    secretAccessKey: need('STORAGE_SECRET_KEY'),
  },
});

try {
  await client.send(new HeadBucketCommand({ Bucket: bucket }));
  console.log(`버킷이 이미 있습니다: ${bucket}`);
} catch {
  await client.send(new CreateBucketCommand({ Bucket: bucket }));
  console.log(`버킷을 만들었습니다: ${bucket}`);
}
