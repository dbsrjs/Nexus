import { promptHash } from './prompt-hash';
import { LlmMessage } from '../llm/llm.provider';

const msgs: LlmMessage[] = [
  { role: 'system', content: '너는 요약가다' },
  { role: 'user', content: '[01:00] 가영: 안녕' },
];

describe('promptHash', () => {
  it('같은 입력에 같은 값을 준다', () => {
    expect(promptHash('summarize', 'fake:fake', msgs)).toBe(
      promptHash('summarize', 'fake:fake', msgs),
    );
  });

  it('★ 모델이 다르면 값이 다르다 - 모델을 바꿨는데 캐시가 옛 답을 주면 조용히 틀린다', () => {
    expect(promptHash('summarize', 'fake:fake', msgs)).not.toBe(
      promptHash('summarize', 'local:other', msgs),
    );
  });

  it('kind 가 다르면 값이 다르다', () => {
    expect(promptHash('summarize', 'fake:fake', msgs)).not.toBe(
      promptHash('draft_issue', 'fake:fake', msgs),
    );
  });

  it('본문이 한 글자만 달라도 값이 다르다', () => {
    const other: LlmMessage[] = [msgs[0], { role: 'user', content: '[01:00] 가영: 안뇽' }];
    expect(promptHash('summarize', 'fake:fake', msgs)).not.toBe(
      promptHash('summarize', 'fake:fake', other),
    );
  });

  it('역할이 바뀌면 값이 다르다 — 내용만 이어 붙이지 않는다', () => {
    const swapped: LlmMessage[] = [
      { role: 'user', content: '너는 요약가다' },
      { role: 'system', content: '[01:00] 가영: 안녕' },
    ];
    expect(promptHash('summarize', 'fake:fake', msgs)).not.toBe(
      promptHash('summarize', 'fake:fake', swapped),
    );
  });

  it('sha256 16진 문자열이다', () => {
    expect(promptHash('summarize', 'fake:fake', msgs)).toMatch(/^[0-9a-f]{64}$/);
  });
});
