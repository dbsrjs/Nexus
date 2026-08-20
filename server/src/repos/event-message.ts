import { RepoEventType } from '@prisma/client';

/** 제목이 길면 자른다. 한 줄이라는 약속이 지켜져야 채널이 로그가 되지 않는다. */
const TITLE_LIMIT = 120;

export interface EventMessage {
  type: RepoEventType;
  body: string;
}

/**
 * GitHub 웹훅 payload 를 **채널에 뜰 한 줄**로 바꾼다.
 *
 * `null` 이면 "채널에 올리지 않는다"이다 — 모르는 이벤트, 관심 없는 action,
 * 모양이 깨진 payload 가 모두 여기로 온다.
 *
 * **던지지 않는다.** 남이 보내는 것이라 우리가 모양을 강제할 수 없고, 던지면
 * 500 이 되어 GitHub 이 재시도하고 저장소 설정 화면이 빨갛게 된다.
 */
export function describeGithubEvent(
  event: string,
  payload: unknown,
): EventMessage | null {
  const data = asRecord(payload);
  if (!data) return null;

  switch (event) {
    case 'push':
      return describePush(data);
    case 'pull_request':
      return describePullRequest(data);
    case 'issues':
      return describeIssue(data);
    case 'release':
      return describeRelease(data);
    default:
      return null;
  }
}

function describePush(data: Record<string, unknown>): EventMessage | null {
  const commits = Array.isArray(data.commits) ? data.commits : [];
  // 커밋 없는 push(브랜치 삭제 · 태그)는 채널에 "커밋 0개"가 되어 뜻이 없다.
  if (commits.length === 0) return null;

  const branch = String(data.ref ?? '').replace(/^refs\/heads\//, '');
  if (!branch) return null;

  const who = str(asRecord(data.pusher)?.name) ?? '누군가';
  const first = title(str(asRecord(commits[0])?.message) ?? '');

  const what =
    commits.length === 1 ? '커밋을' : `커밋 ${commits.length}개를`;

  return {
    type: RepoEventType.push,
    body: `${who} 님이 ${branch} 에 ${what} 올렸습니다 — ${first}`,
  };
}

function describePullRequest(
  data: Record<string, unknown>,
): EventMessage | null {
  const pr = asRecord(data.pull_request);
  const number = data.number;
  if (!pr || typeof number !== 'number') return null;

  const who = str(asRecord(pr.user)?.login) ?? '누군가';
  const subject = title(str(pr.title) ?? '');

  // synchronize(커밋 추가)는 PR 하나당 수십 번 온다 — 채널이 그것으로 덮인다.
  const verb = ((): string | null => {
    switch (data.action) {
      case 'opened':
      case 'reopened':
        return '열었습니다';
      case 'closed':
        return pr.merged === true ? '머지했습니다' : '닫았습니다';
      default:
        return null;
    }
  })();
  if (!verb) return null;

  return {
    type: RepoEventType.pr,
    body: `${who} 님이 PR #${number} 를 ${verb} — ${subject}`,
  };
}

function describeIssue(data: Record<string, unknown>): EventMessage | null {
  const issue = asRecord(data.issue);
  if (!issue || typeof issue.number !== 'number') return null;

  const verb = ((): string | null => {
    switch (data.action) {
      case 'opened':
      case 'reopened':
        return '열었습니다';
      case 'closed':
        return '닫았습니다';
      default:
        return null;
    }
  })();
  if (!verb) return null;

  const who = str(asRecord(issue.user)?.login) ?? '누군가';

  return {
    type: RepoEventType.issue,
    body: `${who} 님이 이슈 #${issue.number} 을 ${verb} — ${title(str(issue.title) ?? '')}`,
  };
}

function describeRelease(data: Record<string, unknown>): EventMessage | null {
  const release = asRecord(data.release);
  if (!release || data.action !== 'published') return null;

  const tag = str(release.tag_name);
  if (!tag) return null;

  const name = str(release.name);

  return {
    type: RepoEventType.release,
    body: name ? `${tag} 이 릴리스됐습니다 — ${title(name)}` : `${tag} 이 릴리스됐습니다`,
  };
}

/** 커밋 메시지의 **제목 줄만** 쓴다. 본문까지 넣으면 한 줄이 문단이 된다. */
function title(text: string): string {
  const head = text.split('\n')[0].trim();
  return head.length <= TITLE_LIMIT ? head : `${head.slice(0, TITLE_LIMIT)}…`;
}

function asRecord(value: unknown): Record<string, unknown> | null {
  return typeof value === 'object' && value !== null && !Array.isArray(value)
    ? (value as Record<string, unknown>)
    : null;
}

function str(value: unknown): string | null {
  return typeof value === 'string' && value.length > 0 ? value : null;
}
