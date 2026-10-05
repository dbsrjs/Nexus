import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'theme.dart';

/// 작은 호(15단계 설계 D10). **버튼 안에서만 쓴다** — 화면을 기다릴 때는
/// 자리를 지키는 [NxSkeleton] 을 쓴다. 회전 스피너가 화면 가운데서 도는
/// Material 의 기본 모습을 걷는 것이 이 단계의 일이다.
class NxSpinner extends StatefulWidget {
  const NxSpinner({
    super.key,
    this.size = 14,
    this.color,
    this.semanticLabel = '불러오는 중',
  });

  final double size;
  final Color? color;
  final String semanticLabel;

  @override
  State<NxSpinner> createState() => _NxSpinnerState();
}

class _NxSpinnerState extends State<NxSpinner>
    with SingleTickerProviderStateMixin {
  late final _turn = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 800),
  )..repeat();

  @override
  void dispose() {
    _turn.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? NxTheme.of(context).colors.textSecondary;
    return Semantics(
      label: widget.semanticLabel,
      child: RotationTransition(
        turns: _turn,
        child: CustomPaint(
          size: Size.square(widget.size),
          painter: _ArcPainter(color),
        ),
      ),
    );
  }
}

class _ArcPainter extends CustomPainter {
  _ArcPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.shortestSide / 7;
    final rect = (Offset.zero & size).deflate(stroke / 2);
    canvas.drawArc(
      rect,
      -math.pi / 2,
      math.pi * 1.5,
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_ArcPainter old) => old.color != color;
}

/// 자리를 지키는 뼈대 줄(15단계 설계 D10). 화면이 기다릴 때 회전 스피너 대신 쓴다 —
/// 내용이 올 자리를 먼저 그려 두면 도착했을 때 화면이 흔들리지 않는다.
class NxSkeleton extends StatelessWidget {
  const NxSkeleton({
    super.key,
    this.lines = 3,
    this.lineHeight = 12,
    this.semanticLabel = '불러오는 중',
  });

  final int lines;
  final double lineHeight;
  final String semanticLabel;

  /// 줄 길이. 모두 같으면 표처럼 보여 「글」로 읽히지 않는다.
  static const _widths = [0.62, 0.9, 0.44, 0.78, 0.55];

  @override
  Widget build(BuildContext context) {
    final theme = NxTheme.of(context);
    // 라이트의 elevated 는 흰색이라 표면(#F7F8F8) 위에서 거의 안 보인다 — 선 색을 옅게 쓴다.
    final bar = theme.isDark
        ? theme.colors.bgElevated
        // 토큰 밖: 라이트 뼈대 막대 — 흰 표면 위에서 겨우 보이는 정도(다크의 elevated 와 같은 대비).
        : theme.colors.borderStrong.withValues(alpha: .28);
    return Semantics(
      label: semanticLabel,
      child: LayoutBuilder(
        builder: (context, box) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < lines; i++) ...[
              if (i > 0) const SizedBox(height: NxSpacing.sp4),
              Container(
                key: ValueKey('nx-skeleton-line-$i'),
                width:
                    (box.maxWidth.isFinite ? box.maxWidth : 240) *
                    _widths[i % _widths.length],
                height: lineHeight,
                decoration: BoxDecoration(
                  color: bar,
                  borderRadius: BorderRadius.circular(NxRadius.sm),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
