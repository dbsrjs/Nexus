import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_app/data/api/api_failure.dart';
import 'package:nexus_app/data/api/messages_api.dart';
import 'package:nexus_app/data/local/app_database.dart';
import 'package:nexus_app/data/repositories/message_repository.dart';
import 'package:nexus_app/data/socket/socket_event.dart';
import 'package:nexus_app/domain/models/message.dart';

/// 리액션(7-1) 앱 쪽 규칙.
///
/// 서버 계약은 `npm run check:reactions` 가 실서버로 확인한다. 여기서 덮는 것은
/// **앱에만 있는 계산**이다 — 낙관적 토글과, 소켓이 준 `(emoji, userId)` 쌍을
/// 내 기준으로 접는 일. 둘 다 틀리면 화면에 숫자가 잘못 뜨는 방식으로 드러난다.
void main() {
  const me = 'u-me';
  const other = 'u-other';

  group('foldReactions — 소켓 이벤트를 내 기준으로 접는다', () {
    test('이모지별로 세고 순서를 유지한다', () {
      final folded = foldReactions(const [
        ReactionEntry(emoji: '🎉', userId: other),
        ReactionEntry(emoji: '👍', userId: other),
        ReactionEntry(emoji: '👍', userId: me),
      ], me);

      expect(folded.map((r) => r.emoji), ['🎉', '👍']);
      expect(folded[1].count, 2);
    });

    test('★ mine 은 내 userId 로만 결정된다', () {
      const entries = [
        ReactionEntry(emoji: '👍', userId: other),
        ReactionEntry(emoji: '🎉', userId: me),
      ];

      final asMe = foldReactions(entries, me);
      expect(asMe.firstWhere((r) => r.emoji == '👍').mine, isFalse);
      expect(asMe.firstWhere((r) => r.emoji == '🎉').mine, isTrue);

      // 같은 이벤트라도 다른 사람에게는 답이 다르다. 서버가 mine 을
      // 브로드캐스트에 싣지 않는 이유다.
      final asOther = foldReactions(entries, other);
      expect(asOther.firstWhere((r) => r.emoji == '👍').mine, isTrue);
    });

    test('비어 있으면 빈 목록', () {
      expect(foldReactions(const [], me), isEmpty);
    });
  });

  group('낙관적 토글', () {
    late AppDatabase db;
    late _FakeApi api;
    late MessageRepository repository;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      api = _FakeApi(db);
      repository = MessageRepository(api: api, db: db);
    });

    tearDown(() => db.close());

    Future<void> seed(List<MessageReaction> reactions) => db.upsertMessage(
          's1',
          Message(
            id: 'm1',
            channelId: 'c1',
            body: '본문',
            createdAt: DateTime.utc(2026, 8, 16),
            author: const MessageAuthor(id: me, name: '나'),
            reactions: reactions,
          ),
        );

    Future<List<MessageReaction>> current() => db.reactionsOf('m1');

    test('없던 이모지를 누르면 count 1 · mine', () async {
      await seed(const []);
      await repository.toggleReaction(
          spaceId: 's1', messageId: 'm1', emoji: '👍', add: true);

      final list = await current();
      expect(list.single.emoji, '👍');
      expect(list.single.count, 1);
      expect(list.single.mine, isTrue);
    });

    test('남이 이미 누른 것에 더하면 count 가 는다', () async {
      await seed(const [MessageReaction(emoji: '👍', count: 1)]);
      await repository.toggleReaction(
          spaceId: 's1', messageId: 'm1', emoji: '👍', add: true);

      expect((await current()).single.count, 2);
      expect((await current()).single.mine, isTrue);
    });

    test('★ 내가 마지막 한 명이면 항목 자체가 사라진다', () async {
      await seed(const [MessageReaction(emoji: '👍', count: 1, mine: true)]);
      await repository.toggleReaction(
          spaceId: 's1', messageId: 'm1', emoji: '👍', add: false);

      expect(await current(), isEmpty);
    });

    test('남이 남아 있으면 항목은 남고 개수만 준다', () async {
      await seed(const [MessageReaction(emoji: '👍', count: 2, mine: true)]);
      await repository.toggleReaction(
          spaceId: 's1', messageId: 'm1', emoji: '👍', add: false);

      final list = await current();
      expect(list.single.count, 1);
      expect(list.single.mine, isFalse);
    });

    test('★ 순서를 유지한다 — 누를 때마다 버튼이 움직이면 안 된다', () async {
      await seed(const [
        MessageReaction(emoji: '🎉', count: 1),
        MessageReaction(emoji: '👍', count: 5),
      ]);
      await repository.toggleReaction(
          spaceId: 's1', messageId: 'm1', emoji: '🎉', add: true);

      expect((await current()).map((r) => r.emoji), ['🎉', '👍']);
    });

    test('★ 실패하면 원래대로 되돌린다', () async {
      await seed(const [MessageReaction(emoji: '👍', count: 3)]);
      api.fail = true;

      await repository.toggleReaction(
          spaceId: 's1', messageId: 'm1', emoji: '👍', add: true);

      final list = await current();
      expect(list.single.count, 3);
      expect(list.single.mine, isFalse);
    });

    test('소켓이 알려 준 값으로 갈아 끼운다', () async {
      await seed(const [MessageReaction(emoji: '👍', count: 1, mine: true)]);

      await repository.applyReactionChanged(
        'm1',
        const [
          ReactionEntry(emoji: '👍', userId: me),
          ReactionEntry(emoji: '👍', userId: other),
          ReactionEntry(emoji: '🔥', userId: other),
        ],
        me,
      );

      final list = await current();
      expect(list.map((r) => r.emoji), ['👍', '🔥']);
      expect(list[0].count, 2);
      expect(list[0].mine, isTrue);
      expect(list[1].mine, isFalse);
    });
  });
}

class _FakeApi implements MessagesApi {
  _FakeApi(this._db);

  final AppDatabase _db;
  bool fail = false;

  /// 서버는 접힌 요약을 돌려준다.
  ///
  /// 여기서는 **낙관적 예측이 맞았을 때**를 흉내 낸다 — 방금 캐시에 쓴 값을
  /// 그대로 돌려주는 것이 곧 "서버도 같은 결론을 냈다"는 뜻이다. 빈 목록을
  /// 돌려주면 낙관적 갱신이 매번 지워져 규칙을 태울 수 없다.
  Future<List<MessageReaction>> _settle(String messageId) {
    if (fail) throw const ApiException(ApiFailure.network);
    return _db.reactionsOf(messageId);
  }

  @override
  Future<List<MessageReaction>> addReaction({
    required String spaceId,
    required String messageId,
    required String emoji,
  }) =>
      _settle(messageId);

  @override
  Future<List<MessageReaction>> removeReaction({
    required String spaceId,
    required String messageId,
    required String emoji,
  }) =>
      _settle(messageId);

  @override
  Future<MessagePage> list({
    required String spaceId,
    required String channelId,
    String? cursor,
    int limit = 30,
  }) async =>
      const MessagePage(items: []);

@override
  Future<Message> setPinned({
    required String spaceId,
    required String messageId,
    required bool pinned,
  }) async =>
      throw UnimplementedError();

  @override
  Future<List<Message>> listPinned({
    required String spaceId,
    required String channelId,
  }) async =>
      const [];

  @override
  Future<ThreadPage> listReplies({
    required String spaceId,
    required String messageId,
    String? cursor,
    int limit = 50,
  }) async =>
      throw UnimplementedError();

  @override
  Future<Message> send({
    required String spaceId,
    required String channelId,
    required String body,
    String? parentId,
    String? quotedMessageId,
  }) async =>
      throw UnimplementedError();
}
