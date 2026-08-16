import '../../domain/models/space_member.dart';

/// 입력창에서 지금 치고 있는 멘션.
class MentionQuery {
  const MentionQuery({
    required this.start,
    required this.text,
  });

  /// 본문에서 `@` 가 시작하는 위치. 고른 뒤 갈아 끼울 범위의 왼쪽 끝이다.
  final int start;

  /// `@` 뒤에 친 글자. 빈 문자열이면 방금 `@` 만 쳤다는 뜻이다.
  final String text;
}

/// 커서 위치를 보고 **지금 멘션을 치는 중인지** 판단한다.
///
/// 규칙:
/// - 커서 왼쪽에서 가장 가까운 `@` 를 찾는다
/// - 그 사이에 공백이나 줄바꿈이 있으면 멘션이 아니다(이미 끝난 단어다)
/// - `@` 앞은 줄 시작이거나 공백이어야 한다 — 이메일 주소의 `@` 를 걸러낸다
///
/// 반환이 null 이면 자동완성을 띄우지 않는다.
MentionQuery? findMentionQuery(String text, int cursor) {
  if (cursor < 0 || cursor > text.length) return null;

  final at = text.lastIndexOf('@', cursor - 1);
  if (at < 0) return null;

  // `@` 앞이 글자면 이메일 같은 것이다.
  if (at > 0) {
    final before = text[at - 1];
    if (before != ' ' && before != '\n') return null;
  }

  final typed = text.substring(at + 1, cursor);
  if (typed.contains(' ') || typed.contains('\n')) return null;

  return MentionQuery(start: at, text: typed);
}

/// 친 글자로 멤버를 거른다.
///
/// **자기 자신은 뺀다.** 서버가 자기 멘션을 저장하지 않으므로(뱃지가 자기 글로
/// 켜지면 뜻이 없다) 후보에 두면 골라도 아무 일이 없어 혼란스럽다.
List<SpaceMemberProfile> filterMembers(
  List<SpaceMemberProfile> members,
  String query, {
  String? excludeUserId,
  int limit = 8,
}) {
  final needle = query.toLowerCase();
  final result = <SpaceMemberProfile>[];

  for (final member in members) {
    if (member.userId == excludeUserId) continue;
    if (needle.isEmpty ||
        member.displayName.toLowerCase().contains(needle)) {
      result.add(member);
      if (result.length >= limit) break;
    }
  }
  return result;
}

/// 고른 멤버를 본문에 끼워 넣은 결과.
class MentionInsertion {
  const MentionInsertion({required this.text, required this.cursor});

  final String text;
  final int cursor;
}

/// 치던 `@글자` 를 `<@userId> ` 로 갈아 끼운다.
///
/// **본문에 이름이 아니라 id 를 넣는다.** 이름을 넣으면 사용자가 이름을 바꿀 때
/// 지난 메시지가 낡고, 동명이인을 구분할 수 없다(서버가 같은 형식을 요구한다).
/// 뒤에 공백을 붙여 바로 이어 쓸 수 있게 한다.
MentionInsertion applyMention(
  String text,
  MentionQuery query,
  SpaceMemberProfile member,
) {
  final token = '<@${member.userId}> ';
  final end = query.start + 1 + query.text.length;
  final next = text.replaceRange(query.start, end, token);
  return MentionInsertion(text: next, cursor: query.start + token.length);
}
