/**
 * 스페이스 slug 에서 이슈 키 접두사를 만든다 (NEXUS-138 의 'NEXUS').
 *
 * slug 에서 뽑는 이유는 `UpdateSpaceDto` 에 slug 가 없어 **불변**이기 때문이다 —
 * 한 스페이스 안에서 접두사가 섞이지 않는다. 사람이 접두사를 고르는 UI 가
 * 필요해지면 `Space.issueKeyPrefix` 컬럼으로 승격한다.
 */
export function issueKeyPrefix(slug: string): string {
  const parts = slug
    .toUpperCase()
    .split(/[^A-Z0-9]+/)
    .filter(Boolean);

  // 첫 마디가 두 글자 이하면 무엇의 키인지 읽히지 않아 다음 마디를 잇는다.
  let prefix = '';
  for (const part of parts) {
    prefix += part;
    if (prefix.length >= 3) break;
  }

  return prefix.slice(0, 6) || 'ISSUE';
}

/** `NEXUS-12`. 연번은 Space.issueSeq 가 발급한다. */
export function formatIssueKey(slug: string, seq: number): string {
  return `${issueKeyPrefix(slug)}-${seq}`;
}
