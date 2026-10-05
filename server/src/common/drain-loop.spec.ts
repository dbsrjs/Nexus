import { DrainLoop } from './drain-loop';

describe('DrainLoop', () => {
  it('꺼낼 것이 없을 때까지 비운다', async () => {
    const items = [1, 2, 3];
    const seen: number[] = [];
    const loop = new DrainLoop(async () => {
      const x = items.shift();
      if (x === undefined) return false;
      seen.push(x);
      return true;
    }, jest.fn());
    await loop.drain();
    expect(seen).toEqual([1, 2, 3]);
  });

  it('★ 「비었다」를 본 직후 온 깨우기를 잃지 않는다 — 한 바퀴 더 돈다', async () => {
    const items: number[] = [];
    const seen: number[] = [];
    let first = true;
    const loop: DrainLoop = new DrainLoop(async () => {
      const x = items.shift();
      if (x === undefined) {
        // 비었다고 답하기 직전에 새 작업이 들어오고 깨우기가 온다.
        if (first) {
          first = false;
          items.push(9);
          loop.kick();
        }
        return false;
      }
      seen.push(x);
      return true;
    }, jest.fn());
    await loop.drain();
    expect(seen).toEqual([9]);
  });

  it('실패하면 onError 로 넘기고, 다음 깨우기에 다시 돈다', async () => {
    const onError = jest.fn();
    let fail = true;
    let calls = 0;
    const loop = new DrainLoop(async () => {
      calls++;
      if (fail) {
        fail = false;
        throw new Error('boom');
      }
      return false;
    }, onError);
    await loop.drain();
    expect(onError).toHaveBeenCalledTimes(1);
    await loop.drain();
    expect(calls).toBe(2);
  });
});
