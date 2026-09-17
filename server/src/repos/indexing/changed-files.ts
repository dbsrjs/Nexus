import { GithubComparedFile } from '../../oauth/github-oauth.client';

/**
 * compare 를 부르기도 전에 전체로 떨어지는 이유. 없으면 `null` — 증분을 시도한다.
 *
 * **모델 비교가 `baseSha === headSha` 보다 먼저다.** 같은 커밋이라도 모델이
 * 바뀌었으면 할 일이 없는 게 아니라 전부 다시 해야 한다. 순서를 뒤집으면
 * 사람이 모델을 바꾼 뒤 같은 커밋으로 다시 태울 때 조용히 건너뛴다.
 *
 * **기록이 `null` 이어도 전체다.** 이 컬럼이 생기기 전에 만든 인덱스는 어떤
 * 모델로 만들었는지 모른다 — 모르면 섞였다고 본다(§3 판단 2 · 7).
 */
export function fullReindexBeforeCompare(input: {
  baseSha: string | null;
  indexedModel: string | null;
  currentModel: string;
}): 'first' | 'model-changed' | null {
  if (!input.baseSha) return 'first';
  if (input.indexedModel !== input.currentModel) return 'model-changed';
  return null;
}

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
