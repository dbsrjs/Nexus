/**
 * DB 큐를 비우는 루프 — AI 워커와 인덱싱 워커가 같이 쓴다.
 *
 * 둘이 같은 `running` · `wanted` 루프를 따로 들고 있었고, **깨우기를 잃는 버그를 두
 * 군데서 따로 고쳤다**(13-2, CLAUDE.md §2). 한 곳에 두어 다음 고침이 한 번이면 되게 했다.
 *
 * - 한 프로세스에서 한 번에 하나만 돈다. 겹치면 같은 작업을 두 번 잡는다.
 * - **도는 중에 온 `kick()` 을 버리지 않는다.** `step` 이 「비었다」를 본 직후 적재된
 *   작업의 깨우기가 `running` 에 막혀 버려지면 다음 크론(30초)까지 밀린다 — `wanted` 를
 *   세워 한 바퀴 더 돈다.
 * - 실패해도 서버는 떠 있어야 한다. 예외는 `onError` 로 넘기고 다음 깨우기를 기다린다.
 */
export class DrainLoop {
  private running = false;
  private wanted = false;

  /**
   * @param step 큐에서 하나를 꺼내 처리한다. **꺼낼 것이 없으면 false.**
   */
  constructor(
    private readonly step: () => Promise<boolean>,
    private readonly onError: (err: unknown) => void,
  ) {}

  /** 적재 직후 부른다. 기다리지 않는다 — 실패해도 크론이 받는다. */
  kick(): void {
    void this.drain();
  }

  /** 있는 만큼 비운다. 이미 도는 중이면 한 바퀴 더 돌라고만 남기고 돌아간다. */
  async drain(): Promise<void> {
    if (this.running) {
      this.wanted = true;
      return;
    }
    this.running = true;
    try {
      do {
        this.wanted = false;
        while (await this.step()) {
          // 꺼낼 것이 있는 동안 계속.
        }
      } while (this.wanted);
    } catch (err) {
      this.onError(err);
    } finally {
      this.running = false;
    }
  }
}
