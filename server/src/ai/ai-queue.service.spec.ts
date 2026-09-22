import { shouldGiveUp, AI_MAX_ATTEMPTS, retryDelayMs } from './ai-queue.service';

describe('retryDelayMs', () => {
  it('★ 5xx 는 몇 초 뒤 다시 건다 - 사람이 패널 앞에서 기다린다', () => {
    expect(retryDelayMs(1, { countsAsAttempt: true })).toBe(5_000);
    expect(retryDelayMs(2, { countsAsAttempt: true })).toBe(10_000);
  });

  it('네트워크 실패는 1분 뒤다 — 오프라인에서 두드리지 않는다', () => {
    expect(retryDelayMs(0, { countsAsAttempt: false })).toBe(60_000);
  });

  it('★ Retry-After 가 있으면 그것을 쓴다 — 0 도 살아남는다', () => {
    expect(retryDelayMs(0, { countsAsAttempt: false, retryAfterSec: 7 })).toBe(7_000);
    expect(retryDelayMs(0, { countsAsAttempt: false, retryAfterSec: 0 })).toBe(0);
  });
});

describe('shouldGiveUp', () => {
  it('fatal 이면 시도 수와 무관하게 포기한다', () => {
    expect(shouldGiveUp(0, { countsAsAttempt: true, fatal: true })).toBe(true);
    expect(shouldGiveUp(0, { countsAsAttempt: false, fatal: true })).toBe(true);
  });

  it('★ 네트워크 실패는 시도로 세지 않아 영원히 포기하지 않는다', () => {
    expect(shouldGiveUp(99, { countsAsAttempt: false })).toBe(false);
  });

  it('시도로 세는 실패는 MAX_ATTEMPTS 에서 포기한다', () => {
    expect(shouldGiveUp(AI_MAX_ATTEMPTS, { countsAsAttempt: true })).toBe(true);
  });

  it('MAX_ATTEMPTS 직전에는 포기하지 않는다', () => {
    expect(shouldGiveUp(AI_MAX_ATTEMPTS - 1, { countsAsAttempt: true })).toBe(false);
  });

  it('MAX_ATTEMPTS 는 3 이다', () => {
    expect(AI_MAX_ATTEMPTS).toBe(3);
  });
});
