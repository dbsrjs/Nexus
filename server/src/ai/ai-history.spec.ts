import { AiRunKind } from '@prisma/client';
import {
  PREVIEW_MAX,
  listContextOf,
  previewOf,
  rootQuestionOf,
  threadContextOf,
} from './ai-history';

describe('rootQuestionOf', () => {
  it('지시문이면 질문, 프리셋은 null', () => {
    expect(rootQuestionOf({ instruction: '버그가 어디야?' })).toEqual({
      question: '버그가 어디야?',
      preset: null,
    });
  });

  it('프리셋이면 질문은 null', () => {
    expect(
      rootQuestionOf({ preset: 'issue', channelId: 'c', messageIds: ['m'] }),
    ).toEqual({ question: null, preset: 'issue' });
  });

  it('13-1 행(지시문 · 프리셋 없음)은 요약이다', () => {
    expect(rootQuestionOf({ channelId: 'c', messageIds: ['m'] })).toEqual({
      question: null,
      preset: 'summary',
    });
  });
});

describe('previewOf', () => {
  it('이슈 초안은 제목', () => {
    expect(
      previewOf(AiRunKind.draft_issue, { title: '로그인 버그', description: '…' }),
    ).toBe('로그인 버그');
  });

  it(`마크다운은 앞 ${PREVIEW_MAX}자`, () => {
    const long = 'ㄱ'.repeat(PREVIEW_MAX + 50);
    expect(previewOf(AiRunKind.ask, { markdown: long })).toHaveLength(PREVIEW_MAX);
  });

  it('결과가 없으면 빈 문자열 - 지어내지 않는다', () => {
    expect(previewOf(AiRunKind.summarize, null)).toBe('');
    expect(previewOf(AiRunKind.ask, { markdown: 3 })).toBe('');
  });
});

describe('contextOf', () => {
  const input = {
    instruction: 'q',
    channelId: 'c1',
    messageIds: ['m1', 'm2'],
    repoId: 'r1',
  };

  it('목록은 메시지 수만', () => {
    expect(listContextOf(input)).toEqual({
      channelId: 'c1',
      messageCount: 2,
      repoId: 'r1',
    });
  });

  it('사슬은 메시지 id 까지', () => {
    expect(threadContextOf(input)).toEqual({
      channelId: 'c1',
      messageIds: ['m1', 'm2'],
      repoId: 'r1',
    });
  });

  it('근거가 없는 자리는 null', () => {
    expect(listContextOf({ instruction: 'q', repoId: 'r1' })).toEqual({
      channelId: null,
      messageCount: null,
      repoId: 'r1',
    });
  });
});
