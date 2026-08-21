/// 블록 마크다운. **줄 단위**이고 인라인을 모른다 — 렌더링할 때 각 줄에
/// 대해 인라인 파서를 부른다 (설계 §2).
///
/// **블록 중첩을 넣지 않는다**(인용 안의 목록 등). 한 겹이면 파서가 줄 단위로
/// 끝나고, 채팅에서 쓰임이 드물다 (설계 §1).
enum BlockKind { paragraph, code, quote, list, heading, table }

class BlockNode {
  const BlockNode(
    this.kind, {
    this.lines = const [],
    this.language,
    this.level,
    this.ordered = false,
    this.rows = const [],
  });

  final BlockKind kind;

  /// 문단 · 인용 · 목록 · 코드의 줄들. 마커(`> ` · `- `)는 벗겨져 있다.
  final List<String> lines;

  /// 코드블록의 언어(``` 뒤). 없으면 null.
  final String? language;

  /// 제목 단계 1~3.
  final int? level;

  /// 목록이 번호 목록인지.
  final bool ordered;

  /// 표. **첫 행이 헤더다.**
  final List<List<String>> rows;
}

final _heading = RegExp(r'^(#{1,3})\s+(.*)$');
final _bullet = RegExp(r'^[-*]\s+(.*)$');
final _ordered = RegExp(r'^\d+[.)]\s+(.*)$');
final _tableDivider = RegExp(r'^\|?\s*:?-{2,}:?\s*(\|\s*:?-{2,}:?\s*)*\|?$');

List<BlockNode> parseBlocks(String source) {
  final lines = source.split('\n');
  final blocks = <BlockNode>[];
  var i = 0;

  while (i < lines.length) {
    final line = lines[i];

    // ── 코드블록이 가장 먼저다 ──────────────────────
    // 안에서는 다른 블록을 찾지 않는다.
    if (line.trimLeft().startsWith('```')) {
      final language = line.trimLeft().substring(3).trim();
      final body = <String>[];
      i++;
      while (i < lines.length && !lines[i].trimLeft().startsWith('```')) {
        body.add(lines[i]);
        i++;
      }
      // 닫는 ``` 을 지나간다. **없으면 끝까지 코드다** — 여기서 되돌리면
      // 사람이 코드블록을 쓰다 만 순간 본문이 통째로 다르게 그려진다.
      if (i < lines.length) i++;
      blocks.add(BlockNode(
        BlockKind.code,
        lines: body,
        language: language.isEmpty ? null : language,
      ));
      continue;
    }

    if (line.trim().isEmpty) {
      i++;
      continue;
    }

    // ── 제목 ─────────────────────────────────────────
    final heading = _heading.firstMatch(line);
    if (heading != null) {
      blocks.add(BlockNode(
        BlockKind.heading,
        lines: [heading.group(2)!],
        level: heading.group(1)!.length,
      ));
      i++;
      continue;
    }

    // ── 표 — **구분 행이 있어야 표다** ──────────────
    // 그냥 파이프를 쓴 문장이 표로 바뀌면 안 된다.
    if (line.contains('|') &&
        i + 1 < lines.length &&
        _tableDivider.hasMatch(lines[i + 1].trim())) {
      final rows = <List<String>>[_splitRow(line)];
      i += 2;
      while (i < lines.length && lines[i].contains('|')) {
        rows.add(_splitRow(lines[i]));
        i++;
      }
      blocks.add(BlockNode(BlockKind.table, rows: rows));
      continue;
    }

    // ── 인용 ─────────────────────────────────────────
    if (line.trimLeft().startsWith('>')) {
      final body = <String>[];
      while (i < lines.length && lines[i].trimLeft().startsWith('>')) {
        body.add(lines[i].trimLeft().substring(1).trimLeft());
        i++;
      }
      blocks.add(BlockNode(BlockKind.quote, lines: body));
      continue;
    }

    // ── 목록 ─────────────────────────────────────────
    final bullet = _bullet.firstMatch(line);
    final ordered = _ordered.firstMatch(line);
    if (bullet != null || ordered != null) {
      final isOrdered = ordered != null;
      final body = <String>[];
      while (i < lines.length) {
        final m = isOrdered
            ? _ordered.firstMatch(lines[i])
            : _bullet.firstMatch(lines[i]);
        if (m == null) break;
        body.add(m.group(1)!);
        i++;
      }
      blocks.add(BlockNode(BlockKind.list, lines: body, ordered: isOrdered));
      continue;
    }

    // ── 문단 — 빈 줄이나 다른 블록이 시작될 때까지 ──
    final body = <String>[lines[i]];
    i++;
    while (i < lines.length &&
        lines[i].trim().isNotEmpty &&
        !_isBlockStart(lines[i])) {
      body.add(lines[i]);
      i++;
    }
    blocks.add(BlockNode(BlockKind.paragraph, lines: body));
  }

  return blocks;
}

/// 문단을 끊는 줄인지. 문단 도중에 목록이 시작되면 거기서 끊는다.
bool _isBlockStart(String line) =>
    line.trimLeft().startsWith('```') ||
    line.trimLeft().startsWith('>') ||
    _heading.hasMatch(line) ||
    _bullet.hasMatch(line) ||
    _ordered.hasMatch(line);

List<String> _splitRow(String line) {
  var text = line.trim();
  if (text.startsWith('|')) text = text.substring(1);
  if (text.endsWith('|')) text = text.substring(0, text.length - 1);
  return text.split('|').map((c) => c.trim()).toList();
}
