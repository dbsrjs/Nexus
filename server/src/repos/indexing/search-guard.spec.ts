import { searchBlocker } from './search-guard';

describe('searchBlocker', () => {
  it('한 번도 인덱싱하지 않았으면 막는다', () => {
    expect(searchBlocker(null, 'fake:fake')).toMatch(/인덱싱되지 않았/);
  });

  it('★ 다른 모델로 만든 인덱스면 막는다 — 오류 없이 순위만 틀리는 구간을 없앤다', () => {
    expect(searchBlocker('local:embeddinggemma', 'gemini:gemini-embedding-001')).toMatch(
      /모델이 바뀌어/,
    );
  });

  it('같은 모델이면 통과한다', () => {
    expect(searchBlocker('fake:fake', 'fake:fake')).toBeNull();
  });
});
