import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_app/data/api/api_failure.dart';
import 'package:nexus_app/data/api/messages_api.dart';
import 'package:nexus_app/data/local/app_database.dart';
import 'package:nexus_app/data/repositories/message_repository.dart';
import 'package:nexus_app/domain/models/message.dart';

/// 핀(7-5) 앱 쪽 규칙.
///
/// 서버 계약은 `npm run check:pins` 가 확인한다. 여기서는 **낙관적 토글이
/// 실패했을 때 되돌아오는가**를 고정한다 - 되돌리지 않으면 화면과 서버가
/// 갈라지고, 사용자는 고정한 줄 안다.
void main() {
  late AppDatabase db;
  late _FakeApi api;
  late MessageRepository repository;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    api = _FakeApi();
    repository = MessageRepository(api: api, db: db);
  });

  tearDown(() => db.close());

  const author = MessageAuthor(id: 'u1', name: '나');

  Future<void> seed({bool pinned = false}) => db.upsertMessage(
        's1',
        Message(
          id: 'm1',
          channelId: 'c1',
          body: '본문',
          createdAt: DateTime.utc(2026, 8, 16),
          author: author,
          pinned: pinned,
        ),
      );

  Future<Message> current() async =>
      (await db.watchChannelMessages('c1').first).single;

  test('고정하면 캐시에 반영된다', () async {
    await seed();
    await repository.setPinned(spaceId: 's1', messageId: 'm1', pinned: true);

    expect((await current()).pinned, isTrue);
  });

  test('해제하면 되돌아온다', () async {
    await seed(pinned: true);
    await repository.setPinned(spaceId: 's1', messageId: 'm1', pinned: false);

    expect((await current()).pinned, isFalse);
  });

  test('★ 실패하면 원래대로 되돌린다', () async {
    // 되돌리지 않으면 화면은 고정됐다고 하는데 서버에는 없다.
    await seed();
    api.fail = true;

    await repository.setPinned(spaceId: 's1', messageId: 'm1', pinned: true);

    expect((await current()).pinned, isFalse);
  });

  test('★ 해제 실패도 되돌린다', () async {
    await seed(pinned: true);
    api.fail = true;

    await repository.setPinned(spaceId: 's1', messageId: 'm1', pinned: false);

    expect((await current()).pinned, isTrue);
  });

  test('소켓이 알려 준 상태를 반영한다', () async {
    await seed();
    await repository.applyPinChanged('m1', true);

    expect((await current()).pinned, isTrue);
  });

  test('★ 고정 상태만 바뀌고 본문은 그대로다', () async {
    // 소켓 이벤트에는 본문이 없다. 행 전체를 덮어쓰면 잃는다.
    await seed();
    await repository.applyPinChanged('m1', true);

    final message = await current();
    expect(message.body, '본문');
    expect(message.author.name, '나');
  });

  test('목록을 못 받아도 빈 목록으로 끝난다', () async {
    api.fail = true;
    expect(
      await repository.pinnedMessages(spaceId: 's1', channelId: 'c1'),
      isEmpty,
    );
  });
}

class _FakeApi implements MessagesApi {
  bool fail = false;

  @override
  Future<Message> setPinned({
    required String spaceId,
    required String messageId,
    required bool pinned,
  }) async {
    if (fail) throw const ApiException(ApiFailure.network);
    return Message(
      id: messageId,
      channelId: 'c1',
      body: '본문',
      createdAt: DateTime.utc(2026, 8, 16),
      author: const MessageAuthor(id: 'u1', name: '나'),
      pinned: pinned,
    );
  }

  @override
  Future<List<Message>> listPinned({
    required String spaceId,
    required String channelId,
  }) async {
    if (fail) throw const ApiException(ApiFailure.network);
    return const [];
  }

  @override
  Future<MessagePage> list({
    required String spaceId,
    required String channelId,
    String? cursor,
    int limit = 30,
  }) async =>
      const MessagePage(items: []);

  @override
  Future<ThreadPage> listReplies({
    required String spaceId,
    required String messageId,
    String? cursor,
    int limit = 50,
  }) async =>
      throw UnimplementedError();

  @override
  Future<List<MessageReaction>> addReaction({
    required String spaceId,
    required String messageId,
    required String emoji,
  }) async =>
      const [];

  @override
  Future<List<MessageReaction>> removeReaction({
    required String spaceId,
    required String messageId,
    required String emoji,
  }) async =>
      const [];

  @override
  Future<Message> send({
    required String spaceId,
    required String channelId,
    required String body,
    String? parentId,
    String? quotedMessageId,
    List<String> attachmentIds = const [],
  }) async =>
      throw UnimplementedError();
}
