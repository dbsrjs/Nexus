import { askPrompt } from './ask';

describe('askPrompt', () => {
  it('있는 절만 싣는다', () => {
    const out = askPrompt({ transcript: '[01:00] 가영: 안녕', code: '', instruction: '세 줄로' });
    expect(out[1].content).toBe('## 대화\n[01:00] 가영: 안녕\n\n## 요청\n세 줄로');
  });

  it('대화 없이 코드만 있을 수 있다', () => {
    const out = askPrompt({ transcript: null, code: '[1] a.ts:1-2', instruction: '뭐야' });
    expect(out[1].content).toBe('## 코드\n[1] a.ts:1-2\n\n## 요청\n뭐야');
  });

  it('★ 주어진 자료만 근거로 하라고 지시한다 — 지어내지 않게', () => {
    const out = askPrompt({ transcript: 'x', code: '', instruction: 'y' });
    expect(out[0].content).toContain('주어진 자료');
    expect(out[0].content).toContain('[n]');
  });
});
