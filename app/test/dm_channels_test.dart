import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_app/domain/models/channel.dart';
import 'package:nexus_app/domain/models/space_member.dart';
import 'package:nexus_app/features/channel/channel_controller.dart';
import 'package:nexus_app/features/channel/dm.dart';

/// DM 묶음(17단계 D10) — 채널 묶음에서 빠지고, 최근순이며, 빈 DM 은 숨는다.
void main() {
  Channel text(String id) => Channel(id: id, key: id, name: id);
  Channel dm(String id, {DateTime? last, String peer = 'u2'}) => Channel(
        id: id,
        key: 'dm:u1:$peer',
        name: 'DM',
        kind: 'dm',
        isPrivate: true,
        dmUserId: peer,
        lastMessageAt: last,
      );

  Future<ProviderContainer> containerOf(List<Channel> channels, {String? current}) async {
    final container = ProviderContainer(
      overrides: [
        channelsProvider.overrideWith((ref) => Stream.value(channels)),
        categoriesProvider.overrideWith((ref) => Stream.value(const <Category>[])),
      ],
    );
    addTearDown(container.dispose);
    container.listen(channelsProvider, (_, _) {}, fireImmediately: true);
    container.listen(categoriesProvider, (_, _) {}, fireImmediately: true);
    if (current != null) container.read(currentChannelIdProvider.notifier).set(current);
    await Future<void>.delayed(const Duration(milliseconds: 10));
    return container;
  }

  test('★ 채널 묶음에는 DM 이 없다', () async {
    final c = await containerOf([text('general'), dm('d1', last: DateTime.utc(2026))]);
    final ids = [for (final g in c.read(channelGroupsProvider)) ...g.channels.map((x) => x.id)];
    expect(ids, ['general']);
  });

  test('DM 은 최근 메시지 순', () async {
    final c = await containerOf([
      dm('old', last: DateTime.utc(2026, 1, 1)),
      dm('new', last: DateTime.utc(2026, 3, 1), peer: 'u3'),
      text('general'),
    ]);
    expect(c.read(dmChannelsProvider).map((x) => x.id).toList(), ['new', 'old']);
  });

  test('★ 메시지가 없는 DM 은 숨는다 — 지금 열린 것은 맨 위에 보인다', () async {
    final hidden = await containerOf([dm('empty'), dm('talked', last: DateTime.utc(2026), peer: 'u3')]);
    expect(hidden.read(dmChannelsProvider).map((x) => x.id).toList(), ['talked']);

    final open = await containerOf(
      [dm('empty'), dm('talked', last: DateTime.utc(2026), peer: 'u3')],
      current: 'empty',
    );
    expect(open.read(dmChannelsProvider).map((x) => x.id).toList(), ['empty', 'talked']);
  });

  test('상대 이름 — 멤버 목록에 없으면 「나간 사람」', () {
    final members = {'u2': const SpaceMemberProfile(userId: 'u2', name: '가나', nickname: '별명')};
    expect(dmPeerName(members, dm('d')), '별명');
    expect(dmPeerName(members, dm('d', peer: 'gone')), '나간 사람');
  });

  test('서버 응답의 kind · dmUserId · lastMessageAt 을 읽는다', () {
    final c = Channel.fromJson({
      'id': 'd',
      'key': 'dm:a:b',
      'name': 'DM',
      'kind': 'dm',
      'dmUserId': 'b',
      'lastMessageAt': '2026-10-05T01:02:03.000Z',
    });
    expect(c.isDm, isTrue);
    expect(c.dmUserId, 'b');
    expect(c.lastMessageAt, DateTime.utc(2026, 10, 5, 1, 2, 3));
    expect(Channel.fromJson({'id': 'x', 'key': 'x', 'name': 'x'}).isDm, isFalse);
  });
}
