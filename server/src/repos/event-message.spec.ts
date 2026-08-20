import { RepoEventType } from '@prisma/client';
import { describeGithubEvent } from './event-message';

/**
 * 채널에 뜨는 한 줄. **커밋 목록을 다 펼치지 않는다** — 대화 안에 개발이
 * 흘러 들어오는 것이 목적이지, 대화를 개발 로그로 바꾸는 것이 아니다.
 */
describe('describeGithubEvent — push', () => {
  const push = {
    ref: 'refs/heads/main',
    pusher: { name: '윤건' },
    commits: [
      { message: '보드 폭 계산을 고친다\n\n본문은 버린다' },
      { message: '두 번째' },
      { message: '세 번째' },
    ],
  };

  it('브랜치 · 커밋 수 · 첫 커밋 제목을 한 줄로 만든다', () => {
    const result = describeGithubEvent('push', push);

    expect(result?.type).toBe(RepoEventType.push);
    expect(result?.body).toBe(
      '윤건 님이 main 에 커밋 3개를 올렸습니다 — 보드 폭 계산을 고친다',
    );
  });

  it('커밋 메시지의 본문은 버리고 제목 줄만 쓴다', () => {
    const result = describeGithubEvent('push', push);

    expect(result?.body).not.toContain('본문은 버린다');
  });

  it('커밋이 하나면 개수를 말하지 않는다', () => {
    const result = describeGithubEvent('push', {
      ...push,
      commits: [{ message: '한 건' }],
    });

    expect(result?.body).toBe('윤건 님이 main 에 커밋을 올렸습니다 — 한 건');
  });

  it('커밋이 없는 push(브랜치 삭제 등)는 만들지 않는다', () => {
    // 채널에 "커밋 0개" 가 뜨면 무슨 일인지 알 수 없다.
    expect(describeGithubEvent('push', { ...push, commits: [] })).toBeNull();
  });

  it('refs/heads/ 접두사를 벗긴다', () => {
    const result = describeGithubEvent('push', {
      ...push,
      ref: 'refs/heads/feat/repo-webhooks',
    });

    expect(result?.body).toContain('feat/repo-webhooks 에');
  });
});

describe('describeGithubEvent — pull_request', () => {
  const pr = {
    action: 'opened',
    number: 12,
    pull_request: { title: '스프린트 · 번다운', user: { login: 'dbsrjs' } },
  };

  it('열림을 알린다', () => {
    const result = describeGithubEvent('pull_request', pr);

    expect(result?.type).toBe(RepoEventType.pr);
    expect(result?.body).toBe(
      'dbsrjs 님이 PR #12 를 열었습니다 — 스프린트 · 번다운',
    );
  });

  it('머지는 닫힘과 다르게 말한다', () => {
    const result = describeGithubEvent('pull_request', {
      ...pr,
      action: 'closed',
      pull_request: { ...pr.pull_request, merged: true },
    });

    expect(result?.body).toContain('머지했습니다');
  });

  it('머지되지 않은 닫힘은 닫혔다고 말한다', () => {
    const result = describeGithubEvent('pull_request', {
      ...pr,
      action: 'closed',
      pull_request: { ...pr.pull_request, merged: false },
    });

    expect(result?.body).toContain('닫았습니다');
  });

  it('관심 없는 action 은 만들지 않는다', () => {
    // synchronize(커밋 추가)는 PR 하나당 수십 번 온다. 채널이 그것으로 덮인다.
    expect(
      describeGithubEvent('pull_request', { ...pr, action: 'synchronize' }),
    ).toBeNull();
  });
});

describe('describeGithubEvent — 그 밖', () => {
  it('이슈 열림을 알린다', () => {
    const result = describeGithubEvent('issues', {
      action: 'opened',
      issue: { number: 3, title: '보드가 잘린다', user: { login: 'dbsrjs' } },
    });

    expect(result?.type).toBe(RepoEventType.issue);
    expect(result?.body).toBe('dbsrjs 님이 이슈 #3 을 열었습니다 — 보드가 잘린다');
  });

  it('릴리스를 알린다', () => {
    const result = describeGithubEvent('release', {
      action: 'published',
      release: { tag_name: 'v1.2.0', name: '스프린트' },
    });

    expect(result?.type).toBe(RepoEventType.release);
    expect(result?.body).toContain('v1.2.0');
  });

  it('모르는 이벤트는 null 이다 — 200 으로 조용히 넘긴다', () => {
    expect(describeGithubEvent('star', { action: 'created' })).toBeNull();
    expect(describeGithubEvent('ping', { zen: '...' })).toBeNull();
  });

  it('모양이 깨진 payload 에 던지지 않는다', () => {
    // 남이 보내는 것이라 우리가 모양을 강제할 수 없다. 던지면 500 이 되고
    // GitHub 이 재시도해 저장소 설정 화면이 빨갛게 된다.
    expect(describeGithubEvent('push', {})).toBeNull();
    expect(describeGithubEvent('pull_request', {})).toBeNull();
    expect(describeGithubEvent('issues', { action: 'opened' })).toBeNull();
  });

  it('긴 제목은 잘라 준다', () => {
    const long = 'ㄱ'.repeat(300);
    const result = describeGithubEvent('issues', {
      action: 'opened',
      issue: { number: 1, title: long, user: { login: 'x' } },
    });

    expect(result!.body.length).toBeLessThan(200);
  });
});
