import { Repo, RepoProvider } from '@prisma/client';
import { WebhooksService } from './webhooks.service';

/**
 * 봇 계정 판정. 가입이 `.invalid` 를 막기 전에 사람이 봇 이메일로 먼저 가입했을 수
 * 있다 — 그 계정을 봇으로 쓰면 모든 스페이스의 GitHub 메시지 작성자가 그 사람이 된다.
 */
const push = {
  ref: 'refs/heads/feature',
  pusher: { name: 'dev' },
  commits: [{ message: '커밋 하나' }],
};

const repo = {
  id: 'repo-1',
  spaceId: 'space-1',
  provider: RepoProvider.github,
  linkedChannelId: 'channel-1',
  defaultBranch: 'main',
} as Repo;

function setup(existingBot: { id: string; passwordHash: string | null } | null) {
  const tx = {
    message: { create: jest.fn().mockResolvedValue({ id: 'm-1', channelId: 'channel-1' }) },
    repoEvent: { create: jest.fn().mockResolvedValue({ id: 'e-1' }) },
  };
  const prisma = {
    user: {
      findUnique: jest.fn().mockResolvedValue(existingBot),
      create: jest.fn().mockResolvedValue({ id: 'bot-new', passwordHash: 'bot:no-login' }),
    },
    message: { findUnique: jest.fn().mockResolvedValue({ id: 'm-1' }) },
    $transaction: jest.fn(async (fn: (t: typeof tx) => Promise<unknown>) => fn(tx)),
  };
  const realtime = { toChannel: jest.fn() };
  const service = new WebhooksService(
    prisma as never,
    realtime as never,
    { enqueue: jest.fn() } as never,
    { kick: jest.fn() } as never,
  );
  return { service, prisma, tx, realtime };
}

describe('WebhooksService — 봇 계정', () => {
  it('봇 행이 있으면 그 계정으로 채널에 게시한다', async () => {
    const { service, tx } = setup({ id: 'bot-1', passwordHash: 'bot:no-login' });
    const result = await service.handle(repo, 'push', null, push);

    expect(result.posted).toBe(true);
    expect(tx.message.create).toHaveBeenCalledWith(
      expect.objectContaining({ data: expect.objectContaining({ authorId: 'bot-1' }) }),
    );
  });

  it('봇 행이 없으면 만들어 쓴다', async () => {
    const { service, prisma, tx } = setup(null);
    await service.handle(repo, 'push', null, push);

    expect(prisma.user.create).toHaveBeenCalled();
    expect(tx.message.create).toHaveBeenCalledWith(
      expect.objectContaining({ data: expect.objectContaining({ authorId: 'bot-new' }) }),
    );
  });

  it('★ 봇 이메일을 사람이 차지하고 있으면 그 계정으로 게시하지 않는다 — 이벤트는 적재한다', async () => {
    const { service, tx, realtime } = setup({ id: 'human-1', passwordHash: '$argon2id$v=19$...' });
    const result = await service.handle(repo, 'push', null, push);

    expect(tx.message.create).not.toHaveBeenCalled();
    expect(realtime.toChannel).not.toHaveBeenCalled();
    // 웹훅은 여전히 성공이고 이벤트는 남는다 — GitHub 이 재시도하지 않게.
    expect(tx.repoEvent.create).toHaveBeenCalled();
    expect(result).toEqual({ stored: true, posted: false, duplicate: false });
  });
});
