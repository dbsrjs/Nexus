import { buildBurndown, utcDays } from './burndown';

const day = (iso: string) => new Date(`${iso}T00:00:00.000Z`);

/**
 * 번다운은 `closedAt` 하나로 역산한다 — 상태 전이 이력 테이블을 두지 않기로
 * 했기 때문이다(설계 §3). 순수 계산이라 여기서 고정하고, DB 왕복은
 * check:issues 가 덮는다.
 */
describe('utcDays', () => {
  it('시작일과 종료일을 모두 포함한다', () => {
    const days = utcDays(day('2026-08-01'), day('2026-08-03'));
    expect(days.map((d) => d.toISOString().slice(0, 10))).toEqual([
      '2026-08-01',
      '2026-08-02',
      '2026-08-03',
    ]);
  });

  it('하루짜리 스프린트도 한 칸이 된다', () => {
    expect(utcDays(day('2026-08-01'), day('2026-08-01'))).toHaveLength(1);
  });

  it('시각이 섞여 있어도 UTC 자정으로 자른다', () => {
    // 기기 시간대로 자르면 같은 스프린트가 사람마다 다른 그래프가 된다.
    const days = utcDays(
      new Date('2026-08-01T23:59:59.000Z'),
      new Date('2026-08-02T00:00:01.000Z'),
    );
    expect(days).toHaveLength(2);
  });
});

describe('buildBurndown', () => {
  const start = day('2026-08-01');
  const end = day('2026-08-04');

  it('아무것도 닫히지 않으면 평평하다', () => {
    const result = buildBurndown({
      startsAt: start,
      endsAt: end,
      issues: [
        { storyPoints: 3, closedAt: null },
        { storyPoints: 5, closedAt: null },
      ],
    });

    expect(result.total.points).toBe(8);
    expect(result.total.count).toBe(2);
    expect(result.days.map((d) => d.points)).toEqual([8, 8, 8, 8]);
    expect(result.days.map((d) => d.count)).toEqual([2, 2, 2, 2]);
  });

  it('닫힌 날부터 줄어든다 — 그날 안에 닫혔으면 그날부터 빠진다', () => {
    const result = buildBurndown({
      startsAt: start,
      endsAt: end,
      issues: [
        { storyPoints: 3, closedAt: new Date('2026-08-02T10:00:00.000Z') },
        { storyPoints: 5, closedAt: new Date('2026-08-03T23:59:00.000Z') },
      ],
    });

    expect(result.days.map((d) => d.points)).toEqual([8, 5, 0, 0]);
    expect(result.days.map((d) => d.count)).toEqual([2, 1, 0, 0]);
  });

  it('포인트를 안 매긴 이슈는 개수로만 세어진다', () => {
    // 포인트만 주면 그래프가 평평한데, 그건 "안 줄었다"가 아니라
    // "잴 것이 없다"다. 두 계열을 함께 주는 이유다.
    const result = buildBurndown({
      startsAt: start,
      endsAt: end,
      issues: [
        { storyPoints: null, closedAt: null },
        { storyPoints: null, closedAt: new Date('2026-08-02T09:00:00.000Z') },
      ],
    });

    expect(result.total.points).toBe(0);
    expect(result.total.count).toBe(2);
    expect(result.days.map((d) => d.points)).toEqual([0, 0, 0, 0]);
    expect(result.days.map((d) => d.count)).toEqual([2, 1, 1, 1]);
  });

  it('스프린트 시작 전에 닫힌 이슈는 처음부터 빠져 있다', () => {
    const result = buildBurndown({
      startsAt: start,
      endsAt: end,
      issues: [
        { storyPoints: 3, closedAt: new Date('2026-07-30T10:00:00.000Z') },
        { storyPoints: 5, closedAt: null },
      ],
    });

    expect(result.total.points).toBe(8);
    expect(result.days[0].points).toBe(5);
  });

  it('스프린트가 끝난 뒤에 닫힌 이슈는 끝까지 남아 있다', () => {
    const result = buildBurndown({
      startsAt: start,
      endsAt: end,
      issues: [
        { storyPoints: 3, closedAt: new Date('2026-08-10T10:00:00.000Z') },
      ],
    });

    expect(result.days[result.days.length - 1].points).toBe(3);
  });

  it('이슈가 없으면 0으로 평평하다', () => {
    const result = buildBurndown({ startsAt: start, endsAt: end, issues: [] });

    expect(result.total).toEqual({ points: 0, count: 0 });
    expect(result.days).toHaveLength(4);
    expect(result.days.every((d) => d.points === 0 && d.count === 0)).toBe(true);
  });
});
