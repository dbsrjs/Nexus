import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'theme.dart';

/// 작은 호(15단계 설계 D10). **버튼 안에서만 쓴다** — 화면을 기다릴 때는
/// 자리를 지키는 [NxSkeleton] 을 쓴다. 회전 스피너가 화면 가운데서 도는
/// Material 의 기본 모습을 걷는 것이 이 단계의 일이다.
class NxSpinner extends StatefulWidget {
  const NxSpinner({super.key, this.size = 14, this.color, this.semanticLabel = '불러오는 중'});

  final double size;
  final Color? color;
  final String semanticLabel;

  @override
  State<NxSpinner> createState() => _NxSpinnerState();
}

class _NxSpinnerState extends State<NxSpinner> with SingleTickerProviderStateMixin {
  late final _turn = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))
    ..repeat();

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
