/**
 * 검색을 막아야 하는지. 막을 이유(화면에 나가지 않는 서버 문구) 또는 `null`.
 *
 * **다른 모델로 만든 벡터를 새 모델의 질의로 찾으면 오류 없이 순위만
 * 틀린다.** 2026-09-17 에 인덱싱은 모델이 다르면 전체로 떨어지게 했지만
 * 검색은 기록을 보지 않아, 다음 인덱싱 전까지 그 구간이 남아 있었다
 * (CLAUDE.md §5 의 빚). 13-2 에서 AI 가 검색을 부르는 모양이 정해져 여기서
 * 거절로 확정한다 — 조용히 틀린 순위를 내놓는 것보다 못 한다고 말하는 쪽이
 * 낫다(판단 #4).
 *
 * 기록이 `null` 이면 한 번도 끝까지 인덱싱하지 않은 것이다. 전체 재인덱싱
 * 중에는 기록이 옛 모델로 남아 있어 두 번째 갈래가 막는다.
 */
export function searchBlocker(recorded: string | null, current: string): string | null {
  if (recorded === null) return '저장소가 아직 인덱싱되지 않았습니다.';
  if (recorded !== current) {
    return '임베딩 모델이 바뀌어 저장소를 다시 인덱싱해야 합니다.';
  }
  return null;
}

/**
 * 막힌 검색이 스스로 다시 인덱싱을 걸어야 하는지.
 *
 * **막힘을 사람이 풀어야만 풀리게 두지 않는다.** 기록이 없는 옛 인덱스
 * (2026-09-17 마이그레이션 전에 만든 것 — 기록을 NULL 로 두었다)와 모델이
 * 바뀐 인덱스는 push 가 와야 전체로 다시 돈다. push 가 없는 저장소는 그때까지
 * 검색 · AI 코드 질문이 503 에 묶인다 — 13-2 최종 검토에서 드러났다.
 *
 * 청크가 있어야 건다 — 한 번도 끝나지 않은(대개 실패한) 저장소를 검색마다
 * 두드리지 않는다. 이미 줄을 섰거나 도는 중이면 또 걸지 않는다 — 도는 작업의
 * 목표를 덮으면 끝난 뒤 한 번 더 돈다(`succeed()` 의 stale 판정).
 */
export function shouldHealIndex(jobState: string | null, chunkCount: number): boolean {
  if (jobState === 'queued' || jobState === 'running') return false;
  return chunkCount > 0;
}
