import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_app/data/local/app_database.dart';
import 'package:nexus_app/domain/models/message.dart';

/// 답장(인용, 7-3) 앱 쪽 규칙.
///
/// 서버 계약은 `npm run check:quotes` 가 확인한다. 여기서 덮는 것은 **캐시가
/// 인용을 어떻게 들고 있는가**다 — 특히 큐에 있는 동안에도 인용문이 보여야
/// 한다는 점. 그때는 서버에서 원본을 받아올 수 없기 때문이다.
void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  const author = MessageAuthor(id: 'u1', name: '나');

  Message message(String id, {QuotedMessage? quoted, int minute = 0}) => Message(
        id: id,
        channelId: 'c1',
        body: id,
        createdAt: DateTime.utc(2026, 8, 16, 12, minute),
        author: author,
        quoted: quoted,
      );

  test('인용 없는 메시지의 quoted 는 null', () async {
    await db.upsertMessage('s1', message('평범한 메시지'));

    final list = await db.watchChannelMessages('c1').first;
    expect(list.single.quoted, isNull);
    expect(list.single.isReply, isFalse);
  });

  test('★ 답장은 타임라인에 남는다 — 스레드 답글과 다른 축이다', () async {
    await db.upsertMessages('s1', [
      message('원본'),
      message(
        '답장',
        minute: 1,
        quoted: const QuotedMessage(
          id: '원본',
          body: '원본',
          authorName: '나',
        ),
      ),
    ]);

    final list = await db.watchChannelMessages('c1').first;
    expect(list.map((m) => m.body), ['답장', '원본']);
    expect(list.first.quoted!.id, '원본');
  });

  test('삭제된 원본을 인용하면 그 사실이 남는다', () async {
    await db.upsertMessage(
      's1',
      message(
        '답장',
        quoted: const QuotedMessage(
          id: '지워진 것',
          body: '',
          authorName: '남',
          deleted: true,
        ),
      ),
    );

    final quoted = (await db.watchChannelMessages('c1').first).single.quoted!;
    expect(quoted.deleted, isTrue);
    expect(quoted.body, isEmpty);
    expect(quoted.authorName, '남');
  });

  test('★ 아직 보내지 못한 답장도 인용문이 보인다', () async {
    // 큐에 있는 동안에는 서버에서 원본을 받아올 수 없다. 요약을 함께 넣어
    // 두지 않으면 인용문이 빈 채로 보인다.
    await db.enqueue(
      OutboxMessagesCompanion.insert(
        id: 'local-1',
        spaceId: 's1',
        channelId: 'c1',
        body: '못 보낸 답장',
        quotedMessageId: const Value('원본'),
        quoted: const Value(
          QuotedMessage(id: '원본', body: '원본 본문', authorName: '남'),
        ),
        createdAt: DateTime.utc(2026, 8, 16, 12, 5),
        authorId: author.id,
        authorName: author.name,
      ),
    );

    final list = await db.watchChannelMessages('c1').first;
    expect(list.single.pending, isTrue);
    expect(list.single.quoted!.body, '원본 본문');
  });

  test('★ 큐에서 나갈 때 인용 대상도 함께 나간다', () async {
    await db.enqueue(
      OutboxMessagesCompanion.insert(
        id: 'local-1',
        spaceId: 's1',
        channelId: 'c1',
        body: '답장',
        quotedMessageId: const Value('원본'),
        createdAt: DateTime.utc(2026, 8, 16, 12),
        authorId: author.id,
        authorName: author.name,
      ),
    );

    expect((await db.queuedMessages()).single.quotedMessageId, '원본');
  });

  test('quotedFrom — 서버가 주는 것과 같은 모양을 만든다', () {
    final quoted = quotedFrom(message('본문'));
    expect(quoted.id, '본문');
    expect(quoted.body, '본문');
    expect(quoted.authorName, '나');
    expect(quoted.deleted, isFalse);
  });

  test('★ 삭제된 메시지를 답장 대상으로 삼으면 본문을 싣지 않는다', () async {
    final deleted = Message(
      id: 'm1',
      channelId: 'c1',
      body: '지워지기 전 본문',
      createdAt: DateTime.utc(2026, 8, 16),
      author: author,
      deletedAt: DateTime.utc(2026, 8, 16, 13),
    );

    final quoted = quotedFrom(deleted);
    expect(quoted.deleted, isTrue);
    expect(quoted.body, isEmpty);
  });
}
