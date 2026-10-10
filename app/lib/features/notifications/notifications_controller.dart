import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/api/api_failure.dart';
import '../../data/api/notifications_api.dart';
import '../../data/socket/socket_event.dart';
import '../../domain/models/notification_item.dart';
import '../../shared/markdown/plain_text.dart';
import '../auth/auth_controller.dart';
import '../realtime/socket_controller.dart';
import '../space/space_controller.dart';

export '../../domain/models/notification_item.dart';

final notificationsApiProvider = Provider<NotificationsApi>(
  (ref) => NotificationsApi(ref.watch(apiClientProvider)),
);

/// 지금 스페이스의 안 읽은 알림 수(18단계 N19). **REST 처음 값 + 소켓.**
///
/// 소켓으로 수를 직접 더하고 빼지 않는다 — 그 알림이 볼 수 있는 채널의 것인지(N15)는 서버만
/// 알아서, 이벤트가 올 때마다 다시 센다(한 줄짜리 요청이다). 스페이스에 들어갈 때 · 소켓이 다시
/// 붙을 때(끊긴 동안 놓친 것) · 볼 수 있는 채널이 바뀔 때도 다시 센다.
///
/// 셸(채널 판 · 모바일 탭)이 보지만 **`main.dart` 가 뿌리에서 붙든다** — 셸 밖(설정 창)에
/// 다녀오는 동안 구독자가 0 이 되면 Riverpod 3 이 멈춰 두기 때문이다(CLAUDE.md §2).
class UnreadNotificationsNotifier extends Notifier<int> {
  @override
  int build() {
    ref.listen<String?>(
      currentSpaceIdProvider,
      (_, id) => _load(id),
      fireImmediately: true,
    );
    ref.listen<AsyncValue<SocketEvent>>(socketEventsProvider, (_, next) {
      final spaceId = ref.read(currentSpaceIdProvider);
      final reload = switch (next.value) {
        NotificationNew(spaceId: final s) ||
        NotificationRead(spaceId: final s) => s == spaceId,
        SocketConnected() || RoomsInvalidated() => true,
        _ => false,
      };
      if (reload) _load(spaceId);
    });
    return 0;
  }

  Future<void> _load(String? spaceId) async {
    if (spaceId == null) {
      state = 0;
      return;
    }
    try {
      final count = await ref
          .read(notificationsApiProvider)
          .unreadCount(spaceId);
      // 다른 스페이스로 옮겨 갔으면 늦게 온 값을 버린다.
      if (ref.read(currentSpaceIdProvider) == spaceId) state = count;
    } catch (_) {
      // 오프라인이면 마지막 수를 둔다 — 0 으로 덮으면 「놓친 것이 없다」로 읽힌다.
    }
  }
}

final unreadNotificationsProvider =
    NotifierProvider<UnreadNotificationsNotifier, int>(
      UnreadNotificationsNotifier.new,
    );

/// 알림함 화면의 상태.
class NotificationsState {
  const NotificationsState({
    this.items = const [],
    this.nextCursor,
    this.loading = true,
    this.loadingMore = false,
    this.failure,
  });

  final List<NotificationItem> items;
  final String? nextCursor;

  /// 첫 쪽을 받는 중.
  final bool loading;
  final bool loadingMore;

  /// 첫 쪽을 못 받았다. 다음 쪽 실패는 여기 싣지 않는다 — 받은 줄을 지우지 않는다.
  final ApiFailure? failure;

  NotificationsState copyWith({
    List<NotificationItem>? items,
    String? nextCursor,
    bool clearCursor = false,
    bool? loading,
    bool? loadingMore,
    ApiFailure? failure,
    bool clearFailure = false,
  }) => NotificationsState(
    items: items ?? this.items,
    nextCursor: clearCursor ? null : (nextCursor ?? this.nextCursor),
    loading: loading ?? this.loading,
    loadingMore: loadingMore ?? this.loadingMore,
    failure: clearFailure ? null : (failure ?? this.failure),
  );
}

/// 지금 스페이스의 알림 목록(18단계 N20). **캐시하지 않는다** — 파일 목록과 같은 판단이다.
/// 화면을 닫으면 버리고(autoDispose), 열면 다시 받는다.
///
/// 열려 있는 동안 소켓을 따라간다 — 새 알림은 맨 위에 붙이고, 다른 기기에서 읽은 것은 읽음으로.
class NotificationsNotifier extends Notifier<NotificationsState> {
  @override
  NotificationsState build() {
    final spaceId = ref.watch(currentSpaceIdProvider);
    ref.listen<AsyncValue<SocketEvent>>(socketEventsProvider, (_, next) {
      final event = next.value;
      switch (event) {
        case NotificationNew() when event.spaceId == spaceId:
          // 같은 알림이 두 번 오지 않게(다시 받은 첫 쪽과 겹칠 수 있다).
          if (state.items.any((n) => n.id == event.notification.id)) return;
          state = state.copyWith(items: [event.notification, ...state.items]);
        case NotificationRead() when event.spaceId == spaceId:
          _applyRead(event.ids);
        case SocketConnected():
        case RoomsInvalidated():
          // 끊긴 동안 놓친 것 · 볼 수 있는 채널이 바뀐 것 — 첫 쪽을 다시 받는다.
          refresh();
        default:
          break;
      }
    });
    Future.microtask(refresh);
    return const NotificationsState();
  }

  String? get _spaceId => ref.read(currentSpaceIdProvider);

  Future<void> refresh() async {
    final spaceId = _spaceId;
    if (spaceId == null) return;
    try {
      final page = await ref.read(notificationsApiProvider).list(spaceId);
      if (!ref.mounted || _spaceId != spaceId) return;
      state = NotificationsState(
        items: page.items,
        nextCursor: page.nextCursor,
        loading: false,
      );
    } on ApiException catch (e) {
      if (!ref.mounted) return;
      // 이미 받은 줄이 있으면 지우지 않는다 — 다시 받기 실패가 목록을 비우면 안 된다.
      state = state.items.isEmpty
          ? state.copyWith(loading: false, failure: e.failure)
          : state.copyWith(loading: false);
    }
  }

  Future<void> loadMore() async {
    final spaceId = _spaceId;
    final cursor = state.nextCursor;
    if (spaceId == null || cursor == null || state.loadingMore) return;
    state = state.copyWith(loadingMore: true);
    try {
      final page = await ref
          .read(notificationsApiProvider)
          .list(spaceId, cursor: cursor);
      if (!ref.mounted) return;
      final known = state.items.map((n) => n.id).toSet();
      state = state.copyWith(
        items: [
          ...state.items,
          ...page.items.where((n) => !known.contains(n.id)),
        ],
        nextCursor: page.nextCursor,
        clearCursor: page.nextCursor == null,
        loadingMore: false,
      );
    } on ApiException {
      if (ref.mounted) state = state.copyWith(loadingMore: false);
    }
  }

  /// 하나 읽음(N21). 화면을 먼저 바꾼다 — 누르면 곧바로 그 자리로 가므로 응답을 기다리지 않는다.
  /// 실패해도 되돌리지 않는다: 다음에 목록을 받으면 서버 값으로 맞춰진다.
  Future<void> markRead(NotificationItem item) async {
    final spaceId = _spaceId;
    if (spaceId == null || item.read) return;
    _applyRead([item.id]);
    try {
      await ref.read(notificationsApiProvider).markRead(spaceId, item.id);
    } on ApiException {
      // 위 주석대로 — 조용히 넘긴다. 수는 소켓 · 재연결 때 서버 값으로 다시 센다.
    }
  }

  /// 「모두 읽음」. 실패하면 던진다 — 화면이 토스트로 알린다.
  Future<void> markAllRead() async {
    final spaceId = _spaceId;
    if (spaceId == null) return;
    await ref.read(notificationsApiProvider).markAllRead(spaceId);
    if (ref.mounted) _applyRead(null);
  }

  void _applyRead(List<String>? ids) {
    final set = ids?.toSet();
    state = state.copyWith(
      items: [
        for (final n in state.items)
          (set == null || set.contains(n.id)) && !n.read ? n.withRead(true) : n,
      ],
    );
  }
}

final notificationsProvider =
    NotifierProvider.autoDispose<NotificationsNotifier, NotificationsState>(
      NotificationsNotifier.new,
    );

/// 한 줄의 머리 문구(N22) — 「가나 님이 #개발 에서 멘션했습니다」. DM 은 채널 이름이 뜻이 없다.
String notificationHeadline(NotificationItem n) {
  final who = n.actorName.isEmpty ? '알 수 없는 사람' : n.actorName;
  final where = n.isDm ? '' : ' #${n.channelName}에서';
  return switch (n.type) {
    NotificationType.mention => '$who 님이$where 나를 멘션했습니다',
    NotificationType.broadcast => '$who 님이$where 모두를 불렀습니다',
    NotificationType.dm => '$who 님이 메시지를 보냈습니다',
    NotificationType.reply => '$who 님이$where 내 글에 답글을 달았습니다',
    NotificationType.other => '$who 님의 새 소식',
  };
}

/// 한 줄의 본문 미리보기. 원문 마크다운이라 서식을 벗기고 `<@id>` 를 이름으로 바꾼다.
/// 알림함과 OS 알림(«마지막»)이 같은 문구를 쓴다.
String notificationPreview(NotificationItem n, Map<String, String> names) =>
    n.deleted
    ? '삭제된 메시지입니다'
    : n.body.isEmpty
    ? '파일을 보냈습니다'
    : toPlainText(n.body, names: names);

/// 누르면 갈 곳(N21) — 답글이면 스레드(셸 밖, 덮어서), 아니면 채널(셸 안).
String notificationTarget(String spaceId, NotificationItem n) {
  final channel = '/s/$spaceId/c/${n.channelId}';
  return n.threadId == null ? channel : '$channel/t/${n.threadId}';
}
