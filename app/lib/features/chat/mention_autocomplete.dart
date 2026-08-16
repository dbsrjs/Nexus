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

/// 입력창에 박아 둔 멘션 한 건.
class DraftMention {
  const DraftMention({
    required this.start,
    required this.label,
    required this.userId,
  });

  /// 입력창 본문에서 `@` 가 있는 위치.
  final int start;

  /// 화면에 보이는 글자. `@홍길동` 처럼 `@` 를 포함한다.
  final String label;

  final String userId;

  int get end => start + label.length;

  DraftMention shifted(int delta) =>
      DraftMention(start: start + delta, label: label, userId: userId);
}

/// 작성 중인 본문과, 그 안의 멘션이 어디를 차지하는지.
///
/// **입력창에는 `@닉네임` 이 보이고 서버로 나갈 때만 `<@id>` 로 되돌린다.**
/// 저장 형식은 여전히 id 다(이름을 저장하면 사용자가 이름을 바꿀 때 지난
/// 메시지가 낡는다). 다만 그 형식을 사람에게까지 보여 줄 이유는 없다 —
/// 입력창에 uuid 가 박혀 있으면 **누구를 부른 것인지 읽을 수 없다.**
///
/// 이름을 본문에 그대로 두고 보낼 때 다시 찾는 방법은 쓰지 않는다. 이름에
/// 공백이 있으면 어디까지가 멘션인지 알 수 없고 동명이인도 가릴 수 없다 —
/// 7-4 에서 저장 형식을 id 로 정한 이유가 그대로 여기에도 걸린다. 그래서
/// **위치를 따로 들고 다닌다.**
class MentionDraft {
  const MentionDraft({this.text = '', this.mentions = const []});

  final String text;

  /// 시작 위치 오름차순. `toBody()` 가 뒤에서부터 갈아 끼우는 전제다.
  final List<DraftMention> mentions;

  /// 치던 `@글자` 를 `@닉네임 ` 으로 갈아 끼운다.
  ///
  /// 뒤에 공백을 붙여 바로 이어 쓸 수 있게 한다.
  MentionInsertion insert(MentionQuery query, SpaceMemberProfile member) {
    final label = '@${member.displayName}';
    final replaced = query.start + 1 + query.text.length;
    final delta = label.length + 1 - (replaced - query.start);

    final next = <DraftMention>[
      for (final m in mentions)
        if (m.end <= query.start)
          m
        else if (m.start >= replaced)
          m.shifted(delta),
      DraftMention(start: query.start, label: label, userId: member.userId),
    ]..sort((a, b) => a.start.compareTo(b.start));

    return MentionInsertion(
      draft: MentionDraft(
        text: text.replaceRange(query.start, replaced, '$label '),
        mentions: next,
      ),
      cursor: query.start + label.length + 1,
    );
  }

  /// 사용자가 입력창을 고친 뒤 위치를 다시 맞춘다.
  ///
  /// 한 곳만 고쳤다고 보고 앞뒤로 같은 부분을 걷어내 바뀐 구간을 찾는다.
  /// **고친 구간이 멘션 안쪽을 건드렸으면 그 멘션은 버린다** — 글자는 그대로
  /// 두고 표시만 푼다. 사용자가 지우려던 것보다 많이 지우지 않기 위함이고,
  /// 강조가 사라지는 것이 곧 "이제 멘션이 아니다"라는 신호가 된다.
  MentionDraft withText(String next) {
    if (next == text) return this;
    if (mentions.isEmpty) return MentionDraft(text: next);

    final shortest = text.length < next.length ? text.length : next.length;
    var prefix = 0;
    while (prefix < shortest && text.codeUnitAt(prefix) == next.codeUnitAt(prefix)) {
      prefix++;
    }
    var suffix = 0;
    while (suffix < shortest - prefix &&
        text.codeUnitAt(text.length - 1 - suffix) ==
            next.codeUnitAt(next.length - 1 - suffix)) {
      suffix++;
    }

    // 지워진 구간은 [prefix, removedEnd) 이고 그 자리에 새 글자가 들어갔다.
    final removedEnd = text.length - suffix;
    final delta = next.length - text.length;

    final kept = <DraftMention>[];
    for (final mention in mentions) {
      final moved = mention.end <= prefix
          ? mention
          : (mention.start >= removedEnd ? mention.shifted(delta) : null);
      if (moved == null) continue;

      // 안전망. 한 곳만 고쳤다는 전제가 깨져도(붙여넣기 등) 엉뚱한 자리를
      // id 로 되돌리는 일만은 없어야 한다.
      if (moved.end > next.length) continue;
      if (next.substring(moved.start, moved.end) != moved.label) continue;
      kept.add(moved);
    }
    return MentionDraft(text: next, mentions: kept);
  }

  /// 서버로 보낼 본문. 보이던 이름을 `<@id>` 로 되돌린다.
  ///
  /// 뒤에서부터 갈아 끼운다 — 앞부터 하면 길이가 바뀌어 뒤 위치가 어긋난다.
  String toBody() {
    var body = text;
    for (var i = mentions.length - 1; i >= 0; i--) {
      final mention = mentions[i];
      body = body.replaceRange(mention.start, mention.end, '<@${mention.userId}>');
    }
    return body;
  }
}

/// 고른 멤버를 끼워 넣은 결과.
class MentionInsertion {
  const MentionInsertion({required this.draft, required this.cursor});

  final MentionDraft draft;

  /// 끼워 넣은 뒤 커서가 갈 자리. 붙인 공백 뒤다.
  final int cursor;
}
