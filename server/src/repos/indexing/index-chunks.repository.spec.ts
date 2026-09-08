import { toVectorLiteral } from './index-chunks.repository';

describe('toVectorLiteral', () => {
  it('pgvector 가 읽는 모양이다 — 대괄호에 쉼표', () => {
    expect(toVectorLiteral([1, -0.5, 0])).toBe('[1,-0.5,0]');
  });

  it('공백을 넣지 않는다 — 청크마다 부질없이 커진다', () => {
    expect(toVectorLiteral([0.1, 0.2])).not.toContain(' ');
  });

  it('유한하지 않은 값은 던진다 — NaN 이 들어가면 검색이 조용히 망가진다', () => {
    expect(() => toVectorLiteral([1, NaN])).toThrow(/유한/);
    expect(() => toVectorLiteral([Infinity])).toThrow(/유한/);
  });

  it('지수 표기를 만들지 않는다 — pgvector 는 받지만 읽기 어렵다', () => {
    expect(toVectorLiteral([1e-7])).not.toMatch(/e/i);
  });
});
