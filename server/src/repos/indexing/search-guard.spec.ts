import { searchBlocker, shouldHealIndex } from './search-guard';

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

describe('shouldHealIndex', () => {
  it('★ 청크가 있는데 막혔고 도는 작업이 없으면 다시 인덱싱한다 - 옛 인덱스가 영영 막히지 않게', () => {
    expect(shouldHealIndex(null, 12)).toBe(true);
    expect(shouldHealIndex('done', 12)).toBe(true);
    expect(shouldHealIndex('failed', 12)).toBe(true);
  });

  it('이미 줄을 섰거나 도는 중이면 또 걸지 않는다', () => {
    expect(shouldHealIndex('queued', 12)).toBe(false);
    expect(shouldHealIndex('running', 12)).toBe(false);
  });

  it('청크가 없으면 걸지 않는다 — 한 번도 끝나지 않은 저장소를 검색마다 두드리지 않는다', () => {
    expect(shouldHealIndex(null, 0)).toBe(false);
  });
});
