// 첨부(8-1) 검증. 실제 서버 · 실제 DB · 실제 스토리지로 확인한다.
//
// **드라이버와 무관하게 돈다.** 지금은 로컬 디스크지만, 배포 직전에
// STORAGE_DRIVER=s3 로 바꿔 같은 스크립트를 한 번 돌리는 것이 S3 경로를
// 태워 보는 유일한 계기다. 그래서 파일 경로를 직접 들여다보지 않는다 —
// 저장 위치를 아는 검사는 로컬에서만 통과한다.
//
// 사전 조건: npm run db:up && npm run server:dev
// 사용: npm run check:attachments

import zlib from 'zlib';

import { requireServer } from './lib/preflight.mjs';
import { BASE, stamp, api, signup } from './lib/api.mjs';
import { check, summary } from './lib/checks.mjs';
await requireServer(BASE);


/** multipart 업로드. Node 의 FormData·Blob 을 그대로 쓴다. */
async function upload(spaceId, channelId, token, { name, bytes, type }) {
  const form = new FormData();
  form.append('file', new Blob([bytes], { type }), name);

  const res = await fetch(
    `${BASE}/spaces/${spaceId}/channels/${channelId}/attachments`,
    { method: 'POST', headers: { authorization: `Bearer ${token}` }, body: form },
  );
  let json = null;
  try {
    json = await res.json();
  } catch {
    /* 본문 없음 */
  }
  return { status: res.status, json };
}

async function download(spaceId, attachmentId, token, variant) {
  const url =
    `${BASE}/spaces/${spaceId}/attachments/${attachmentId}` +
    (variant ? `?variant=${variant}` : '');
  const res = await fetch(url, { headers: { authorization: `Bearer ${token}` } });
  const buffer = res.ok ? Buffer.from(await res.arrayBuffer()) : null;
  return { status: res.status, headers: res.headers, buffer };
}

/** 지정한 크기의 PNG 를 만든다. 썸네일이 실제로 줄어드는지 보려면 큰 그림이 필요하다. */
function makePng(width, height) {
  const crc32 = (buf) => {
    let c = ~0;
    for (const byte of buf) {
      c ^= byte;
      for (let i = 0; i < 8; i++) c = (c >>> 1) ^ (0xedb88320 & -(c & 1));
    }
    return ~c >>> 0;
  };
  const chunk = (type, data) => {
    const len = Buffer.alloc(4);
    len.writeUInt32BE(data.length);
    const body = Buffer.concat([Buffer.from(type, 'ascii'), data]);
    const crc = Buffer.alloc(4);
    crc.writeUInt32BE(crc32(body));
    return Buffer.concat([len, body, crc]);
  };

  const ihdr = Buffer.alloc(13);
  ihdr.writeUInt32BE(width, 0);
  ihdr.writeUInt32BE(height, 4);
  ihdr[8] = 8; // bit depth
  ihdr[9] = 2; // truecolor
  // 각 줄 = 필터 바이트 + RGB. 색을 조금씩 바꿔야 압축 후에도 크기가 남는다.
  const raw = Buffer.alloc(height * (1 + width * 3));
  let p = 0;
  for (let y = 0; y < height; y++) {
    raw[p++] = 0;
    for (let x = 0; x < width; x++) {
      raw[p++] = (x * 7) & 0xff;
      raw[p++] = (y * 13) & 0xff;
      raw[p++] = (x * y) & 0xff;
    }
  }
  const idat = zlib.deflateSync(raw);
  return Buffer.concat([
    Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]),
    chunk('IHDR', ihdr),
    chunk('IDAT', idat),
    chunk('IEND', Buffer.alloc(0)),
  ]);
}


/** 1×1 빨간 점 PNG. 크기 측정이 되는지 보려면 진짜 이미지여야 한다. */
const PNG_1X1 = Buffer.from(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==',
  'base64',
);

console.log('\n첨부 검증 — 실서버 · 실DB · 실스토리지\n');

const alice = await signup('att', 'a');
const outsider = await signup('att', 'x');

const space = await api('POST', '/spaces', {
  token: alice.token,
  body: { name: `첨부 검증 ${stamp}` },
});
const spaceId = space.json.id;

const channels = await api('GET', `/spaces/${spaceId}/channels`, {
  token: alice.token,
});
const channel = channels.json[0];
check('스페이스 · 채널 준비', !!channel);

// ── 업로드 ────────────────────────────────────
console.log('\n[업로드]');

const TEXT = Buffer.from('첨부 본문입니다\n', 'utf8');

const uploaded = await upload(spaceId, channel.id, alice.token, {
  name: '메모 파일.txt',
  bytes: TEXT,
  type: 'text/plain',
});
check('업로드 201', uploaded.status === 201, `status=${uploaded.status} ${JSON.stringify(uploaded.json)}`);
check(
  '★ 한글 파일명이 깨지지 않는다',
  uploaded.json?.name === '메모 파일.txt',
  JSON.stringify(uploaded.json?.name),
);
check(
  '크기가 바이트 수 그대로다',
  String(uploaded.json?.sizeBytes) === String(TEXT.length),
  `${uploaded.json?.sizeBytes} vs ${TEXT.length}`,
);
check(
  '★ storageKey 를 내보내지 않는다',
  uploaded.json && !('storageKey' in uploaded.json),
  JSON.stringify(Object.keys(uploaded.json ?? {})),
);

const image = await upload(spaceId, channel.id, alice.token, {
  name: 'dot.png',
  bytes: PNG_1X1,
  type: 'image/png',
});
check(
  '★ 이미지는 가로·세로를 재 둔다 — 미리보기 자리를 먼저 잡기 위해',
  image.json?.width === 1 && image.json?.height === 1,
  JSON.stringify({ w: image.json?.width, h: image.json?.height }),
);
check(
  '이미지가 아니면 크기는 null',
  uploaded.json?.width === null && uploaded.json?.height === null,
  JSON.stringify({ w: uploaded.json?.width, h: uploaded.json?.height }),
);

const empty = await upload(spaceId, channel.id, alice.token, {
  name: 'empty.txt',
  bytes: Buffer.alloc(0),
  type: 'text/plain',
});
check('빈 파일은 거부한다', empty.status === 400, `status=${empty.status}`);

// ── 테넌트 격리 ───────────────────────────────
console.log('\n[격리]');

const strangerUpload = await upload(spaceId, channel.id, outsider.token, {
  name: 'x.txt',
  bytes: TEXT,
  type: 'text/plain',
});
check(
  '★ 비멤버는 올릴 수 없다 (404 — 403 이면 존재를 알린다)',
  strangerUpload.status === 404,
  `status=${strangerUpload.status}`,
);

const strangerDownload = await download(spaceId, uploaded.json.id, outsider.token);
check(
  '★ 비멤버는 내려받을 수 없다',
  strangerDownload.status === 404,
  `status=${strangerDownload.status}`,
);

// ── 다운로드 ──────────────────────────────────
console.log('\n[다운로드]');

const got = await download(spaceId, uploaded.json.id, alice.token);
check('다운로드 200', got.status === 200, `status=${got.status}`);
check(
  '★ 올린 바이트가 그대로 돌아온다',
  got.buffer?.equals(TEXT),
  JSON.stringify(got.buffer?.toString('utf8')),
);
check(
  'Content-Type 이 올린 그대로다',
  got.headers.get('content-type')?.startsWith('text/plain'),
  got.headers.get('content-type'),
);
check(
  '★ 파일명을 RFC 5987 로 싣는다 — 한글이 깨지지 않는다',
  got.headers.get('content-disposition')?.includes("filename*=UTF-8''"),
  got.headers.get('content-disposition'),
);
check(
  '공용 캐시에 담기지 않는다 (열람 권한이 사람마다 다르다)',
  got.headers.get('cache-control')?.includes('private'),
  got.headers.get('cache-control'),
);

const missing = await download(spaceId, '00000000-0000-4000-8000-000000000000', alice.token);
check('없는 첨부는 404', missing.status === 404, `status=${missing.status}`);

// ── 썸네일 ────────────────────────────────────
console.log('\n[썸네일]');

const BIG_PNG = makePng(1200, 900);
const big = await upload(spaceId, channel.id, alice.token, {
  name: 'big.png',
  bytes: BIG_PNG,
  type: 'image/png',
});
check(
  '큰 이미지 업로드',
  big.status === 201 && big.json?.width === 1200 && big.json?.height === 900,
  JSON.stringify({ w: big.json?.width, h: big.json?.height }),
);

const thumb = await download(spaceId, big.json.id, alice.token, 'thumb');
check('썸네일 200', thumb.status === 200, `status=${thumb.status}`);
check(
  '★ 썸네일은 WebP 다 — 투명도를 지키면서 작다',
  thumb.headers.get('content-type') === 'image/webp',
  thumb.headers.get('content-type'),
);
check(
  '★ 썸네일이 원본보다 작다',
  thumb.buffer && thumb.buffer.length < BIG_PNG.length,
  `${thumb.buffer?.length} vs ${BIG_PNG.length}`,
);

const full = await download(spaceId, big.json.id, alice.token);
check(
  '변형을 안 주면 원본이 온다',
  full.buffer?.equals(BIG_PNG) &&
    full.headers.get('content-type') === 'image/png',
  `${full.buffer?.length} vs ${BIG_PNG.length}`,
);

const smallThumb = await download(spaceId, image.json.id, alice.token, 'thumb');
check(
  '★ 작은 이미지는 썸네일 없이 원본으로 떨어진다',
  smallThumb.status === 200 && smallThumb.buffer?.equals(PNG_1X1),
  `status=${smallThumb.status} len=${smallThumb.buffer?.length}`,
);

const textThumb = await download(spaceId, uploaded.json.id, alice.token, 'thumb');
check(
  '이미지가 아니면 원본으로 떨어진다',
  textThumb.status === 200 && textThumb.buffer?.equals(TEXT),
  `status=${textThumb.status}`,
);

const badVariant = await fetch(
  `${BASE}/spaces/${spaceId}/attachments/${big.json.id}?variant=huge`,
  { headers: { authorization: `Bearer ${alice.token}` } },
);
check('모르는 변형은 400', badVariant.status === 400, `status=${badVariant.status}`);

const strangerThumb = await download(spaceId, big.json.id, outsider.token, 'thumb');
check(
  '★ 썸네일도 같은 권한 검사를 지난다',
  strangerThumb.status === 404,
  `status=${strangerThumb.status}`,
);

// ── 메시지 연결 ───────────────────────────────
console.log('\n[메시지 연결]');

const sent = await api('POST', `/spaces/${spaceId}/channels/${channel.id}/messages`, {
  token: alice.token,
  body: { body: '파일 붙임', attachmentIds: [uploaded.json.id, image.json.id] },
});
check('전송 201', sent.status === 201, `status=${sent.status} ${JSON.stringify(sent.json)}`);
check(
  '★ 전송 응답에 첨부가 함께 온다',
  sent.json?.attachments?.length === 2,
  JSON.stringify(sent.json?.attachments?.length),
);
check(
  '첨부 순서는 올린 순서다',
  sent.json?.attachments?.[0]?.id === uploaded.json.id,
  JSON.stringify(sent.json?.attachments?.map((a) => a.name)),
);

const list = await api(
  'GET',
  `/spaces/${spaceId}/channels/${channel.id}/messages`,
  { token: alice.token },
);
const listed = list.json.items.find((m) => m.id === sent.json.id);
check(
  '★ 목록에도 첨부가 실린다',
  listed?.attachments?.length === 2,
  JSON.stringify(listed?.attachments?.length),
);

const reused = await api('POST', `/spaces/${spaceId}/channels/${channel.id}/messages`, {
  token: alice.token,
  body: { body: '같은 첨부 다시', attachmentIds: [uploaded.json.id] },
});
check(
  '★ 이미 쓴 첨부는 다시 붙일 수 없다',
  reused.status === 400,
  `status=${reused.status}`,
);

const foreign = await upload(spaceId, channel.id, alice.token, {
  name: 'other.txt',
  bytes: TEXT,
  type: 'text/plain',
});
const bogus = await api('POST', `/spaces/${spaceId}/channels/${channel.id}/messages`, {
  token: alice.token,
  body: {
    body: '없는 첨부',
    attachmentIds: [foreign.json.id, '00000000-0000-4000-8000-000000000000'],
  },
});
check(
  '★ 하나라도 못 찾으면 메시지를 만들지 않는다',
  bogus.status === 400,
  `status=${bogus.status}`,
);

const stillFree = await api('POST', `/spaces/${spaceId}/channels/${channel.id}/messages`, {
  token: alice.token,
  body: { body: '되살린 첨부', attachmentIds: [foreign.json.id] },
});
check(
  '앞의 실패가 첨부를 소모하지 않았다 (트랜잭션이 통째로 되돌아간다)',
  stillFree.status === 201 && stillFree.json.attachments.length === 1,
  `status=${stillFree.status}`,
);

// ── 본문 없이 첨부만 ──────────────────────────
console.log('\n[본문 없이 첨부만]');

const onlyFile = await upload(spaceId, channel.id, alice.token, {
  name: 'only.png',
  bytes: PNG_1X1,
  type: 'image/png',
});
const noBody = await api('POST', `/spaces/${spaceId}/channels/${channel.id}/messages`, {
  token: alice.token,
  body: { attachmentIds: [onlyFile.json.id] },
});
check(
  '★ 첨부만 있으면 본문이 없어도 보낼 수 있다',
  noBody.status === 201,
  `status=${noBody.status} ${JSON.stringify(noBody.json)}`,
);

const nothing = await api('POST', `/spaces/${spaceId}/channels/${channel.id}/messages`, {
  token: alice.token,
  body: { body: '   ' },
});
check(
  '★ 본문도 첨부도 없으면 400',
  nothing.status === 400,
  `status=${nothing.status}`,
);

// ── 소프트 삭제 ───────────────────────────────
console.log('\n[보관 정책]');

await api('DELETE', `/spaces/${spaceId}/messages/${sent.json.id}`, {
  token: alice.token,
});
const afterDelete = await api(
  'GET',
  `/spaces/${spaceId}/channels/${channel.id}/messages`,
  { token: alice.token },
);
const deleted = afterDelete.json.items.find((m) => m.id === sent.json.id);
check(
  '★ 메시지를 지워도 첨부는 남는다 — 본문만 가려진다',
  deleted?.body === '' && deleted?.attachments?.length === 2,
  JSON.stringify({ body: deleted?.body, count: deleted?.attachments?.length }),
);

const afterDeleteDownload = await download(spaceId, uploaded.json.id, alice.token);
check(
  '지워진 메시지의 첨부도 계속 내려받힌다',
  afterDeleteDownload.status === 200,
  `status=${afterDeleteDownload.status}`,
);

// ── 스페이스 파일 목록 ────────────────────────
console.log('\n[파일 목록]');

const files = await api('GET', `/spaces/${spaceId}/attachments`, {
  token: alice.token,
});
check('목록 200', files.status === 200, `status=${files.status}`);
check(
  '★ 연결되지 않은 첨부는 목록에 없다 — 아직 아무에게도 보이지 않는다',
  files.json.items.every((a) => a.messageId !== null),
  JSON.stringify(files.json.items.map((a) => a.name)),
);
check(
  '연결된 것은 전부 나온다',
  files.json.items.length === 4,
  JSON.stringify(files.json.items.length),
);

const filtered = await api(
  'GET',
  `/spaces/${spaceId}/attachments?channelId=${channel.id}`,
  { token: alice.token },
);
check(
  '채널로 좁힐 수 있다',
  filtered.status === 200 && filtered.json.items.length === 4,
  `status=${filtered.status} n=${filtered.json?.items?.length}`,
);

const strangerList = await api('GET', `/spaces/${spaceId}/attachments`, {
  token: outsider.token,
});
check(
  '비멤버에게는 목록도 없다',
  strangerList.status === 404,
  `status=${strangerList.status}`,
);

// ── 비공개 채널 ───────────────────────────────
console.log('\n[비공개 채널]');

const priv = await api('POST', `/spaces/${spaceId}/channels`, {
  token: alice.token,
  body: { name: `비공개 ${stamp}`, isPrivate: true },
});
const secret = await upload(spaceId, priv.json.id, alice.token, {
  name: 'secret.txt',
  bytes: Buffer.from('비밀', 'utf8'),
  type: 'text/plain',
});
await api('POST', `/spaces/${spaceId}/channels/${priv.json.id}/messages`, {
  token: alice.token,
  body: { body: '비공개 첨부', attachmentIds: [secret.json.id] },
});

// 두 번째 멤버를 초대해 비공개 채널이 실제로 가려지는지 본다.
const invite = await api('POST', `/spaces/${spaceId}/invites`, {
  token: alice.token,
  body: {},
});
await api('POST', `/invites/${invite.json.code}/accept`, {
  token: outsider.token,
});

const memberList = await api('GET', `/spaces/${spaceId}/attachments`, {
  token: outsider.token,
});
check(
  '★ 멤버가 돼도 비공개 채널의 파일은 목록에 없다',
  memberList.status === 200 &&
    !memberList.json.items.some((a) => a.name === 'secret.txt'),
  JSON.stringify(memberList.json?.items?.map((a) => a.name)),
);

const secretDownload = await download(spaceId, secret.json.id, outsider.token);
check(
  '★ 비공개 채널의 첨부는 id 를 알아도 못 연다',
  secretDownload.status === 404,
  `status=${secretDownload.status}`,
);

// ── 결과 ──────────────────────────────────────
process.exit(summary() === 0 ? 0 : 1);
