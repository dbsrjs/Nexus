import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_app/domain/models/message.dart';
import 'package:nexus_app/domain/models/space_member.dart';
import 'package:nexus_app/features/chat/mention_autocomplete.dart';
import 'package:nexus_app/features/chat/mention_text.dart';

/// 멘션(7-4) 앱 쪽 규칙.
///
/// 서버 계약은 `npm run check:mentions` 가 확인한다. 여기서 덮는 것은 **앱에만
/// 있는 두 계산**이다.
///
/// 1. 본문의 `<@uuid>` 를 이름으로 바꿔 그리기 — 틀리면 화면에 id 가 그대로 뜬다
/// 2. 입력 자동완성 — 서버가 id 형식을 요구하므로 이것이 없으면 사용자가
///    멘션을 만들 방법이 아예 없다
void main() {
  const uuid = '3f2504e0-4f89-41d3-9a0c-0305e82c3301';
  const other = 'a1b2c3d4-e5f6-4a5b-8c7d-9e0f1a2b3c4d';

  const mentions = [
    MessageMention(type: 'user', userId: uuid, name: '홍길동'),
  ];

  group('buildMentionSpans - 본문을 이름으로 그린다', () {
    test('id 자리에 이름이 들어간다', () {
      final spans = buildMentionSpans('<@$uuid> 안녕', mentions);

      expect(spans.map((s) => s.text).join(), '@홍길동 안녕');
      expect(spans.first.isMention, isTrue);
      expect(spans.last.isMention, isFalse);
    });

    test('★ 이름을 못 찾으면 id 를 그대로 보이지 않는다', () {
      // 멤버가 나갔거나 목록이 아직 없을 때. 원본 표기가 보이면 읽을 수 없다.
      final spans = buildMentionSpans('<@$uuid> 안녕', const []);
      expect(spans.first.text, '@알 수 없음');
    });

    test('여러 멘션과 사이 글자를 순서대로 쪼갠다', () {
      final spans = buildMentionSpans(
        '<@$uuid> 그리고 <@$other> 확인',
        const [
          MessageMention(type: 'user', userId: uuid, name: '홍길동'),
          MessageMention(type: 'user', userId: other, name: '김철수'),
        ],
      );

      expect(spans.map((s) => s.text).join(), '@홍길동 그리고 @김철수 확인');
      expect(spans.where((s) => s.isMention).length, 2);
    });

    test('@channel 도 강조 대상이다', () {
      final spans = buildMentionSpans('@channel 공지', const []);
      expect(spans.first.text, '@channel');
      expect(spans.first.isMention, isTrue);
      expect(spans.first.userId, isNull);
    });

    test('★ 이메일 속 @ 는 멘션이 아니다', () {
      final spans = buildMentionSpans('name@channel.com 으로', const []);
      expect(spans.every((s) => !s.isMention), isTrue);
    });

    test('멘션이 없으면 통째로 한 조각', () {
      final spans = buildMentionSpans('그냥 본문', const []);
      expect(spans.single.text, '그냥 본문');
      expect(spans.single.isMention, isFalse);
    });

    test('★ 메시지에 이름이 없으면 멤버 목록으로 채운다', () {
      // 아직 보내지 못한 큐의 메시지에는 서버가 붙여 주는 멘션 목록이 없다.
      final spans = buildMentionSpans(
        '<@$uuid> 안녕',
        const [],
        fallbackNames: const {uuid: '홍길동'},
      );

      expect(spans.first.text, '@홍길동');
    });

    test('메시지에 실려 온 이름이 우선이다', () {
      // 보낸 시점의 이름이 그 메시지의 맥락이다.
      final spans = buildMentionSpans(
        '<@$uuid>',
        mentions,
        fallbackNames: const {uuid: '지금이름'},
      );

      expect(spans.single.text, '@홍길동');
    });
  });

  group('mentionPlainText - 인용·미리보기', () {
    test('★ 인용문에도 id 가 보이지 않는다', () {
      // 인용 요약에는 멘션 목록이 없다(서버가 본문만 준다).
      expect(
        mentionPlainText(
          '<@$uuid> 확인',
          const [],
          fallbackNames: const {uuid: '홍길동'},
        ),
        '@홍길동 확인',
      );
    });

    test('멘션이 없으면 본문 그대로', () {
      expect(mentionPlainText('그냥 글', const []), '그냥 글');
    });
  });

  group('mentionsMe - 나를 불렀는지', () {
    Message withMentions(List<MessageMention> list) => Message(
          id: 'm1',
          channelId: 'c1',
          body: '본문',
          createdAt: DateTime.utc(2026, 8, 16),
          author: const MessageAuthor(id: 'someone', name: '남'),
          mentions: list,
        );

    test('내 id 가 있으면 참', () {
      expect(mentionsMe(withMentions(mentions), uuid), isTrue);
    });

    test('남만 불렸으면 거짓', () {
      expect(mentionsMe(withMentions(mentions), other), isFalse);
    });

    test('★ @everyone 은 나도 부른 것이다', () {
      final m = withMentions(const [MessageMention(type: 'everyone')]);
      expect(mentionsMe(m, other), isTrue);
    });
  });

  group('findMentionQuery - 지금 멘션을 치는 중인가', () {
    test('@ 만 쳐도 후보를 띄운다', () {
      final q = findMentionQuery('안녕 @', 4);
      expect(q, isNotNull);
      expect(q!.text, isEmpty);
      expect(q.start, 3);
    });

    test('@ 뒤에 친 글자를 넘겨준다', () {
      expect(findMentionQuery('@홍길', 3)!.text, '홍길');
    });

    test('★ 공백이 끼면 이미 끝난 단어다', () {
      expect(findMentionQuery('@홍길동 안녕', 8), isNull);
    });

    test('★ 이메일의 @ 는 잡지 않는다', () {
      // 앞이 글자면 주소의 일부다.
      expect(findMentionQuery('me@exam', 7), isNull);
    });

    test('줄 시작의 @ 는 잡는다', () {
      expect(findMentionQuery('@홍', 2), isNotNull);
    });

    test('@ 가 없으면 null', () {
      expect(findMentionQuery('그냥 글', 3), isNull);
    });
  });

  group('filterMembers', () {
    const members = [
      SpaceMemberProfile(userId: uuid, name: '홍길동'),
      SpaceMemberProfile(userId: other, name: '김철수'),
    ];

    test('친 글자로 거른다', () {
      expect(filterMembers(members, '홍').single.userId, uuid);
    });

    test('빈 글자면 전부 후보', () {
      expect(filterMembers(members, ''), hasLength(2));
    });

    test('★ 자기 자신은 후보에서 뺀다', () {
      // 서버가 자기 멘션을 저장하지 않으므로 골라도 아무 일이 없다.
      final result = filterMembers(members, '', excludeUserId: uuid);
      expect(result.single.userId, other);
    });

    test('별명이 있으면 별명으로 찾는다', () {
      const withNick = [
        SpaceMemberProfile(userId: uuid, name: '홍길동', nickname: '길동'),
      ];
      expect(filterMembers(withNick, '길동'), hasLength(1));
    });

  });

  /// 입력창은 **이름을 보여 주고 보낼 때만 id 로 되돌린다.**
  ///
  /// 저장 형식은 그대로 `<@id>` 다. 다만 그 형식이 입력창에까지 보이면 누구를
  /// 부른 것인지 읽을 수 없다 — 실제로 `<@c0f87f1f-...>` 가 그대로 보였다.
  group('MentionDraft - 보이는 것은 이름, 보내는 것은 id', () {
    const members = [
      SpaceMemberProfile(userId: uuid, name: '홍길동'),
      SpaceMemberProfile(userId: other, name: '김철수'),
    ];

    /// 커서를 안 주면 글 끝에서 고른 것으로 본다.
    MentionInsertion pick(MentionDraft draft, [int? cursor, int index = 0]) {
      final query = findMentionQuery(draft.text, cursor ?? draft.text.length)!;
      return draft.insert(query, members[index]);
    }

    test('★ 고르면 입력창에는 이름이 보인다', () {
      final result = pick(const MentionDraft(text: '안녕 @홍'));

      expect(result.draft.text, '안녕 @홍길동 ');
      expect(result.cursor, result.draft.text.length);
    });

    test('★ 보낼 때는 id 로 되돌린다', () {
      final result = pick(const MentionDraft(text: '안녕 @홍'));

      expect(result.draft.toBody(), '안녕 <@$uuid> ');
    });

    test('문장 가운데서 골라도 뒤 글자가 남는다', () {
      final result = pick(const MentionDraft(text: '@홍 님 확인'), 2);

      expect(result.draft.text, '@홍길동  님 확인');
      expect(result.draft.toBody(), '<@$uuid>  님 확인');
    });

    test('★ 둘을 부르면 둘 다 되돌아간다', () {
      // 뒤에서부터 갈아 끼우지 않으면 앞의 길이 변화로 뒤 위치가 어긋난다.
      var draft = pick(const MentionDraft(text: '@홍')).draft;
      draft = pick(draft.withText('${draft.text}@김'), draft.text.length + 2, 1)
          .draft;

      expect(draft.text, '@홍길동 @김철수 ');
      expect(draft.toBody(), '<@$uuid> <@$other> ');
    });

    test('★ 뒤에 이어 써도 멘션 자리는 그대로다', () {
      final draft = pick(const MentionDraft(text: '@홍'))
          .draft
          .withText('@홍길동 확인 부탁');

      expect(draft.toBody(), '<@$uuid> 확인 부탁');
    });

    test('★ 앞에 끼워 써도 따라 밀린다', () {
      final draft =
          pick(const MentionDraft(text: '@홍')).draft.withText('저기 @홍길동 ');

      expect(draft.toBody(), '저기 <@$uuid> ');
    });

    test('★ 이름 안쪽을 지우면 멘션이 아니게 된다', () {
      // 글자는 남기고 표시만 푼다. 사용자가 지우려던 것보다 많이 지우지 않는다.
      final draft =
          pick(const MentionDraft(text: '@홍')).draft.withText('@홍길 ');

      expect(draft.mentions, isEmpty);
      expect(draft.toBody(), '@홍길 ');
    });

    test('★ 통째로 지우면 함께 사라진다', () {
      final draft = pick(const MentionDraft(text: '@홍')).draft.withText('');

      expect(draft.mentions, isEmpty);
      expect(draft.toBody(), '');
    });

    test('이름에 공백이 있어도 온전히 남는다', () {
      // 이름을 본문에 저장하면 어디까지가 멘션인지 알 수 없는 경우다.
      // 위치를 따로 들고 다니므로 여기서는 문제가 되지 않는다.
      const spaced = SpaceMemberProfile(userId: uuid, name: '홍 길동');
      final query = findMentionQuery('@홍', 2)!;
      final draft = const MentionDraft(text: '@홍').insert(query, spaced).draft;

      expect(draft.text, '@홍 길동 ');
      expect(draft.toBody(), '<@$uuid> ');
    });

    test('별명이 있으면 별명이 보인다', () {
      const nick = SpaceMemberProfile(userId: uuid, name: '홍길동', nickname: '길동');
      final query = findMentionQuery('@길', 2)!;
      final draft = const MentionDraft(text: '@길').insert(query, nick).draft;

      expect(draft.text, '@길동 ');
      expect(draft.toBody(), '<@$uuid> ');
    });

    test('멘션이 없으면 본문이 그대로 나간다', () {
      expect(const MentionDraft().withText('그냥 글').toBody(), '그냥 글');
    });
  });
}
