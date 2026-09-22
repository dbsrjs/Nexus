import { AiWorker } from './ai.worker';

describe('AiWorker', () => {
  it(
    '★ 비우는 중에 온 깨우기를 잃지 않는다 - 「비었다」를 본 직후 적재된 것이 ' +
      '30초 크론까지 밀리던 경쟁 조건',
    async () => {
      const job = { id: 'run-2' };
      let worker!: AiWorker;
      let pending: object | null = null;
      const lease = jest.fn().mockImplementation(async () => {
        // 첫 lease 가 「비었다」를 확인하는 순간 다른 요청이 적재하고 깨운다.
        if (lease.mock.calls.length === 1) {
          pending = job;
          worker.kick();
          return null;
        }
        const next = pending;
        pending = null;
        return next;
      });
      const runOne = jest.fn().mockResolvedValue(undefined);
      worker = new AiWorker({ lease } as never, { runOne } as never);

      await worker.tick();
      // kick() 이 띄운 drain 이 있으면 끝날 때까지 기다린다.
      await new Promise((r) => setImmediate(r));

      expect(runOne).toHaveBeenCalledWith(job);
    },
  );
});
