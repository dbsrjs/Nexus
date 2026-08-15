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

    /// 낙관적 갱신용 — 서버 응답을 기다리는 중.
    /// 서버 응답에는 없는 필드라 기본값 false 로 들어온다.
    @Default(false) bool pending,

    /// 전송이 실패해 재시도를 기다리는 중. 역시 로컬 전용이다.
    @Default(false) bool failed,
  }) = _Message;

  const Message._();

  factory Message.fromJson(Map<String, dynamic> json) => _$MessageFromJson(json);

  bool get isDeleted => deletedAt != null;

  /// 아직 서버에 닿지 않은 메시지. id 가 로컬에서 만든 임시 값이다.
  bool get isLocal => pending || failed;
}
