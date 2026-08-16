import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_app/data/api/api_failure.dart';
import 'package:nexus_app/data/api/messages_api.dart';
import 'package:nexus_app/data/local/app_database.dart';
import 'package:nexus_app/data/repositories/message_repository.dart';
import 'package:nexus_app/domain/models/message.dart';

/// 전송 큐(6-2).
///
/// 이 계층은 **오프라인에서만 드러나는 규칙**을 담고 있어 화면으로 확인하기가
/// 특히 번거롭다. 서버를 껐다 켜 가며 손으로 재현해야 하는 것들 — 순서 보장,
/// 재시도 한도, 네트워크 실패와 영구 실패의 구분 — 을 여기서 덮는다.
void main() {
  late AppDatabase db;
  late _FakeMessagesApi api;
  late MessageRepository repository;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    api = _FakeMessagesApi();
    repository = MessageRepository(api: api, db: db);
  });

  tearDown(() => db.close());

  const author = MessageAuthor(id: 'u1', name: '나');

  Future<String> enqueue(String body, {String channel = 'c1'}) => repository.enqueue(
        spaceId: 's1',
        channelId: channel,
        body: body,
        author: author,
      );

  Future<List<Message>> visible({String channel = 'c1'}) =>
      repository.watch(channel).first;

  test('큐에 넣으면 곧바로 화면에 보인다 — pending 으로', () async {
    await enqueue('안녕');

    final list = await visible();
    expect(list.single.body, '안녕');
    expect(list.single.pending, isTrue);
    expect(list.single.failed, isFalse);
  });

  test('전송에 성공하면 큐에서 빠지고 서버 메시지로 바뀐다', () async {
    await enqueue('안녕');
    final sent = await repository.flush();

    expect(sent, 1);
    expect(await db.queuedMessages(), isEmpty);

    final list = await visible();
    expect(list.single.id, 'server-1');
    expect(list.single.pending, isFalse);
  });

  test('★ 오프라인이면 큐에 남고 실패로 표시하지 않는다', () async {
    // 오프라인은 오류가 아니라 정상 경로다. 여기서 실패로 찍으면 지하철에서
    // 몇 정거장만 지나도 보낸 것이 전부 빨갛게 된다.
    api.failWith = ApiFailure.network;
    await enqueue('안녕');
    await repository.flush();

    final queued = await db.queuedMessages();
    expect(queued.single.failed, isFalse);
    expect(queued.single.attempts, 0);
    expect((await visible()).single.pending, isTrue);
  });

  test('★ 다시 연결되면 쌓아 둔 것이 쓴 순서대로 나간다', () async {
    api.failWith = ApiFailure.network;
    await enqueue('첫째');
    await enqueue('둘째');
    await enqueue('셋째');
    await repository.flush();
    expect(api.sentBodies, isEmpty);

    api.failWith = null;
    final sent = await repository.flush();

    expect(sent, 3);
    expect(api.sentBodies, ['첫째', '둘째', '셋째']);
    expect(await db.queuedMessages(), isEmpty);
  });

  test('★ 시각이 완전히 같아도 넣은 순서대로 나간다', () async {
    // 순서를 시각에 맡기면 안 되는 이유를 고정한다.
    //
    // Windows 의 `DateTime.now()` 는 밀리초 해상도라, 연속으로 보낸 메시지
    // 여러 건이 **완전히 같은 값**을 갖는다. 그때 순서가 tie-break 로 넘어가면
    // 뒤집힌다 — 이 테스트를 넣기 전에 15회 중 5회 실패했다.
    // 그래서 큐는 삽입 순번(seq)으로 정렬한다.
    final same = DateTime.utc(2026, 8, 15, 14, 20, 48);
    for (final body in ['첫째', '둘째', '셋째', '넷째', '다섯째']) {
      await db.enqueue(
        OutboxMessagesCompanion.insert(
          id: 'local-$body',
          spaceId: 's1',
          channelId: 'c1',
          body: body,
          createdAt: same,
          authorId: author.id,
          authorName: author.name,
        ),
      );
    }

    expect(
      (await db.queuedMessages()).map((m) => m.body),
      ['첫째', '둘째', '셋째', '넷째', '다섯째'],
    );

    await repository.flush();
    expect(api.sentBodies, ['첫째', '둘째', '셋째', '넷째', '다섯째']);
  });

  test('★ 앞이 실패하면 같은 채널의 뒤는 나가지 않는다 — 순서가 뒤집히면 안 된다', () async {
    await enqueue('첫째');
    await enqueue('둘째');

    api.failOnBody = '첫째';
    await repository.flush();

    // 둘째가 먼저 도착하면 대화가 뒤집힌다. 이번 회차에서는 아예 건너뛴다.
    expect(api.sentBodies, isEmpty);
    expect((await db.queuedMessages()).length, 2);
  });

  test('★ 다른 채널은 서로 막지 않는다', () async {
    await enqueue('c1 메시지', channel: 'c1');
    await enqueue('c2 메시지', channel: 'c2');

    api.failOnBody = 'c1 메시지';
    await repository.flush();

    expect(api.sentBodies, ['c2 메시지']);
  });

  test('★ 404 는 다시 걸어도 같으므로 한 번에 실패로 넘긴다', () async {
    // 채널이 사라졌거나 권한을 잃은 것이라 자동 재시도가 의미 없다.
    api.failWith = ApiFailure.notFound;
    await enqueue('안녕');
    await repository.flush();

    final queued = await db.queuedMessages();
    expect(queued.single.failed, isTrue);
    expect(queued.single.attempts, 1);
    expect((await visible()).single.failed, isTrue);
  });

  test('서버 오류는 세 번까지 다시 걸고 그 뒤 실패로 넘긴다', () async {
    api.failWith = ApiFailure.server;
    await enqueue('안녕');

    await repository.flush();
    expect((await db.queuedMessages()).single.failed, isFalse);
    await repository.flush();
    expect((await db.queuedMessages()).single.failed, isFalse);
    await repository.flush();

    final queued = await db.queuedMessages();
    expect(queued.single.attempts, 3);
    expect(queued.single.failed, isTrue);
  });

  test('실패한 것은 재시도 전까지 자동으로 나가지 않는다', () async {
    api.failWith = ApiFailure.notFound;
    await enqueue('안녕');
    await repository.flush();

    api.failWith = null;
    expect(await repository.flush(), 0);

    // 사용자가 재시도를 누르면 그때 나간다.
    final queued = await db.queuedMessages();
    await repository.retry(queued.single.id);
    expect(api.sentBodies, ['안녕']);
  });

  test('버리면 큐에서 사라진다 — 서버에는 간 적이 없다', () async {
    final id = await enqueue('오타');
    await repository.discard(id);

    expect(await db.queuedMessages(), isEmpty);
    expect(await visible(), isEmpty);
  });

  test('★ 캐시를 통째로 지워도 큐는 살아남는다', () async {
    // 이것이 큐를 캐시와 다른 테이블에 둔 이유다. 캐시는 서버에서 다시 받으면
    // 되지만, 아직 보내지 못한 메시지는 사용자가 쓴 유일본이다.
    await enqueue('아직 못 보낸 것');
    await db.replaceServerMessages('s1', 'c1', [
      Message(
        id: 'server-0',
        channelId: 'c1',
        body: '서버에 있던 것',
        createdAt: DateTime(2026, 1, 1),
        author: author,
      ),
    ]);

    expect((await db.queuedMessages()).single.body, '아직 못 보낸 것');
    expect((await visible()).map((m) => m.body), contains('아직 못 보낸 것'));
  });

  test('★ 같은 초에 도착한 메시지도 순서가 유지된다', () async {
    // 실기기에서 겪은 버그의 회귀 테스트.
    //
    // 오프라인에 쌓아 둔 둘을 한꺼번에 내보내니 서버 기록은 .192 · .397 로
    // 멀쩡한데 화면만 뒤집혔다. drift 가 시각을 **초 단위**로 저장해 둘이
    // 동률이 됐기 때문이다. 저장 형식을 밀리초가 남는 텍스트로 바꿔 고쳤다.
    final base = DateTime.utc(2026, 8, 15, 14, 20, 48);
    await db.upsertMessages('s1', [
      for (final ms in [192, 397])
        Message(
          id: 'server-$ms',
          channelId: 'c1',
          body: 'ms-$ms',
          createdAt: base.add(Duration(milliseconds: ms)),
          author: author,
        ),
    ]);

    // 최신순이므로 나중에 온 397 이 앞에 온다.
    expect((await visible()).map((m) => m.body), ['ms-397', 'ms-192']);
  });

  test('목록은 캐시와 큐를 합쳐 최신순으로 준다', () async {
    await db.upsertMessage(
      's1',
      Message(
        id: 'server-0',
        channelId: 'c1',
        body: '예전 것',
        createdAt: DateTime(2026, 1, 1),
        author: author,
      ),
    );
    await enqueue('방금 쓴 것');

    // 화면은 reverse ListView 라 최신이 앞에 온다.
    expect((await visible()).map((m) => m.body), ['방금 쓴 것', '예전 것']);
  });
}

/// 서버 대신. 실패 종류를 마음대로 지정할 수 있어야 큐 규칙을 태울 수 있다.
class _FakeMessagesApi implements MessagesApi {
  ApiFailure? failWith;

  /// 특정 본문에서만 실패시킨다. 순서 규칙을 확인할 때 쓴다.
  String? failOnBody;

  final List<String> sentBodies = [];
  int _serial = 0;

  @override
  Future<Message> send({
    required String spaceId,
    required String channelId,
    required String body,
    String? parentId,
    String? quotedMessageId,
  }) async {
    if (failWith != null || failOnBody == body) {
      throw ApiException(failWith ?? ApiFailure.server);
    }
    sentBodies.add(body);
    return Message(
      id: 'server-${++_serial}',
      channelId: channelId,
      body: body,
      createdAt: DateTime(2026, 8, 15),
      author: const MessageAuthor(id: 'u1', name: '나'),
    );
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

  // 리액션은 이 파일의 관심사가 아니다. 큐 규칙만 태운다.
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
}
