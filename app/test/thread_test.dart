import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_app/data/local/app_database.dart';
import 'package:nexus_app/domain/models/message.dart';

/// 스레드(7-2) 캐시 규칙.
///
/// 서버 계약은 `npm run check:threads` 가 실서버로 확인한다. 여기서 덮는 것은
/// **캐시가 답글을 어디에 두는가**다 — 채널 타임라인과 스레드는 같은 테이블을
/// 쓰므로, 나누는 조건이 틀리면 답글이 채널에 새거나 스레드가 빈다.
void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  const author = MessageAuthor(id: 'u1', name: '나');

  Message message(
    String id, {
    String? parentId,
    int replyCount = 0,
    int minute = 0,
  }) =>
      Message(
        id: id,
        channelId: 'c1',
        body: id,
        createdAt: DateTime.utc(2026, 8, 16, 12, minute),
        author: author,
        parentId: parentId,
        replyCount: replyCount,
      );

  test('★ 답글은 채널 타임라인에 섞이지 않는다', () async {
    await db.upsertMessages('s1', [
      message('최상위', replyCount: 2),
      message('답글1', parentId: '최상위', minute: 1),
      message('답글2', parentId: '최상위', minute: 2),
    ]);

    final timeline = await db.watchChannelMessages('c1').first;
    expect(timeline.map((m) => m.body), ['최상위']);
  });

  test('★ 스레드에는 그 부모의 답글만 온다', () async {
    await db.upsertMessages('s1', [
      message('부모A', replyCount: 1),
      message('부모B', replyCount: 1),
      message('A의 답글', parentId: '부모A', minute: 1),
      message('B의 답글', parentId: '부모B', minute: 2),
    ]);

    final thread = await db.watchThreadReplies('부모A').first;
    expect(thread.map((m) => m.body), ['A의 답글']);
  });

  test('답글도 최신순이다 — 화면이 뒤집어 그린다', () async {
    await db.upsertMessages('s1', [
      message('부모', replyCount: 2),
      message('먼저', parentId: '부모', minute: 1),
      message('나중', parentId: '부모', minute: 2),
    ]);

    expect(
      (await db.watchThreadReplies('부모').first).map((m) => m.body),
      ['나중', '먼저'],
    );
  });

  test('★ 채널을 새로고침해도 열어 둔 스레드가 비지 않는다', () async {
    // 서버의 채널 목록 응답에는 답글이 들어 있지 않다(parent_id IS NULL 로
    // 잘라서 준다). 교체할 때 답글까지 지우면 스레드 화면이 빈다.
    await db.upsertMessages('s1', [
      message('최상위', replyCount: 1),
      message('답글', parentId: '최상위', minute: 1),
    ]);

    await db.replaceServerMessages('s1', 'c1', [
      message('최상위', replyCount: 1),
      message('새 메시지', minute: 5),
    ]);

    expect(
      (await db.watchThreadReplies('최상위').first).map((m) => m.body),
      ['답글'],
    );
  });

  test('스레드를 새로고침해도 채널 타임라인은 그대로다', () async {
    await db.upsertMessages('s1', [
      message('최상위', replyCount: 1),
      message('다른 메시지', minute: 3),
    ]);

    await db.replaceThreadReplies('s1', '최상위', [
      message('새 답글', parentId: '최상위', minute: 4),
    ]);

    final timeline = await db.watchChannelMessages('c1').first;
    expect(timeline.map((m) => m.body), ['다른 메시지', '최상위']);
  });

  test('★ 오프라인에서 쓴 답글도 스레드에만 보인다', () async {
    await db.upsertMessage('s1', message('최상위'));
    await db.enqueue(
      OutboxMessagesCompanion.insert(
        id: 'local-1',
        spaceId: 's1',
        channelId: 'c1',
        body: '못 보낸 답글',
        parentId: const Value('최상위'),
        createdAt: DateTime.utc(2026, 8, 16, 12, 9),
        authorId: author.id,
        authorName: author.name,
      ),
    );

    final timeline = await db.watchChannelMessages('c1').first;
    expect(timeline.map((m) => m.body), ['최상위']);

    final thread = await db.watchThreadReplies('최상위').first;
    expect(thread.single.body, '못 보낸 답글');
    expect(thread.single.pending, isTrue);
  });

  test('답글 요약만 갱신해도 본문은 남는다', () async {
    await db.upsertMessage('s1', message('최상위'));
    await db.setThreadSummary(
      '최상위',
      replyCount: 3,
      lastReplyAt: DateTime.utc(2026, 8, 16, 13),
    );

    final parent = await db.watchMessage('최상위').first;
    expect(parent!.body, '최상위');
    expect(parent.replyCount, 3);
    expect(parent.hasThread, isTrue);
  });
}
