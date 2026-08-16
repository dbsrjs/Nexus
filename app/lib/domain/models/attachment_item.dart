import 'message.dart';

/// 스페이스 파일 목록의 한 줄.
///
/// [MessageAttachment] 에 **어느 채널·어느 메시지의 것인지**를 더한 값이다.
/// 메시지에 실려 올 때는 그 맥락이 이미 있어 담지 않지만, 파일 목록은 여러
/// 채널을 가로지르므로 필요하다.
class AttachmentItem {
  const AttachmentItem({
    required this.attachment,
    required this.channelId,
    this.messageId,
  });

  final MessageAttachment attachment;
  final String channelId;

  /// 목록에는 연결된 것만 나오므로 사실상 늘 값이 있다.
  final String? messageId;

  factory AttachmentItem.fromJson(Map<String, dynamic> json) => AttachmentItem(
        attachment: MessageAttachment.fromJson(json),
        channelId: json['channelId'] as String,
        messageId: json['messageId'] as String?,
      );
}
