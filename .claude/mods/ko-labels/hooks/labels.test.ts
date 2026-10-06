import { describe, expect, test } from 'claude-code/testing'

import { koDescription, koLabel, lookupCommand } from './register'

describe('명령 설명', () => {
  test('한국어를 앞에 붙인다', () => {
    expect(koDescription('compact', 'Free up context')).toBe(
      '지금까지의 대화를 요약해 컨텍스트 확보 — Free up context',
    )
  })
  test('MCP 같은 고유 명칭은 영어로 둔다', () => {
    expect(koDescription('mcp', 'Manage MCP servers')).toBe('MCP 서버 관리 — Manage MCP servers')
  })
  test('접두사 붙은 스킬은 마지막 마디로 찾는다', () => {
    expect(lookupCommand('anthropic-skills:pdf')).toBe('PDF 읽기 · 병합 · 분할 · 생성')
  })
  test('사전에 없거나 이미 한국어면 그대로', () => {
    expect(koDescription('no-such-command', 'x')).toBe(undefined)
    expect(koDescription('git-band', 'git 상태 띠를 새로 고친다')).toBe(undefined)
  })
})

describe('설정 행', () => {
  test('라벨 옆에 한국어', () => {
    expect(koLabel('autoCompact', 'Auto-compact')).toBe('Auto-compact · 자동 압축')
    expect(koLabel('autoConnectIde', 'Auto-connect to IDE (external terminal)')).toBe(
      'Auto-connect to IDE (external terminal) · IDE 자동 연결(외부 터미널)',
    )
  })
  test('모르는 키는 그대로', () => {
    expect(koLabel('someNewRow', 'Some row')).toBe(undefined)
  })
})

test('엔진의 describe 이벤트를 거쳐 바뀐다', async ($, on) => {
  on('command.describe', ($, e) => ({ description: e.description, argumentHint: e.argumentHint, isHidden: e.isHidden }))
  on('config.describe', ($, e) => ({ label: e.label, description: e.description, isHidden: e.isHidden }))
  const core = { plugin: 'engine', tier: 'core' } as const
  const c = await $.command.describe({ command: 'clear', description: 'Start a new session', isHidden: false, immediate: false, provider: core } as never)
  expect(c.description).toBe('빈 컨텍스트로 새 세션 시작(이전 세션은 /resume 으로 재개 가능) — Start a new session')
  const r = await $.config.describe({ key: 'theme', label: 'Theme', isHidden: false, provider: core } as never)
  expect(r.label).toBe('Theme · 테마')
})
