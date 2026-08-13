/**
 * Nexus — 시드 데이터
 *
 * Phase 0 는 나 혼자 쓰는 개발 허브다. 그래서 시드도 딱 그만큼만 만든다:
 * 계정 1개 + 스페이스 1개 + 채널 몇 개.
 *
 * 이전 시드는 사내 데모용 인물 7명·채널 8개·근태·공지를 담고 있었는데,
 * 그 데이터 모델 자체가 사라졌다.
 *
 * 실행:  npm run seed         (DATABASE_URL 이 가리키는 DB 필요)
 * 비밀번호: SEED_PASSWORD 환경변수. 없으면 임의 생성해 한 번 출력한다.
 * 반복 실행해도 안전하다(upsert 기반).
 */
import { randomBytes } from 'crypto';
import { PrismaClient, SpaceRole } from '@prisma/client';
import * as argon2 from 'argon2';

const prisma = new PrismaClient();

const SEED_EMAIL = process.env.SEED_EMAIL ?? 'dbsrjs1224@gmail.com';
const SEED_NAME = process.env.SEED_NAME ?? '이윤건';
const SPACE_SLUG = process.env.SEED_SPACE_SLUG ?? 'nexus';
const SPACE_NAME = process.env.SEED_SPACE_NAME ?? 'Nexus';

const CATEGORIES = [
  {
    name: '개발',
    position: 0,
    channels: [
      { key: 'general', name: '일반', topic: '아무 이야기나' },
      { key: 'dev', name: '개발', topic: '커밋 · PR · 이슈가 흘러 들어오는 곳' },
      { key: 'nexus', name: 'nexus', topic: '이 프로젝트 자체에 대한 채널' },
    ],
  },
  {
    name: '기록',
    position: 1,
    channels: [
      { key: 'notes', name: '메모', topic: '나중에 찾아볼 것들' },
      { key: 'links', name: '링크', topic: '읽을거리 · 레퍼런스' },
    ],
  },
];

async function main(): Promise<void> {
  console.log('🌱  Nexus 시드 시작…');

  // ── 1) 계정 ────────────────────────────────
  const generated = !process.env.SEED_PASSWORD;
  const password =
    process.env.SEED_PASSWORD ?? randomBytes(12).toString('base64url');

  const user = await prisma.user.upsert({
    where: { email: SEED_EMAIL },
    update: { name: SEED_NAME },
    create: {
      email: SEED_EMAIL,
      name: SEED_NAME,
      passwordHash: await argon2.hash(password),
    },
  });
  console.log(`  • user: ${user.email}`);

  // ── 2) 스페이스 + owner 멤버십 ──────────────
  const space = await prisma.space.upsert({
    where: { slug: SPACE_SLUG },
    update: { name: SPACE_NAME },
    create: { slug: SPACE_SLUG, name: SPACE_NAME, ownerId: user.id },
  });

  await prisma.spaceMember.upsert({
    where: { spaceId_userId: { spaceId: space.id, userId: user.id } },
    update: { role: SpaceRole.owner },
    create: { spaceId: space.id, userId: user.id, role: SpaceRole.owner },
  });
  console.log(`  • space: ${space.slug} (owner ${user.email})`);

  // ── 3) 카테고리 + 채널 ──────────────────────
  let channelCount = 0;
  for (const cat of CATEGORIES) {
    // categories 에는 (space_id, name) 유니크가 없으므로 조회 후 분기한다.
    const existing = await prisma.category.findFirst({
      where: { spaceId: space.id, name: cat.name },
    });
    const category =
      existing ??
      (await prisma.category.create({
        data: { spaceId: space.id, name: cat.name, position: cat.position },
      }));

    for (let i = 0; i < cat.channels.length; i++) {
      const c = cat.channels[i];
      const channel = await prisma.channel.upsert({
        where: { spaceId_key: { spaceId: space.id, key: c.key } },
        update: { name: c.name, topic: c.topic, categoryId: category.id },
        create: {
          spaceId: space.id,
          categoryId: category.id,
          key: c.key,
          name: c.name,
          topic: c.topic,
          position: i,
        },
      });

      await prisma.channelMember.upsert({
        where: { channelId_userId: { channelId: channel.id, userId: user.id } },
        update: {},
        create: { channelId: channel.id, userId: user.id },
      });
      channelCount++;
    }
  }
  console.log(`  • channels: ${channelCount}`);

  console.log('✅  시드 완료.');
  if (generated) {
    console.log('');
    console.log(`   로그인: ${SEED_EMAIL}`);
    console.log(`   비밀번호(임의 생성 — 지금 저장해 두십시오): ${password}`);
    console.log('   고정하려면 SEED_PASSWORD 환경변수를 쓰십시오.');
  }
}

main()
  .catch((e) => {
    console.error('❌  시드 실패:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
