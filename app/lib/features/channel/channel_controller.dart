import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/api/channels_api.dart';
import '../../domain/models/channel.dart';
import '../auth/auth_controller.dart';
import '../space/space_controller.dart';

final channelsApiProvider =
    Provider<ChannelsApi>((ref) => ChannelsApi(ref.watch(apiClientProvider)));

/// 현재 스페이스의 채널 목록. 안 읽은 수가 함께 온다.
///
/// 스페이스가 바뀌면 자동으로 다시 불러온다 — `currentSpaceIdProvider` 를
/// watch 하기 때문이다.
final channelsProvider = FutureProvider<List<Channel>>((ref) async {
  final spaceId = ref.watch(currentSpaceIdProvider);
  if (spaceId == null) return const [];
  return ref.watch(channelsApiProvider).list(spaceId);
});

final categoriesProvider = FutureProvider<List<Category>>((ref) async {
  final spaceId = ref.watch(currentSpaceIdProvider);
  if (spaceId == null) return const [];
  return ref.watch(channelsApiProvider).listCategories(spaceId);
});

/// 현재 열려 있는 채널. 라우트(`/s/:spaceId/c/:channelId`)가 진실의 원천이고
/// 셸이 그 값을 여기에 실어 준다 — 스페이스와 같은 방식이다.
class CurrentChannelId extends Notifier<String?> {
  @override
  String? build() => null;

  void set(String? id) => state = id;
}

final currentChannelIdProvider =
    NotifierProvider<CurrentChannelId, String?>(CurrentChannelId.new);

final currentChannelProvider = Provider<Channel?>((ref) {
  final id = ref.watch(currentChannelIdProvider);
  if (id == null) return null;

  final channels = ref.watch(channelsProvider).value;
  if (channels == null) return null;

  for (final channel in channels) {
    if (channel.id == id) return channel;
  }
  return null;
});

/// 카테고리별로 묶은 채널. 카테고리가 없는 채널은 마지막에 미분류로 모은다
/// (카테고리를 지워도 채널은 남기 때문에 — onDelete: SetNull).
class ChannelGroup {
  const ChannelGroup({required this.title, required this.channels});

  final String title;
  final List<Channel> channels;
}

final channelGroupsProvider = Provider<List<ChannelGroup>>((ref) {
  final channels = ref.watch(channelsProvider).value ?? const <Channel>[];
  final categories = ref.watch(categoriesProvider).value ?? const <Category>[];

  final groups = <ChannelGroup>[];

  for (final category in categories) {
    final inCategory =
        channels.where((c) => c.categoryId == category.id).toList()
          ..sort((a, b) => a.position.compareTo(b.position));
    if (inCategory.isNotEmpty) {
      groups.add(ChannelGroup(title: category.name, channels: inCategory));
    }
  }

  final uncategorized = channels.where((c) => c.categoryId == null).toList()
    ..sort((a, b) => a.position.compareTo(b.position));
  if (uncategorized.isNotEmpty) {
    groups.add(ChannelGroup(title: '기타', channels: uncategorized));
  }

  return groups;
});
