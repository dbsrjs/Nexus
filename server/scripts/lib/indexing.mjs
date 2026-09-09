// 계약 검증 공용 — 인덱싱 워커가 조용해질 때까지 기다린다.
//
// **왜 필요한가**: 저장소를 붙이면(`POST /repos/connect`) 12단계의 인덱싱
// 워커가 깨어나 **백그라운드로** GitHub 을 부른다. 그 호출은 스크립트가 어디를
// 지나고 있든 상관없이 착지하므로, 가짜 GitHub 이 받은 요청 수를 스냅샷으로
// 비교하는 단언(「GitHub 을 부르지 않았다」 — 10-3b·11단계의 핵심 판단)을
// 간헐적으로 깨뜨린다.
//
// **실제로 CI 에서 깨졌다** (`check:browse` 의 `23 → 24`). 로컬에서는 워커가
// 연결 직후에 끝나 재현되지 않았지만, 느린 러너에서는 워커가 리스를 잡고
// 토큰을 복호화하는 사이에 스크립트가 앞질러 간다.
//
// **포트를 물려받는 것이 두 번째 경로다.** 가짜 GitHub 은 스크립트마다 4599 를
// 새로 잡는다. 앞 스크립트가 남긴 작업이 뒤 스크립트 실행 중에 깨어나면
// **뒤 스크립트의 가짜 서버**를 때린다. 그래서 연결한 스크립트가 끝나기 전에
// 조용해지는 것까지 이 함수의 몫이다.
import { api } from './api.mjs';

/** 250ms × 60 = 15초. 인덱싱은 가짜 GitHub 상대라 이보다 훨씬 빨리 끝난다. */
const TRIES = 60;
const INTERVAL_MS = 250;

/**
 * 저장소 하나의 인덱싱 작업이 끝날 때까지 기다린다.
 *
 * **연결에 성공한 직후에 부른다.** `connect` 응답이 돌아온 시점에는 작업이
 * 이미 큐에 있으므로(`queueIndex` 가 `await` 된다) 여기서 기다리면 워커가
 * 반드시 끝난 뒤에 진행한다.
 *
 * 끝났다는 것은 `done` 이든 `failed` 든 상관없다 — 이 함수가 확인하는 것은
 * 인덱싱의 성공이 아니라 **더 이상 GitHub 을 부르지 않는다**는 것뿐이다.
 * (검증용 가짜 GitHub 은 트리·blob 을 답하지 않으므로 대개 `failed` 로 끝난다.)
 *
 * 인덱싱이 꺼져 있거나 상태를 볼 수 없으면 기다릴 것이 없으므로 그냥 넘어간다.
 *
 * @returns 조용해진 것을 확인했으면 true, 시간 안에 못 봤으면 false
 */
export async function settleIndexing(token, spaceId, repoId) {
  for (let i = 0; i < TRIES; i++) {
    const res = await api('GET', `/spaces/${spaceId}/repos/${repoId}/index`, { token });
    // 200 이 아니면 인덱싱 상태를 볼 수 없다 — 기다릴 대상이 없다.
    if (res.status !== 200) return true;

    const state = res.json?.state;
    if (state !== 'queued' && state !== 'running') return true;

    await new Promise((resolve) => setTimeout(resolve, INTERVAL_MS));
  }
  return false;
}

/**
 * 스페이스에 붙은 **모든** 저장소의 인덱싱이 끝날 때까지 기다린다.
 *
 * 한 스크립트가 저장소를 여러 번 붙이면(`check:oauth` 는 넷이다) 연결마다
 * 재우는 대신 이것을 끝에서 한 번 부르면 된다 — **이 스크립트가 끝난 뒤에
 * 4599 를 물려받는 다음 스크립트로 워커 호출이 새 나가지 않게 하는 것**이
 * 목적이다.
 *
 * 목록을 못 받으면(권한 없음 · 스페이스 없음) 기다릴 것이 없으므로 넘어간다.
 */
export async function settleIndexingForSpace(token, spaceId) {
  const res = await api('GET', `/spaces/${spaceId}/repos`, { token });
  if (res.status !== 200 || !Array.isArray(res.json)) return true;

  let quiet = true;
  for (const repo of res.json) {
    if (!repo?.id) continue;
    if (!(await settleIndexing(token, spaceId, repo.id))) quiet = false;
  }
  return quiet;
}
