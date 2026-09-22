import { AiRunKind } from '@prisma/client';
import { AiRunnerService, classifyFailure } from './ai-runner.service';
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
    loadPrompt: jest.fn().mockResolvedValue([]),
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

describe('AiRunnerService.runOne', () => {
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
});
