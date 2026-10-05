/**
 * 다른 응답에 끼워 보내는 사람 정보(작성자 · 담당자 · 명단). **이메일은 내보내지 않는다.**
 * 메시지 · 이슈 · 댓글 · 알림 · 채널 명단 · 웹훅 게시가 같은 세 필드를 각자 적고 있었다 —
 * 한 곳에 필드를 더하면 앱이 화면마다 다른 모양을 받는다.
 */
export const USER_SUMMARY_SELECT = { id: true, name: true, avatarUrl: true } as const;
