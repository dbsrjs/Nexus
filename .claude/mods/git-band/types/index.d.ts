// 띠가 그리는 git 상태. 저장소가 아니면 null.
export type GitSnapshot = {
  project: string
  oid: string
  branch: string
  isDetached: boolean
  upstream: string | null
  ahead: number
  behind: number
  staged: number
  unstaged: number
  untracked: number
  conflicted: number
  operation: string | null
  lastCommit: { hash: string; subject: string; age: string } | null
}

// gh 로 읽은 최신 워크플로 실행. gh 가 없거나 인증이 안 되면 kind 가 'unknown'.
export type CiSnapshot =
  | { kind: 'unknown'; reason: string }
  | { kind: 'none' }
  | {
      kind: 'run'
      workflow: string
      status: string
      conclusion: string
      createdAt: string
      headSha: string
    }

declare module 'claude-code' {
  interface PluginState {
    'git-band': { git: GitSnapshot | null; ci: CiSnapshot | null }
  }
}
