import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../domain/models/sprint.dart';

/// 어떤 계열을 그릴지. 포인트를 안 매기는 사람에게는 개수가 유일한 지표다.
enum BurndownSeries { points, count }

/// 번다운 차트.
///
/// **차트 라이브러리를 쓰지 않는다.** 선 두 개와 축이 전부라 의존성을 들일
/// 이유가 없다 — 의존성은 늘리기는 쉽고 걷어내기는 어렵다.
class BurndownChart extends StatelessWidget {
  const BurndownChart({
    super.key,
    required this.burndown,
    required this.series,
  });

  final Burndown burndown;
  final BurndownSeries series;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = series == BurndownSeries.points
        ? burndown.total.points
        : burndown.total.count;
    final values = burndown.days
        .map((d) => series == BurndownSeries.points ? d.points : d.count)
        .toList(growable: false);

    // 잴 것이 없으면 그래프 대신 그 사실을 말한다. 평평한 0 선은 "일이 안
    // 줄었다"로 읽히는데 뜻이 다르다.
    if (total == 0) {
      return SizedBox(
        height: 180,
        child: Center(
          child: Text(
            series == BurndownSeries.points
                ? '스토리 포인트를 매긴 이슈가 없습니다.'
                : '이 스프린트에 이슈가 없습니다.',
            style: theme.textTheme.bodySmall,
          ),
        ),
      );
    }

    return SizedBox(
      height: 180,
      child: CustomPaint(
        painter: _BurndownPainter(
          values: values,
          total: total,
          lineColor: theme.colorScheme.primary,
          idealColor: theme.dividerColor,
          axisColor: theme.dividerColor,
          labelStyle:
              theme.textTheme.labelSmall ?? const TextStyle(fontSize: 11),
        ),
        size: Size.infinite,
      ),
    );
  }
}

class _BurndownPainter extends CustomPainter {
  _BurndownPainter({
    required this.values,
    required this.total,
    required this.lineColor,
    required this.idealColor,
    required this.axisColor,
    required this.labelStyle,
  });

  final List<int> values;
  final int total;
  final Color lineColor;
  final Color idealColor;
  final Color axisColor;
  final TextStyle labelStyle;

  static const _leftGutter = 32.0;
  static const _bottomGutter = 18.0;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    final plotWidth = size.width - _leftGutter;
    final plotHeight = size.height - _bottomGutter;
    if (plotWidth <= 0 || plotHeight <= 0) return;

    double x(int i) => _leftGutter +
        (values.length == 1 ? plotWidth / 2 : plotWidth * i / (values.length - 1));
    double y(num value) => plotHeight * (1 - value / total);

    final axis = Paint()
      ..color = axisColor
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(_leftGutter, plotHeight),
      Offset(size.width, plotHeight),
      axis,
    );
    canvas.drawLine(
      Offset(_leftGutter, 0),
      Offset(_leftGutter, plotHeight),
      axis,
    );

    // 이상선 — 시작 총량에서 균등하게 내려오는 직선. 서버가 보내지 않는
    // 이유가 이것이다: 두 점이면 그릴 수 있다.
    final ideal = Paint()
      ..color = idealColor
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(x(0), y(total)),
      Offset(x(values.length - 1), y(0)),
      ideal,
    );

    // 실제선 — 이슈를 done 으로 옮기는 순간에만 떨어져 계단이 된다.
    final path = Path()..moveTo(x(0), y(values.first));
    for (var i = 1; i < values.length; i++) {
      path.lineTo(x(i), y(values[i]));
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = lineColor
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke,
    );

    final dot = Paint()..color = lineColor;
    for (var i = 0; i < values.length; i++) {
      canvas.drawCircle(Offset(x(i), y(values[i])), 2.5, dot);
    }

    _label(canvas, '$total', Offset(0, y(total) - 6));
    _label(canvas, '0', Offset(0, y(0) - 6));
    _label(canvas, '1일', Offset(_leftGutter, plotHeight + 4));
    if (values.length > 1) {
      _label(
        canvas,
        '${values.length}일',
        Offset(size.width - 24, plotHeight + 4),
      );
    }
  }

  void _label(Canvas canvas, String text, Offset at) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: labelStyle),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, at);
  }

  @override
  bool shouldRepaint(_BurndownPainter old) =>
      old.total != total ||
      old.lineColor != lineColor ||
      !identical(old.values, values);
}

/// 차트 위의 범례. 선 두 개가 무엇인지 말해 주지 않으면 읽을 수 없다.
class BurndownLegend extends StatelessWidget {
  const BurndownLegend({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        _Swatch(color: theme.colorScheme.primary, label: '실제'),
        const SizedBox(width: NexusSpacing.sp5),
        _Swatch(color: theme.dividerColor, label: '이상'),
      ],
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 12, height: 2, color: color),
        const SizedBox(width: NexusSpacing.sp3),
        Text(label, style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }
}
