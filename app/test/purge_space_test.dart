import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_app/data/local/app_database.dart';
import 'package:nexus_app/domain/models/message.dart';

/// 16단계 설계 D13 — 내보내지면 그 스페이스의 캐시와 큐만 지운다.
void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  Message message(String id, String channelId) => Message(
        id: id,
        channelId: channelId,
        body: '본문 $id',
        createdAt: DateTime.utc(2026, 10, 4),
        author: const MessageAuthor(id: 'u', name: '나'),
      );

  Future<void> queue(String id, String spaceId, String channelId) => db.enqueue(
        OutboxMessagesCompanion.insert(
          id: id,
          spaceId: spaceId,
          channelId: channelId,
          body: '큐 $id',
          createdAt: DateTime.utc(2026, 10, 4),
          authorId: 'u',
          authorName: '나',
        ),
      );

  test('★ 그 스페이스의 메시지 · 큐만 지우고 다른 스페이스는 남긴다', () async {
    await db.upsertMessages('s1', [message('m1', 'c1')]);
    await db.upsertMessages('s2', [message('m2', 'c2')]);
    await queue('local-1', 's1', 'c1');
    await queue('local-2', 's2', 'c2');

    await db.purgeSpace('s1');

    expect(await db.watchChannelMessages('c1').first, isEmpty);
    // 캐시 1 + 큐 1 — 다른 스페이스는 손대지 않는다.
    expect(await db.watchChannelMessages('c2').first, hasLength(2));
  });

  test('채널 · 스페이스 행도 지운다', () async {
    await db.replaceSpaces([
      CachedSpacesCompanion.insert(id: 's1', slug: 's1', name: '하나', role: 'member'),
      CachedSpacesCompanion.insert(id: 's2', slug: 's2', name: '둘', role: 'member'),
    ]);
    await db.replaceChannels('s1', [
      CachedChannelsCompanion.insert(id: 'c1', spaceId: 's1', key: 'c1', name: 'c1'),
    ]);

    await db.purgeSpace('s1');

    expect(await db.watchChannels('s1').first, isEmpty);
    expect((await db.watchSpaces().first).map((s) => s.id), ['s2']);
  });
}
