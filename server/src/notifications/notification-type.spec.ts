import {
  NotificationPrefs,
  NotificationReasons,
  pickNotificationType,
} from './notification-type';

/**
 * 알림 고르기(18단계 설계 N2 · N7). 실 DB 로는 `npm run check:notifications` 가 본다 —
 * 여기는 갈래가 많은 판정만 못 박는다.
 */
const none: NotificationReasons = {
  mention: false,
  broadcast: false,
  dm: false,
  reply: false,
};
const allOn: NotificationPrefs = {
  mention: true,
  broadcast: true,
  dm: true,
  reply: true,
};

const reasons = (r: Partial<NotificationReasons>) => ({ ...none, ...r });

describe('pickNotificationType', () => {
  it('이유가 없으면 만들지 않는다', () => {
    expect(pickNotificationType(none, allOn, false)).toBeNull();
  });

  it('이유가 하나면 그 종류', () => {
    expect(pickNotificationType(reasons({ dm: true }), allOn, false)).toBe('dm');
    expect(pickNotificationType(reasons({ reply: true }), allOn, false)).toBe('reply');
    expect(pickNotificationType(reasons({ broadcast: true }), allOn, false)).toBe(
      'broadcast',
    );
  });

  it('겹치면 mention > dm > reply > broadcast 로 하나만', () => {
    const every = reasons({ mention: true, dm: true, reply: true, broadcast: true });
    expect(pickNotificationType(every, allOn, false)).toBe('mention');
    expect(pickNotificationType(reasons({ dm: true, reply: true }), allOn, false)).toBe(
      'dm',
    );
    expect(
      pickNotificationType(reasons({ reply: true, broadcast: true }), allOn, false),
    ).toBe('reply');
  });

  it('꺼진 종류는 건너뛰고 다음 이유로 내려간다', () => {
    const prefs = { ...allOn, mention: false };
    expect(pickNotificationType(reasons({ mention: true, dm: true }), prefs, false)).toBe(
      'dm',
    );
    expect(pickNotificationType(reasons({ mention: true }), prefs, false)).toBeNull();
  });

  it('DM 을 꺼도 DM 에서 나를 부르면 멘션으로 온다', () => {
    const prefs = { ...allOn, dm: false };
    expect(pickNotificationType(reasons({ mention: true, dm: true }), prefs, false)).toBe(
      'mention',
    );
    expect(pickNotificationType(reasons({ dm: true }), prefs, false)).toBeNull();
  });

  it('음소거한 채널은 직접 멘션만 알린다', () => {
    expect(pickNotificationType(reasons({ mention: true }), allOn, true)).toBe('mention');
    expect(pickNotificationType(reasons({ broadcast: true }), allOn, true)).toBeNull();
    expect(pickNotificationType(reasons({ dm: true }), allOn, true)).toBeNull();
    expect(pickNotificationType(reasons({ reply: true }), allOn, true)).toBeNull();
    expect(
      pickNotificationType(reasons({ mention: true, reply: true }), allOn, true),
    ).toBe('mention');
  });

  it('음소거에 멘션 스위치까지 꺼져 있으면 아무것도 없다', () => {
    const prefs = { ...allOn, mention: false };
    expect(
      pickNotificationType(reasons({ mention: true, dm: true }), prefs, true),
    ).toBeNull();
  });
});
