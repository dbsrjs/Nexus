import 'package:freezed_annotation/freezed_annotation.dart';

part 'channel.freezed.dart';
part 'channel.g.dart';

/// `GET /api/spaces/:spaceId/channels` 의 한 항목.
///
/// 서버가 채널 레코드에 **내 읽음 상태와 안 읽은 수를 얹어서** 준다
/// (server/src/channels/channels.service.ts 의 ChannelListItem).
/// 안 읽은 수는 채널마다 기준 시각이 달라 raw SQL 한 방으로 센다 — 클라이언트가
/// 따로 계산하지 않는다.
@freezed
abstract class Channel with _$Channel {
  const factory Channel({
    required String id,
    required String key,
    required String name,
    String? topic,
    String? categoryId,
    @Default(false) bool isPrivate,
    @Default(0) int position,
    @Default(0) int unreadCount,

    /// 안 읽은 **멘션** 수. 안 읽은 수와 따로 온다 - 나를 부른 것이라
    /// 무게가 다르고 화면에서도 다른 색으로 그린다.
    @Default(0) int mentionCount,
    String? lastReadMessageId,
    @Default(false) bool muted,

    /// 내가 이 채널에 보낼 수 있는가(16단계 D26). 거짓이면 입력창 대신 「읽기 전용」을 보이고
    /// 답장 · 스레드 · 고정을 감춘다 — 리액션은 남는다. 서버가 안 주면(옛 응답) 보낼 수 있다고 본다.
    @Default(true) bool canSend,

    /// `text` · `dm`(17단계) · `voice`(20단계). 모르는 값은 일반 채널로 본다.
    @Default('text') String kind,

    /// DM 의 상대(17단계 D6). 일반 채널은 null. 상대가 스페이스를 떠나도 남는다.
    String? dmUserId,

    /// 마지막 최상위 메시지 시각 — DM 묶음을 최근순으로 줄 세우고 빈 DM 을 가린다(D10).
    DateTime? lastMessageAt,
  }) = _Channel;

  const Channel._();

  bool get isDm => kind == 'dm';

  /// 음성 채널(20단계) — 메시지 대신 통화가 열린다. 만든 뒤에는 종류가 바뀌지 않는다.
  bool get isVoice => kind == 'voice';

  factory Channel.fromJson(Map<String, dynamic> json) => _$ChannelFromJson(json);
}

/// 채널을 묶는 그룹. `GET /api/spaces/:spaceId/categories`
@freezed
abstract class Category with _$Category {
  const factory Category({
    required String id,
    required String name,
    @Default(0) int position,
  }) = _Category;

  factory Category.fromJson(Map<String, dynamic> json) => _$CategoryFromJson(json);
}
