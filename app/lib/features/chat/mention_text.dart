import '../../domain/models/message.dart';

/// 본문에 박혀 있는 멘션 표기. 서버와 같은 형식이어야 한다
/// (server/src/messages/mentions.service.ts).
final _userMention = RegExp(r'<@([0-9a-fA-F-]{36})>');
final _specialMention = RegExp(r'(^|\s)(@channel|@everyone)\b');

/// 본문을 그리기 위해 쪼갠 조각.
class MentionSpan {
  const MentionSpan.text(this.text)
      : isMention = false,
        userId = null;

  const MentionSpan.mention(this.text, {this.userId}) : isMention = true;

  final String text;
  final bool isMention;

  /// `@channel` · `@everyone` 은 대상이 없어 null.
  final String? userId;
}

/// 본문을 **이름이 보이는 조각들**로 쪼갠다.
///
/// 본문에는 `<@uuid>` 가 박혀 있고 사람이 읽을 이름은 `mentions` 에 따로 온다.
/// 이름을 본문에 저장하지 않는 이유는 사용자가 이름을 바꾸면 지난 메시지가
/// 낡기 때문이다 — 그 대가로 그릴 때 이어 붙이는 일이 생긴다.
///
/// 이름을 못 찾으면(멤버가 나갔거나 목록이 아직 없음) `@알 수 없음` 으로 둔다.
/// 원본 `<@uuid>` 를 그대로 보이면 사용자가 읽을 수 없다.
List<MentionSpan> buildMentionSpans(
  String body,
  List<MessageMention> mentions,
) {
  final nameById = <String, String>{
    for (final m in mentions)
      if (m.userId != null && m.name != null) m.userId!: m.name!,
  };

  final spans = <MentionSpan>[];
  var cursor = 0;

  // 사용자 멘션과 특수 멘션을 한 번에 훑는다. 두 번 나눠 훑으면 위치가 어긋난다.
  final matches = <_Match>[
    for (final m in _userMention.allMatches(body))
      _Match(m.start, m.end, userId: m.group(1)!.toLowerCase()),
    for (final m in _specialMention.allMatches(body))
      // group(1) 은 앞의 공백이라 실제 토큰은 group(2) 부터다.
      _Match(m.start + m.group(1)!.length, m.end, special: m.group(2)!),
  ]..sort((a, b) => a.start.compareTo(b.start));

  for (final match in matches) {
    if (match.start > cursor) {
      spans.add(MentionSpan.text(body.substring(cursor, match.start)));
    }

    if (match.special != null) {
      spans.add(MentionSpan.mention(match.special!));
    } else {
      final name = nameById[match.userId!];
      spans.add(
        MentionSpan.mention(
          name == null ? '@알 수 없음' : '@$name',
          userId: match.userId,
        ),
      );
    }
    cursor = match.end;
  }

  if (cursor < body.length) {
    spans.add(MentionSpan.text(body.substring(cursor)));
  }
  return spans;
}

/// 이 메시지가 **나를** 불렀는지. 강조 여부를 정한다.
///
/// `@channel` · `@everyone` 도 나를 부른 것으로 친다 — 그 채널을 보는 사람
/// 전원이 대상이기 때문이다.
bool mentionsMe(Message message, String myUserId) {
  for (final mention in message.mentions) {
    if (mention.type != 'user') return true;
    if (mention.userId == myUserId) return true;
  }
  return false;
}

class _Match {
  _Match(this.start, this.end, {this.userId, this.special});

  final int start;
  final int end;
  final String? userId;
  final String? special;
}
