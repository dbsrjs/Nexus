import { groupBy } from './group-by';

describe('groupBy', () => {
  it('키마다 들어온 순서대로 묶는다', () => {
    const rows = [
      { m: 'a', v: 1 },
      { m: 'b', v: 2 },
      { m: 'a', v: 3 },
    ];
    expect(
      groupBy(
        rows,
        (r) => r.m,
        (r) => r.v,
      ),
    ).toEqual(
      new Map([
        ['a', [1, 3]],
        ['b', [2]],
      ]),
    );
  });

  it('값을 바꾸지 않으면 원소 그대로', () => {
    const rows = [{ m: 'a' }];
    expect(groupBy(rows, (r) => r.m).get('a')).toEqual([{ m: 'a' }]);
  });
});
