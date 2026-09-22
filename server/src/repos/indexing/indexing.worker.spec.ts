import { IndexingWorker } from './indexing.worker';

describe('IndexingWorker', () => {
  it('★ 비우는 중에 온 깨우기를 잃지 않는다', async () => {
    const job = { repoId: 'r-2' };
    let pending: object | null = null;
    const lease = jest.fn().mockImplementation(async () => {
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
    const worker = new IndexingWorker({ lease } as never, { runOne } as never);

    await worker.tick();
    await new Promise((r) => setImmediate(r));

    expect(runOne).toHaveBeenCalledWith(job);
  });
});
