import 'package:flutter/widgets.dart';
import 'theme.dart';

/// 자체 선 아이콘(15단계 설계 D5). **Material 아이콘 글꼴(`Icons.*`)을 쓰지 않는다.**
///
/// 16 격자 · 선 1.5 · 둥근 끝. 경로는 디자인 캔버스의 SVG 를 그대로 옮겼다 —
/// 손으로 `Path` 를 다시 쓰면 옮기다 틀린다. 그래서 SVG 경로 문법의 작은
/// 부분집합(M L H V C S Q A Z, 대소문자)을 읽는 해석기를 둔다.
///
/// **아이콘은 글자 없는 버튼과 상태 표시에만 쓴다.** 목록 행 앞 장식 아이콘은
/// 두지 않는다(사용자 지시, 2026-09-27).
enum NxIcons {
  send,
  attach,
  ai,
  pin,
  files,
  close,
  back,
  chevronDown,
  chevronRight,
  check,
  plus,
  search,
  more,
  reply,
  thread,
  reaction,
  mutedBell,
  lock,
  hash,
  trash,
  copy,
  edit,
  external,
  refresh,
  logout,
  settings,
  warning,
  info,
  image,
  download,
  // 음성 채널(20단계) — 채널 줄의 종류 표시 · 통화 버튼.
  speaker,
  mic,
  micOff,
  hangUp,
  screenShare,
}

sealed class _Part {
  const _Part();
}

class _Stroke extends _Part {
  const _Stroke(this.d);
  final String d;
}

class _Circle extends _Part {
  const _Circle(this.cx, this.cy, this.r, {this.fill = false});
  final double cx, cy, r;
  final bool fill;
}

class _Rect extends _Part {
  const _Rect(this.x, this.y, this.w, this.h, this.r);
  final double x, y, w, h, r;
}

const _glyphs = <NxIcons, List<_Part>>{
  NxIcons.send: [_Stroke('M8 13V3M3.5 7.5 8 3l4.5 4.5')],
  NxIcons.attach: [
    _Stroke(
      'M13 7.5 7.8 12.7a3 3 0 0 1-4.3-4.3l5.6-5.6a2 2 0 0 1 2.9 2.9L6.4 11.3a1 1 0 0 1-1.4-1.4L10 4.9',
    ),
  ],
  NxIcons.ai: [
    _Stroke('M8 2 9.4 6.6 14 8l-4.6 1.4L8 14l-1.4-4.6L2 8l4.6-1.4z'),
  ],
  NxIcons.pin: [_Stroke('M6 2h4l-.5 4 2.5 2H4l2.5-2zM8 8v6')],
  NxIcons.files: [_Stroke('M2 4.5h4.5l1.5 1.5H14v6.5H2z')],
  NxIcons.close: [_Stroke('M3.5 3.5l9 9M12.5 3.5l-9 9')],
  NxIcons.back: [_Stroke('M10 3 5 8l5 5')],
  NxIcons.chevronDown: [_Stroke('M4.5 6 8 9.5 11.5 6')],
  NxIcons.chevronRight: [_Stroke('M6 4.5 9.5 8 6 11.5')],
  NxIcons.check: [_Stroke('M3 8.5 6.5 12 13 4.5')],
  NxIcons.plus: [_Stroke('M8 3v10M3 8h10')],
  NxIcons.search: [_Circle(7, 7, 4.5), _Stroke('M10.5 10.5 14 14')],
  NxIcons.more: [
    _Circle(3.5, 8, 1.2, fill: true),
    _Circle(8, 8, 1.2, fill: true),
    _Circle(12.5, 8, 1.2, fill: true),
  ],
  NxIcons.reply: [_Stroke('M6 4 2 8l4 4M2 8h8a4 4 0 0 1 4 4')],
  NxIcons.thread: [_Stroke('M2 3h12v8H7l-3 2.5V11H2z')],
  NxIcons.reaction: [
    _Circle(8, 8, 6),
    _Stroke('M5.5 9.5c.7.9 1.5 1.3 2.5 1.3s1.8-.4 2.5-1.3'),
    _Circle(6, 6.3, .7, fill: true),
    _Circle(10, 6.3, .7, fill: true),
  ],
  NxIcons.mutedBell: [
    _Stroke('M6 13h4M4 11V7a4 4 0 0 1 6.5-3.1M12 7v4M2 2l12 12'),
  ],
  NxIcons.lock: [
    _Rect(3, 7, 10, 7, 1.5),
    _Stroke('M5.5 7V5a2.5 2.5 0 0 1 5 0v2'),
  ],
  NxIcons.hash: [_Stroke('M6.5 2.5 5 13.5M11 2.5l-1.5 11M3 6h10.5M2.5 10H13')],
  NxIcons.trash: [_Stroke('M3 4.5h10M6.5 4.5V3h3v1.5M4.5 4.5l.7 9h5.6l.7-9')],
  NxIcons.copy: [
    _Rect(5.5, 5.5, 8, 8, 1.5),
    _Stroke('M10.5 5.5v-2a1 1 0 0 0-1-1h-6a1 1 0 0 0-1 1v6a1 1 0 0 0 1 1h2'),
  ],
  NxIcons.edit: [_Stroke('M10.5 2.5l3 3L6 13H3v-3z')],
  NxIcons.external: [_Stroke('M9 3h4v4M13 3 7.5 8.5M11 9.5V13H3V5h3.5')],
  NxIcons.refresh: [_Stroke('M13 8a5 5 0 1 1-1.46-3.54M13 3v2.5h-2.5')],
  NxIcons.logout: [_Stroke('M6 3H3v10h3M10 5l3 3-3 3M13 8H6')],
  NxIcons.settings: [
    _Circle(8, 8, 2.5),
    _Stroke(
      'M8 1.5v2M8 12.5v2M1.5 8h2M12.5 8h2M3.4 3.4l1.4 1.4M11.2 11.2l1.4 1.4M3.4 12.6l1.4-1.4M11.2 4.8l1.4-1.4',
    ),
  ],
  NxIcons.warning: [
    _Stroke('M8 2.5 14 13H2zM8 6.5v3'),
    _Circle(8, 11.2, .75, fill: true),
  ],
  NxIcons.info: [
    _Circle(8, 8, 6),
    _Stroke('M8 7.5v4'),
    _Circle(8, 5.2, .75, fill: true),
  ],
  NxIcons.image: [
    _Rect(2, 3, 12, 10, 1.5),
    _Stroke('M2 11l3.5-3.5 3 3 2-2L14 12'),
    _Circle(10.5, 6, 1),
  ],
  NxIcons.download: [_Stroke('M8 2.5v8M4.5 7 8 10.5 11.5 7M3 13.5h10')],
  NxIcons.speaker: [
    _Stroke('M2.5 6H5l3.5-3v10L5 10H2.5z'),
    _Stroke('M11 5.5a3.5 3.5 0 0 1 0 5'),
    _Stroke('M12.8 3.3a6.5 6.5 0 0 1 0 9.4'),
  ],
  NxIcons.mic: [
    _Rect(6, 1.5, 4, 8, 2),
    _Stroke('M3.5 7.5a4.5 4.5 0 0 0 9 0M8 12v2.5M5.5 14.5h5'),
  ],
  NxIcons.micOff: [
    _Rect(6, 1.5, 4, 8, 2),
    _Stroke('M3.5 7.5a4.5 4.5 0 0 0 9 0M8 12v2.5M5.5 14.5h5M2.5 2.5l11 11'),
  ],
  NxIcons.screenShare: [
    _Rect(1.5, 2.5, 13, 9, 1.5),
    _Stroke('M5.5 14h5M8 11.5V14M8 9V5M6 7l2-2 2 2'),
  ],
  NxIcons.hangUp: [
    _Stroke(
      'M2 10c3.3-3.2 8.7-3.2 12 0l-1.6 1.8-2.4-.9V9.2a6 6 0 0 0-4 0v1.7l-2.4.9z',
    ),
  ],
};

/// 아이콘 하나. 크기와 색은 지정하지 않으면 가장 가까운 `IconTheme` 을 따른다.
///
/// [semanticLabel] 이 없으면 보조 기술에 드러나지 않는다 — 대개 곁의 글자나
/// 버튼이 이미 뜻을 말한다. 아이콘만 있는 버튼은 `NxIconButton` 이 라벨을 강제한다.
class NxIcon extends StatelessWidget {
  const NxIcon(
    this.icon, {
    super.key,
    this.size,
    this.color,
    this.semanticLabel,
  });

  final NxIcons icon;
  final double? size;
  final Color? color;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final theme = IconTheme.of(context);
    final resolvedSize = size ?? theme.size ?? 16;
    final resolvedColor = color ?? theme.color ?? NxColors.dark.textSecondary;
    final paint = CustomPaint(
      size: Size.square(resolvedSize),
      painter: _IconPainter(icon, resolvedColor),
    );
    final label = semanticLabel;
    if (label == null) return ExcludeSemantics(child: paint);
    return Semantics(
      label: label,
      image: true,
      child: ExcludeSemantics(child: paint),
    );
  }
}

class _IconPainter extends CustomPainter {
  _IconPainter(this.icon, this.color);

  final NxIcons icon;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.shortestSide / 16;
    canvas.save();
    canvas.scale(scale);
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      // 16 격자 단위의 1.5 — 캔버스가 크기만큼 늘리므로 16px 에서 1.5px 다.
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final fill = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    for (final part in _glyphs[icon]!) {
      switch (part) {
        case _Stroke(:final d):
          canvas.drawPath(parseSvgPath(d), stroke);
        case _Circle(:final cx, :final cy, :final r, fill: final isFill):
          canvas.drawCircle(Offset(cx, cy), r, isFill ? fill : stroke);
        case _Rect(:final x, :final y, :final w, :final h, :final r):
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(x, y, w, h),
              Radius.circular(r),
            ),
            stroke,
          );
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_IconPainter old) =>
      old.icon != icon || old.color != color;
}

final _token = RegExp(r'[A-Za-z]|[-+]?(?:\d+\.?\d*|\.\d+)(?:[eE][-+]?\d+)?');

/// SVG 경로 문법의 부분집합을 `Path` 로. 아이콘 경로 전용이라 T 와 절대/상대 외의
/// 드문 형식은 받지 않는다 — 모르는 명령은 던져 조용히 틀린 그림을 그리지 않는다.
///
/// 테스트가 경계 사례(암시적 반복 · 붙은 소수점 `-.4` · 호 플래그)를 덮는다.
Path parseSvgPath(String d) {
  final tokens = _token.allMatches(d).map((m) => m.group(0)!).toList();
  final path = Path();
  var i = 0;
  var cmd = '';
  var cur = Offset.zero;
  var start = Offset.zero;
  Offset? lastCtrl; // S 의 반사점

  bool isCmd(String t) => RegExp(r'^[A-Za-z]$').hasMatch(t);
  double n() => double.parse(tokens[i++]);

  while (i < tokens.length) {
    if (isCmd(tokens[i])) {
      cmd = tokens[i++];
    } else if (cmd.isEmpty) {
      throw FormatException('경로가 명령으로 시작하지 않는다: $d');
    }
    final rel = cmd == cmd.toLowerCase();
    Offset pt(double x, double y) => rel ? cur + Offset(x, y) : Offset(x, y);

    switch (cmd.toUpperCase()) {
      case 'M':
        cur = pt(n(), n());
        start = cur;
        path.moveTo(cur.dx, cur.dy);
        // M 뒤에 이어지는 좌표 쌍은 L 이다(SVG 규칙).
        cmd = rel ? 'l' : 'L';
        lastCtrl = null;
      case 'L':
        cur = pt(n(), n());
        path.lineTo(cur.dx, cur.dy);
        lastCtrl = null;
      case 'H':
        final x = n();
        cur = Offset(rel ? cur.dx + x : x, cur.dy);
        path.lineTo(cur.dx, cur.dy);
        lastCtrl = null;
      case 'V':
        final y = n();
        cur = Offset(cur.dx, rel ? cur.dy + y : y);
        path.lineTo(cur.dx, cur.dy);
        lastCtrl = null;
      case 'C':
        final c1 = pt(n(), n());
        final c2 = pt(n(), n());
        final end = pt(n(), n());
        path.cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, end.dx, end.dy);
        lastCtrl = c2;
        cur = end;
      case 'S':
        final c1 = lastCtrl == null ? cur : cur * 2 - lastCtrl;
        final c2 = pt(n(), n());
        final end = pt(n(), n());
        path.cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, end.dx, end.dy);
        lastCtrl = c2;
        cur = end;
      case 'Q':
        final c = pt(n(), n());
        final end = pt(n(), n());
        path.quadraticBezierTo(c.dx, c.dy, end.dx, end.dy);
        lastCtrl = null;
        cur = end;
      case 'A':
        final rx = n();
        final ry = n();
        final rotation = n();
        final large = n() != 0;
        final sweep = n() != 0;
        final end = pt(n(), n());
        path.arcToPoint(
          end,
          radius: Radius.elliptical(rx, ry),
          rotation: rotation,
          largeArc: large,
          clockwise: sweep,
        );
        lastCtrl = null;
        cur = end;
      case 'Z':
        path.close();
        cur = start;
        lastCtrl = null;
        // Z 뒤에 좌표가 오면 안 된다 — 다음 토큰은 명령이어야 한다.
        if (i < tokens.length && !isCmd(tokens[i])) {
          throw FormatException('Z 뒤에 좌표가 있다: $d');
        }
      default:
        throw FormatException('모르는 경로 명령 $cmd: $d');
    }
  }
  return path;
}

/// 테스트용 — 아이콘마다 경로가 모두 읽히는지.
@visibleForTesting
Iterable<String> debugIconPaths(NxIcons icon) =>
    _glyphs[icon]!.whereType<_Stroke>().map((s) => s.d);

/// 테스트용 — 경로가 차지하는 영역이 16 격자 안인지.
@visibleForTesting
Rect debugIconBounds(NxIcons icon) {
  Rect? bounds;
  for (final part in _glyphs[icon]!) {
    final r = switch (part) {
      _Stroke(:final d) => _tightBounds(parseSvgPath(d)),
      _Circle(:final cx, :final cy, :final r) => Rect.fromCircle(
        center: Offset(cx, cy),
        radius: r,
      ),
      _Rect(:final x, :final y, :final w, :final h) => Rect.fromLTWH(
        x,
        y,
        w,
        h,
      ),
    };
    bounds = bounds == null ? r : bounds.expandToInclude(r);
  }
  return bounds ?? Rect.zero;
}

/// `Path.getBounds` 는 곡선의 조절점까지 넣어 호를 부풀린다. 경로를 따라 점을 찍어 잰다.
Rect _tightBounds(Path path) {
  Rect? r;
  for (final metric in path.computeMetrics()) {
    for (var t = 0.0; t <= metric.length; t += 0.1) {
      final p = metric.getTangentForOffset(t)!.position;
      final dot = Rect.fromCenter(center: p, width: 0, height: 0);
      r = r == null ? dot : r.expandToInclude(dot);
    }
  }
  return r ?? Rect.zero;
}
