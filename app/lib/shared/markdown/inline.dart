/// 인라인 마크다운 + 멘션.
///
/// **멘션이 여기 함께 있는 이유**는 한 본문을 두 파서가 각자 쪼개면 위치가
/// 어긋나기 때문이다 (설계 §0). 멘션은 볼드 · 코드와 같은 층의 토큰이다.
///
/// 파서는 위젯을 모른다 — `String` 을 받아 노드 트리를 준다. 그래야 테스트가
/// 화면 없이 돌고, 같은 트리를 화면과 평문화가 함께 쓴다.
enum InlineKind { text, bold, italic, strike, code, spoiler, link, mention }

class InlineNode {
  const InlineNode(
    this.kind,
    this.text, {
    this.children = const [],
    this.url,
    this.userId,
  });

  final InlineKind kind;

  /// 화면에 보일 글자. 감싸는 종류(볼드 등)는 비어 있고 `children` 을 그린다.
  final String text;
  final List<InlineNode> children;

  /// `link` 일 때만. **http(s) 만 채워진다**(설계 §4).
  final String? url;

  /// `mention` 이고 사용자 멘션일 때만. `@channel` · `@everyone` 은 null.
  final String? userId;
}

/// 서버와 같은 형식이어야 한다(server/src/messages/mentions.service.ts).
final _userMention = RegExp(r'<@([0-9a-fA-F-]{36})>');
final _bareUrl = RegExp(r'https?://[^\s<>()\[\]]+');
final _mdLink = RegExp(r'\[([^\]]*)\]\(([^)\s]+)\)');

/// **감싸는 표기.** 긴 것부터 본다 — `**` 를 `*` 둘로 읽으면 빈 이탤릭이 된다.
const _wrappers = <(String, InlineKind)>[
  ('**', InlineKind.bold),
  ('~~', InlineKind.strike),
  ('||', InlineKind.spoiler),
  ('*', InlineKind.italic),
  ('_', InlineKind.italic),
];

List<InlineNode> parseInline(
  String source, {
  Map<String, String> names = const {},
}) {
  if (source.isEmpty) return const [];

  final nodes = <InlineNode>[];
  final buffer = StringBuffer();
  var i = 0;

  void flush() {
    if (buffer.isEmpty) return;
    nodes.add(InlineNode(InlineKind.text, buffer.toString()));
    buffer.clear();
  }

  while (i < source.length) {
    final rest = source.substring(i);

    // ── 코드가 가장 먼저다 ───────────────────────────
    // 안에서는 아무것도 해석하지 않는다 — 그것이 인라인 코드의 존재 이유다.
    if (source[i] == '`') {
      final end = source.indexOf('`', i + 1);
      if (end > i) {
        flush();
        nodes.add(InlineNode(InlineKind.code, source.substring(i + 1, end)));
        i = end + 1;
        continue;
      }
    }

    // ── 멘션 ─────────────────────────────────────────
    final user = _userMention.matchAsPrefix(rest);
    if (user != null) {
      flush();
      final id = user.group(1)!.toLowerCase();
      // 이름을 모르면 `@알 수 없음`. 원본 uuid 를 보이면 읽을 수 없다.
      nodes.add(InlineNode(
        InlineKind.mention,
        '@${names[id] ?? '알 수 없음'}',
        userId: id,
      ));
      i += user.end;
      continue;
    }

    if (rest.startsWith('@channel') || rest.startsWith('@everyone')) {
      // 앞에 공백(또는 시작)이 있어야 한다 — `name@channel.com` 의 일부가 아니다.
      final atStart = i == 0 || _isSpace(source[i - 1]);
      final token = rest.startsWith('@channel') ? '@channel' : '@everyone';
      final after = i + token.length;
      final endsClean = after >= source.length || !_isWordish(source[after]);
      if (atStart && endsClean) {
        flush();
        nodes.add(InlineNode(InlineKind.mention, token));
        i = after;
        continue;
      }
    }

    // ── 링크 ─────────────────────────────────────────
    final md = _mdLink.matchAsPrefix(rest);
    if (md != null && _isSafeUrl(md.group(2)!)) {
      flush();
      nodes.add(InlineNode(
        InlineKind.link,
        '',
        children: parseInline(md.group(1)!, names: names),
        url: md.group(2),
      ));
      i += md.end;
      continue;
    }

    final bare = _bareUrl.matchAsPrefix(rest);
    if (bare != null) {
      flush();
      final url = bare.group(0)!;
      nodes.add(InlineNode(
        InlineKind.link,
        '',
        children: [InlineNode(InlineKind.text, url)],
        url: url,
      ));
      i += bare.end;
      continue;
    }

    // ── 감싸는 표기 ──────────────────────────────────
    var matched = false;
    for (final (mark, kind) in _wrappers) {
      if (!rest.startsWith(mark)) continue;

      final close = source.indexOf(mark, i + mark.length);
      // **닫히지 않으면 서식이 아니다.** 사람이 `**` 를 하나만 치는 일이
      // 흔한데, 그때 나머지 본문이 통째로 굵어지면 안 된다. 빈 것(`****`)도
      // 서식으로 보지 않는다.
      if (close < 0 || close == i + mark.length) continue;

      flush();
      nodes.add(InlineNode(
        kind,
        '',
        children: parseInline(
          source.substring(i + mark.length, close),
          names: names,
        ),
      ));
      i = close + mark.length;
      matched = true;
      break;
    }
    if (matched) continue;

    buffer.write(source[i]);
    i++;
  }

  flush();
  return nodes;
}

/// **http(s) 만 연다.** `javascript:` 같은 스킴이 웹 빌드에서 실행될 수 있다.
bool _isSafeUrl(String url) =>
    url.startsWith('http://') || url.startsWith('https://');

bool _isSpace(String c) => c.trim().isEmpty;

bool _isWordish(String c) {
  final code = c.codeUnitAt(0);
  return (code >= 65 && code <= 90) ||
      (code >= 97 && code <= 122) ||
      (code >= 48 && code <= 57) ||
      code == 95 ||
      code == 46; // `.` — name@channel.com 을 거른다
}
