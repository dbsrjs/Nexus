import { summarizePrompt } from './summarize';

describe('summarizePrompt', () => {
  const out = summarizePrompt('[01:00] 가영: 배포를 금요일로 미룹시다');

  it('system 과 user 두 줄이다', () => {
    expect(out).toHaveLength(2);
    expect(out[0].role).toBe('system');
    expect(out[1].role).toBe('user');
  });

  it('대화 원문이 user 쪽에 그대로 들어간다', () => {
    expect(out[1].content).toContain('[01:00] 가영: 배포를 금요일로 미룹시다');
  });

  it('한국어로 답하라고 지시한다', () => {
    expect(out[0].content).toContain('한국어');
  });

  it('셋을 뽑으라고 지시한다 — 정해진 것 · 맡은 사람 · 남은 질문', () => {
    expect(out[0].content).toContain('정해진');
    expect(out[0].content).toContain('맡은');
    expect(out[0].content).toContain('남은');
  });

  it('마크다운으로 답하라고 지시한다 — 앱이 MarkdownBody 로 그린다', () => {
    expect(out[0].content).toContain('마크다운');
  });
});
