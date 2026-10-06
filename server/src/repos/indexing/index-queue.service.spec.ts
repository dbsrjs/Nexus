import {
  MAX_ATTEMPTS,
  indexRetryDelayMs,
  shouldGiveUpIndexing,
} from './index-queue.service';

describe('indexRetryDelayMs', () => {
  it('★ Retry-After 0 은 곧바로 다시다 - 0 을 없음으로 읽으면 1분을 기다린다(§2 함정)', () => {
    expect(indexRetryDelayMs({ countsAsAttempt: false, retryAfterSec: 0 })).toBe(0);
  });

  it('Retry-After 가 있으면 그 초를 쓴다', () => {
    expect(indexRetryDelayMs({ countsAsAttempt: false, retryAfterSec: 7 })).toBe(7000);
  });

  it('없으면 1분 물러선다', () => {
    expect(indexRetryDelayMs({ countsAsAttempt: true })).toBe(60_000);
  });
});

describe('shouldGiveUpIndexing', () => {
  it('fatal 이면 첫 실패에 포기한다', () => {
    expect(shouldGiveUpIndexing(1, { countsAsAttempt: true, fatal: true })).toBe(true);
  });

  it(`시도로 세는 실패는 ${MAX_ATTEMPTS}번째에 포기한다`, () => {
    expect(shouldGiveUpIndexing(MAX_ATTEMPTS - 1, { countsAsAttempt: true })).toBe(false);
    expect(shouldGiveUpIndexing(MAX_ATTEMPTS, { countsAsAttempt: true })).toBe(true);
  });

  it('시도로 세지 않는 실패(429 · 네트워크)로는 포기하지 않는다', () => {
    expect(shouldGiveUpIndexing(MAX_ATTEMPTS + 5, { countsAsAttempt: false })).toBe(
      false,
    );
  });
});
