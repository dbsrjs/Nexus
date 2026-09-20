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

  it('★ 메시지 경계가 다르면 이어 붙인 내용이 같아도 해시가 다르다 - 캐시가 남의 답을 주면 안 된다', () => {
    // 공백으로 이으면 메시지 두 개("system"+"a", "user"+"b")를 이어 붙인
    // 결과와, 메시지 한 개("system"+"a user b")를 이어 붙인 결과가
    // 똑같이 "system a user b" 로 펴진다 — content 는 buildTranscript 가
    // 만든 대화 원문이라 공백을 얼마든지 담을 수 있는 사용자 통제 값이다.
    const twoMessages: LlmMessage[] = [
      { role: 'system', content: 'a' },
      { role: 'user', content: 'b' },
    ];
    const oneMessage: LlmMessage[] = [{ role: 'system', content: 'a user b' }];
    expect(promptHash('summarize', 'fake:fake', twoMessages)).not.toBe(
      promptHash('summarize', 'fake:fake', oneMessage),
    );
  });
});
