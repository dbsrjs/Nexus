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

/// 스레드에 답글이 달렸다.
///
/// **채널 룸으로 온다.** 스레드를 연 사람만 받는 룸을 따로 두면, 채널을 보고
/// 있는 사람에게 답글 수를 알릴 경로가 하나 더 필요해진다. 갱신된 `replyCount`
/// 를 함께 실어 보내므로 채널 화면이 목록을 다시 받을 필요가 없다.
class ThreadReply extends SocketEvent {
  const ThreadReply({
    required this.spaceId,
    required this.channelId,
    required this.parentId,
    required this.message,
    required this.replyCount,
    this.lastReplyAt,
  });

  final String spaceId;
  final String channelId;
  final String parentId;
  final Message message;
  final int replyCount;
  final DateTime? lastReplyAt;
}

/// 리액션이 바뀌었다(추가·제거 둘 다).
///
/// **서버는 접힌 요약이 아니라 `(emoji, userId)` 쌍을 보낸다.** "내가 눌렀는지"
/// 는 받는 사람마다 답이 다른 값이라 브로드캐스트에 실을 수 없기 때문이다.
/// 접는 것은 앱의 일이다.
class ReactionChanged extends SocketEvent {
  const ReactionChanged({
    required this.spaceId,
    required this.channelId,
    required this.messageId,
    required this.entries,
  });

  final String spaceId;
  final String channelId;
  final String messageId;
  final List<ReactionEntry> entries;
}

/// 누가 어떤 이모지를 눌렀는지. 접기 전의 날 것이다.
class ReactionEntry {
  const ReactionEntry({required this.emoji, required this.userId});

  final String emoji;
  final String userId;
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
