import { Prisma } from '@prisma/client';
import { needsRenumber, positionBetween, POSITION_STEP } from './position';

const d = (n: string | number) => new Prisma.Decimal(n);

/**
 * 칸반은 사이 삽입이 기본 동작이라, 두 카드 사이에 넣을 때 중간값을 줘서
 * 재정렬 쓰기를 1건으로 끝낸다 (docs/백엔드-설계.md §3).
 */
describe('positionBetween', () => {
  it('두 카드 사이는 중간값이다', () => {
    expect(positionBetween(d(0), d(1000)).toString()).toBe('500');
  });

  it('위 카드만 주면 그 아래로 한 칸 내려간다', () => {
    expect(positionBetween(d(1000), null).toString()).toBe('2000');
  });

  it('아래 카드만 주면 그 위로 한 칸 올라간다', () => {
    expect(positionBetween(null, d(1000)).toString()).toBe('0');
  });

  it('빈 컬럼이면 0 이다', () => {
    expect(positionBetween(null, null).toString()).toBe('0');
  });

  it('음수 자리도 만든다 — 맨 위로 계속 올릴 수 있어야 한다', () => {
    expect(positionBetween(null, d(0)).toString()).toBe('-1000');
  });

  it('결과는 언제나 두 이웃 사이에 엄격히 들어간다', () => {
    let prev = d(0);
    const next = d(1);
    for (let i = 0; i < 10; i++) {
      const mid = positionBetween(prev, next);
      expect(mid.greaterThan(prev)).toBe(true);
      expect(mid.lessThan(next)).toBe(true);
      prev = mid;
    }
  });
});

/**
 * Decimal 의 유효 자릿수가 소진되면 중간값이 이웃과 같아진다. 그때는 그
 * 컬럼만 다시 채번해야 한다 — 조용히 같은 값을 쓰면 두 카드의 순서가
 * tie-break 로 넘어가 흔들린다(전송 큐에서 시각이 동률이던 것과 같다).
 */
describe('needsRenumber', () => {
  it('중간값이 이웃과 같아지면 참이다', () => {
    expect(needsRenumber(d(5), d(5), d(6))).toBe(true);
    expect(needsRenumber(d(6), d(5), d(6))).toBe(true);
  });

  it('사이에 들어가면 거짓이다', () => {
    expect(needsRenumber(d('5.5'), d(5), d(6))).toBe(false);
  });

  it('이웃이 없으면 거짓이다', () => {
    expect(needsRenumber(d(0), null, null)).toBe(false);
  });
});

describe('POSITION_STEP', () => {
  it('1000 이다 — 재채번 간격과 같아야 한다', () => {
    expect(POSITION_STEP.toString()).toBe('1000');
  });
});
