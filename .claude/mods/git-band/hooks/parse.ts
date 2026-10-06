import type { CiSnapshot, GitSnapshot } from '../types'

// git status --porcelain=v2 --branch 를 파싱한다. 사람이 읽는 형식(git status)은
// 로케일 · 버전마다 문구가 바뀌어 기계용 v2 형식을 쓴다.
export function parseStatus(
  text: string,
): Omit<GitSnapshot, 'project' | 'operation' | 'lastCommit'> {
  let oid = ''
  let head = ''
  let upstream: string | null = null
  let ahead = 0
  let behind = 0
  let staged = 0
  let unstaged = 0
  let untracked = 0
  let conflicted = 0

  for (const line of text.split(/\r?\n/)) {
    if (line.startsWith('# branch.oid ')) oid = line.slice(13)
    else if (line.startsWith('# branch.head ')) head = line.slice(14)
    else if (line.startsWith('# branch.upstream ')) upstream = line.slice(18)
    else if (line.startsWith('# branch.ab ')) {
      const m = /\+(\d+) -(\d+)/.exec(line)
      if (m) {
        ahead = Number(m[1])
        behind = Number(m[2])
      }
    } else if (line.startsWith('1 ') || line.startsWith('2 ')) {
      // XY: X 는 인덱스(스테이징), Y 는 작업 트리. '.' 은 변경 없음.
      const xy = line.slice(2, 4)
      if (xy[0] !== '.') staged++
      if (xy[1] !== '.') unstaged++
    } else if (line.startsWith('u ')) conflicted++
    else if (line.startsWith('? ')) untracked++
  }

  const isDetached = head === '(detached)'
  return {
    oid,
    branch: isDetached ? oid.slice(0, 7) : head,
    isDetached,
    upstream,
    ahead,
    behind,
    staged,
    unstaged,
    untracked,
    conflicted,
  }
}

// gh run list --json 결과 중 첫 줄. 실패를 'unknown' 으로 접어 띠가 이유를 보이게 한다.
export function parseRuns(stdout: string): CiSnapshot {
  let runs: unknown
  try {
    runs = JSON.parse(stdout)
  } catch {
    return { kind: 'unknown', reason: 'gh 응답 해석 실패' }
  }
  if (!Array.isArray(runs) || runs.length === 0) return { kind: 'none' }
  const r = runs[0] as Record<string, unknown>
  return {
    kind: 'run',
    workflow: String(r.workflowName ?? ''),
    status: String(r.status ?? ''),
    conclusion: String(r.conclusion ?? ''),
    createdAt: String(r.createdAt ?? ''),
    headSha: String(r.headSha ?? ''),
  }
}

// 「3분 전」 같은 상대 시각. 모르는 값이면 빈 문자열(화면이 말하지 않는다).
export function ago(iso: string, nowMs: number): string {
  const t = Date.parse(iso)
  if (Number.isNaN(t)) return ''
  const s = Math.max(0, Math.round((nowMs - t) / 1000))
  if (s < 60) return '방금'
  if (s < 3600) return `${Math.floor(s / 60)}분 전`
  if (s < 86400) return `${Math.floor(s / 3600)}시간 전`
  return `${Math.floor(s / 86400)}일 전`
}

export function ciLabel(ci: CiSnapshot): { text: string; color: string } {
  if (ci.kind === 'unknown') return { text: `CI ? (${ci.reason})`, color: 'inactive' }
  if (ci.kind === 'none') return { text: 'CI 실행 없음', color: 'inactive' }
  if (ci.status !== 'completed') {
    return { text: ci.status === 'queued' ? 'CI ⏳ 대기' : 'CI ⟳ 실행 중', color: 'warning' }
  }
  switch (ci.conclusion) {
    case 'success':
      return { text: 'CI ✓ 통과', color: 'success' }
    case 'failure':
    case 'timed_out':
    case 'startup_failure':
      return { text: 'CI ✗ 실패', color: 'error' }
    case 'cancelled':
      return { text: 'CI ⊘ 취소', color: 'inactive' }
    case 'skipped':
      return { text: 'CI – 건너뜀', color: 'inactive' }
    default:
      return { text: `CI ${ci.conclusion}`, color: 'inactive' }
  }
}
