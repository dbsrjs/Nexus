import { fullReindexBeforeCompare, planFromCompare } from './changed-files';

describe('fullReindexBeforeCompare', () => {
  const same = { indexedModel: 'local:embeddinggemma', currentModel: 'local:embeddinggemma' };

  it('기준 커밋이 없으면 첫 인덱싱이다', () => {
    expect(fullReindexBeforeCompare({ ...same, baseSha: null })).toBe('first');
  });

  it('모델이 같으면 증분을 시도한다', () => {
    expect(fullReindexBeforeCompare({ ...same, baseSha: 'abc' })).toBeNull();
  });

  it('모델이 바뀌면 전체다', () => {
    expect(
      fullReindexBeforeCompare({
        baseSha: 'abc',
        indexedModel: 'local:nomic-embed-text',
        currentModel: 'local:embeddinggemma',
      }),
    ).toBe('model-changed');
  });

  it('모델 이름이 같아도 provider 가 다르면 전체다', () => {
    expect(
      fullReindexBeforeCompare({
        baseSha: 'abc',
        indexedModel: 'gemini:embeddinggemma',
        currentModel: 'local:embeddinggemma',
      }),
    ).toBe('model-changed');
  });

  it('기록이 없는 옛 인덱스는 모델을 모르므로 전체다', () => {
    expect(
      fullReindexBeforeCompare({ baseSha: 'abc', indexedModel: null, currentModel: 'fake:fake' }),
    ).toBe('model-changed');
  });
});

describe('planFromCompare', () => {
  it('추가 · 수정은 다시 인덱싱한다', () => {
    const plan = planFromCompare([
      { path: 'a.ts', status: 'added', previousPath: null },
      { path: 'b.ts', status: 'modified', previousPath: null },
    ]);
    expect(plan.reindex.sort()).toEqual(['a.ts', 'b.ts']);
    expect(plan.remove).toEqual([]);
  });

  it('삭제는 지우기만 한다', () => {
    const plan = planFromCompare([{ path: 'gone.ts', status: 'removed', previousPath: null }]);
    expect(plan.reindex).toEqual([]);
    expect(plan.remove).toEqual(['gone.ts']);
  });

  it('이름이 바뀌면 옛 경로를 지우고 새 경로를 인덱싱한다', () => {
    const plan = planFromCompare([
      { path: 'new.ts', status: 'renamed', previousPath: 'old.ts' },
    ]);
    expect(plan.reindex).toEqual(['new.ts']);
    expect(plan.remove).toEqual(['old.ts']);
  });

  it('previousPath 가 없는 renamed 는 추가로 본다 — 지울 대상을 짐작하지 않는다', () => {
    const plan = planFromCompare([{ path: 'new.ts', status: 'renamed', previousPath: null }]);
    expect(plan.reindex).toEqual(['new.ts']);
    expect(plan.remove).toEqual([]);
  });

  it('같은 경로가 여러 번 와도 한 번만 다룬다', () => {
    const plan = planFromCompare([
      { path: 'a.ts', status: 'added', previousPath: null },
      { path: 'a.ts', status: 'modified', previousPath: null },
    ]);
    expect(plan.reindex).toEqual(['a.ts']);
  });

  it('지웠다가 다시 만든 경로는 인덱싱만 한다 — 지우기가 뒤에 오면 빈 채로 남는다', () => {
    const plan = planFromCompare([
      { path: 'a.ts', status: 'removed', previousPath: null },
      { path: 'a.ts', status: 'added', previousPath: null },
    ]);
    expect(plan.reindex).toEqual(['a.ts']);
    expect(plan.remove).toEqual([]);
  });
});
