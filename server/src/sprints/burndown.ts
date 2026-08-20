/** 번다운 계산에 필요한 이슈 정보. DB 행 전체가 아니라 이 둘뿐이다. */
export interface BurndownIssue {
  storyPoints: number | null;
  closedAt: Date | null;
}

export interface BurndownInput {
  startsAt: Date;
  endsAt: Date;
  issues: BurndownIssue[];
}

export interface BurndownDay {
  /** UTC 자정 기준 날짜. */
  date: Date;
  /** 그날 끝 시점에 남아 있던 스토리 포인트. */
  points: number;
  /** 그날 끝 시점에 남아 있던 이슈 개수. */
  count: number;
}

const DAY_MS = 24 * 60 * 60 * 1000;

/** 그 시각이 속한 UTC 날짜의 자정. */
function utcMidnight(date: Date): Date {
  return new Date(
    Date.UTC(date.getUTCFullYear(), date.getUTCMonth(), date.getUTCDate()),
  );
}

/**
 * 시작일부터 종료일까지의 날짜 목록(양끝 포함).
 *
 * **UTC 자정으로 자른다.** 기기 시간대로 자르면 같은 스프린트가 사람마다
 * 다른 그래프가 된다.
 */
export function utcDays(startsAt: Date, endsAt: Date): Date[] {
  const first = utcMidnight(startsAt).getTime();
  const last = utcMidnight(endsAt).getTime();

  const days: Date[] = [];
  for (let t = first; t <= last; t += DAY_MS) {
    days.push(new Date(t));
  }
  return days;
}

/**
 * `closedAt` 하나로 날짜별 남은 양을 역산한다.
 *
 * 상태 전이 이력 테이블을 두지 않기로 했으므로(설계 §3), "각 이슈가 언제
 * 닫혔는가"가 유일한 입력이다. 어떤 날 `d` 에 남아 있던 것은 **아직 안
 * 닫혔거나 `d` 의 끝보다 뒤에 닫힌** 이슈다.
 *
 * **포인트와 개수를 함께 준다.** 포인트만 주면 `storyPoints` 를 비워 둔
 * 사람에게는 평평한 선이 되는데, 그건 "일이 안 줄었다"가 아니라 "잴 것이
 * 없다"이다. 화면에서 둘이 구분되어야 한다.
 *
 * **이상선은 만들지 않는다.** 시작 총량에서 균등하게 내려오는 직선이라
 * 클라이언트가 두 점으로 그린다 — 서버가 날짜마다 보내면 같은 값을 두 번 담는다.
 */
export function buildBurndown(input: BurndownInput): {
  total: { points: number; count: number };
  days: BurndownDay[];
} {
  const days = utcDays(input.startsAt, input.endsAt);

  const total = input.issues.reduce(
    (acc, issue) => ({
      points: acc.points + (issue.storyPoints ?? 0),
      count: acc.count + 1,
    }),
    { points: 0, count: 0 },
  );

  return {
    total,
    days: days.map((date) => {
      // 그날 "끝" 시점을 기준으로 본다 — 그날 안에 닫힌 것은 그날부터 빠진다.
      const endOfDay = date.getTime() + DAY_MS;

      let points = 0;
      let count = 0;
      for (const issue of input.issues) {
        const open =
          issue.closedAt === null || issue.closedAt.getTime() >= endOfDay;
        if (!open) continue;
        points += issue.storyPoints ?? 0;
        count += 1;
      }
      return { date, points, count };
    }),
  };
}
