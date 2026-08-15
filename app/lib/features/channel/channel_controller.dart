import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/api/channels_api.dart';
import '../../domain/models/channel.dart';
import '../auth/auth_controller.dart';
import '../space/space_controller.dart';

final channelsApiProvider =
    Provider<ChannelsApi>((ref) => ChannelsApi(ref.watch(apiClientProvider)));

/// 현재 스페이스의 채널 목록. 안 읽은 수가 함께 온다.
///
/// 스페이스와 마찬가지로 **캐시를 구독하고 서버는 뒤에서 갱신한다.**
/// 스페이스가 바뀌면 자동으로 다시 불러온다 — `currentSpaceIdProvider` 를
/// watch 하기 때문이다.
final channelsProvider = StreamProvider<List<Channel>>((ref) {
  final spaceId = ref.watch(currentSpaceIdProvider);
  if (spaceId == null) return Stream.value(const []);

  final repository = ref.watch(workspaceRepositoryProvider);
  Future.microtask(() => repository.refreshChannels(spaceId));
  return repository.watchChannels(spaceId);
});

/// 카테고리. 채널과 **같은 방식**이다 — 캐시를 구독하고 서버는 뒤에서 갱신한다.
///
/// 한때 이것만 `FutureProvider` 로 REST 를 한 번 부르고 끝냈다가, 오프라인에서
/// 빈 목록을 받으면 서버가 돌아와도 회복되지 않는 버그가 났다. 같은 화면을
/// 그리는 두 목록은 같은 공급원을 봐야 한다.
final categoriesProvider = StreamProvider<List<Category>>((ref) {
  final spaceId = ref.watch(currentSpaceIdProvider);
  if (spaceId == null) return Stream.value(const []);

  final repository = ref.watch(workspaceRepositoryProvider);
  Future.microtask(() => repository.refreshCategories(spaceId));
  return repository.watchCategories(spaceId);
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
  final placed = <String>{};

  for (final category in categories) {
    final inCategory =
        channels.where((c) => c.categoryId == category.id).toList()
          ..sort((a, b) => a.position.compareTo(b.position));
    if (inCategory.isNotEmpty) {
      groups.add(ChannelGroup(title: category.name, channels: inCategory));
      placed.addAll(inCategory.map((c) => c.id));
    }
  }

  // **어느 카테고리에도 들어가지 못한 채널은 전부 '기타'로 모은다.**
  // categoryId 가 null 인 경우뿐 아니라, categoryId 는 있는데 그 카테고리를
  // 받지 못한 경우도 포함한다 — 카테고리도 캐시하지만 **처음 켠 기기가
  // 오프라인이면** 아직 받은 적이 없어 비어 있다. 그때 채널이 통째로
  // 사라지면 안 된다.
  final rest = channels.where((c) => !placed.contains(c.id)).toList()
    ..sort((a, b) => a.position.compareTo(b.position));
  if (rest.isNotEmpty) {
    groups.add(ChannelGroup(title: '기타', channels: rest));
  }

  return groups;
});
