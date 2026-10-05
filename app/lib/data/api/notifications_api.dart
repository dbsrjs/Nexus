
import '../../domain/models/notification_item.dart';
import 'api_client.dart';
import 'api_failure.dart';

/// 알림 한 쪽. 커서가 null 이면 끝이다.
class NotificationPage {
  const NotificationPage({required this.items, required this.nextCursor});

  final List<NotificationItem> items;
  final String? nextCursor;
}

/// 알림함 · 알림 스위치(18단계). 실패는 전부 [ApiException] 으로 올린다.
class NotificationsApi {
  NotificationsApi(this._client);

  final ApiClient _client;

  /// GET /api/spaces/:spaceId/notifications — 최신순. 볼 수 없는 채널의 것은 서버가 뺀다.
  Future<NotificationPage> list(
    String spaceId, {
    String? cursor,
    int limit = 30,
  }) => guardApi(() async {
    final res = await _client.dio.get<Map<String, dynamic>>(
      '/spaces/$spaceId/notifications',
      queryParameters: {'limit': limit, 'cursor': ?cursor},
    );
    final items = (res.data?['items'] as List<dynamic>? ?? const [])
        .cast<Map<String, dynamic>>()
        .map(NotificationItem.fromJson)
        .toList(growable: false);
    return NotificationPage(
      items: items,
      nextCursor: res.data?['nextCursor'] as String?,
    );
  });

  /// GET /api/spaces/:spaceId/notifications/unread-count
  Future<int> unreadCount(String spaceId) => guardApi(() async {
    final res = await _client.dio.get<Map<String, dynamic>>(
      '/spaces/$spaceId/notifications/unread-count',
    );
    return (res.data?['count'] as num?)?.toInt() ?? 0;
  });

  /// POST .../notifications/:id/read — 멱등.
  Future<void> markRead(String spaceId, String id) => guardApi(() async {
    await _client.dio.post<void>('/spaces/$spaceId/notifications/$id/read');
  });

  /// POST .../notifications/read-all
  Future<void> markAllRead(String spaceId) => guardApi(() async {
    await _client.dio.post<void>('/spaces/$spaceId/notifications/read-all');
  });

  /// GET /api/me/notification-settings
  Future<NotificationSettings> settings() => guardApi(() async {
    final res = await _client.dio.get<Map<String, dynamic>>(
      '/me/notification-settings',
    );
    return NotificationSettings.fromJson(res.data ?? const {});
  });

  /// PATCH /api/me/notification-settings — 바꾼 것만 보낸다(N10). 응답은 넷 다.
  Future<NotificationSettings> updateSettings({
    bool? mentions,
    bool? broadcast,
    bool? dms,
    bool? replies,
  }) => guardApi(() async {
    final res = await _client.dio.patch<Map<String, dynamic>>(
      '/me/notification-settings',
      data: {
        'mentions': ?mentions,
        'broadcast': ?broadcast,
        'dms': ?dms,
        'replies': ?replies,
      },
    );
    return NotificationSettings.fromJson(res.data ?? const {});
  });
}
