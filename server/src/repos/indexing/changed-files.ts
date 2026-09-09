import { GithubComparedFile } from '../../oauth/github-oauth.client';

export interface ReindexPlan {
  /** 받아서 다시 청킹할 경로. */
  reindex: string[];
  /** 청크만 지울 경로. */
  remove: string[];
}

/**
 * compare 응답 → 무엇을 다시 하나.
 *
 * **`reindex` 가 `remove` 를 이긴다.** 지웠다가 다시 만든 경로가 양쪽에 들어가면
 * 순서에 따라 방금 쌓은 청크를 지우게 된다 — 그러면 그 파일이 인덱스에서 조용히
 * 사라진다. 다시 인덱싱하는 경로는 어차피 `replaceFile()` 이 먼저 지운다.
 */
export function planFromCompare(files: GithubComparedFile[]): ReindexPlan {
  const reindex = new Set<string>();
  const remove = new Set<string>();

  for (const file of files) {
    if (file.status === 'removed') {
      remove.add(file.path);
      continue;
    }

    reindex.add(file.path);
    // 이름이 바뀌었으면 옛 경로의 청크가 남아 있다. **previousPath 가 없으면
    // 짐작하지 않는다** — 엉뚱한 경로를 지우는 것보다 남기는 편이 낫다.
    if (file.status === 'renamed' && file.previousPath) {
      remove.add(file.previousPath);
    }
  }

  for (const path of reindex) remove.delete(path);

  return { reindex: [...reindex], remove: [...remove] };
}
