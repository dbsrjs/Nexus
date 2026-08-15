import '../../domain/models/message.dart';

/// 서버 → 클라이언트 소켓 이벤트.
///
/// 계약은 docs/superpowers/specs/2026-08-14-실시간-최소-design.md §5 다.
/// `message` 페이로드는 REST 응답과 **같은 모양**이라 파서를 따로 두지 않는다.
sealed class SocketEvent {
  const SocketEvent();
}

/// 연결이 (재)수립됐다. 끊겨 있는 동안 놓친 것이 있으므로 catch-up 이 필요하다.
class SocketConnected extends SocketEvent {
  const SocketConnected();
}

class SocketDisconnected extends SocketEvent {
  const SocketDisconnected(this.reason);

  final String? reason;
}

/// 핸드셰이크 거부. 토큰 만료·위조 등 — 재시도해도 같은 결과다.
class SocketUnauthorized extends SocketEvent {
  const SocketUnauthorized();
}

class MessageNew extends SocketEvent {
  const MessageNew({
    required this.spaceId,
    required this.channelId,
    required this.message,
  });

  final String spaceId;
  final String channelId;
  final Message message;
}

class MessageEdited extends SocketEvent {
  const MessageEdited({
    required this.spaceId,
    required this.channelId,
    required this.message,
  });

  final String spaceId;
  final String channelId;
  final Message message;
}

class MessageDeleted extends SocketEvent {
  const MessageDeleted({
    required this.spaceId,
    required this.channelId,
    required this.messageId,
  });

  final String spaceId;
  final String channelId;
  final String messageId;
}

/// 다른 기기에서 읽음 위치가 바뀌었다. 룸은 `user:{id}` 라 내 모든 기기에 온다.
class ReadSynced extends SocketEvent {
  const ReadSynced({
    required this.spaceId,
    required this.channelId,
    required this.lastReadMessageId,
  });

  final String spaceId;
  final String channelId;
  final String? lastReadMessageId;
}

/// 볼 수 있는 채널 집합이 바뀌었다. 룸을 다시 계산해야 한다.
class RoomsInvalidated extends SocketEvent {
  const RoomsInvalidated(this.reason);

  /// `channel.created` · `channel.visibility` · `channel.joined` · `member.role`
  final String? reason;
}
