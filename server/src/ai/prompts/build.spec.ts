import { AiRunKind } from '@prisma/client';
import { buildAskPrompt } from './build';
import { summarizePrompt } from './summarize';

const material = { transcript: '[01:00] 가영: 안녕', chunks: [] };

describe('buildAskPrompt', () => {
  it('summary 프리셋은 13-1 요약 프롬프트와 바이트 단위로 같다', () => {
    const out = buildAskPrompt({ instruction: null, preset: 'summary' }, material);
    expect(out.kind).toBe(AiRunKind.summarize);
    expect(out.json).toBe(false);
    expect(out.messages).toEqual(summarizePrompt(material.transcript));
  });

  it('issue 프리셋은 draft_issue 이고 JSON 출력이다', () => {
    const out = buildAskPrompt({ instruction: null, preset: 'issue' }, material);
    expect(out.kind).toBe(AiRunKind.draft_issue);
    expect(out.json).toBe(true);
  });

  it('지시문은 ask 다', () => {
    const out = buildAskPrompt({ instruction: '세 줄로', preset: null }, material);
    expect(out.kind).toBe(AiRunKind.ask);
    expect(out.messages[1].content).toContain('## 요청\n세 줄로');
  });

  it('순수 함수다 — 같은 입력이면 같은 출력 (promptHash 의 입력이다)', () => {
    const a = buildAskPrompt({ instruction: 'q', preset: null }, material);
    const b = buildAskPrompt({ instruction: 'q', preset: null }, material);
    expect(a).toEqual(b);
  });
});
