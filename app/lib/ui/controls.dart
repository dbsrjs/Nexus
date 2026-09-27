import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'icons.dart';
import 'overlay.dart';
import 'pressable.dart';
import 'theme.dart';

/// 켜고 끄기(Switch · SwitchListTile 의 자리). 36×20.
class NxSwitch extends StatelessWidget {
  const NxSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    required this.label,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;

  /// 보조 기술이 읽을 이름. 화면에 보이는 글자는 곁에서 따로 그린다.
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = NxTheme.of(context).colors;
    final enabled = onChanged != null;
    return NxPressable(
      toggled: value,
      semanticLabel: label,
      excludeChildSemantics: true,
      focusRingRadius: NxRadius.full,
      onPressed: enabled ? () => onChanged!(!value) : null,
      builder: (context, s) => AnimatedContainer(
        duration: NxMotion.micro,
        curve: NxMotion.ease,
        width: 36,
        height: 20,
        padding: EdgeInsets.all(value ? 2 : 1),
        decoration: BoxDecoration(
          color: value
              ? (enabled ? c.accent : c.borderStrong)
              : const Color(0x00000000),
          borderRadius: BorderRadius.circular(NxRadius.full),
          border: value ? null : Border.all(color: c.borderStrong),
        ),
        child: AnimatedAlign(
          duration: NxMotion.micro,
          curve: NxMotion.ease,
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: value
                  ? c.bgBase
                  : (s.hovered ? c.textPrimary : c.textSecondary),
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}

/// 체크(Checkbox 의 자리). 글자까지 한 덩어리로 눌린다.
class NxCheck extends StatelessWidget {
  const NxCheck({
    super.key,
    required this.value,
    required this.onChanged,
    required this.label,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = NxTheme.of(context);
    final c = theme.colors;
    return NxPressable(
      checked: value,
      semanticLabel: label,
      excludeChildSemantics: true,
      focusRingRadius: NxRadius.sm,
      onPressed: onChanged == null ? null : () => onChanged!(!value),
      builder: (context, s) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: NxMotion.micro,
            width: 16,
            height: 16,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: value ? c.accent : const Color(0x00000000),
              borderRadius: BorderRadius.circular(NxRadius.sm),
              border: value
                  ? null
                  : Border.all(
                      color: s.hovered ? c.textSecondary : c.borderStrong,
                    ),
            ),
            child: value
                ? NxIcon(NxIcons.check, size: 12, color: c.onAccent)
                : null,
          ),
          const SizedBox(width: NxSpacing.sp4),
          Text(
            label,
            style: theme.text.base.copyWith(
              color: value ? c.textPrimary : c.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// 몇 개 중 하나(SegmentedButton · 라디오의 자리). 방향키로 옮긴다.
class NxSegmented<T> extends StatelessWidget {
  const NxSegmented({
    super.key,
    required this.segments,
    required this.value,
    required this.onChanged,
    required this.label,
    this.expand = true,
  });

  final List<(T, String)> segments;
  final T value;
  final ValueChanged<T>? onChanged;

  /// 무리 전체의 이름(「테마」).
  final String label;
  final bool expand;

  void _step(int delta) {
    final i = segments.indexWhere((s) => s.$1 == value);
    final next = (i + delta).clamp(0, segments.length - 1);
    if (next != i) onChanged?.call(segments[next].$1);
  }

  @override
  Widget build(BuildContext context) {
    final theme = NxTheme.of(context);
    final c = theme.colors;
    final buttons = [
      for (final (v, text) in segments)
        () {
          final selected = v == value;
          final pressable = NxPressable(
            inMutuallyExclusiveGroup: true,
            checked: selected,
            selected: selected,
            focusRingRadius: 6,
            onPressed: onChanged == null ? null : () => onChanged!(v),
            builder: (context, s) => AnimatedContainer(
              duration: NxMotion.micro,
              height: 32,
              padding: const EdgeInsets.symmetric(horizontal: NxSpacing.sp5),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected
                    ? c.bgElevated
                    : (s.hovered
                          ? c.bgElevated.withValues(alpha: .5)
                          : const Color(0x00000000)),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                text,
                style: theme.text.sm.copyWith(
                  color: selected ? c.textPrimary : c.textSecondary,
                  fontWeight: selected ? FontWeight.w600 : null,
                ),
              ),
            ),
          );
          return expand ? Expanded(child: pressable) : pressable;
        }(),
    ];

    return Semantics(
      label: label,
      container: true,
      child: Shortcuts(
        shortcuts: const {
          SingleActivator(LogicalKeyboardKey.arrowRight): _Step(1),
          SingleActivator(LogicalKeyboardKey.arrowLeft): _Step(-1),
        },
        child: Actions(
          actions: {
            _Step: CallbackAction<_Step>(
              onInvoke: (i) {
                _step(i.delta);
                return null;
              },
            ),
          },
          child: Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: c.bgBase,
              borderRadius: BorderRadius.circular(NxRadius.md),
            ),
            child: Row(
              mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
              children: buttons,
            ),
          ),
        ),
      ),
    );
  }
}

class _Step extends Intent {
  const _Step(this.delta);
  final int delta;
}

/// 목록에서 하나 고르기(DropdownButton 의 자리). 누르면 [NxMenu] 가 열린다.
class NxSelect<T> extends StatelessWidget {
  const NxSelect({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
    this.placeholder = '고르기',
    this.width = 260,
  });

  final List<(T, String)> options;
  final T? value;
  final ValueChanged<T>? onChanged;
  final String placeholder;
  final double width;

  @override
  Widget build(BuildContext context) {
    final theme = NxTheme.of(context);
    final c = theme.colors;
    final current = options
        .where((o) => o.$1 == value)
        .map((o) => o.$2)
        .firstOrNull;

    return NxMenu(
      width: width,
      entries: [
        for (final (v, text) in options)
          NxMenuItem(
            text,
            selected: v == value,
            onSelected: onChanged == null ? null : () => onChanged!(v),
          ),
      ],
      anchorBuilder: (context, toggle) => NxPressable(
        onPressed: onChanged == null ? null : toggle,
        builder: (context, s) => AnimatedContainer(
          duration: NxMotion.micro,
          width: width,
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: NxSpacing.sp5),
          decoration: BoxDecoration(
            color: c.bgElevated,
            borderRadius: BorderRadius.circular(NxRadius.md),
            border: Border.all(
              color: s.hovered ? c.textSecondary : c.borderStrong,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  current ?? placeholder,
                  overflow: TextOverflow.ellipsis,
                  style: theme.text.base.copyWith(
                    color: current == null ? c.textSecondary : c.textPrimary,
                  ),
                ),
              ),
              NxIcon(NxIcons.chevronDown, size: 14, color: c.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
