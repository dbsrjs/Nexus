import { AiRunKind } from '@prisma/client';
import { AiRunnerService, classifyFailure, resultOf } from './ai-runner.service';
import { LlmHttpError, LlmProvider } from '../llm/llm.provider';
import { LeasedRun } from './ai-queue.service';

describe('classifyFailure', () => {
  it('네트워크 실패는 시도로 세지 않는다 — 오프라인은 오류가 아니다', () => {
    expect(classifyFailure(new TypeError('fetch failed'))).toEqual({
      countsAsAttempt: false,
    });
  });

  it('429 는 시도로 세지 않고 Retry-After 를 그대로 쓴다', () => {
    expect(classifyFailure(new LlmHttpError('x', 429, 12))).toEqual({
      countsAsAttempt: false,
      retryAfterSec: 12,
    });
  });

  it('★ retryAfterSec 이 0 이어도 살아남는다 - 0 을 거짓으로 보면 기본값으로 새어 나간다', () => {
    expect(classifyFailure(new LlmHttpError('x', 429, 0))).toEqual({
      countsAsAttempt: false,
      retryAfterSec: 0,
    });
  });

  it('5xx 는 시도로 센다', () => {
    expect(classifyFailure(new LlmHttpError('x', 503))).toEqual({
      countsAsAttempt: true,
    });
  });

  it('★ 4xx 는 fatal 이다 - 다시 걸어도 같은 프롬프트에 같은 거절이 온다', () => {
    expect(classifyFailure(new LlmHttpError('x', 400))).toEqual({
      countsAsAttempt: true,
      fatal: true,
    });
  });

  it('401 도 fatal 이다 — 키가 틀린 것을 세 번 확인할 이유가 없다', () => {
    expect(classifyFailure(new LlmHttpError('x', 401))).toEqual({
      countsAsAttempt: true,
      fatal: true,
    });
  });

  it('그 밖의 오류는 fatal 이다 — 코드 문제라 재시도로 낫지 않는다', () => {
    expect(classifyFailure(new Error('프롬프트 조립 실패'))).toEqual({
      countsAsAttempt: true,
      fatal: true,
    });
  });
});

/** `AiRunnerService` 를 최소 의존성으로 세운다. */
function service(llm: LlmProvider) {
  const queue = { succeed: jest.fn(), fail: jest.fn() };
  const ai = {
    loadPrompt: jest.fn().mockResolvedValue({
      kind: AiRunKind.summarize,
      messages: [],
      json: false,
      citations: [],
    }),
    getRunState: jest.fn().mockResolvedValue('failed'),
  };
  const realtime = { toUser: jest.fn() };
  const runner = new AiRunnerService(
    llm,
    queue as never,
    ai as never,
    realtime as never,
  );
  return { runner, queue, ai, realtime };
}

function leasedRun(): LeasedRun {
  return {
    id: 'run-1',
    spaceId: 's-1',
    userId: 'u-1',
    kind: AiRunKind.summarize,
    input: { channelId: 'c-1', messageIds: ['m-1'] },
    attempts: 0,
  };
}

describe('resultOf', () => {
  const cites = [{ n: 1, path: 'a.ts', startLine: 1, endLine: 2, commitSha: 'x' }];

  it('요약 · 자유 질문은 마크다운과 인용이다', () => {
    expect(resultOf(AiRunKind.ask, '답', cites)).toEqual({ markdown: '답', citations: cites });
    expect(resultOf(AiRunKind.summarize, '요약', [])).toEqual({ markdown: '요약', citations: [] });
  });

  it('이슈 초안은 제목 · 본문 · 인용이다', () => {
    expect(
      resultOf(AiRunKind.draft_issue, '{"title":"t","description":"d"}', []),
    ).toEqual({ title: 't', description: 'd', citations: [] });
  });

  it('★ 이슈 초안이 JSON 이 아니면 던진다 — 러너가 fatal 로 친다', () => {
    expect(() => resultOf(AiRunKind.draft_issue, '제목: 버튼', [])).toThrow();
    expect(classifyFailure(new Error('x'))).toEqual({ countsAsAttempt: true, fatal: true });
  });
});

describe('AiRunnerService.runOne', () => {
  it('이슈 초안이면 json 옵션을 넘긴다 — 어댑터가 구조화 출력으로 번역한다', async () => {
    const complete = jest.fn().mockResolvedValue({
      text: '{"title":"t","description":"d"}',
      promptTokens: 1,
      completionTokens: 1,
      model: 'm',
    });
    const llm: LlmProvider = { modelId: 'fake:fake', maxTokens: 2048, complete };
    const { runner, ai, queue } = service(llm);
    ai.loadPrompt.mockResolvedValue({
      kind: AiRunKind.draft_issue,
      messages: [],
      json: true,
      citations: [],
    });

    await runner.runOne(leasedRun());

    expect(complete).toHaveBeenCalledWith([], expect.objectContaining({ json: true }));
    expect(queue.succeed).toHaveBeenCalledWith(
      'run-1',
      { title: 't', description: 'd', citations: [] },
      expect.anything(),
    );
  });

  it(
    '★ LLM_MAX_TOKENS 설정값이 complete() 에 그대로 넘어간다 - 러너의 ' +
      '하드코딩 상수를 쓰지 않는다(최종 리뷰 ②)',
    async () => {
      const complete = jest.fn().mockResolvedValue({
        text: '요약',
        promptTokens: 1,
        completionTokens: 1,
        model: 'm',
      });
      const llm: LlmProvider = { modelId: 'fake:fake', maxTokens: 2048, complete };
      const { runner } = service(llm);

      await runner.runOne(leasedRun());

      expect(complete).toHaveBeenCalledWith(
        [],
        expect.objectContaining({ maxTokens: 2048 }),
      );
    },
  );

  it(
    '★ 출력 한도에서 잘린 답은 성공으로 굳지 않는다 - fatal 실패라 잘린 답이 ' +
      '캐시에 박혀 같은 질문마다 되풀이되지 않는다',
    async () => {
      const complete = jest.fn().mockResolvedValue({
        text: '원인은 두 가지입니다. 첫째',
        promptTokens: 1,
        completionTokens: 8000,
        model: 'm',
        truncated: true,
      });
      const llm: LlmProvider = { modelId: 'fake:fake', maxTokens: 8192, complete };
      const { runner, queue } = service(llm);

      await runner.runOne(leasedRun());

      expect(queue.succeed).not.toHaveBeenCalled();
      expect(queue.fail).toHaveBeenCalledWith(
        'run-1',
        expect.stringContaining('LLM_MAX_TOKENS'),
        { countsAsAttempt: true, fatal: true },
      );
    },
  );

  it(
    '★ 빈 응답은 성공으로 굳지 않는다 - fatal 실패라 같은 프롬프트가 다시 ' +
      '와도 캐시에 빈 결과가 박히지 않는다(최종 리뷰 ③)',
    async () => {
      const complete = jest.fn().mockResolvedValue({
        text: '   ',
        promptTokens: 1,
        completionTokens: 0,
        model: 'm',
      });
      const llm: LlmProvider = { modelId: 'fake:fake', maxTokens: 1024, complete };
      const { runner, queue } = service(llm);

      await runner.runOne(leasedRun());

      expect(queue.succeed).not.toHaveBeenCalled();
      expect(queue.fail).toHaveBeenCalledWith(
        'run-1',
        expect.any(String),
        expect.objectContaining({ fatal: true }),
      );
    },
  );
});
