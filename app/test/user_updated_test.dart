import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_app/data/local/app_database.dart';
import 'package:nexus_app/domain/models/issue.dart';
import 'package:nexus_app/domain/models/message.dart';

/// 14단계 — 남(또는 내 다른 기기)이 이름 · 사진을 바꾸면 `user:updated` 가 오고,
/// 앱은 **drift 의 작성자 칸을 고친다.** 화면은 drift 만 보므로 여기가 틀리면
/// 옛 이름이 계속 보인다.
void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  Message message(String id, String authorId, String name) => Message(
        id: id,
        channelId: 'c1',
        body: '본문 $id',
        createdAt: DateTime.utc(2026, 9, 27, 0, 0, int.parse(id.substring(1))),
        author: MessageAuthor(id: authorId, name: name),
      );

  Issue issue(String id, String? assigneeId) => Issue(
        id: id,
        key: 'NEXUS-$id',
        title: '이슈 $id',
        status: IssueStatus.backlog,
        priority: IssuePriority.mid,
        position: '0',
        assignee: assigneeId == null ? null : IssueAuthor(id: assigneeId, name: '옛 이름'),
        createdAt: DateTime.utc(2026, 9, 27),
        updatedAt: DateTime.utc(2026, 9, 27),
      );

  test('★ 그 사람이 쓴 캐시 메시지의 이름 · 사진만 바뀐다', () async {
    await db.upsertMessages('s1', [
      message('m1', 'alice', '옛 이름'),
      message('m2', 'bob', '밥'),
    ]);

    await db.applyUserUpdated(userId: 'alice', name: '새 이름', avatarUrl: '/users/alice/avatar?v=1');

    final rows = await db.watchChannelMessages('c1').first;
    final alice = rows.firstWhere((m) => m.id == 'm1').author;
    final bob = rows.firstWhere((m) => m.id == 'm2').author;
    expect(alice.name, '새 이름');
    expect(alice.avatarUrl, '/users/alice/avatar?v=1');
    expect(bob.name, '밥');
    expect(bob.avatarUrl, isNull);
  });

  test('★ 전송 큐에 있는 내 메시지의 작성자명도 바뀐다 - 보내지기 전에도 새 이름으로 보인다', () async {
    await db.enqueue(OutboxMessagesCompanion.insert(
      id: 'local-1',
      spaceId: 's1',
      channelId: 'c1',
      body: '큐에 있는 글',
      createdAt: DateTime.utc(2026, 9, 27),
      authorId: 'alice',
      authorName: '옛 이름',
    ));

    await db.applyUserUpdated(userId: 'alice', name: '새 이름', avatarUrl: null);

    final queued = await db.watchChannelMessages('c1').first;
    expect(queued.single.author.name, '새 이름');
  });

  test('담당 이슈의 담당자명 · 사진도 바뀐다', () async {
    await db.replaceIssues('s1', [issue('1', 'alice'), issue('2', 'bob'), issue('3', null)]);

    await db.applyUserUpdated(userId: 'alice', name: '새 이름', avatarUrl: '/a');

    final rows = await db.watchIssues('s1').first;
    expect(rows.firstWhere((r) => r.id == '1').assigneeName, '새 이름');
    expect(rows.firstWhere((r) => r.id == '1').assigneeAvatarUrl, '/a');
    expect(rows.firstWhere((r) => r.id == '2').assigneeName, '옛 이름');
    expect(rows.firstWhere((r) => r.id == '3').assigneeName, isNull);
  });

  test('사진을 지우면 null 로 덮는다 - 옛 사진 주소가 남지 않는다', () async {
    await db.upsertMessages('s1', [message('m1', 'alice', '가영')]);
    await db.applyUserUpdated(userId: 'alice', name: '가영', avatarUrl: '/old');
    await db.applyUserUpdated(userId: 'alice', name: '가영', avatarUrl: null);

    final rows = await db.watchChannelMessages('c1').first;
    expect(rows.single.author.avatarUrl, isNull);
  });

  group('채널 음소거', () {
    CachedChannelsCompanion channel(String id, {bool muted = false}) =>
        CachedChannelsCompanion.insert(
          id: id,
          spaceId: 's1',
          key: id,
          name: id,
          muted: Value(muted),
        );

    test('replaceChannels 가 muted 를 담는다', () async {
      await db.replaceChannels('s1', [channel('a', muted: true), channel('b')]);
      final rows = await db.watchChannels('s1').first;
      expect(rows.firstWhere((c) => c.id == 'a').muted, isTrue);
      expect(rows.firstWhere((c) => c.id == 'b').muted, isFalse);
    });

    test('setChannelMuted 가 그 채널만 바꾼다', () async {
      await db.replaceChannels('s1', [channel('a'), channel('b')]);
      await db.setChannelMuted('a', true);
      final rows = await db.watchChannels('s1').first;
      expect(rows.firstWhere((c) => c.id == 'a').muted, isTrue);
      expect(rows.firstWhere((c) => c.id == 'b').muted, isFalse);
    });
  });
}
