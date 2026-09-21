import { BadRequestException, NotFoundException, ServiceUnavailableException } from '@nestjs/common';
import { AiService } from './ai.service';
import { MAX_TRANSCRIPT_MESSAGES, buildTranscript } from './transcript';
import { promptHash } from './prompt-hash';
import { summarizePrompt } from './prompts/summarize';
import { FakeLlmProvider } from '../llm/fake-llm.provider';

function service(over: { prisma?: unknown; llm?: unknown; queue?: unknown } = {}) {
  const prisma = over.prisma ?? {
    channel: { findFirst: jest.fn().mockResolvedValue({ id: 'c-1' }) },
    message: { findMany: jest.fn().mockResolvedValue([]) },
    aiRun: { findFirst: jest.fn().mockResolvedValue(null) },
  };
  const queue = over.queue ?? { enqueue: jest.fn().mockResolvedValue('run-1') };
  return new AiService(
    prisma as never,
    over.llm === undefined ? new FakeLlmProvider() : (over.llm as never),
    queue as never,
  );
}

describe('AiService.summarize', () => {
  it('LLM 미설정이면 503 이다 — 서버는 떠 있고 AI 만 멈춘다', async () => {
    await expect(
      service({ llm: null }).summarize('s-1', 'u-1', {
        channelId: 'c-1',
        messageIds: ['m-1'],
      }),
    ).rejects.toBeInstanceOf(ServiceUnavailableException);
  });

  it('★ 볼 수 없는 채널이면 403 이 아니라 404 다', async () => {
    const prisma = {
      channel: { findFirst: jest.fn().mockResolvedValue(null) },
      message: { findMany: jest.fn() },
      aiRun: { findFirst: jest.fn() },
    };
    await expect(
      service({ prisma }).summarize('s-1', 'u-1', {
        channelId: 'c-1',
        messageIds: ['m-1'],
      }),
    ).rejects.toBeInstanceOf(NotFoundException);
  });

  it('상한을 넘으면 400 이다 — 조용히 자르지 않는다 (판단 #4)', async () => {
    const ids = Array.from({ length: MAX_TRANSCRIPT_MESSAGES + 1 }, (_, i) => `m-${i}`);
    await expect(
      service().summarize('s-1', 'u-1', { channelId: 'c-1', messageIds: ids }),
    ).rejects.toBeInstanceOf(BadRequestException);
  });

  it('빈 선택은 400 이다', async () => {
    await expect(
      service().summarize('s-1', 'u-1', { channelId: 'c-1', messageIds: [] }),
    ).rejects.toBeInstanceOf(BadRequestException);
  });

  it('★ 요청한 메시지 일부가 안 보이면 404 다 - 일부만 요약하지 않는다', async () => {
    const prisma = {
      channel: { findFirst: jest.fn().mockResolvedValue({ id: 'c-1' }) },
      // 둘을 요청했는데 하나만 돌아왔다
      message: {
        findMany: jest.fn().mockResolvedValue([
          {
            id: 'm-1',
            body: 'a',
            deletedAt: null,
            createdAt: new Date(),
            author: { name: '가영' },
            attachments: [],
          },
        ]),
      },
      aiRun: { findFirst: jest.fn() },
    };
    await expect(
      service({ prisma }).summarize('s-1', 'u-1', {
        channelId: 'c-1',
        messageIds: ['m-1', 'm-2'],
      }),
    ).rejects.toBeInstanceOf(NotFoundException);
  });

  it('★ 스페이스 밖 사용자의 멘션은 이름이 새지 않는다', async () => {
    const outsiderId = 'outsider-1';
    const createdAt = new Date('2026-01-01T00:00:00Z');
    const prisma = {
      channel: { findFirst: jest.fn().mockResolvedValue({ id: 'c-1' }) },
      message: {
        findMany: jest.fn().mockResolvedValue([
          {
            id: 'm-1',
            body: `<@${outsiderId}> 안녕`,
            deletedAt: null,
            createdAt,
            author: { name: '가영' },
            attachments: [],
          },
        ]),
      },
      aiRun: { findFirst: jest.fn().mockResolvedValue(null) },
      // 버그가 있다면 이 전역 조회가 스페이스 밖 사용자의 이름을 돌려준다 —
      // 실제로는 호출되지 않아야 한다.
      user: {
        findMany: jest.fn().mockResolvedValue([{ id: outsiderId, name: '유출된이름' }]),
      },
      // 올바른 경로 — 스페이스 멤버가 아니므로 빈 배열을 돌려준다.
      spaceMember: { findMany: jest.fn().mockResolvedValue([]) },
    };
    const queue = { enqueue: jest.fn().mockResolvedValue('run-1') };

    await service({ prisma, queue }).summarize('s-1', 'u-1', {
      channelId: 'c-1',
      messageIds: ['m-1'],
    });

    // 스페이스 밖이라 이름을 못 찾으므로 "(알 수 없음)" 으로 남아야 한다.
    const expectedTranscript = buildTranscript(
      [
        {
          body: `<@${outsiderId}> 안녕`,
          deletedAt: null,
          createdAt,
          authorName: '가영',
          attachmentNames: [],
        },
      ],
      new Map(),
    );
    const expectedHash = promptHash(
      'summarize',
      new FakeLlmProvider().modelId,
      summarizePrompt(expectedTranscript),
    );

    expect(queue.enqueue).toHaveBeenCalledWith(
      expect.objectContaining({ promptHash: expectedHash }),
    );
    expect(prisma.user.findMany).not.toHaveBeenCalled();
    expect(prisma.spaceMember.findMany).toHaveBeenCalledWith(
      expect.objectContaining({
        where: expect.objectContaining({
          spaceId: 's-1',
          userId: { in: [outsiderId] },
        }),
      }),
    );
  });

  it('중복된 messageIds 는 누락으로 오판하지 않는다', async () => {
    const prisma = {
      channel: { findFirst: jest.fn().mockResolvedValue({ id: 'c-1' }) },
      // 중복 id 를 보냈지만 SQL IN 은 중복을 접으므로 행은 하나만 돌아온다.
      message: {
        findMany: jest.fn().mockResolvedValue([
          {
            id: 'm-1',
            body: '안녕',
            deletedAt: null,
            createdAt: new Date(),
            author: { name: '가영' },
            attachments: [],
          },
        ]),
      },
      aiRun: { findFirst: jest.fn().mockResolvedValue(null) },
      spaceMember: { findMany: jest.fn().mockResolvedValue([]) },
    };
    const queue = { enqueue: jest.fn().mockResolvedValue('run-1') };

    const result = await service({ prisma, queue }).summarize('s-1', 'u-1', {
      channelId: 'c-1',
      messageIds: ['m-1', 'm-1'],
    });

    expect(result).toEqual({ runId: 'run-1', state: 'queued' });
  });
});

describe('AiService.getRun', () => {
  it('남의 실행은 404 다', async () => {
    const prisma = {
      channel: { findFirst: jest.fn() },
      message: { findMany: jest.fn() },
      aiRun: { findFirst: jest.fn().mockResolvedValue(null) },
    };
    await expect(
      service({ prisma }).getRun('s-1', 'u-1', 'run-9'),
    ).rejects.toBeInstanceOf(NotFoundException);
  });
});
