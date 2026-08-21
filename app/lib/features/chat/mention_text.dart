import '../../domain/models/message.dart';
import '../../shared/markdown/inline.dart';

/// 본문을 그리기 위해 쪼갠 조각.
///
/// **마크다운 도입 이후 이 파일은 어댑터다** — 실제 파싱은
/// `shared/markdown/inline.dart` 가 한다. 마크다운과 멘션이 한 본문을 나눠
/// 가지므로 파서가 하나여야 하기 때문이다(마크다운 설계 §0).
///
/// 이 함수는 **서식을 그리지 않는 자리**를 위해 남는다 — 인용 요약, 답장
/// 미리보기처럼 한 줄로 줄이는 곳이다. 거기서도 `<@uuid>` 가 보이면 무엇에
/// 답하는지 읽을 수 없으므로 이름으로 바꾸는 일은 여전히 필요하다.
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
/// [fallbackNames] 는 **메시지에 이름이 실려 오지 않는 자리**를 위한 것이다 —
/// 아직 보내지 못한 큐의 메시지(서버가 멘션을 아직 붙이지 않았다)와 인용
/// 요약(서버가 본문만 준다)이 그렇다. 스페이스 멤버 목록에서 채운다.
List<MentionSpan> buildMentionSpans(
  String body,
  List<MessageMention> mentions, {
  Map<String, String> fallbackNames = const {},
}) {
  final names = <String, String>{
    ...fallbackNames,
    // 메시지에 실려 온 이름이 우선이다 — 그 시점의 이름이기 때문이다.
    for (final m in mentions)
      if (m.userId != null && m.name != null) m.userId!: m.name!,
  };

  final spans = <MentionSpan>[];

  // **서식은 무시하고 평평하게 편다.** 이 함수를 쓰는 자리는 마크다운을
  // 그리지 않는 곳이라, 트리를 글자로 되돌려 준다. 서식 문자(`**`)는 파서가
  // 이미 걷어냈으므로 여기서 다시 나타나지 않는다.
  void walk(List<InlineNode> nodes) {
    for (final node in nodes) {
      if (node.kind == InlineKind.mention) {
        spans.add(MentionSpan.mention(node.text, userId: node.userId));
        continue;
      }
      if (node.children.isNotEmpty) {
        walk(node.children);
        continue;
      }
      // 앞 조각이 텍스트면 이어 붙인다 — 이 함수의 계약은 텍스트를 잘게
      // 쪼개지 않는 것이다(멘션 사이의 글자가 한 조각이어야 한다).
      if (spans.isNotEmpty && !spans.last.isMention) {
        final merged = spans.removeLast().text + node.text;
        spans.add(MentionSpan.text(merged));
      } else {
        spans.add(MentionSpan.text(node.text));
      }
    }
  }

  walk(parseInline(body, names: names));
  return spans;
}

/// 멘션을 이름으로 바꾼 **평문**.
///
/// 인용 블록·답장 미리보기처럼 한 줄로 줄여 보여 주는 자리에서 쓴다. 거기에도
/// `<@uuid>` 가 보이면 무엇에 답하는지 읽을 수 없다.
String mentionPlainText(
  String body,
  List<MessageMention> mentions, {
  Map<String, String> fallbackNames = const {},
}) {
  if (!body.contains('<@')) return body;
  return buildMentionSpans(body, mentions, fallbackNames: fallbackNames)
      .map((span) => span.text)
      .join();
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
