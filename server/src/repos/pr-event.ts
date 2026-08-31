/**
 * PR 웹훅 payload 에서 번호만 꺼낸다.
 *
 * **GitHub 을 부르지 않는다** — 10-3b 가 커밋에서 세운 규칙과 같다. 저장소
 * 접근 권한이 나중에 사라져도 지난 기록으로 들어갈 수 있다.
 */
export function readPullNumber(payload: unknown): number | null {
  // `WebhooksService.handle()` 이 GitHub 원본을 `raw` 로 한 겹 감싸 저장한다
  // (`{ deliveryId, event, raw }`) — `readPushCommits` 와 같은 자리를 벗긴다.
  const data = asRecord(asRecord(payload)?.raw);
  if (!data) return null;

  if (typeof data.number === 'number') return data.number;

  const pr = data.pull_request;
  if (pr && typeof pr === 'object') {
    const inner = (pr as Record<string, unknown>).number;
    if (typeof inner === 'number') return inner;
  }
  return null;
}

function asRecord(value: unknown): Record<string, unknown> | null {
  return typeof value === 'object' && value !== null && !Array.isArray(value)
    ? (value as Record<string, unknown>)
    : null;
}
