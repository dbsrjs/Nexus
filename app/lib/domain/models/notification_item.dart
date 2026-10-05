/// 알림 종류(18단계 설계 N1). 모르는 값이 오면 [other] — 서버가 종류를 늘려도 앱이 죽지 않는다.
enum NotificationType {
  mention,
  broadcast,
  dm,
  reply,
  other;

  static NotificationType fromWire(Object? value) => switch (value) {
        'mention' => mention,
        'broadcast' => broadcast,
        'dm' => dm,
        'reply' => reply,
        _ => other,
      };
}

/// 알림함의 한 줄(18단계 설계 §1). 목록 응답과 소켓 `notification:new` 가 같은 모양이다.
///
/// freezed 를 쓰지 않는다 — 읽음 하나만 바뀌고([withRead]) 캐시에 넣지도 않는다(N20).
/// [AttachmentItem] 과 같은 판단이다.
class NotificationItem {
  const NotificationItem({
    required this.id,
    required this.type,
    required this.read,
    required this.createdAt,
    required this.channelId,
    required this.messageId,
    required this.threadId,
    required this.actorId,
    required this.actorName,
    required this.actorAvatarUrl,
    required this.channelName,
    required this.isDm,
    required this.body,
    required this.deleted,
  });

  final String id;
  final NotificationType type;
  final bool read;
  final DateTime createdAt;
  final String channelId;
  final String messageId;

  /// 답글이면 부모 id — 누르면 스레드로 연다(N21).
  final String? threadId;

  final String actorId;
  final String actorName;
  final String? actorAvatarUrl;
  final String channelName;
  final bool isDm;

  /// 지금 본문(원문 마크다운). 삭제됐으면 ''.
  final String body;
  final bool deleted;

  NotificationItem withRead(bool value) => NotificationItem(
        id: id,
        type: type,
        read: value,
        createdAt: createdAt,
        channelId: channelId,
        messageId: messageId,
        threadId: threadId,
        actorId: actorId,
        actorName: actorName,
        actorAvatarUrl: actorAvatarUrl,
        channelName: channelName,
        isDm: isDm,
        body: body,
        deleted: deleted,
      );

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    final actor = (json['actor'] as Map?)?.cast<String, dynamic>() ?? const {};
    final channel = (json['channel'] as Map?)?.cast<String, dynamic>() ?? const {};
    return NotificationItem(
      id: json['id'] as String,
      type: NotificationType.fromWire(json['type']),
      read: json['read'] == true,
      createdAt: DateTime.parse(json['createdAt'] as String),
      channelId: json['channelId'] as String,
      messageId: json['messageId'] as String,
      threadId: json['threadId'] as String?,
      actorId: actor['id'] as String? ?? '',
      actorName: actor['name'] as String? ?? '',
      actorAvatarUrl: actor['avatarUrl'] as String?,
      channelName: channel['name'] as String? ?? '',
      isDm: channel['kind'] == 'dm',
      body: json['body'] as String? ?? '',
      deleted: json['deleted'] == true,
    );
  }
}

/// 사용자의 알림 스위치(N9). 사용자 단위다.
class NotificationSettings {
  const NotificationSettings({
    required this.mentions,
    required this.broadcast,
    required this.dms,
    required this.replies,
  });

  final bool mentions;
  final bool broadcast;
  final bool dms;
  final bool replies;

  factory NotificationSettings.fromJson(Map<String, dynamic> json) => NotificationSettings(
        // 모르면 켜진 것으로 본다 — 서버 기본값과 같다.
        mentions: json['mentions'] != false,
        broadcast: json['broadcast'] != false,
        dms: json['dms'] != false,
        replies: json['replies'] != false,
      );
}
