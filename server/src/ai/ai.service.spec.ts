import { BadRequestException, NotFoundException, ServiceUnavailableException } from '@nestjs/common';
import { AiService } from './ai.service';
import { MAX_TRANSCRIPT_MESSAGES } from './transcript';
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
