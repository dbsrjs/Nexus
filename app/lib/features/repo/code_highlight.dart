import 'package:flutter/material.dart';

import '../../core/theme.dart';

/// 코드 한 줄을 색칠할 조각으로 쪼갠다.
///
/// **언어별 규칙을 두지 않는다.** 주석 · 문자열 · 숫자 · 키워드 넷은 Dart ·
/// TypeScript · Python · Java 가 거의 같아서, 언어를 몰라도 흑백보다 훨씬
/// 읽힌다. 언어별 정확도를 쫓으면 규칙 표를 계속 들고 있어야 하는데 그 비용이
/// 얻는 것보다 크다 — 9-3 에서 차트 라이브러리 대신 `CustomPainter` 를 쓴 것과
/// 같은 판단이다.
///
/// **줄 단위다.** 여러 줄에 걸친 블록 주석(`/* … */`)은 추적하지 않는다.
/// 상태를 줄 사이로 넘기려면 파일 전체를 한 번에 파싱해야 하는데, 화면이 줄
/// 단위로 그리는 구조와 어긋난다. 시작 줄만 주석으로 칠하고 만다.
enum CodeSpanKind { plain, keyword, string, number, comment }

class CodeSpan {
  const CodeSpan(this.kind, this.text);

  final CodeSpanKind kind;
  final String text;
}

/// 여러 언어에 공통인 것만 넣는다. **한 언어에만 있는 것은 빼는 편이 낫다** —
/// 다른 언어에서 평범한 식별자가 키워드로 칠해지면 오히려 방해가 된다.
const _keywords = <String>{
  'abstract', 'as', 'async', 'await', 'break', 'case', 'catch', 'class',
  'const', 'continue', 'def', 'default', 'do', 'elif', 'else', 'enum',
  'export', 'extends', 'final', 'finally', 'for', 'from', 'func', 'function',
  'if', 'implements', 'import', 'in', 'interface', 'is', 'let', 'new', 'not',
  'null', 'package', 'private', 'protected', 'public', 'return', 'static',
  'super', 'switch', 'this', 'throw', 'try', 'type', 'typedef', 'var', 'void',
  'while', 'with', 'yield',
  // 리터럴도 키워드처럼 칠한다 — 값이 눈에 띄는 편이 읽기 좋다.
  'true', 'false', 'None', 'True', 'False', 'nil', 'undefined',
};

List<CodeSpan> highlightLine(String line) {
  if (line.isEmpty) return const [];

  final spans = <CodeSpan>[];
  final buffer = StringBuffer();
  var i = 0;

  void flushPlain() {
    if (buffer.isEmpty) return;
    spans.add(CodeSpan(CodeSpanKind.plain, buffer.toString()));
    buffer.clear();
  }

  while (i < line.length) {
    final rest = line.substring(i);

    // ── 주석 — 줄 끝까지 ─────────────────────────────
    // **문자열보다 먼저 보지 않는다.** 이 자리에 온 것은 문자열 밖이라는 뜻이라
    // 순서가 곧 "문자열 안의 // 는 주석이 아니다"를 만든다.
    if (rest.startsWith('//') || rest.startsWith('#') || rest.startsWith('/*')) {
      flushPlain();
      spans.add(CodeSpan(CodeSpanKind.comment, rest));
      return spans;
    }

    // ── 문자열 ───────────────────────────────────────
    final quote = line[i];
    if (quote == '"' || quote == "'" || quote == '`') {
      flushPlain();
      final end = _findStringEnd(line, i, quote);
      spans.add(CodeSpan(CodeSpanKind.string, line.substring(i, end)));
      i = end;
      continue;
    }

    // ── 숫자 ─────────────────────────────────────────
    // 앞이 식별자 문자면 숫자가 아니다(`utf8` 의 8).
    if (_isDigit(line[i]) && (i == 0 || !_isWordChar(line[i - 1]))) {
      flushPlain();
      var end = i;
      while (end < line.length &&
          (_isDigit(line[end]) || line[end] == '.' || line[end] == '_')) {
        end++;
      }
      spans.add(CodeSpan(CodeSpanKind.number, line.substring(i, end)));
      i = end;
      continue;
    }

    // ── 단어 — 키워드인지 본다 ───────────────────────
    if (_isWordChar(line[i]) && (i == 0 || !_isWordChar(line[i - 1]))) {
      var end = i;
      while (end < line.length && _isWordChar(line[end])) {
        end++;
      }
      final word = line.substring(i, end);
      if (_keywords.contains(word)) {
        flushPlain();
        spans.add(CodeSpan(CodeSpanKind.keyword, word));
      } else {
        buffer.write(word);
      }
      i = end;
      continue;
    }

    buffer.write(line[i]);
    i++;
  }

  flushPlain();
  return spans;
}

/// 여는 따옴표 다음부터 같은 따옴표를 찾는다. **없으면 줄 끝**이다 —
/// 여기서 멈추지 않으면 그 줄 전체가 엉뚱하게 칠해진다.
int _findStringEnd(String line, int start, String quote) {
  var i = start + 1;
  while (i < line.length) {
    // 이스케이프된 따옴표는 닫지 않는다.
    if (line[i] == r'\' && i + 1 < line.length) {
      i += 2;
      continue;
    }
    if (line[i] == quote) return i + 1;
    i++;
  }
  return line.length;
}

bool _isDigit(String c) => c.codeUnitAt(0) >= 48 && c.codeUnitAt(0) <= 57;

bool _isWordChar(String c) {
  final code = c.codeUnitAt(0);
  return (code >= 65 && code <= 90) || // A-Z
      (code >= 97 && code <= 122) || // a-z
      (code >= 48 && code <= 57) || // 0-9
      code == 95; // _
}

/// 코드 색. **테마 토큰에서 파생시킨다** — 하이라이터가 자기 팔레트를 들고
/// 있으면 라이트/다크 전환에서 혼자 어긋난다.
class CodePalette {
  const CodePalette({
    required this.plain,
    required this.keyword,
    required this.string,
    required this.number,
    required this.comment,
  });

  final Color plain;
  final Color keyword;
  final Color string;
  final Color number;
  final Color comment;

  factory CodePalette.of(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;

    return CodePalette(
      plain: dark ? NexusColors.textPrimaryDark : NexusColors.textPrimaryLight,
      // 액센트를 키워드에 쓴다 — 이 앱에서 "구조"를 가리키는 색이다.
      keyword: dark ? NexusColors.accentDark : NexusColors.accentLight,
      string: NexusColors.success,
      number: NexusColors.warning,
      // 주석은 **가장 흐리게**. 코드를 읽을 때 먼저 건너뛰는 것이라
      // 눈에 띄면 방해가 된다.
      comment:
          dark ? NexusColors.textSecondaryDark : NexusColors.textSecondaryLight,
    );
  }

  Color colorOf(CodeSpanKind kind) => switch (kind) {
        CodeSpanKind.plain => plain,
        CodeSpanKind.keyword => keyword,
        CodeSpanKind.string => string,
        CodeSpanKind.number => number,
        CodeSpanKind.comment => comment,
      };
}

/// 코드 한 줄. **`Text.rich` 한 개로 그린다** — 조각마다 위젯을 만들면 줄이
/// 만 개인 파일에서 위젯 수가 폭발한다.
class CodeLine extends StatelessWidget {
  const CodeLine({
    super.key,
    required this.line,
    required this.style,
    required this.palette,
  });

  final String line;
  final TextStyle? style;
  final CodePalette palette;

  @override
  Widget build(BuildContext context) {
    // 빈 줄도 높이를 차지해야 줄 번호와 어긋나지 않는다.
    if (line.isEmpty) return Text('', style: style);

    return Text.rich(
      TextSpan(
        children: [
          for (final span in highlightLine(line))
            TextSpan(
              text: span.text,
              style: style?.copyWith(
                color: palette.colorOf(span.kind),
                // 주석만 기울인다. 서식을 더 쓰면 코드가 산만해진다.
                fontStyle: span.kind == CodeSpanKind.comment
                    ? FontStyle.italic
                    : null,
              ),
            ),
        ],
      ),
      style: style,
    );
  }
}
