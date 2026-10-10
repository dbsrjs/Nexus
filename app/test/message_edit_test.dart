import 'package:drift/native.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_app/data/api/api_failure.dart';
import 'package:nexus_app/data/api/messages_api.dart';
import 'package:nexus_app/data/local/app_database.dart';
import 'package:nexus_app/data/repositories/message_repository.dart';
import 'package:nexus_app/domain/models/message.dart';
import 'package:nexus_app/features/chat/mention_autocomplete.dart';
import 'package:nexus_app/features/chat/message_edit.dart';
import 'package:nexus_app/ui/ui.dart';

import 'support/nx_host.dart';

/// 메시지 수정 · 삭제(2026-10-11). 서버 계약은 `check:messages` 쪽(수정 이력 · 소프트 삭제)이 본다.
/// 여기서는 앱이 **캐시를 어떻게 고치는가**와 멘션 되돌리기를 고정한다.
void main() {
  const ann = '11111111-1111-4111-8111-111111111111';
  const ben = '22222222-2222-4222-8222-222222222222';

  group('MentionDraft.fromBody — 저장 본문을 입력창 모양으로', () {
    test('★ 아는 id 는 @이름 으로 보이고 toBody 가 그대로 되돌린다', () {
      const body = '안녕 <@$ann> 그리고 <@$ben>!';
      final draft = MentionDraft.fromBody(body, {ann: '앤', ben: '벤 자민'});
      expect(draft.text, '안녕 @앤 그리고 @벤 자민!');
      expect(draft.mentions.map((m) => m.userId), [ann, ben]);
      expect(draft.toBody(), body);
    });

    test('모르는 id(떠난 사람)는 글자 그대로 두어 저장해도 바뀌지 않는다', () {
      const body = '<@$ann> 와 <@$ben>';
      final draft = MentionDraft.fromBody(body, {ben: '벤'});
      expect(draft.text, '<@$ann> 와 @벤');
      expect(draft.toBody(), body);
    });

    test('멘션 앞의 글자를 고쳐도 멘션 자리가 따라간다', () {
      final draft = MentionDraft.fromBody('hi <@$ann>', {ann: '앤'});
      expect(draft.withText('hello @앤').toBody(), 'hello <@$ann>');
    });
  });

  group('캐시 반영', () {
    late AppDatabase db;
    late _FakeApi api;
    late MessageRepository repository;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      api = _FakeApi();
      repository = MessageRepository(api: api, db: db);
    });

    tearDown(() => db.close());

    Future<void> seed() => db.upsertMessage(
      's1',
      Message(
        id: 'm1',
        channelId: 'c1',
        body: '처음',
        createdAt: DateTime.utc(2026, 10, 11),
        author: const MessageAuthor(id: 'u1', name: '나'),
        reactions: const [MessageReaction(emoji: '👍', count: 2, mine: true)],
        mentions: const [MessageMention(type: 'user', userId: ann)],
      ),
    );

    Future<Message> current() async =>
        (await db.watchChannelMessages('c1').first).single;

    test('★ 수정은 본문 · 수정 시각만 바꾸고 리액션 · 멘션을 지킨다', () async {
      // 서버의 수정 응답 · message:edited 에는 리액션 · 멘션이 없다. 예전에는 통째로 덮어
      // 다른 사람 화면에서도 리액션과 멘션 강조가 사라졌다.
      await seed();
      final at = DateTime.utc(2026, 10, 11, 9);
      await repository.applyEdited(
        Message(
          id: 'm1',
          channelId: 'c1',
          body: '고친 글',
          createdAt: DateTime.utc(2026, 10, 11),
          editedAt: at,
          author: const MessageAuthor(id: 'u1', name: '나'),
        ),
      );

      final m = await current();
      expect(m.body, '고친 글');
      expect(m.editedAt!.isAtSameMomentAs(at), isTrue);
      expect(m.reactions.single.emoji, '👍');
      expect(m.reactions.single.count, 2);
      expect(m.mentions.single.userId, ann);
    });

    test('내 수정은 서버에 보내고 응답의 본문을 캐시에 넣는다', () async {
      await seed();
      await repository.edit(spaceId: 's1', messageId: 'm1', body: '서버로');
      expect(api.edited, ['m1:서버로']);
      expect((await current()).body, '서버로');
      expect((await current()).reactions, isNotEmpty);
    });

    test('★ 수정이 실패하면 던지고 캐시는 그대로다 — 대화상자가 이유를 보인다', () async {
      await seed();
      api.fail = true;
      await expectLater(
        repository.edit(spaceId: 's1', messageId: 'm1', body: 'x'),
        throwsA(isA<ApiException>()),
      );
      expect((await current()).body, '처음');
    });

    test('삭제하면 본문이 가려진다(소프트 삭제)', () async {
      await seed();
      await repository.remove(spaceId: 's1', messageId: 'm1');
      expect(api.removed, ['m1']);
      final m = await current();
      expect(m.isDeleted, isTrue);
      expect(m.body, isEmpty);
    });

    test('★ 삭제가 실패하면 던지고 메시지는 남는다', () async {
      await seed();
      api.fail = true;
      await expectLater(
        repository.remove(spaceId: 's1', messageId: 'm1'),
        throwsA(isA<ApiException>()),
      );
      expect((await current()).isDeleted, isFalse);
    });
  });

  group('EditMessageForm', () {
    testWidgets('★ 바꾸기 전에는 저장할 수 없고, 저장하면 <@id> 로 되돌려 보낸다', (tester) async {
      final saved = <String>[];
      await tester.pumpWidget(
        nxTestApp(
          home: EditMessageForm(
            initial: MentionDraft.fromBody('hi <@$ann>', {ann: '앤'}),
            onSave: (body) async => saved.add(body),
          ),
        ),
      );

      NxButton save() => tester.widget<NxButton>(find.byType(NxButton));
      expect(find.text('hi @앤'), findsOneWidget);
      expect(save().onPressed, isNull);

      await tester.enterText(find.byType(EditableText), 'hello @앤');
      await tester.pump();
      expect(save().onPressed, isNotNull);

      await tester.tap(find.text('저장'));
      await tester.pump();
      expect(saved, ['hello <@$ann>']);
    });

    testWidgets('비우면 저장할 수 없다', (tester) async {
      await tester.pumpWidget(
        nxTestApp(
          home: EditMessageForm(
            initial: const MentionDraft(text: '글'),
            onSave: (_) async {},
          ),
        ),
      );
      await tester.enterText(find.byType(EditableText), '   ');
      await tester.pump();
      expect(tester.widget<NxButton>(find.byType(NxButton)).onPressed, isNull);
    });
  });
}

class _FakeApi implements MessagesApi {
  bool fail = false;
  final edited = <String>[];
  final removed = <String>[];

  @override
  Future<Message> edit({
    required String spaceId,
    required String messageId,
    required String body,
  }) async {
    if (fail) throw const ApiException(ApiFailure.network);
    edited.add('$messageId:$body');
    return Message(
      id: messageId,
      channelId: 'c1',
      body: body,
      createdAt: DateTime.utc(2026, 10, 11),
      editedAt: DateTime.utc(2026, 10, 11, 10),
      author: const MessageAuthor(id: 'u1', name: '나'),
    );
  }

  @override
  Future<void> remove({
    required String spaceId,
    required String messageId,
  }) async {
    if (fail) throw const ApiException(ApiFailure.network);
    removed.add(messageId);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
