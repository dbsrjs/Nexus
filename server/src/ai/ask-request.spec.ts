import { BadRequestException } from '@nestjs/common';
import { MAX_INSTRUCTION, validateAskRequest } from './ask-request';

const C = '11111111-1111-4111-8111-111111111111';
const R = '22222222-2222-4222-8222-222222222222';
const M = '33333333-3333-4333-8333-333333333333';

const bad = (dto: Parameters<typeof validateAskRequest>[0]) =>
  expect(() => validateAskRequest(dto)).toThrow(BadRequestException);

describe('validateAskRequest', () => {
  it('지시문과 프리셋이 둘 다 있으면 400 이다 (D4)', () => {
    bad({ instruction: '요약', preset: 'summary', context: { channelId: C } });
  });

  it('지시문도 프리셋도 없으면 400 이다', () => {
    bad({ context: { channelId: C } });
  });

  it('공백뿐인 지시문은 400 이다', () => {
    bad({ instruction: '   \n', context: { channelId: C } });
  });

  it('지시문이 상한을 넘으면 400 이다 — DTO 를 거치지 않는 호출도 막는다', () => {
    bad({ instruction: 'a'.repeat(MAX_INSTRUCTION + 1), context: { channelId: C } });
  });

  it('컨텍스트가 하나도 없으면 400 이다 (D5)', () => {
    bad({ instruction: '뭐야', context: {} });
  });

  it('messageIds 만 있고 channelId 가 없으면 400 이다', () => {
    bad({ instruction: '뭐야', context: { messageIds: [M] } });
  });

  it('★ 프리셋인데 대화가 없으면 400 이다 — 코드만으로 이슈 초안을 지어내지 않는다', () => {
    bad({ preset: 'issue', context: { repoId: R } });
  });

  it('지시문은 앞뒤 공백을 벗긴다', () => {
    const req = validateAskRequest({ instruction: '  세 줄로  ', context: { channelId: C } });
    expect(req.instruction).toBe('세 줄로');
    expect(req.preset).toBeNull();
  });

  it('메시지 중복은 접는다 — 개수 불일치로 404 가 나지 않게', () => {
    const req = validateAskRequest({
      preset: 'summary',
      context: { channelId: C, messageIds: [M, M] },
    });
    expect(req.messageIds).toEqual([M]);
  });

  it('코드만 · 대화 + 코드 조합을 받는다', () => {
    expect(validateAskRequest({ instruction: 'q', context: { repoId: R } })).toEqual({
      instruction: 'q',
      preset: null,
      channelId: null,
      messageIds: null,
      repoId: R,
    });
    const both = validateAskRequest({ preset: 'issue', context: { channelId: C, repoId: R } });
    expect(both.channelId).toBe(C);
    expect(both.repoId).toBe(R);
  });
});
