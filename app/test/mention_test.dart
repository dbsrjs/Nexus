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

  group('filterMembers · applyMention', () {
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

    test('★ 고르면 본문에 이름이 아니라 id 가 박힌다', () {
      const text = '안녕 @홍';
      final query = findMentionQuery(text, text.length)!;
      final result = applyMention(text, query, members.first);

      expect(result.text, '안녕 <@$uuid> ');
      expect(result.cursor, result.text.length);
    });

    test('문장 가운데서 골라도 뒤 글자가 남는다', () {
      const text = '@홍 님 확인';
      final query = findMentionQuery(text, 2)!;
      final result = applyMention(text, query, members.first);

      expect(result.text, '<@$uuid>  님 확인');
    });
  });
}
