import { BadRequestException, NotFoundException, ServiceUnavailableException } from '@nestjs/common';
import { AiService } from './ai.service';
import { MAX_TRANSCRIPT_MESSAGES, buildTranscript } from './transcript';
import { promptHash } from './prompt-hash';
import { summarizePrompt } from './prompts/summarize';
import { FakeLlmProvider } from '../llm/fake-llm.provider';

function service(
  over: { prisma?: unknown; llm?: unknown; queue?: unknown; indexing?: unknown } = {},
) {
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
    (over.indexing ?? { search: jest.fn(), chunksByIds: jest.fn() }) as never,
  );
}

describe('AiService.ask — 요약 프리셋(13-1 에서 옮김)', () => {
  it('LLM 미설정이면 503 이다 — 서버는 떠 있고 AI 만 멈춘다', async () => {
    await expect(
      service({ llm: null }).ask('s-1', 'u-1', {
      preset: 'summary',
      context: { channelId: 'c-1', messageIds: ['m-1'] },
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
      service({ prisma }).ask('s-1', 'u-1', {
      preset: 'summary',
      context: { channelId: 'c-1', messageIds: ['m-1'] },
    }),
    ).rejects.toBeInstanceOf(NotFoundException);
  });

  it('상한을 넘으면 400 이다 — 조용히 자르지 않는다 (판단 #4)', async () => {
    const ids = Array.from({ length: MAX_TRANSCRIPT_MESSAGES + 1 }, (_, i) => `m-${i}`);
    await expect(
      service().ask('s-1', 'u-1', {
      preset: 'summary',
      context: { channelId: 'c-1', messageIds: ids },
    }),
    ).rejects.toBeInstanceOf(BadRequestException);
  });

  it('빈 선택은 400 이다', async () => {
    await expect(
      service().ask('s-1', 'u-1', {
      preset: 'summary',
      context: { channelId: 'c-1', messageIds: [] },
    }),
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
      service({ prisma }).ask('s-1', 'u-1', {
      preset: 'summary',
      context: { channelId: 'c-1', messageIds: ['m-1', 'm-2'] },
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

    await service({ prisma, queue }).ask('s-1', 'u-1', {
      preset: 'summary',
      context: { channelId: 'c-1', messageIds: ['m-1'] },
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
    // ★ 전환 모델이 쓴 답은 캐시로 쓰지 않는다(LLM 교체).
    expect(prisma.aiRun.findFirst).toHaveBeenCalledWith(
      expect.objectContaining({
        where: expect.objectContaining({ promptHash: expectedHash, fallback: false }),
      }),
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

    const result = await service({ prisma, queue }).ask('s-1', 'u-1', {
      preset: 'summary',
      context: { channelId: 'c-1', messageIds: ['m-1', 'm-1'] },
    });

    expect(result).toEqual({ runId: 'run-1', state: 'queued' });
  });

  it(
    '★ 캐시 조회는 spaceId 뿐 아니라 userId 도 본다 - 아니면 bob 이 alice 와 ' +
      '같은 구간을 요약할 때 alice 의 runId 를 받고 영구 404 가 난다(최종 리뷰 ①)',
    async () => {
      const prisma = {
        channel: { findFirst: jest.fn().mockResolvedValue({ id: 'c-1' }) },
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

      await service({ prisma, queue }).ask('s-1', 'bob', {
      preset: 'summary',
      context: { channelId: 'c-1', messageIds: ['m-1'] },
    });

      expect(prisma.aiRun.findFirst).toHaveBeenCalledWith(
        expect.objectContaining({
          where: expect.objectContaining({ spaceId: 's-1', userId: 'bob' }),
        }),
      );
    },
  );
});

const row = (id: string, body = '안녕') => ({
  id,
  body,
  deletedAt: null,
  createdAt: new Date('2026-01-01T00:00:00Z'),
  author: { name: '가영' },
  attachments: [],
});

const chunk = (id: string) => ({
  id,
  path: 'lib/a.dart',
  lang: 'dart',
  startLine: 1,
  endLine: 3,
  content: 'x',
  commitSha: 'sha',
  score: 0.5,
});

function prismaWith(messages: unknown[]) {
  return {
    channel: { findFirst: jest.fn().mockResolvedValue({ id: 'c-1' }) },
    message: { findMany: jest.fn().mockResolvedValue(messages) },
    aiRun: { findFirst: jest.fn().mockResolvedValue(null) },
    spaceMember: { findMany: jest.fn().mockResolvedValue([]) },
  };
}

describe('AiService.ask — 13-2', () => {
  it('★ 채널만 주면 최근 최상위 메시지 50개를 읽고 그 id 를 input 에 박는다', async () => {
    // desc 로 읽은 것을 뒤집어 시간순으로 둔다
    const prisma = prismaWith([row('m-2'), row('m-1')]);
    const queue = { enqueue: jest.fn().mockResolvedValue('run-1') };

    await service({ prisma, queue }).ask('s-1', 'u-1', {
      instruction: '뭐 정했어?',
      context: { channelId: 'c-1' },
    });

    expect(prisma.message.findMany).toHaveBeenCalledWith(
      expect.objectContaining({
        where: { spaceId: 's-1', channelId: 'c-1', parentId: null },
        orderBy: { createdAt: 'desc' },
        take: 50,
      }),
    );
    expect(queue.enqueue).toHaveBeenCalledWith(
      expect.objectContaining({
        kind: 'ask',
        input: { instruction: '뭐 정했어?', channelId: 'c-1', messageIds: ['m-1', 'm-2'] },
      }),
    );
  });

  it('빈 채널은 400 이다 — 빈 대화를 요약하게 하지 않는다', async () => {
    await expect(
      service({ prisma: prismaWith([]) }).ask('s-1', 'u-1', {
        preset: 'summary',
        context: { channelId: 'c-1' },
      }),
    ).rejects.toBeInstanceOf(BadRequestException);
  });

  it('저장소는 지시문으로 검색하고 고른 청크 id 를 input 에 박는다', async () => {
    const indexing = { search: jest.fn().mockResolvedValue({ chunks: [chunk('k-1'), chunk('k-2')] }) };
    const queue = { enqueue: jest.fn().mockResolvedValue('run-1') };

    await service({ prisma: prismaWith([]), queue, indexing }).ask('s-1', 'u-1', {
      instruction: '소켓 재연결은 어디서?',
      context: { repoId: 'r-1' },
    });

    expect(indexing.search).toHaveBeenCalledWith('s-1', 'r-1', '소켓 재연결은 어디서?', 8);
    expect(queue.enqueue).toHaveBeenCalledWith(
      expect.objectContaining({
        input: { instruction: '소켓 재연결은 어디서?', repoId: 'r-1', chunkIds: ['k-1', 'k-2'] },
      }),
    );
  });

  it('프리셋 + 저장소면 대화 원문으로 검색한다', async () => {
    const indexing = { search: jest.fn().mockResolvedValue({ chunks: [] }) };

    await service({ prisma: prismaWith([row('m-1', '로그인 버튼 버그')]), indexing }).ask(
      's-1',
      'u-1',
      { preset: 'issue', context: { channelId: 'c-1', repoId: 'r-1' } },
    );

    expect(indexing.search.mock.calls[0][2]).toContain('로그인 버튼 버그');
  });

  it('검색이 503 이면 그대로 올라간다 — 틀린 순위로 답하지 않는다', async () => {
    const indexing = {
      search: jest.fn().mockRejectedValue(new ServiceUnavailableException('모델')),
    };
    await expect(
      service({ prisma: prismaWith([]), indexing }).ask('s-1', 'u-1', {
        instruction: 'q',
        context: { repoId: 'r-1' },
      }),
    ).rejects.toBeInstanceOf(ServiceUnavailableException);
  });
});

describe('AiService.loadPrompt', () => {
  it('★ 고른 청크가 사라졌으면 던진다 — 인용이 빈 채로 답하지 않는다', async () => {
    const indexing = { chunksByIds: jest.fn().mockResolvedValue([chunk('k-1')]) };
    await expect(
      service({ prisma: prismaWith([]), indexing }).loadPrompt('s-1', {
        instruction: 'q',
        repoId: 'r-1',
        chunkIds: ['k-1', 'k-2'],
      }),
    ).rejects.toThrow(/다시 인덱싱/);
  });

  it('인용은 input 의 청크 순서다', async () => {
    const indexing = { chunksByIds: jest.fn().mockResolvedValue([chunk('k-1'), chunk('k-2')]) };
    const out = await service({ prisma: prismaWith([]), indexing }).loadPrompt('s-1', {
      instruction: 'q',
      repoId: 'r-1',
      chunkIds: ['k-1', 'k-2'],
    });
    expect(out.kind).toBe('ask');
    expect(out.citations.map((c) => c.n)).toEqual([1, 2]);
    expect(out.messages[1].content).toContain('[2] lib/a.dart:1-3');
  });

  it('13-1 에서 적재된 행(channelId · messageIds 뿐)은 요약으로 읽는다', async () => {
    const out = await service({ prisma: prismaWith([row('m-1')]) }).loadPrompt('s-1', {
      channelId: 'c-1',
      messageIds: ['m-1'],
    });
    expect(out.kind).toBe('summarize');
    expect(out.citations).toEqual([]);
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

describe('AiService.ask — 이어 묻기(13-3)', () => {
  const doneRoot = {
    id: 'root',
    userId: 'u-1',
    kind: 'ask',
    state: 'done',
    parentRunId: null,
    input: { instruction: '정리해 줘', channelId: 'c-1', messageIds: ['m-1'] },
    result: { markdown: '첫 답', citations: [] },
  };
  const message = {
    id: 'm-1',
    body: '배포는 금요일',
    deletedAt: null,
    createdAt: new Date('2026-01-01T00:00:00Z'),
    author: { name: '가영' },
    attachments: [],
  };

  function prismaWith(rows: Record<string, object>) {
    return {
      channel: { findFirst: jest.fn().mockResolvedValue({ id: 'c-1' }) },
      message: { findMany: jest.fn().mockResolvedValue([message]) },
      spaceMember: { findMany: jest.fn().mockResolvedValue([]) },
      aiRun: {
        findFirst: jest.fn(
          ({ where }: { where: { id?: string; userId?: string; promptHash?: string } }) => {
            if (where.promptHash) return Promise.resolve(null); // 캐시 조회
            const row = where.id ? (rows[where.id] as { userId: string } | undefined) : undefined;
            if (!row) return Promise.resolve(null);
            if (where.userId && row.userId !== where.userId) return Promise.resolve(null);
            return Promise.resolve(row);
          },
        ),
      },
    };
  }

  it('★ 부모를 달아 적재하고 input 에는 지시문과 부모만 둔다', async () => {
    const prisma = prismaWith({ root: doneRoot });
    const queue = { enqueue: jest.fn().mockResolvedValue('run-2') };

    await service({ prisma, queue }).ask('s-1', 'u-1', {
      instruction: '더 짧게',
      parentRunId: 'root',
    });

    expect(queue.enqueue).toHaveBeenCalledWith(
      expect.objectContaining({
        kind: 'ask',
        parentRunId: 'root',
        input: { instruction: '더 짧게', parentRunId: 'root' },
      }),
    );
  });

  it('★ 다른 사용자의 부모는 404 다', async () => {
    const prisma = prismaWith({ root: { ...doneRoot, userId: 'u-other' } });
    await expect(
      service({ prisma }).ask('s-1', 'u-1', { instruction: 'q', parentRunId: 'root' }),
    ).rejects.toBeInstanceOf(NotFoundException);
  });

  it('끝나지 않은 부모는 400 이다', async () => {
    const prisma = prismaWith({ root: { ...doneRoot, state: 'running' } });
    await expect(
      service({ prisma }).ask('s-1', 'u-1', { instruction: 'q', parentRunId: 'root' }),
    ).rejects.toBeInstanceOf(BadRequestException);
  });

  it('★ 이슈 초안에는 이어 묻지 않는다 - 400', async () => {
    const prisma = prismaWith({
      root: {
        ...doneRoot,
        kind: 'draft_issue',
        input: { preset: 'issue', channelId: 'c-1', messageIds: ['m-1'] },
      },
    });
    await expect(
      service({ prisma }).ask('s-1', 'u-1', { instruction: 'q', parentRunId: 'root' }),
    ).rejects.toBeInstanceOf(BadRequestException);
  });

  it('★ 사슬이 10 문답이면 400 이다 - 조용히 앞을 자르지 않는다', async () => {
    const rows: Record<string, object> = { r0: { ...doneRoot, id: 'r0' } };
    for (let i = 1; i < 10; i++) {
      rows[`r${i}`] = {
        ...doneRoot,
        id: `r${i}`,
        parentRunId: `r${i - 1}`,
        input: { instruction: `q${i}`, parentRunId: `r${i - 1}` },
        result: { markdown: `a${i}`, citations: [] },
      };
    }
    await expect(
      service({ prisma: prismaWith(rows) }).ask('s-1', 'u-1', {
        instruction: 'q',
        parentRunId: 'r9',
      }),
    ).rejects.toBeInstanceOf(BadRequestException);
  });

  it('워커가 같은 프롬프트를 다시 만든다 - 앞 답이 assistant 로 들어간다', async () => {
    const prisma = prismaWith({ root: doneRoot });
    const prepared = await service({ prisma }).loadPrompt('s-1', {
      instruction: '더 짧게',
      parentRunId: 'root',
    });
    expect(prepared.kind).toBe('ask');
    expect(prepared.messages.map((m) => m.role)).toEqual(['system', 'user', 'assistant', 'user']);
    expect(prepared.messages[2].content).toBe('첫 답');
    expect(prepared.messages[3].content).toBe('더 짧게');
  });
});
