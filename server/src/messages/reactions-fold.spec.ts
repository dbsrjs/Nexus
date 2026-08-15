import { fold } from './reactions.service';

/**
 * 리액션 요약 규칙.
 *
 * 개수와 "내가 눌렀는지"는 화면에 그대로 드러나는 계산이다. DB 동작은
 * `npm run check:reactions` 가 실서버로 확인하고, 여기서는 접는 규칙 자체만
 * 고정한다 — 두 층을 섞지 않는 이유는 전환-계획 §6 의 교훈이다.
 */
describe('fold — 리액션 요약', () => {
  const row = (emoji: string, userId: string) => ({ emoji, userId });

  it('이모지별로 개수를 센다', () => {
    const result = fold(
      [row('👍', 'u1'), row('👍', 'u2'), row('🎉', 'u3')],
      'u9',
    );

    expect(result).toEqual([
      { emoji: '👍', count: 2, mine: false },
      { emoji: '🎉', count: 1, mine: false },
    ]);
  });

  it('★ mine 은 보는 사람 기준이다', () => {
    const rows = [row('👍', 'u1'), row('👍', 'u2')];

    expect(fold(rows, 'u1')[0].mine).toBe(true);
    expect(fold(rows, 'u2')[0].mine).toBe(true);
    expect(fold(rows, 'u3')[0].mine).toBe(false);
  });

  it('★ 처음 눌린 순서를 유지한다 — 개수 순으로 재정렬하지 않는다', () => {
    // 개수로 정렬하면 남이 리액션을 달 때마다 버튼 위치가 바뀐다.
    const result = fold(
      [row('🎉', 'u1'), row('👍', 'u2'), row('👍', 'u3'), row('👍', 'u4')],
      'u1',
    );

    expect(result.map((r) => r.emoji)).toEqual(['🎉', '👍']);
    expect(result[1].count).toBe(3);
  });

  it('내가 누른 것이 뒤쪽에 있어도 mine 이 켜진다', () => {
    const result = fold([row('👍', 'u1'), row('👍', 'u2')], 'u2');
    expect(result[0].mine).toBe(true);
  });

  it('비어 있으면 빈 목록', () => {
    expect(fold([], 'u1')).toEqual([]);
  });
});
