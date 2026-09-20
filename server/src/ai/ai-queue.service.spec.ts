import { shouldGiveUp, AI_MAX_ATTEMPTS } from './ai-queue.service';

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
