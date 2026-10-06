import type { Register } from 'claude-code'

import { COMMANDS, CONFIG } from './dictionary'

// 이미 한글이 들어 있으면(이 모드나 다른 플러그인이 붙였거나 원래 한국어) 다시 붙이지 않는다.
const HANGUL = /[ㄱ-ㆎ가-힣]/

// 플러그인 · 스킬 명령은 `anthropic-skills:pdf` 처럼 접두사가 붙는다. 정확한 이름을 먼저,
// 없으면 마지막 마디로 찾는다.
export function lookupCommand(name: string): string | undefined {
  return COMMANDS[name] ?? COMMANDS[name.split(':').pop() ?? name]
}

// 명령 목록은 한 줄로 그려져 길면 뒤가 잘린다. 스킬 설명은 영어가 길어서 뒤에 붙이면
// 한국어가 잘려 보이지 않으므로 앞에 둔다.
export function koDescription(name: string, description: string): string | undefined {
  const ko = lookupCommand(name)
  if (!ko || HANGUL.test(description)) return undefined
  return description ? `${ko} — ${description}` : ko
}

// 설정 행은 라벨이 짧아 잘릴 걱정이 없으므로 원문 옆에 둔다(원문을 먼저 두어 문서 · 검색어와 대조된다).
export function koLabel(key: string, label: string): string | undefined {
  const ko = CONFIG[key]
  if (!ko || HANGUL.test(label)) return undefined
  return `${label} · ${ko}`
}

export const register: Register = on => {
  on('command.describe', ($, e, next) => {
    const description = koDescription(e.command, e.description)
    return description ? next({ ...e, description }) : next(e)
  })

  on('config.describe', ($, e, next) => {
    const label = koLabel(e.key, e.label)
    return label ? next({ ...e, label }) : next(e)
  })
}
