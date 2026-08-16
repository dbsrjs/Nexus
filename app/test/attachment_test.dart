import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_app/data/api/api_failure.dart';
import 'package:nexus_app/data/api/messages_api.dart';
import 'package:nexus_app/data/local/app_database.dart';
import 'package:nexus_app/data/repositories/message_repository.dart';
import 'package:nexus_app/domain/models/message.dart';
import 'package:nexus_app/features/chat/attachment_widgets.dart';

/// 첨부(8-2) 앱 쪽 규칙.
///
/// 서버 계약은 `npm run check:attachments` 가 확인한다. 여기서 덮는 것은 앱에만
/// 있는 두 가지다 — **큐가 첨부를 잃지 않는가**와, 크기 표기.
void main() {
  const author = MessageAuthor(id: 'u1', name: '나');

  const file = MessageAttachment(
    id: 'a1',
    name: '메모.txt',
    mime: 'text/plain',
    sizeBytes: 2048,
  );
  const image = MessageAttachment(
    id: 'a2',
    name: 'shot.png',
    mime: 'image/png',
    sizeBytes: 4096,
    width: 800,
    height: 600,
  );

  group('모델', () {
    test('★ 서버가 문자열로 준 크기를 숫자로 받는다', () {
      // bigint 컬럼이라 서버가 문자열로 준다. 그대로 두면 표기가 깨진다.
      final parsed = MessageAttachment.fromJson(const {
        'id': 'a1',
        'name': 'x.bin',
        'mime': null,
        'sizeBytes': '1048576',
        'width': null,
        'height': null,
      });

      expect(parsed.sizeBytes, 1048576);
    });

    test('이미지인지 mime 으로 가린다', () {
      expect(image.isImage, isTrue);
      expect(file.isImage, isFalse);
    });
  });

  group('AttachmentImage._fit — 미리보기 자리를 먼저 잡는다', () {
    test('★ 비율을 지키면서 최대 크기 안에 넣는다', () {
      // 자리를 먼저 잡지 않으면 이미지가 로드될 때마다 목록이 튄다.
      final size = AttachmentImage.fit(1200, 900);
      expect(size!.width, AttachmentImage.maxWidth);
      expect(size.height, closeTo(AttachmentImage.maxWidth * 900 / 1200, 0.01));
    });

    test('세로가 긴 이미지는 높이에 맞춘다', () {
      final size = AttachmentImage.fit(400, 1600);
      expect(size!.height, AttachmentImage.maxHeight);
      expect(size.width, closeTo(AttachmentImage.maxHeight * 400 / 1600, 0.01));
    });

    test('★ 작은 이미지를 늘리지 않는다', () {
      final size = AttachmentImage.fit(80, 60);
      expect(size!.width, 80);
      expect(size.height, 60);
    });

    test('크기를 모르면 null — 로드 뒤에 자리가 정해진다', () {
      expect(AttachmentImage.fit(null, null), isNull);
      expect(AttachmentImage.fit(0, 100), isNull);
    });
  });

  group('formatBytes', () {
    test('1KB 미만은 바이트 그대로', () {
      expect(formatBytes(512), '512 B');
    });

    test('KB · MB 로 접는다', () {
      expect(formatBytes(2048), '2.0 KB');
      expect(formatBytes(5 * 1024 * 1024), '5.0 MB');
    });

    test('★ 1024 로 나눈다 — 파일 탐색기와 어긋나면 같은 파일인지 의심한다', () {
      expect(formatBytes(1024), '1.0 KB');
      expect(formatBytes(1000), '1000 B');
    });
  });

  group('캐시 · 큐', () {
    late AppDatabase db;
    late _FakeApi api;
    late MessageRepository repository;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      api = _FakeApi();
      repository = MessageRepository(api: api, db: db);
    });

    tearDown(() => db.close());

    test('캐시에 넣은 첨부가 그대로 나온다', () async {
      await db.upsertMessage(
        's1',
        Message(
          id: 'm1',
          channelId: 'c1',
          body: '파일 붙임',
          createdAt: DateTime.utc(2026, 8, 16),
          author: author,
          attachments: const [file, image],
        ),
      );

      final message = (await repository.watch('c1').first).single;
      expect(message.attachments.map((a) => a.name), ['메모.txt', 'shot.png']);
      expect(message.attachments[1].width, 800);
    });

    test('★ 큐에 있는 동안에도 파일 이름이 보인다', () async {
      // 요약을 함께 담아 두지 않으면 전송 전까지 첨부가 없는 것처럼 보인다.
      await repository.enqueue(
        spaceId: 's1',
        channelId: 'c1',
        body: '',
        author: author,
        attachments: const [file],
      );

      final message = (await repository.watch('c1').first).single;
      expect(message.pending, isTrue);
      expect(message.attachments.single.name, '메모.txt');
    });

    test('★ 전송할 때 첨부 id 를 함께 보낸다', () async {
      await repository.enqueue(
        spaceId: 's1',
        channelId: 'c1',
        body: '파일',
        author: author,
        attachments: const [file, image],
      );
      await repository.flush();

      expect(api.sentAttachmentIds, [
        ['a1', 'a2'],
      ]);
    });

    test('★ 본문 없이 첨부만 있어도 큐에 들어간다', () async {
      await repository.enqueue(
        spaceId: 's1',
        channelId: 'c1',
        body: '',
        author: author,
        attachments: const [file],
      );

      expect(await db.queuedMessages(), hasLength(1));
    });

    test('★ 오프라인이면 첨부 id 를 들고 큐에 남는다', () async {
      // 업로드는 이미 끝났다. 남은 것은 연결뿐이라 재연결 때 그대로 나간다.
      api.failWith = ApiFailure.network;
      await repository.enqueue(
        spaceId: 's1',
        channelId: 'c1',
        body: '파일',
        author: author,
        attachments: const [file],
      );
      await repository.flush();

      final queued = await db.queuedMessages();
      expect(queued.single.attachmentIds, ['a1']);
      expect(queued.single.failed, isFalse);

      api.failWith = null;
      await repository.flush();
      expect(api.sentAttachmentIds, [
        ['a1'],
      ]);
    });

    test('첨부가 없으면 빈 목록으로 나간다', () async {
      await repository.enqueue(
        spaceId: 's1',
        channelId: 'c1',
        body: '그냥 글',
        author: author,
      );
      await repository.flush();

      expect(api.sentAttachmentIds, [<String>[]]);
    });
  });
}

class _FakeApi implements MessagesApi {
  ApiFailure? failWith;
  final List<List<String>> sentAttachmentIds = [];
  int _serial = 0;

  @override
  Future<Message> send({
    required String spaceId,
    required String channelId,
    required String body,
    String? parentId,
    String? quotedMessageId,
    List<String> attachmentIds = const [],
  }) async {
    if (failWith != null) throw ApiException(failWith!);
    sentAttachmentIds.add(attachmentIds);
    return Message(
      id: 'server-${++_serial}',
      channelId: channelId,
      body: body,
      createdAt: DateTime.utc(2026, 8, 16),
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
  Future<ThreadPage> listReplies({
    required String spaceId,
    required String messageId,
    String? cursor,
    int limit = 50,
  }) async =>
      throw UnimplementedError();

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
