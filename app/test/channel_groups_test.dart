import 'dart:async';

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

  /// 채널 목록은 6단계에서 drift 캐시를 구독하는 Stream 으로 바뀌었다.
  /// 테스트는 그 스트림만 갈아 끼운다 — 묶는 규칙 자체는 그대로다.
  Future<List<ChannelGroup>> groupsOf({
    required List<Channel> channels,
    required List<Category> categories,
  }) async {
    final container = ProviderContainer(
      overrides: [
        channelsProvider.overrideWith((ref) => Stream.value(channels)),
        categoriesProvider.overrideWith((ref) => Stream.value(categories)),
      ],
    );
    addTearDown(container.dispose);

    // 구독을 걸어 두고 한 틱 흘려보낸다. 스트림은 마이크로태스크로 값을 내므로
    // 이 시점에는 채워져 있다.
    container.listen(channelsProvider, (_, _) {}, fireImmediately: true);
    container.listen(categoriesProvider, (_, _) {}, fireImmediately: true);
    await Future<void>.delayed(const Duration(milliseconds: 10));

    return container.read(channelGroupsProvider);
  }

  test('카테고리 순서대로 묶고, 그 안에서는 position 순으로 정렬한다', () async {
    final groups = await groupsOf(
      channels: [
        channel('b', categoryId: 'cat1', position: 1),
        channel('a', categoryId: 'cat1', position: 0),
        channel('c', categoryId: 'cat2'),
      ],
      categories: const [
        Category(id: 'cat1', name: '개발', position: 0),
        Category(id: 'cat2', name: '기록', position: 1),
      ],
    );

    expect(groups.map((g) => g.title).toList(), ['개발', '기록']);
    expect(groups.first.channels.map((c) => c.id).toList(), ['a', 'b']);
  });

  test('빈 카테고리는 표시하지 않는다', () async {
    final groups = await groupsOf(
      channels: [channel('a', categoryId: 'cat1')],
      categories: const [
        Category(id: 'cat1', name: '개발'),
        Category(id: 'cat2', name: '빈 카테고리'),
      ],
    );

    expect(groups.map((g) => g.title).toList(), ['개발']);
  });

  test('★ categoryId 가 없는 채널은 기타로 모은다 — 카테고리를 지워도 채널은 남는다', () async {
    final groups = await groupsOf(
      channels: [channel('a', categoryId: 'cat1'), channel('떠돌이')],
      categories: const [Category(id: 'cat1', name: '개발')],
    );

    expect(groups.map((g) => g.title).toList(), ['개발', '기타']);
    expect(groups.last.channels.single.id, '떠돌이');
  });

  test('★ 카테고리를 못 받아도(오프라인 첫 실행) 채널은 기타로 전부 보인다', () async {
    // 카테고리도 캐시하지만, 한 번도 받은 적 없는 기기를 오프라인으로 켜면
    // 빈 목록이 온다. 그래도 채널이 사라지면 안 된다 — 오프라인 읽기가
    // 성립하지 않는다.
    final groups = await groupsOf(
      channels: [channel('a', categoryId: 'cat1'), channel('b')],
      categories: const [],
    );

    expect(groups.map((g) => g.title).toList(), ['기타']);
    expect(groups.single.channels.length, 2);
  });

  test('★ 카테고리가 뒤늦게 도착하면 기타에서 제 그룹으로 옮겨간다', () async {
    // 실기기에서 겪은 버그의 회귀 테스트.
    //
    // 오프라인으로 켜면 채널만 캐시에서 오고 카테고리는 비어 있어 전부 '기타'에
    // 묶인다. 서버가 돌아와 카테고리가 도착하면 **다시 묶여야 한다.**
    // 예전 구현은 카테고리를 FutureProvider 로 한 번만 불러 이 순간이 오지
    // 않았고, 화면은 연결이 돌아온 뒤에도 계속 '기타'였다.
    final categories = StreamController<List<Category>>();
    addTearDown(categories.close);

    final container = ProviderContainer(
      overrides: [
        channelsProvider.overrideWith(
          (ref) => Stream.value([channel('a', categoryId: 'cat1')]),
        ),
        categoriesProvider.overrideWith((ref) => categories.stream),
      ],
    );
    addTearDown(container.dispose);

    container.listen(channelsProvider, (_, _) {}, fireImmediately: true);
    container.listen(categoriesProvider, (_, _) {}, fireImmediately: true);

    categories.add(const []);
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(container.read(channelGroupsProvider).single.title, '기타');

    // 연결이 돌아왔다.
    categories.add(const [Category(id: 'cat1', name: '개발')]);
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(container.read(channelGroupsProvider).single.title, '개발');
  });

  test('아직 로딩 중이면 빈 목록 — 화면이 깨지지 않는다', () async {
    expect(await groupsOf(channels: const [], categories: const []), isEmpty);
  });
}
