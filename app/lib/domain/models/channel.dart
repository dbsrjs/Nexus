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
  }) = _Channel;

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
