import 'dart:async';
import 'dart:collection';

import 'package:flutter/widgets.dart';

import 'icons.dart';
import 'pressable.dart';
import 'theme.dart';

enum NxToastKind { info, success, error }

/// 알림 한 줄(SnackBar 의 자리, 15단계 설계 D9).
///
/// **줄을 세운다** — 둘이 한꺼번에 오면 앞의 것이 사라진 뒤 다음이 뜬다. SnackBar 는
/// 앞의 것을 밀어내 첫 알림을 못 읽고 지나가게 했다.
class NxToast {
  NxToast._();

  static void show(
    BuildContext context,
    String message, {
    NxToastKind kind = NxToastKind.info,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final host = context.findAncestorStateOfType<NxToastHostState>();
    assert(host != null, 'NxToastHost 가 위에 없다 — 앱 맨 위에 깔 것');
    host?._enqueue(_Toast(message, kind, actionLabel, onAction));
  }
}

class _Toast {
  _Toast(this.message, this.kind, this.actionLabel, this.onAction);

  final String message;
  final NxToastKind kind;
  final String? actionLabel;
  final VoidCallback? onAction;
}

/// 앱 맨 위에 한 번 깐다. 화면 아래 가운데에 하나씩 띄운다.
class NxToastHost extends StatefulWidget {
  const NxToastHost({super.key, required this.child, this.bottomInset = 88});

  final Widget child;

  /// 입력창 · 모바일 탭(52)을 가리지 않게 띄울 높이(캔버스의 토스트 자리).
  final double bottomInset;

  @override
  State<NxToastHost> createState() => NxToastHostState();
}

class NxToastHostState extends State<NxToastHost> {
  final _queue = Queue<_Toast>();
  _Toast? _current;
  Timer? _timer;

  /// 읽을 시간. 되돌리기 같은 동작이 있으면 조금 더 둔다.
  static const shown = Duration(seconds: 4);
  static const shownWithAction = Duration(seconds: 6);

  void _enqueue(_Toast toast) {
    _queue.add(toast);
    if (_current == null) _next();
  }

  void _next() {
    _timer?.cancel();
    setState(() => _current = _queue.isEmpty ? null : _queue.removeFirst());
    final current = _current;
    if (current == null) return;
    _timer = Timer(
      current.actionLabel == null ? shown : shownWithAction,
      _next,
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final current = _current;
    return Stack(
      textDirection: TextDirection.ltr,
      children: [
        widget.child,
        if (current != null)
          Positioned(
            left: 0,
            right: 0,
            bottom:
                widget.bottomInset + MediaQuery.viewInsetsOf(context).bottom,
            child: Center(
              child: _ToastView(toast: current, onDone: _next),
            ),
          ),
      ],
    );
  }
}

class _ToastView extends StatelessWidget {
  const _ToastView({required this.toast, required this.onDone});

  final _Toast toast;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final theme = NxTheme.of(context);
    final c = theme.colors;
    final (icon, color) = switch (toast.kind) {
      NxToastKind.success => (NxIcons.check, c.success),
      NxToastKind.error => (NxIcons.warning, c.danger),
      NxToastKind.info => (NxIcons.info, c.textSecondary),
    };
    return Semantics(
      liveRegion: true,
      container: true,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 480),
        margin: const EdgeInsets.symmetric(horizontal: NxSpacing.sp6),
        padding: const EdgeInsets.fromLTRB(
          NxSpacing.sp5,
          NxSpacing.inset,
          NxSpacing.sp4,
          NxSpacing.inset,
        ),
        decoration: BoxDecoration(
          color: c.bgElevated,
          borderRadius: BorderRadius.circular(NxRadius.md),
          border: Border.all(
            color: toast.kind == NxToastKind.error
                ? c.danger.withValues(alpha: NxAlpha.edge)
                : c.divider,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            NxIcon(icon, color: color),
            const SizedBox(width: NxSpacing.inset),
            Flexible(child: Text(toast.message, style: theme.text.sm)),
            if (toast.actionLabel != null) ...[
              const SizedBox(width: NxSpacing.sp4),
              NxPressable(
                onPressed: () {
                  toast.onAction?.call();
                  onDone();
                },
                focusRingRadius: 6,
                builder: (context, s) => AnimatedContainer(
                  duration: NxMotion.micro,
                  height: 28,
                  padding: const EdgeInsets.symmetric(
                    horizontal: NxSpacing.sp4,
                  ),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: s.hovered ? c.accentSubtle : NxColors.transparent,
                    borderRadius: BorderRadius.circular(NxRadius.inner),
                  ),
                  child: Text(
                    toast.actionLabel!,
                    style: theme.text.sm.copyWith(
                      color: c.accent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
