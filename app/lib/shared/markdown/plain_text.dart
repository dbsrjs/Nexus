import 'block.dart';
import 'inline.dart';

/// 서식을 벗겨 **한 줄**로 만든다.
///
/// 원문을 그대로 저장하기 때문에(설계 §3) 한 줄로 줄여 보여주는 자리에서는
/// `**굵게**` 가 그대로 보인다. 그 자리에서만 이것을 쓴다 — 인용 요약,
/// 대화 → 이슈의 제목 미리채움, 앞으로 생길 알림.
///
/// **검색에는 쓰지 않는다.** 검색은 원문으로 한다 — 벗긴 사본을 따로 저장하면
/// 그것이 원문과 어긋나는 순간이 온다.
String toPlainText(String source, {Map<String, String> names = const {}}) {
  final parts = <String>[];

  for (final block in parseBlocks(source)) {
    switch (block.kind) {
      case BlockKind.code:
        // 코드블록도 한 줄로 접는다 — 미리보기에 열 줄이 펼쳐지면 안 된다.
        parts.addAll(block.lines);
      case BlockKind.table:
        for (final row in block.rows) {
          parts.addAll(row);
        }
      default:
        for (final line in block.lines) {
          parts.add(_flatten(parseInline(line, names: names)));
        }
    }
  }

  return parts
      .map((p) => p.trim())
      .where((p) => p.isNotEmpty)
      .join(' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

String _flatten(List<InlineNode> nodes) {
  final buffer = StringBuffer();
  for (final node in nodes) {
    if (node.children.isNotEmpty) {
      buffer.write(_flatten(node.children));
    } else {
      buffer.write(node.text);
    }
  }
  return buffer.toString();
}
