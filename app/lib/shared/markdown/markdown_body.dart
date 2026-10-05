import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../domain/models/message.dart';
import '../../features/repo/code_highlight.dart';
import 'block.dart';
import 'inline.dart';
import '../../ui/theme.dart';

/// 마크다운 본문. **채팅 · 이슈 본문 · 이슈 댓글이 같은 것을 쓴다** —
/// 규칙이 갈라지면 "채팅에서는 되는데 이슈에서는 안 되는" 일이 생긴다.
class MarkdownBody extends StatelessWidget {
  const MarkdownBody({
    super.key,
    required this.body,
    this.mentions = const [],
    this.fallbackNames = const {},
    this.style,
  });

  final String body;

  /// 서버가 실어 준 멘션 목록. 이름을 여기서 얻는다.
  final List<MessageMention> mentions;

  /// 멘션 목록이 없는 자리를 위한 이름(큐에 있는 메시지 · 이슈 본문).
  final Map<String, String> fallbackNames;

  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final base = style ?? NxTheme.of(context).text.body;
    final names = <String, String>{
      ...fallbackNames,
      for (final m in mentions)
        if (m.userId != null && m.name != null) m.userId!: m.name!,
    };

    // **흔한 경우를 빠르게 지나간다**(설계 §2) — 서식 문자가 하나도 없으면
    // 파싱하지 않는다. 대부분의 채팅이 여기 해당한다.
    if (!_hasMarkup(body)) return Text(body, style: base);

    final blocks = parseBlocks(body);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < blocks.length; i++) ...[
          if (i > 0) const SizedBox(height: NxSpacing.sp3),
          _block(context, blocks[i], base, names),
        ],
      ],
    );
  }
}

/// 서식 문자가 하나라도 있는지.
///
/// **넓게 잡는다.** `@` 나 줄바꿈만 있어도 파서를 태운다 — 놓치는 것(서식이
/// 안 그려짐)이 헛도는 것보다 나쁘다.
bool _hasMarkup(String body) {
  for (final c in const ['*', '_', '~', '`', '|', '#', '>', '[', '@', '\n']) {
    if (body.contains(c)) return true;
  }
  return body.contains('http');
}

Widget _block(
  BuildContext context,
  BlockNode block,
  TextStyle? base,
  Map<String, String> names,
) {
  final nx = NxTheme.of(context);
  final c = nx.colors;

  switch (block.kind) {
    case BlockKind.code:
      return _CodeBlock(block: block, base: base);

    case BlockKind.heading:
      final style = switch (block.level) {
        1 => nx.text.heading,
        2 => nx.text.title,
        _ => nx.text.strong,
      };
      return _paragraph(context, block.lines, style, names);

    case BlockKind.quote:
      return Container(
        padding: const EdgeInsets.only(left: NxSpacing.inset),
        decoration: BoxDecoration(
          border: Border(left: BorderSide(color: c.divider, width: 3)),
        ),
        child: _paragraph(
          context,
          block.lines,
          base?.copyWith(color: c.textSecondary),
          names,
        ),
      );

    case BlockKind.list:
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < block.lines.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: NxSpacing.sp1),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 22,
                    child: Text(
                      block.ordered ? '${i + 1}.' : '•',
                      style: base?.copyWith(color: c.textSecondary),
                    ),
                  ),
                  Expanded(
                    child: _paragraph(context, [block.lines[i]], base, names),
                  ),
                ],
              ),
            ),
        ],
      );

    case BlockKind.table:
      return _TableBlock(block: block, base: base, names: names);

    case BlockKind.paragraph:
      return _paragraph(context, block.lines, base, names);
  }
}

/// 여러 줄을 줄바꿈으로 이어 한 `Text.rich` 로 그린다.
Widget _paragraph(
  BuildContext context,
  List<String> lines,
  TextStyle? style,
  Map<String, String> names,
) {
  final spans = <InlineSpan>[];
  for (var i = 0; i < lines.length; i++) {
    if (i > 0) spans.add(const TextSpan(text: '\n'));
    spans.addAll(
      inlineSpans(context, parseInline(lines[i], names: names), style),
    );
  }

  return Text.rich(TextSpan(children: spans), style: style);
}

/// 인라인 노드 트리를 `InlineSpan` 으로 편다.
///
/// **스포일러만 `WidgetSpan` 이다** — 눌러서 드러나는 상태를 `TextSpan` 안에
/// 둘 수 없기 때문이다.
List<InlineSpan> inlineSpans(
  BuildContext context,
  List<InlineNode> nodes,
  TextStyle? style,
) {
  final nx = NxTheme.of(context);
  final c = nx.colors;
  final spans = <InlineSpan>[];

  for (final node in nodes) {
    switch (node.kind) {
      case InlineKind.text:
        spans.add(TextSpan(text: node.text, style: style));

      case InlineKind.bold:
        spans.addAll(
          inlineSpans(
            context,
            node.children,
            style?.copyWith(fontWeight: FontWeight.w700),
          ),
        );

      case InlineKind.italic:
        spans.addAll(
          inlineSpans(
            context,
            node.children,
            style?.copyWith(fontStyle: FontStyle.italic),
          ),
        );

      case InlineKind.strike:
        spans.addAll(
          inlineSpans(
            context,
            node.children,
            style?.copyWith(decoration: TextDecoration.lineThrough),
          ),
        );

      case InlineKind.code:
        spans.add(
          TextSpan(
            text: node.text,
            style: style?.copyWith(
              fontFamily: nx.text.mono.fontFamily,
              fontFamilyFallback: nx.text.mono.fontFamilyFallback,
              backgroundColor: c.divider,
            ),
          ),
        );

      case InlineKind.mention:
        spans.add(
          TextSpan(
            text: node.text,
            style: style?.copyWith(
              color: c.accent,
              fontWeight: FontWeight.w600,
            ),
          ),
        );

      case InlineKind.link:
        final url = node.url;
        spans.add(
          TextSpan(
            children: inlineSpans(
              context,
              node.children,
              style?.copyWith(
                color: c.accent,
                decoration: TextDecoration.underline,
              ),
            ),
            recognizer: url == null
                ? null
                : (TapGestureRecognizer()
                    ..onTap = () => launchUrl(
                      Uri.parse(url),
                      mode: LaunchMode.externalApplication,
                    )),
          ),
        );

      case InlineKind.spoiler:
        spans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.baseline,
            baseline: TextBaseline.alphabetic,
            child: _Spoiler(children: node.children, style: style),
          ),
        );
    }
  }

  return spans;
}

/// **누르면 드러나고 되돌리지 않는다.** 한 번 본 것을 다시 가리는 것은
/// 스포일러의 목적이 아니다.
class _Spoiler extends StatefulWidget {
  const _Spoiler({required this.children, this.style});

  final List<InlineNode> children;
  final TextStyle? style;

  @override
  State<_Spoiler> createState() => _SpoilerState();
}

class _SpoilerState extends State<_Spoiler> {
  var _revealed = false;

  @override
  Widget build(BuildContext context) {
    final content = Text.rich(
      TextSpan(children: inlineSpans(context, widget.children, widget.style)),
      style: widget.style,
    );

    if (_revealed) return content;

    return GestureDetector(
      key: const Key('spoiler-covered'),
      onTap: () => setState(() => _revealed = true),
      child: Container(
        decoration: BoxDecoration(
          color: NxTheme.of(context).colors.textPrimary.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(NxRadius.sm),
        ),
        // 글자를 지우지 않고 가린다 — 폭이 유지돼야 눌렀을 때 줄이 흔들리지 않는다.
        child: Opacity(opacity: 0, child: content),
      ),
    );
  }
}

/// 코드블록. **1번에서 만든 `CodeLine` 을 재사용한다.**
class _CodeBlock extends StatelessWidget {
  const _CodeBlock({required this.block, this.base});

  final BlockNode block;
  final TextStyle? base;

  @override
  Widget build(BuildContext context) {
    final nx = NxTheme.of(context);
    final c = nx.colors;
    final mono = base?.copyWith(
      fontFamily: nx.text.mono.fontFamily,
      fontFamilyFallback: nx.text.mono.fontFamilyFallback,
      height: 1.4,
    );
    final palette = CodePalette.of(context);
    final language = block.language;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(NxSpacing.inset),
      decoration: BoxDecoration(
        // 한 단 위 표면 + 1px 선(캔버스 「채널」의 코드 블록). 반투명 회색은 다크에서
        // 본문보다 밝게 떠 글자가 묻혔다.
        color: c.bgSurface,
        border: Border.all(color: c.divider),
        borderRadius: BorderRadius.circular(NxRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (language != null) ...[
            Text(language, style: nx.text.meta),
            const SizedBox(height: NxSpacing.sp3),
          ],
          // 긴 줄은 접지 않고 가로로 민다 — 접으면 코드를 읽을 수 없다.
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final line in block.lines)
                  CodeLine(line: line, style: mono, palette: palette),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 표. **가로 스크롤로 감싼다** — 채팅 폭이 좁아 열이 많으면 잘리는데,
/// 잘린 채로 두면 내용을 볼 수 없다 (설계 §1).
class _TableBlock extends StatelessWidget {
  const _TableBlock({required this.block, this.base, required this.names});

  final BlockNode block;
  final TextStyle? base;
  final Map<String, String> names;

  @override
  Widget build(BuildContext context) {
    if (block.rows.isEmpty) return const SizedBox.shrink();
    final c = NxTheme.of(context).colors;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: c.divider),
          borderRadius: BorderRadius.circular(NxRadius.md),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var r = 0; r < block.rows.length; r++)
              Container(
                decoration: BoxDecoration(
                  border: r == 0
                      ? Border(bottom: BorderSide(color: c.divider))
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final cell in block.rows[r])
                      Container(
                        constraints: const BoxConstraints(minWidth: 64),
                        padding: const EdgeInsets.symmetric(
                          horizontal: NxSpacing.inset,
                          vertical: NxSpacing.sp3,
                        ),
                        child: Text.rich(
                          TextSpan(
                            children: inlineSpans(
                              context,
                              parseInline(cell, names: names),
                              // 첫 행은 헤더다.
                              r == 0
                                  ? base?.copyWith(fontWeight: FontWeight.w700)
                                  : base,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
