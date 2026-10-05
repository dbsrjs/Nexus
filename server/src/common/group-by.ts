/**
 * 키마다 목록으로 묶는다. 리액션 · 멘션 · 첨부 요약이 메시지 id 로 묶는 같은 반복문을 각자
 * 들고 있었다. 들어온 순서를 지킨다 — 정렬은 조회의 `orderBy` 가 이미 정했다.
 */
export function groupBy<T, K, V = T>(
  items: Iterable<T>,
  keyOf: (item: T) => K,
  valueOf: (item: T) => V = (item) => item as unknown as V,
): Map<K, V[]> {
  const out = new Map<K, V[]>();
  for (const item of items) {
    const key = keyOf(item);
    const list = out.get(key);
    if (list) list.push(valueOf(item));
    else out.set(key, [valueOf(item)]);
  }
  return out;
}
