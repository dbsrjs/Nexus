import 'package:freezed_annotation/freezed_annotation.dart';

part 'message.freezed.dart';
part 'message.g.dart';

/// 메시지에 실려 오는 작성자. 서버의 AUTHOR_SELECT 와 같은 모양이라
/// 이메일은 없다 (server/src/messages/messages.service.ts).
@freezed
abstract class MessageAuthor with _$MessageAuthor {
  const factory MessageAuthor({
    required String id,
    required String name,
    String? avatarUrl,
  }) = _MessageAuthor;

  factory MessageAuthor.fromJson(Map<String, dynamic> json) =>
      _$MessageAuthorFromJson(json);
}

/// 이모지 하나에 대한 요약. 서버가 접어서 준다 — 개수와 "내가 눌렀는지" 를
/// 클라이언트마다 다시 세지 않기 위해서다.
@freezed
abstract class MessageReaction with _$MessageReaction {
  const factory MessageReaction({
    required String emoji,
    required int count,

    /// **보는 사람 기준**이다. 그래서 소켓 브로드캐스트에는 실려 오지 않고,
    /// 앱이 자기 userId 로 계산한다.
    @Default(false) bool mine,
  }) = _MessageReaction;

  factory MessageReaction.fromJson(Map<String, dynamic> json) =>
      _$MessageReactionFromJson(json);
}

@freezed
abstract class Message with _$Message {
  const factory Message({
    required String id,
    required String channelId,
    required String body,
    required DateTime createdAt,
    required MessageAuthor author,
    DateTime? editedAt,

    /// 소프트 삭제. 서버는 행을 지우지 않고 **본문만 비워서** 내려보낸다
    /// (docs/백엔드-설계.md §3 보관 정책). 목록에서 빼지 않는 이유는,
    /// 빼 버리면 클라이언트가 이미 그린 메시지를 지울 근거가 없어서다.
    DateTime? deletedAt,

    /// 이모지별 요약. 서버가 목록에 함께 실어 준다.
    @Default(<MessageReaction>[]) List<MessageReaction> reactions,

    /// 값이 있으면 스레드 답글이다. 채널 타임라인에는 나오지 않는다.
    String? parentId,

    /// 이 메시지에 달린 답글 수. 답글 자신은 늘 0 이다.
    @Default(0) int replyCount,

    /// 마지막 답글 시각. 스레드 요약을 그릴 때 쓴다.
    DateTime? lastReplyAt,

    /// 낙관적 갱신용 — 서버 응답을 기다리는 중.
    /// 서버 응답에는 없는 필드라 기본값 false 로 들어온다.
    @Default(false) bool pending,

    /// 전송이 실패해 재시도를 기다리는 중. 역시 로컬 전용이다.
    @Default(false) bool failed,
  }) = _Message;

  const Message._();

  factory Message.fromJson(Map<String, dynamic> json) => _$MessageFromJson(json);

  bool get isDeleted => deletedAt != null;

  /// 스레드가 달린 최상위 메시지인지. 답글 요약을 그릴지 결정한다.
  bool get hasThread => parentId == null && replyCount > 0;

  /// 아직 서버에 닿지 않은 메시지. id 가 로컬에서 만든 임시 값이다.
  bool get isLocal => pending || failed;
}
