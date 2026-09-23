import { AiRunKind } from '@prisma/client';
import { buildFollowUpPrompt } from './follow-up';
import { ASK_SYSTEM } from './ask';

const material = { transcript: '[09:00] 가영: 배포는 금요일', chunks: [] };

describe('buildFollowUpPrompt', () => {
  it('★ system · 첫 user(자료) · 답 · 질문 … 순서다', () => {
    const built = buildFollowUpPrompt(
      {
        root: { instruction: '정리해 줘', preset: null },
        rootAnswer: '첫 답',
        later: [{ question: '둘째 질문', answer: '둘째 답' }],
      },
      material,
      '셋째 질문',
    );
    expect(built.kind).toBe(AiRunKind.ask);
    expect(built.json).toBe(false);
    expect(built.messages.map((m) => m.role)).toEqual([
      'system',
      'user',
      'assistant',
      'user',
      'assistant',
      'user',
    ]);
    expect(built.messages[2].content).toBe('첫 답');
    expect(built.messages[3].content).toBe('둘째 질문');
    expect(built.messages[5].content).toBe('셋째 질문');
  });

  it('★ 자료는 첫 user 에만 있다', () => {
    const built = buildFollowUpPrompt(
      { root: { instruction: '정리해 줘', preset: null }, rootAnswer: 'a', later: [] },
      material,
      '더',
    );
    const withTranscript = built.messages.filter((m) => m.content.includes('배포는 금요일'));
    expect(withTranscript).toHaveLength(1);
    expect(withTranscript[0]).toBe(built.messages[1]);
  });

  it('★ 첫 문답이 요약 프리셋이어도 system 은 ask 의 것이다 - 세 항목 양식에 굳지 않게', () => {
    const built = buildFollowUpPrompt(
      { root: { instruction: null, preset: 'summary' }, rootAnswer: '### 정해진 것', later: [] },
      material,
      '담당자별로',
    );
    expect(built.messages[0]).toEqual({ role: 'system', content: ASK_SYSTEM });
    expect(built.messages[1].content).toContain('다음 대화를 요약해 줘');
  });

  it('이슈 초안에는 이어 묻지 않는다 - 던진다', () => {
    expect(() =>
      buildFollowUpPrompt(
        { root: { instruction: null, preset: 'issue' }, rootAnswer: '{}', later: [] },
        material,
        'q',
      ),
    ).toThrow();
  });
});
