import { describe, expect, mock, test } from 'claude-code/testing'

import { ago, ciLabel, parseRuns, parseStatus } from './parse'

describe('parseStatus', () => {
  test('브랜치 · 앞뒤 · 변경 종류를 센다', () => {
    const s = parseStatus(
      [
        '# branch.oid 3a7d60d06b53e114e8fe4dfb9e349cf1a8ca8f64',
        '# branch.head feat/x',
        '# branch.upstream origin/feat/x',
        '# branch.ab +2 -1',
        '1 M. N... 100644 100644 100644 a b src/a.ts',
        '1 .M N... 100644 100644 100644 a b src/b.ts',
        '1 MM N... 100644 100644 100644 a b src/c.ts',
        'u UU N... 100644 100644 100644 100644 a b c src/d.ts',
        '? new.txt',
      ].join('\r\n'),
    )
    expect(s).toEqual({
      oid: '3a7d60d06b53e114e8fe4dfb9e349cf1a8ca8f64',
      branch: 'feat/x',
      isDetached: false,
      upstream: 'origin/feat/x',
      ahead: 2,
      behind: 1,
      staged: 2,
      unstaged: 2,
      untracked: 1,
      conflicted: 1,
    })
  })

  test('분리된 HEAD 는 짧은 해시를 브랜치 자리에 둔다', () => {
    const s = parseStatus('# branch.oid abcdef1234\n# branch.head (detached)\n')
    expect(s.isDetached).toBe(true)
    expect(s.branch).toBe('abcdef1')
    expect(s.upstream).toBe(null)
  })
})

describe('CI', () => {
  test('실행 없음 · 깨진 응답 · 성공 · 실행 중', () => {
    expect(parseRuns('[]')).toEqual({ kind: 'none' })
    expect(parseRuns('oops').kind).toBe('unknown')
    const ok = parseRuns(
      '[{"conclusion":"success","createdAt":"2026-10-06T04:54:02Z","status":"completed","workflowName":"CI","headSha":"abc"}]',
    )
    expect(ciLabel(ok)).toEqual({ text: 'CI ✓ 통과', color: 'success' })
    const running = parseRuns('[{"conclusion":"","status":"in_progress","workflowName":"CI"}]')
    expect(ciLabel(running).color).toBe('warning')
    expect(ciLabel({ kind: 'run', workflow: 'CI', status: 'completed', conclusion: 'failure', createdAt: '', headSha: '' }).text).toBe('CI ✗ 실패')
  })

  test('상대 시각', () => {
    const now = Date.parse('2026-10-06T05:00:00Z')
    expect(ago('2026-10-06T04:54:02Z', now)).toBe('5분 전')
    expect(ago('2026-10-06T04:59:50Z', now)).toBe('방금')
    expect(ago('not a date', now)).toBe('')
  })
})

const BAND = {
  plugin: 'git-band',
  component: 'AbovePrompt',
  props: { hasSurvey: false, isWorking: false, maxRows: 10, bodyColumns: 120, scroll: { bodyRows: 9, offset: 0 } },
} as const

test('/git-band 가 git · gh 를 읽어 띠에 그린다', async ($, on) => {
  // 테스트의 on 은 플러그인 아래(엔진 자리)에 붙으므로 git · gh 실행을 흉내 낸다.
  on('process.run', ($, e) => {
    const cmd = e.argv.join(' ')
    const ok = (stdout: string) => ({ value: { exitCode: 0, stdout, stderr: '', isStdoutTruncated: false, isStderrTruncated: false } })
    if (cmd.startsWith('git rev-parse')) return ok('/w/Nexus\n/w/Nexus/.git\n')
    if (cmd.startsWith('git status')) {
      return ok('# branch.oid abc\n# branch.head main\n# branch.upstream origin/main\n# branch.ab +0 -0\n1 M. N... 1 1 1 a b x\n? y\n? z\n')
    }
    if (cmd.startsWith('git log')) return ok('abc1234\x1ffeat: 무엇 추가\x1f2026-10-06T04:00:00Z\n')
    if (cmd.startsWith('gh run list')) {
      return ok('[{"conclusion":"success","createdAt":"2026-10-06T04:54:02Z","status":"completed","workflowName":"CI","headSha":"abc"}]')
    }
    return { deny: `unexpected: ${cmd}` }
  })
  on('fs.stat', () => ({ deny: 'ENOENT' }))

  mock.clock(on, { now: Date.parse('2026-10-06T05:00:00Z') })
  await $.command.run({ command: 'git-band', args: '' } as never)

  for (const surface of ['terminal', 'desktop'] as const) {
    const ui = await $.ui.mount({ ...BAND, surface } as never)
    expect(await ui.find({ type: 'Text', text: /Nexus/ })).toBeDefined()
    expect(await ui.find({ type: 'Text', text: /CI ✓ 통과/ })).toBeDefined()
    expect(await ui.find({ type: 'Text', text: /스테이징 1 · 새 파일 2/ })).toBeDefined()
    expect(await ui.find({ type: 'Text', text: /동기화됨/ })).toBeDefined()
    expect(await ui.find({ type: 'Text', text: /CI · 5분 전/ })).toBeDefined()
    await ui.unmount()
  }
})
