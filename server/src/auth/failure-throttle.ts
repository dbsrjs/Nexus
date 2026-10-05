/**
 * 실패만 세는 시도 제한. 로그인 · 비밀번호 변경의 **현재 비밀번호 대조**에 쓴다.
 *
 * 성공한 시도는 세지 않는다 — 정상 사용자는 한도에 닿을 일이 없고, 계약 검증처럼
 * 같은 주소에서 로그인을 여러 번 하는 경로도 막히지 않는다. 성공하면 그 키의
 * 실패 기록을 지운다.
 *
 * **메모리에 둔다(Redis 를 들이지 않는다 — §3 판단 #8).** 서버가 재시작되면 기록이
 * 사라지는데, 그것은 공격자에게 몇 번을 더 주는 정도라 받아들인다. 인스턴스가
 * 둘이 되면 프레즌스와 함께 옮긴다(§5 빚).
 *
 * 키 수에 상한을 둔다 — 주소 · 이메일을 바꿔 가며 두드리면 Map 이 끝없이 자란다.
 */
export class FailureThrottle {
  private readonly entries = new Map<string, { count: number; resetAt: number }>();

  constructor(
    private readonly maxFailures: number,
    private readonly windowMs: number,
    private readonly maxKeys = 10_000,
    private readonly now: () => number = Date.now,
  ) {}

  /** 막혀 있으면 남은 초, 아니면 null. 판정만 하고 기록은 바꾸지 않는다. */
  blockedFor(key: string): number | null {
    const entry = this.entries.get(key);
    if (!entry) return null;
    const left = entry.resetAt - this.now();
    if (left <= 0) {
      this.entries.delete(key);
      return null;
    }
    return entry.count >= this.maxFailures ? Math.ceil(left / 1000) : null;
  }

  /** 실패 한 번. 창은 **첫 실패부터** 잰다 — 실패마다 늘리면 영영 안 풀릴 수 있다. */
  fail(key: string): void {
    const now = this.now();
    const entry = this.entries.get(key);
    if (entry && entry.resetAt > now) {
      entry.count += 1;
      return;
    }
    this.entries.delete(key);
    this.makeRoom(now);
    this.entries.set(key, { count: 1, resetAt: now + this.windowMs });
  }

  succeed(key: string): void {
    this.entries.delete(key);
  }

  /** 테스트와 상한 확인용. */
  get size(): number {
    return this.entries.size;
  }

  /**
   * 상한에 닿으면 만료된 것부터 치우고, 그래도 넘치면 **가장 오래된 키**를 버린다
   * (Map 은 넣은 순서를 지킨다). 버려진 키는 다시 처음부터 센다 — 메모리를 지키는
   * 쪽을 택한다.
   */
  private makeRoom(now: number): void {
    if (this.entries.size < this.maxKeys) return;
    for (const [key, entry] of this.entries) {
      if (entry.resetAt <= now) this.entries.delete(key);
    }
    while (this.entries.size >= this.maxKeys) {
      const oldest = this.entries.keys().next().value;
      if (oldest === undefined) break;
      this.entries.delete(oldest);
    }
  }
}
