/**
 * ONE 워크스페이스 — 시드 데이터
 *
 * 출처: www/index.html 의 하드코딩된 데모 상태(state)를 그대로 이식.
 *   - 사용자(김도현/박지훈/이수진/한지원/정민호/최현우/경영지원)
 *   - 채널 notice/ops/dev/design/mkt/mgmt/hw/field + ChannelPermission 매트릭스
 *   - 데모 메시지(dev/design/notice/dm)
 *   - 이슈 보드(DEV-138 등), 업무일지, 근태, 공지
 *
 * 모두 upsert 기반이라 반복 실행해도 안전(idempotent)하다.
 * 실행: npm run seed (live DB 필요 — 이 단계에서는 실행하지 않음)
 */
import { PrismaClient, Role, ChannelKind, IssueStatus, IssuePriority, AttendanceStatus } from '@prisma/client';
import * as argon2 from 'argon2';

const prisma = new PrismaClient();

// 데모 공통 비밀번호. 운영 전환 시 반드시 변경.
const DEMO_PASSWORD = 'onework123!';

// ──────────────────────────────────────────────
// 사용자 (www/index.html 의 author/initial/color 조합에서 추출)
// ──────────────────────────────────────────────
interface SeedUser {
  email: string;
  name: string;
  initial: string;
  color: string;
  team: string;
  title: string;
  role: Role;
}

const USERS: SeedUser[] = [
  { email: 'dohyun.kim@onework.local',  name: '김도현', initial: '김', color: '#15181B', team: '개발팀',   title: '팀장',   role: Role.lead },
  { email: 'jihoon.park@onework.local', name: '박지훈', initial: '박', color: '#2563EB', team: '개발팀',   title: '시니어 개발자', role: Role.member },
  { email: 'sujin.lee@onework.local',   name: '이수진', initial: '이', color: '#7C5CFC', team: '디자인',   title: '프로덕트 디자이너', role: Role.member },
  { email: 'jiwon.han@onework.local',   name: '한지원', initial: '한', color: '#E08A00', team: '마케팅',   title: '마케터',   role: Role.member },
  { email: 'minho.jung@onework.local',  name: '정민호', initial: '정', color: '#15A66A', team: '운영팀',   title: '운영 매니저', role: Role.member },
  { email: 'hyunwoo.choi@onework.local',name: '최현우', initial: '최', color: '#0EA5A0', team: '하드웨어 개발', title: '펌웨어 엔지니어', role: Role.member },
  { email: 'admin@onework.local',       name: '경영지원', initial: '경', color: '#5B636B', team: '경영지원', title: '시스템 관리자', role: Role.admin },
];

// ──────────────────────────────────────────────
// 채널 (channelMeta) — key/name/initial/color
// ──────────────────────────────────────────────
interface SeedChannel {
  key: string;
  name: string;
  initial: string;
  color: string;
}

const CHANNELS: SeedChannel[] = [
  { key: 'notice', name: '전사 공지',   initial: '공',  color: '#2563EB' },
  { key: 'ops',    name: '운영팀',      initial: '운',  color: '#15A66A' },
  { key: 'dev',    name: '개발팀',      initial: '개',  color: '#2563EB' },
  { key: 'design', name: '디자인',      initial: '디',  color: '#7C5CFC' },
  { key: 'mkt',    name: '마케팅',      initial: '마',  color: '#E08A00' },
  { key: 'mgmt',   name: '경영',        initial: '경',  color: '#5B636B' },
  { key: 'hw',     name: '하드웨어 개발', initial: 'HW', color: '#0EA5A0' },
  { key: 'field',  name: '현장 지원팀',  initial: '현',  color: '#E5484D' },
];

// 권한 매트릭스 (www/index.html state.perms)
// mk([view: admin,lead,member,guest], [send: admin,lead,member,guest])
type PermRow = { view: [number, number, number, number]; send: [number, number, number, number] };
const PERMS: Record<string, PermRow> = {
  notice: { view: [1, 1, 1, 1], send: [1, 1, 0, 0] },
  ops:    { view: [1, 1, 1, 0], send: [1, 1, 1, 0] },
  dev:    { view: [1, 1, 1, 0], send: [1, 1, 1, 0] },
  design: { view: [1, 1, 1, 0], send: [1, 1, 1, 0] },
  mkt:    { view: [1, 1, 1, 0], send: [1, 1, 1, 0] },
  mgmt:   { view: [1, 0, 0, 0], send: [1, 0, 0, 0] },
  hw:     { view: [1, 1, 1, 0], send: [1, 1, 1, 0] },
  field:  { view: [1, 1, 1, 1], send: [1, 1, 1, 1] },
};

const ROLE_ORDER: Role[] = [Role.admin, Role.lead, Role.member, Role.guest];

// ──────────────────────────────────────────────
// 데모 메시지 (state.msgs) — 작성자 이름 → 위 USERS 의 이메일로 매핑
// ──────────────────────────────────────────────
const NAME_TO_EMAIL: Record<string, string> = {
  김도현: 'dohyun.kim@onework.local',
  '김도현(팀장)': 'dohyun.kim@onework.local',
  박지훈: 'jihoon.park@onework.local',
  이수진: 'sujin.lee@onework.local',
  한지원: 'jiwon.han@onework.local',
  정민호: 'minho.jung@onework.local',
  최현우: 'hyunwoo.choi@onework.local',
  경영지원: 'admin@onework.local',
};

interface SeedMessage {
  channelKey: string;
  author: string;
  body: string;
}

// 텍스트 메시지만 이식(파일/이미지 첨부 플래그는 메시지 본문으로 표기).
const MESSAGES: SeedMessage[] = [
  // dev
  { channelKey: 'dev', author: '박지훈', body: '결제 모듈 v2.3 빌드 올렸습니다. QA 부탁드립니다.' },
  { channelKey: 'dev', author: '박지훈', body: '[파일] payment-v2.3.0.zip (48.2 MB)' },
  { channelKey: 'dev', author: '이수진', body: '결제 완료 화면 디자인 최종본입니다. 적용 부탁드려요.' },
  { channelKey: 'dev', author: '이수진', body: '[이미지] checkout-success-final.png' },
  { channelKey: 'dev', author: '김도현', body: '확인했습니다. 오늘 중으로 반영하겠습니다.' },
  { channelKey: 'dev', author: '김도현(팀장)', body: '좋습니다. 릴리스 전에 결제 실패 케이스도 한 번 같이 봐주세요.' },
  // design
  { channelKey: 'design', author: '이수진', body: '신규 대시보드 컬러 토큰 정리 끝났습니다. 공유드려요.' },
  { channelKey: 'design', author: '한지원', body: '확인했어요! 마케팅 랜딩에도 동일하게 적용할게요.' },
  // notice
  { channelKey: 'notice', author: '경영지원', body: '[필독] 6월 정기 서버 점검 일정 안내 (6/22 02:00~04:00). 해당 시간 서비스 일시 중단됩니다.' },
  { channelKey: 'notice', author: '경영지원', body: '하계 휴가 신청이 오픈되었습니다. 근태 메뉴에서 ~6/30까지 신청해주세요.' },
];

// DM(dm1: 박지훈 ↔ 김도현) 메시지
const DM_MESSAGES: { author: string; body: string }[] = [
  { author: '박지훈', body: '도현님, DEV-138 리뷰 가능하실 때 봐주실 수 있나요?' },
  { author: '김도현', body: '네 오전 중에 볼게요!' },
];

// ──────────────────────────────────────────────
// 이슈 보드 (state.issues) — 한글 priority/label → enum 매핑
// ──────────────────────────────────────────────
const PRIORITY_MAP: Record<string, IssuePriority> = {
  낮음: IssuePriority.low,
  중간: IssuePriority.mid,
  높음: IssuePriority.high,
};

interface SeedIssue {
  key: string;
  title: string;
  assignee: string; // 한글 이름
  priority: string; // 한글
  label: string;
  status: IssueStatus;
}

const ISSUES: SeedIssue[] = [
  // backlog
  { key: 'DEV-142', title: '알림 센터 실시간 동기화',     assignee: '박지훈', priority: '중간', label: '기능', status: IssueStatus.backlog },
  { key: 'DEV-145', title: '다국어(영문) 1차 적용',       assignee: '정민호', priority: '낮음', label: '개선', status: IssueStatus.backlog },
  // doing
  { key: 'DEV-138', title: '결제 모듈 v2.3 리팩터링',     assignee: '박지훈', priority: '높음', label: '기능', status: IssueStatus.doing },
  { key: 'HW-031',  title: '센서 펌웨어 BLE 페어링 이슈', assignee: '최현우', priority: '높음', label: '버그', status: IssueStatus.doing },
  // review
  { key: 'DEV-140', title: '결제 완료 화면 UI 반영',       assignee: '이수진', priority: '중간', label: '디자인', status: IssueStatus.review },
  // done
  { key: 'DEV-133', title: '로그인 세션 만료 버그 수정',   assignee: '박지훈', priority: '높음', label: '버그', status: IssueStatus.done },
  { key: 'OPS-019', title: '고객사 A 데이터 마이그레이션', assignee: '정민호', priority: '중간', label: '운영', status: IssueStatus.done },
];

// ──────────────────────────────────────────────
// 업무일지 (state.worklogs) — 김도현 기준
// ──────────────────────────────────────────────
const WORKLOGS: { date: string; tag: string; body: string }[] = [
  { date: '2026-06-17', tag: '개발', body: '결제 모듈 v2.3 QA 진행, 결제 실패 케이스 3건 발견 및 리포트. DEV-138 리팩터링 50% 완료.' },
  { date: '2026-06-16', tag: '개발', body: '알림 센터 실시간 동기화 설계 문서 작성. 박지훈님과 API 스펙 리뷰 진행.' },
];

// ──────────────────────────────────────────────
// 근태 (renderVals att 배열) — 김도현 기준. 한글 status → enum
// ──────────────────────────────────────────────
const ATT_STATUS_MAP: Record<string, AttendanceStatus> = {
  정상: AttendanceStatus.normal,
  지각: AttendanceStatus.late,
  근무중: AttendanceStatus.working,
  예정: AttendanceStatus.scheduled,
};

const ATTENDANCE: { date: string; in: string | null; out: string | null; status: string }[] = [
  { date: '2026-06-15', in: '09:02', out: '18:10', status: '정상' },
  { date: '2026-06-16', in: '08:58', out: '18:30', status: '정상' },
  { date: '2026-06-17', in: '09:15', out: '18:05', status: '지각' },
  { date: '2026-06-18', in: null,    out: null,    status: '예정' },
  { date: '2026-06-19', in: null,    out: null,    status: '예정' },
];

// ──────────────────────────────────────────────
// 공지 (renderVals notices 배열) — 경영지원(admin) 작성
// ──────────────────────────────────────────────
const NOTICES: { title: string; team: string; pinned: boolean; body: string }[] = [
  { title: '[필독] 6월 정기 점검 일정 안내 (6/22 02:00~04:00)', team: '경영', pinned: true,  body: '6월 정기 서버 점검이 6/22 02:00~04:00 진행됩니다. 해당 시간 서비스가 일시 중단됩니다.' },
  { title: '하계 휴가 신청 오픈 (~6/30)',                       team: '경영', pinned: true,  body: '하계 휴가 신청이 오픈되었습니다. 근태 메뉴에서 ~6/30까지 신청해주세요.' },
  { title: '신규 입사자 환영 — 마케팅팀 한지원님',              team: '경영', pinned: false, body: '마케팅팀에 한지원님이 새로 합류하셨습니다. 따뜻한 환영 부탁드립니다.' },
];

/** "HH:MM" + 날짜(YYYY-MM-DD) → Date(로컬). 값이 없으면 null. */
function atTime(date: string, hhmm: string | null): Date | null {
  if (!hhmm) return null;
  return new Date(`${date}T${hhmm}:00`);
}

async function main(): Promise<void> {
  console.log('🌱  Seeding ONE 워크스페이스 demo data…');

  const passwordHash = await argon2.hash(DEMO_PASSWORD);

  // 1) Users
  const userIdByEmail = new Map<string, string>();
  for (const u of USERS) {
    const user = await prisma.user.upsert({
      where: { email: u.email },
      update: {
        name: u.name,
        initial: u.initial,
        color: u.color,
        team: u.team,
        title: u.title,
        role: u.role,
      },
      create: {
        email: u.email,
        passwordHash,
        name: u.name,
        initial: u.initial,
        color: u.color,
        team: u.team,
        title: u.title,
        role: u.role,
      },
    });
    userIdByEmail.set(u.email, user.id);
  }
  console.log(`  • users: ${userIdByEmail.size}`);

  const userIdByName = (name: string): string => {
    const email = NAME_TO_EMAIL[name];
    const id = email ? userIdByEmail.get(email) : undefined;
    if (!id) throw new Error(`Unknown seed user name: ${name}`);
    return id;
  };

  // 2) Channels + permissions + members
  const channelIdByKey = new Map<string, string>();
  for (const c of CHANNELS) {
    const channel = await prisma.channel.upsert({
      where: { key: c.key },
      update: { name: c.name, initial: c.initial, color: c.color },
      create: {
        key: c.key,
        name: c.name,
        kind: ChannelKind.channel,
        initial: c.initial,
        color: c.color,
        isReadonlyDefault: c.key === 'notice',
      },
    });
    channelIdByKey.set(c.key, channel.id);

    // ChannelPermission (channel_id, role)
    const row = PERMS[c.key];
    if (row) {
      for (let i = 0; i < ROLE_ORDER.length; i++) {
        const role = ROLE_ORDER[i];
        await prisma.channelPermission.upsert({
          where: { channelId_role: { channelId: channel.id, role } },
          update: { canView: !!row.view[i], canSend: !!row.send[i] },
          create: {
            channelId: channel.id,
            role,
            canView: !!row.view[i],
            canSend: !!row.send[i],
          },
        });
      }
    }
  }
  console.log(`  • channels: ${channelIdByKey.size}`);

  // 모든 사용자를 모든 채널의 멤버로 등록(데모 단순화; 권한은 ChannelPermission 으로 강제)
  for (const [, channelId] of channelIdByKey) {
    for (const [, userId] of userIdByEmail) {
      await prisma.channelMember.upsert({
        where: { channelId_userId: { channelId, userId } },
        update: {},
        create: { channelId, userId },
      });
    }
  }

  // 3) DM 채널 (박지훈 ↔ 김도현)
  const dmChannel = await prisma.channel.upsert({
    where: { key: 'dm-dohyun-jihoon' },
    update: { name: '박지훈' },
    create: {
      key: 'dm-dohyun-jihoon',
      name: '박지훈',
      kind: ChannelKind.dm,
      initial: '박',
      color: '#2563EB',
    },
  });
  for (const name of ['김도현', '박지훈']) {
    await prisma.channelMember.upsert({
      where: { channelId_userId: { channelId: dmChannel.id, userId: userIdByName(name) } },
      update: {},
      create: { channelId: dmChannel.id, userId: userIdByName(name) },
    });
  }

  // 4) Messages — 채널별로 기존 메시지를 비우고 데모 메시지를 순서대로 재삽입(idempotent)
  for (const channelKey of new Set(MESSAGES.map((m) => m.channelKey))) {
    const channelId = channelIdByKey.get(channelKey);
    if (channelId) {
      await prisma.message.deleteMany({ where: { channelId } });
    }
  }
  await prisma.message.deleteMany({ where: { channelId: dmChannel.id } });

  for (const m of MESSAGES) {
    const channelId = channelIdByKey.get(m.channelKey);
    if (!channelId) continue;
    await prisma.message.create({
      data: {
        channelId,
        authorId: userIdByName(m.author),
        body: m.body,
      },
    });
  }
  for (const m of DM_MESSAGES) {
    await prisma.message.create({
      data: {
        channelId: dmChannel.id,
        authorId: userIdByName(m.author),
        body: m.body,
      },
    });
  }
  console.log(`  • messages: ${MESSAGES.length + DM_MESSAGES.length}`);

  // 5) Issues
  for (const it of ISSUES) {
    await prisma.issue.upsert({
      where: { key: it.key },
      update: {
        title: it.title,
        status: it.status,
        priority: PRIORITY_MAP[it.priority] ?? IssuePriority.mid,
        label: it.label,
        assigneeId: userIdByName(it.assignee),
      },
      create: {
        key: it.key,
        title: it.title,
        description: '관련 모듈의 동작을 점검하고 재현 경로를 정리합니다. 영향 범위와 회귀 테스트 항목을 함께 확인한 뒤 PR을 연결합니다.',
        status: it.status,
        priority: PRIORITY_MAP[it.priority] ?? IssuePriority.mid,
        label: it.label,
        assigneeId: userIdByName(it.assignee),
      },
    });
  }
  console.log(`  • issues: ${ISSUES.length}`);

  // 6) Issue comments (DEV-138 데모 댓글)
  const dev138 = await prisma.issue.findUnique({ where: { key: 'DEV-138' } });
  if (dev138) {
    await prisma.issueComment.deleteMany({ where: { issueId: dev138.id } });
    await prisma.issueComment.create({
      data: {
        issueId: dev138.id,
        authorId: userIdByName('박지훈'),
        body: '재현 경로 확인했습니다. 우선순위 높여서 오늘 처리하겠습니다.',
      },
    });
    await prisma.issueComment.create({
      data: {
        issueId: dev138.id,
        authorId: userIdByName('김도현'),
        body: '좋아요. 리뷰는 제가 바로 잡겠습니다.',
      },
    });
  }

  // 7) Worklogs (김도현)
  const dohyunId = userIdByName('김도현');
  for (const w of WORKLOGS) {
    const date = new Date(`${w.date}T00:00:00`);
    // (user_id, date) 유니크가 없으므로 동일 날짜 기존 일지 제거 후 삽입
    await prisma.worklog.deleteMany({ where: { userId: dohyunId, date } });
    await prisma.worklog.create({
      data: { userId: dohyunId, date, tag: w.tag, body: w.body },
    });
  }
  console.log(`  • worklogs: ${WORKLOGS.length}`);

  // 8) Attendance (김도현) — (user_id, date) 유니크 사용
  for (const a of ATTENDANCE) {
    const date = new Date(`${a.date}T00:00:00`);
    await prisma.attendance.upsert({
      where: { userId_date: { userId: dohyunId, date } },
      update: {
        checkInAt: atTime(a.date, a.in),
        checkOutAt: atTime(a.date, a.out),
        status: ATT_STATUS_MAP[a.status] ?? AttendanceStatus.scheduled,
      },
      create: {
        userId: dohyunId,
        date,
        checkInAt: atTime(a.date, a.in),
        checkOutAt: atTime(a.date, a.out),
        status: ATT_STATUS_MAP[a.status] ?? AttendanceStatus.scheduled,
      },
    });
  }
  console.log(`  • attendance: ${ATTENDANCE.length}`);

  // 9) Notices (경영지원/admin 작성)
  const adminId = userIdByName('경영지원');
  await prisma.notice.deleteMany({ where: { authorId: adminId } });
  for (const n of NOTICES) {
    await prisma.notice.create({
      data: {
        authorId: adminId,
        title: n.title,
        team: n.team,
        pinned: n.pinned,
        body: n.body,
      },
    });
  }
  console.log(`  • notices: ${NOTICES.length}`);

  console.log('✅  Seed complete.');
  console.log(`   데모 로그인: 모든 사용자 비밀번호 = "${DEMO_PASSWORD}"`);
}

main()
  .catch((e) => {
    console.error('❌  Seed failed:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
