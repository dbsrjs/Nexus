import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_app/domain/models/channel.dart';
import 'package:nexus_app/features/channel/channel_controller.dart';

/// 채널을 카테고리로 묶는 규칙.
///
/// 서버는 채널과 카테고리를 **따로** 준다(`/channels`, `/categories`). 묶는 것은
/// 앱의 일이라 여기서 틀어질 수 있고, 화면으로는 "채널이 하나 안 보인다" 정도로만
/// 드러나 놓치기 쉽다. 특히 **카테고리를 지워도 채널은 남는다**(onDelete: SetNull)
/// 는 서버 설계 때문에 categoryId 가 null 인 채널이 실제로 생긴다.
void main() {
  Channel channel(String id, {String? categoryId, int position = 0}) => Channel(
        id: id,
        key: id,
        name: id,
        categoryId: categoryId,
        position: position,
      );

  List<ChannelGroup> groupsOf({
    required List<Channel> channels,
    required List<Category> categories,
  }) {
    final container = ProviderContainer(
      overrides: [
        channelsProvider.overrideWith((ref) async => channels),
        categoriesProvider.overrideWith((ref) async => categories),
      ],
    );
    addTearDown(container.dispose);

    // FutureProvider 를 먼저 해소해야 value 가 채워진다.
    container.read(channelsProvider);
    container.read(categoriesProvider);
    return container.read(channelGroupsProvider);
  }

  test('카테고리 순서대로 묶고, 그 안에서는 position 순으로 정렬한다', () async {
    final container = ProviderContainer(
      overrides: [
        channelsProvider.overrideWith((ref) async => [
              channel('b', categoryId: 'cat1', position: 1),
              channel('a', categoryId: 'cat1', position: 0),
              channel('c', categoryId: 'cat2'),
            ]),
        categoriesProvider.overrideWith((ref) async => const [
              Category(id: 'cat1', name: '개발', position: 0),
              Category(id: 'cat2', name: '기록', position: 1),
            ]),
      ],
    );
    addTearDown(container.dispose);

    await container.read(channelsProvider.future);
    await container.read(categoriesProvider.future);

    final groups = container.read(channelGroupsProvider);
    expect(groups.map((g) => g.title).toList(), ['개발', '기록']);
    expect(groups.first.channels.map((c) => c.id).toList(), ['a', 'b']);
  });

  test('빈 카테고리는 표시하지 않는다', () async {
    final container = ProviderContainer(
      overrides: [
        channelsProvider.overrideWith((ref) async => [
              channel('a', categoryId: 'cat1'),
            ]),
        categoriesProvider.overrideWith((ref) async => const [
              Category(id: 'cat1', name: '개발'),
              Category(id: 'cat2', name: '빈 카테고리'),
            ]),
      ],
    );
    addTearDown(container.dispose);

    await container.read(channelsProvider.future);
    await container.read(categoriesProvider.future);

    expect(container.read(channelGroupsProvider).map((g) => g.title).toList(),
        ['개발']);
  });

  test('★ categoryId 가 없는 채널은 기타로 모은다 — 카테고리를 지워도 채널은 남는다', () async {
    final container = ProviderContainer(
      overrides: [
        channelsProvider.overrideWith((ref) async => [
              channel('a', categoryId: 'cat1'),
              channel('떠돌이'),
            ]),
        categoriesProvider.overrideWith((ref) async => const [
              Category(id: 'cat1', name: '개발'),
            ]),
      ],
    );
    addTearDown(container.dispose);

    await container.read(channelsProvider.future);
    await container.read(categoriesProvider.future);

    final groups = container.read(channelGroupsProvider);
    expect(groups.map((g) => g.title).toList(), ['개발', '기타']);
    expect(groups.last.channels.single.id, '떠돌이');
  });

  test('아직 로딩 중이면 빈 목록 — 화면이 깨지지 않는다', () {
    expect(groupsOf(channels: const [], categories: const []), isEmpty);
  });
}
