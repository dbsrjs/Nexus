import { classifyFailure } from './ai-runner.service';
import { LlmHttpError } from '../llm/llm.provider';

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
