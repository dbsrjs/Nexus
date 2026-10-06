import { atom, read, update } from 'claude-code'
import type { EngineInterface, Register } from 'claude-code'

import type { CiSnapshot, GitSnapshot } from '../types'
import { ago, ciLabel, parseRuns, parseStatus } from './parse'

const git = atom({ plugin: 'git-band', key: 'git' } as const, null)
const ci = atom({ plugin: 'git-band', key: 'ci' } as const, null)

// git 은 싸서 자주, CI(gh → GitHub API)는 비싸서 드물게 본다.
// 실행 중인 CI 만은 결과가 곧 바뀌므로 git 주기에 맞춰 따라간다.
const TICK_MS = 15_000
const CI_EVERY_TICKS = 6

// 진행 중인 작업 표시. 파일 이름은 git 이 쓰는 그대로다.
const OPERATIONS: readonly [string, string][] = [
  ['rebase-merge', '리베이스 중'],
  ['rebase-apply', '리베이스 중'],
  ['MERGE_HEAD', '병합 중'],
  ['CHERRY_PICK_HEAD', '체리픽 중'],
  ['REVERT_HEAD', '되돌리기 중'],
  ['BISECT_LOG', 'bisect 중'],
]

// 모듈 변수는 리로드 때 초기화돼도 괜찮은 것만 둔다(겹침 방지 · 주기 계산).
// $ 를 받는 함수는 검증기가 따라갈 수 있게 최상위 함수 선언으로 둔다.
let busy = false
let tick = 0
let lastCiKey = ''

async function run($: EngineInterface, argv: string[], cwd?: string) {
  try {
    return await $.process.run(argv, { cwd, timeoutMs: 20_000 })
  } catch {
    // 명령이 없거나(ENOENT) 시간 초과 — 호출부가 「모름」으로 접는다.
    return null
  }
}

async function readGit($: EngineInterface): Promise<GitSnapshot | null> {
  const top = await run($, ['git', 'rev-parse', '--show-toplevel', '--absolute-git-dir'])
  if (!top || top.exitCode !== 0) return null
  const [root, gitDir] = top.stdout.trim().split(/\r?\n/)
  if (!root || !gitDir) return null

  const [status, log] = await Promise.all([
    run($, ['git', 'status', '--porcelain=v2', '--branch'], root),
    // 날짜는 %cr(로케일 영어) 대신 ISO 로 받아 한국어로 직접 쓴다.
    run($, ['git', 'log', '-1', '--format=%h%x1f%s%x1f%cI'], root),
  ])
  if (!status || status.exitCode !== 0) return null

  let operation: string | null = null
  for (const [file, label] of OPERATIONS) {
    try {
      await $.fs.stat(`${gitDir}/${file}`)
      operation = label
      break
    } catch {
      // 없으면 그 작업이 아니다.
    }
  }

  let lastCommit: GitSnapshot['lastCommit'] = null
  if (log && log.exitCode === 0 && log.stdout.trim()) {
    const [hash, subject, iso] = log.stdout.trim().split('\x1f')
    lastCommit = { hash: hash ?? '', subject: subject ?? '', age: iso ?? '' }
  }

  const name = root.replace(/[\\/]+$/, '').split(/[\\/]/).pop() ?? root
  return { project: name, operation, lastCommit, ...parseStatus(status.stdout) }
}

async function readCi($: EngineInterface, snap: GitSnapshot): Promise<CiSnapshot> {
  if (snap.isDetached) return { kind: 'unknown', reason: '분리된 HEAD' }
  const r = await run($, [
    'gh', 'run', 'list',
    '--branch', snap.branch,
    '--limit', '1',
    '--json', 'status,conclusion,workflowName,createdAt,headSha',
  ])
  if (!r) return { kind: 'unknown', reason: 'gh 없음' }
  if (r.exitCode !== 0) {
    const msg = r.stderr.toLowerCase()
    if (msg.includes('auth') || msg.includes('login')) return { kind: 'unknown', reason: 'gh 로그인 필요' }
    if (msg.includes('could not resolve') || msg.includes('no git remote')) return { kind: 'unknown', reason: 'GitHub 원격 없음' }
    return { kind: 'unknown', reason: 'gh 실패' }
  }
  return parseRuns(r.stdout)
}

async function refresh($: EngineInterface, forceCi: boolean) {
  if (busy) return
  busy = true
  try {
    const snap = await readGit($)
    await update($, git, () => snap)
    if (!snap) return

    const prev = await read($, ci)
    const ciKey = `${snap.project}|${snap.branch}|${snap.oid}`
    const isRunning = prev?.kind === 'run' && prev.status !== 'completed'
    // 브랜치나 HEAD 가 바뀌면(커밋 · 체크아웃 · push 후) 곧바로 다시 본다.
    if (forceCi || isRunning || ciKey !== lastCiKey || tick % CI_EVERY_TICKS === 0) {
      lastCiKey = ciKey
      const next = await readCi($, snap)
      await update($, ci, () => next)
    }
  } finally {
    busy = false
  }
}

export const register: Register = on => {
  on('session.start', async ($, e, next) => {
    const r = await next(e)
    void refresh($, true)
    $.clock.every(TICK_MS, () => {
      tick++
      void refresh($, false)
    })
    await $.command.register({
      name: 'git-band',
      description: 'git 상태 띠를 지금 새로 고친다(CI 포함)',
    })
    return r
  })

  on('command.run', { command: 'git-band' }, async $ => {
    await refresh($, true)
    return { text: 'git 상태를 새로 고쳤습니다.' }
  })

  // 턴이 끝나면 Claude 가 커밋 · 체크아웃 · push 했을 수 있으니 바로 반영한다.
  on('turn.complete', async ($, e, next) => {
    const r = await next(e)
    void refresh($, false)
    return r
  })

  on('ui.render', { component: 'AbovePrompt' }, async ($, e, next) => {
    if (e.props.hasSurvey) return next(e)
    const snap = await read($, git)
    if (!snap) return next(e)
    const c = await read($, ci)
    const { Box, Text } = $.ui.resolve(e)
    const now = await $.clock.now()

    const sync =
      snap.upstream === null
        ? '원격 추적 없음'
        : snap.ahead === 0 && snap.behind === 0
          ? '동기화됨'
          : `↑${snap.ahead} ↓${snap.behind}`
    const changes = [
      snap.conflicted ? `충돌 ${snap.conflicted}` : '',
      snap.staged ? `스테이징 ${snap.staged}` : '',
      snap.unstaged ? `수정 ${snap.unstaged}` : '',
      snap.untracked ? `새 파일 ${snap.untracked}` : '',
    ].filter(Boolean)
    const changeText = changes.length ? changes.join(' · ') : '깨끗함'
    const changeColor = snap.conflicted ? 'error' : changes.length ? 'warning' : 'success'

    let ciText: { text: string; color: string } | null = null
    let ciMeta = ''
    if (c) {
      ciText = ciLabel(c)
      if (c.kind === 'run') {
        const when = ago(c.createdAt, now)
        // 최신 실행이 지금 HEAD 의 것이 아니면 「아직 push 안 함 / CI 안 돎」을 알린다.
        const stale = c.headSha && snap.oid && c.headSha !== snap.oid ? ' · 이전 커밋 기준' : ''
        ciMeta = ` ${c.workflow}${when ? ` · ${when}` : ''}${stale}`
      }
    }

    return (
      <Box flexDirection="column" width={e.props.bodyColumns}>
        <Box flexDirection="row">
          <Text wrap="truncate-end">
            <Text bold color="claude">{snap.project}</Text>
            <Text dimColor> ⎇ </Text>
            <Text color="suggestion">{snap.branch}</Text>
            {snap.isDetached ? <Text color="warning"> (분리된 HEAD)</Text> : null}
            {snap.operation ? <Text color="error"> [{snap.operation}]</Text> : null}
            <Text dimColor> │ </Text>
            <Text>{sync}</Text>
            <Text dimColor> │ </Text>
            <Text color={changeColor}>{changeText}</Text>
            {ciText ? <Text dimColor> │ </Text> : null}
            {ciText ? <Text color={ciText.color}>{ciText.text}</Text> : null}
            {ciMeta ? <Text dimColor>{ciMeta}</Text> : null}
          </Text>
        </Box>
        {snap.lastCommit ? (
          <Text dimColor wrap="truncate-end">
            {snap.lastCommit.hash} {snap.lastCommit.subject}
            {ago(snap.lastCommit.age, now) ? ` · ${ago(snap.lastCommit.age, now)}` : ''}
          </Text>
        ) : null}
      </Box>
    )
  })
}
