import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'theme.dart';

/// 누를 수 있는 것의 상태.
@immutable
class NxPressState {
  const NxPressState({
    required this.enabled,
    required this.hovered,
    required this.pressed,
    required this.focused,
    required this.selected,
  });

  final bool enabled;
  final bool hovered;
  final bool pressed;

  /// **키보드로 왔을 때만** 참이다 — 마우스로 누른 뒤에는 링을 그리지 않는다.
  final bool focused;
  final bool selected;
}

/// 누를 수 있는 모든 것의 바탕(15단계 설계 D7). **물결(ripple)이 없다.**
///
/// Material 의 `InkWell` 이 공짜로 주던 것을 직접 챙긴다 — 호버 · 눌림 상태,
/// 키보드 활성(Enter · Space), 포커스 링(키보드일 때만), 손가락 커서, 보조 기술
/// (버튼 · 활성 · 선택 · 이름). 모양은 [builder] 가 상태를 보고 그린다.
class NxPressable extends StatefulWidget {
  const NxPressable({
    super.key,
    required this.builder,
    this.onPressed,
    this.onLongPress,
    this.semanticLabel,
    this.selected = false,
    this.focusNode,
    this.autofocus = false,
    this.focusRingRadius = NxRadius.md,
    this.excludeChildSemantics = false,
  });

  final Widget Function(BuildContext context, NxPressState state) builder;
  final VoidCallback? onPressed;
  final VoidCallback? onLongPress;

  /// 글자가 없는 것(아이콘 버튼)은 반드시 준다.
  final String? semanticLabel;
  final bool selected;
  final FocusNode? focusNode;
  final bool autofocus;

  /// 포커스 링의 모서리. 링은 2px 바깥에 2px 로 그린다(디자인 시스템 §6).
  final double focusRingRadius;

  /// 안의 글자를 보조 기술에서 숨기고 [semanticLabel] 만 읽힌다.
  final bool excludeChildSemantics;

  @override
  State<NxPressable> createState() => _NxPressableState();
}

class _NxPressableState extends State<NxPressable> {
  bool _hovered = false;
  bool _pressed = false;
  bool _focused = false;

  bool get _enabled => widget.onPressed != null;

  static final _shortcuts = <ShortcutActivator, Intent>{
    const SingleActivator(LogicalKeyboardKey.enter): const ActivateIntent(),
    const SingleActivator(LogicalKeyboardKey.numpadEnter):
        const ActivateIntent(),
    const SingleActivator(LogicalKeyboardKey.space): const ActivateIntent(),
  };

  late final _actions = <Type, Action<Intent>>{
    ActivateIntent: CallbackAction<ActivateIntent>(
      onInvoke: (_) {
        widget.onPressed?.call();
        return null;
      },
    ),
  };

  void _setPressed(bool v) {
    if (_pressed != v) setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    final state = NxPressState(
      enabled: _enabled,
      hovered: _enabled && _hovered,
      pressed: _enabled && _pressed,
      focused: _enabled && _focused,
      selected: widget.selected,
    );
    final colors = NxTheme.of(context).colors;

    Widget body = widget.builder(context, state);
    if (state.focused) {
      body = CustomPaint(
        key: const ValueKey('nx-focus-ring'),
        foregroundPainter: _RingPainter(colors.accent, widget.focusRingRadius),
        child: body,
      );
    }

    return Semantics(
      button: true,
      enabled: _enabled,
      selected: widget.selected ? true : null,
      label: widget.semanticLabel,
      excludeSemantics: widget.excludeChildSemantics,
      child: FocusableActionDetector(
        enabled: _enabled,
        focusNode: widget.focusNode,
        autofocus: widget.autofocus,
        shortcuts: _shortcuts,
        actions: _actions,
        mouseCursor: _enabled
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        onShowFocusHighlight: (v) => setState(() => _focused = v),
        // 호버는 포커스 강조 모드와 무관하게 마우스가 올라와 있는지로만 본다 —
        // FocusableActionDetector 의 호버 강조는 터치 모드에서 꺼진다.
        child: MouseRegion(
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: _enabled ? (_) => _setPressed(true) : null,
            onTapUp: _enabled ? (_) => _setPressed(false) : null,
            onTapCancel: _enabled ? () => _setPressed(false) : null,
            onTap: widget.onPressed,
            onLongPress: widget.onLongPress,
            child: body,
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.color, this.radius);

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    // 2px 떨어진 자리에 2px 선 — 선의 가운데가 3px 바깥이다.
    final rect = (Offset.zero & size).inflate(3);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(radius + 3)),
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.color != color || old.radius != radius;
}
