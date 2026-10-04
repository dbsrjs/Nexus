import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/api/channels_api.dart';
import '../../domain/models/channel_access.dart';
import '../../domain/models/space.dart';
import '../auth/auth_controller.dart';

final channelsApiProvider =
    Provider<ChannelsApi>((ref) => ChannelsApi(ref.watch(apiClientProvider)));

/// 채널 설정 창의 섹션(16단계 설계 D16). `slug` 는 주소에 쓰인다.
enum ChannelSettingsSection {
  overview('overview', '개요'),
  members('members', '멤버'),
  permissions('permissions', '권한');

  const ChannelSettingsSection(this.slug, this.label);

  final String slug;
  final String label;

  /// 볼 수 있는 섹션만(설계 §3). 명단은 비공개 채널에만 있고(D19), 권한은 공개 채널에서
  /// admin+ 만 고친다 — 비공개 채널은 명단이 정하므로 역할 가림이 없다(D22).
  static List<ChannelSettingsSection> visibleFor({
    required bool isPrivate,
    required SpaceRole role,
  }) =>
      [
        overview,
        if (isPrivate) members,
        if (!isPrivate && role.atLeast(SpaceRole.admin)) permissions,
      ];

  static ChannelSettingsSection? parse(String? slug) {
    for (final section in values) {
      if (section.slug == slug) return section;
    }
    return null;
  }
}

String channelSettingsLocation(
  String spaceId,
  String channelId,
  ChannelSettingsSection? section,
) {
  final base = '/s/$spaceId/c/$channelId/settings';
  return section == null ? base : '$base/${section.slug}';
}

typedef ChannelKey = ({String spaceId, String channelId});

/// 비공개 채널 명단. 캐시하지 않는다 — 설정 창을 열 때만 본다.
final channelMembersProvider =
    FutureProvider.family<List<ChannelMemberView>, ChannelKey>(
  (ref, key) => ref.watch(channelsApiProvider).members(key.spaceId, key.channelId),
);

/// 공개 채널의 역할별 권한(admin+).
final channelPermissionsProvider =
    FutureProvider.family<List<RolePermission>, ChannelKey>(
  (ref, key) => ref.watch(channelsApiProvider).permissions(key.spaceId, key.channelId),
);

/// 명단 한 줄에 보일 동작(16단계 D18). 서버 규칙을 그대로 비춘다 — 눌러 봐야 실패할 버튼을
/// 만들지 않는다(§3-7).
enum MemberRowAction {
  /// 본인 — 나가기.
  leave,

  /// 남 — 빼기(admin+).
  remove,

  /// 아무것도 없다.
  none,
}

MemberRowAction memberRowAction({
  required bool self,
  required SpaceRole me,
}) {
  if (self) return MemberRowAction.leave;
  if (me.atLeast(SpaceRole.admin)) return MemberRowAction.remove;
  return MemberRowAction.none;
}
