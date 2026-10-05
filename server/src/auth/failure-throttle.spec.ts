import { FailureThrottle } from './failure-throttle';

function clock(start = 1_000_000) {
  let t = start;
  return { now: () => t, advance: (ms: number) => (t += ms) };
}

describe('FailureThrottle', () => {
  it('한도 전까지는 막지 않고, 한도에 닿으면 남은 초를 준다', () => {
    const c = clock();
    const throttle = new FailureThrottle(3, 60_000, 100, c.now);

    throttle.fail('k');
    throttle.fail('k');
    expect(throttle.blockedFor('k')).toBeNull();

    throttle.fail('k');
    expect(throttle.blockedFor('k')).toBe(60);
  });

  it('★ 창은 첫 실패부터 잰다 — 창이 지나면 풀린다', () => {
    const c = clock();
    const throttle = new FailureThrottle(2, 60_000, 100, c.now);
    throttle.fail('k');
    c.advance(30_000);
    throttle.fail('k');
    expect(throttle.blockedFor('k')).toBe(30);

    c.advance(30_000);
    expect(throttle.blockedFor('k')).toBeNull();
    // 풀린 뒤의 실패는 새 창이다.
    throttle.fail('k');
    expect(throttle.blockedFor('k')).toBeNull();
  });

  it('성공하면 그 키의 실패 기록을 지운다', () => {
    const throttle = new FailureThrottle(2, 60_000);
    throttle.fail('k');
    throttle.succeed('k');
    throttle.fail('k');
    expect(throttle.blockedFor('k')).toBeNull();
  });

  it('키끼리 섞이지 않는다', () => {
    const throttle = new FailureThrottle(1, 60_000);
    throttle.fail('a');
    expect(throttle.blockedFor('a')).not.toBeNull();
    expect(throttle.blockedFor('b')).toBeNull();
  });

  it('★ 키 수가 상한을 넘지 않는다 — 주소를 바꿔 가며 두드려도 메모리가 자라지 않는다', () => {
    const c = clock();
    const throttle = new FailureThrottle(5, 60_000, 3, c.now);
    for (let i = 0; i < 50; i++) throttle.fail(`k${i}`);
    expect(throttle.size).toBeLessThanOrEqual(3);
    // 가장 최근 키는 남아 있다.
    throttle.fail('k49');
    expect(throttle.size).toBeLessThanOrEqual(3);
  });
});
