/**
 * 알림 종류(18단계 설계 N1). DB 컬럼은 문자열이다 — 늘어날 수 있어 enum 으로 묶지 않았다.
 *
 * - `mention`   나를 직접 부름(`<@나>`)
 * - `broadcast` `@channel` · `@everyone`
 * - `dm`        DM 에 온 메시지
 * - `reply`     **내가 쓴 메시지**의 스레드에 달린 답글
 */
export const NOTIFICATION_TYPES = ['mention', 'broadcast', 'dm', 'reply'] as const;
export type NotificationType = (typeof NOTIFICATION_TYPES)[number];

/** 이 사람이 이 메시지를 알림으로 받을 이유. 여럿이 겹칠 수 있다. */
export type NotificationReasons = Record<NotificationType, boolean>;

/** 사용자의 종류별 스위치(N9). 켜져 있으면 true. */
export type NotificationPrefs = Record<NotificationType, boolean>;

/**
 * 겹칠 때 고르는 순서(N2) — 「나만 겨냥했는가」의 순서다. DM 에서 나를 부르고 내 글의
 * 답글이기까지 해도 알림은 하나다.
 */
const PRIORITY: NotificationType[] = ['mention', 'dm', 'reply', 'broadcast'];

/**
 * 받는 사람 한 명에게 만들 알림 종류. 없으면 null.
 *
 * - 꺼진 종류는 건너뛰고 **다음 이유로 내려간다**(N2) — DM 알림을 껐어도 DM 에서 나를
 *   부르면 멘션으로 온다
 * - **음소거한 채널은 직접 멘션만**(N7) — 14단계 D17 이 「나를 부른 것은 음소거해도
 *   놓치면 안 된다」로 정했다. 뱃지와 같은 규칙이다
 *
 * DB 를 보지 않는 순수 함수라 갈래를 단위 테스트로 못 박는다.
 */
export function pickNotificationType(
  reasons: NotificationReasons,
  prefs: NotificationPrefs,
  muted: boolean,
): NotificationType | null {
  for (const type of PRIORITY) {
    if (!reasons[type] || !prefs[type]) continue;
    if (muted && type !== 'mention') continue;
    return type;
  }
  return null;
}
