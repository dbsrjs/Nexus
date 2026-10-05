import { cursorArgs, pageOf } from './pagination';

describe('cursorArgs', () => {
  it('limit 이 없으면 30 이고, 하나 더 읽는다', () => {
    expect(cursorArgs({})).toEqual({ limit: 30, args: { take: 31 } });
  });

  it('커서가 있으면 그 다음부터 읽는다', () => {
    expect(cursorArgs({ cursor: 'm9', limit: 5 })).toEqual({
      limit: 5,
      args: { take: 6, cursor: { id: 'm9' }, skip: 1 },
    });
  });
});

describe('pageOf', () => {
  const rows = (n: number) => Array.from({ length: n }, (_, i) => ({ id: `m${i}` }));

  it('넘치면 잘라서 마지막 id 를 다음 커서로 준다', () => {
    expect(pageOf(rows(4), 3)).toEqual({ page: rows(3), nextCursor: 'm2' });
  });

  it('딱 맞거나 모자라면 끝 — 커서는 null', () => {
    expect(pageOf(rows(3), 3)).toEqual({ page: rows(3), nextCursor: null });
    expect(pageOf([], 3)).toEqual({ page: [], nextCursor: null });
  });
});
