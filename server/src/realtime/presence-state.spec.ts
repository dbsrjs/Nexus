import { combinePresence } from './presence-state';

describe('combinePresence', () => {
  it('소켓이 없으면 오프라인', () => {
    expect(combinePresence([])).toBe('offline');
  });

  it('★ 하나라도 online 이면 온라인 — 다른 기기가 자리를 비워도', () => {
    expect(combinePresence(['away', 'online'])).toBe('online');
  });

  it('모두 away 면 자리비움', () => {
    expect(combinePresence(['away', 'away'])).toBe('away');
  });
});
