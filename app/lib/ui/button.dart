import 'package:flutter/widgets.dart';

import 'icons.dart';
import 'loading.dart';
import 'pressable.dart';
import 'theme.dart';

enum NxButtonKind { primary, secondary, ghost, danger }

/// sm 28 · md 36 · lg 44(모바일 터치 하한).
enum NxSize { sm, md, lg }

/// 글자 버튼(15단계 설계 D3). Filled/Outlined/TextButton 의 자리.
///
/// - primary — 액센트 채움. 화면에 하나
/// - secondary — 테두리
/// - ghost — 글자만(더 보기 · 다시 시도)
/// - danger — 위험 테두리(삭제)
class NxButton extends StatelessWidget {
  const NxButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.kind = NxButtonKind.primary,
    this.size = NxSize.md,
    this.loading = false,
    this.icon,
    this.expand = false,
    this.autofocus = false,
    this.focusNode,
  });

  final String label;
  final VoidCallback? onPressed;
  final NxButtonKind kind;
  final NxSize size;

  /// 참이면 누를 수 없고 글자 앞에 작은 호가 돈다.
  final bool loading;

  /// 글자 앞 아이콘. **장식으로 두지 않는다** — 뜻을 더할 때만(새 이슈의 +).
  final NxIcons? icon;

  /// 가로를 꽉 채운다(모바일 폼).
  final bool expand;
  final bool autofocus;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    final theme = NxTheme.of(context);
    final c = theme.colors;
    final (height, padding, radius, fontSize) = switch (size) {
      NxSize.sm => (28.0, 10.0, NxRadius.sm, 13.0),
      NxSize.md => (36.0, 16.0, NxRadius.md, 14.0),
      NxSize.lg => (44.0, 20.0, NxRadius.md, 15.0),
    };

    return NxPressable(
      onPressed: loading ? null : onPressed,
      autofocus: autofocus,
      focusNode: focusNode,
      focusRingRadius: radius,
      builder: (context, s) {
        final enabled = onPressed != null;
        final (Color bg, Color fg, Color? border) = switch (kind) {
          // 꺼진 버튼은 옅은 중립 바탕. bgElevated 로 칠하면 같은 색인 패널 · 다이얼로그
          // 위에서 사라진다(AI 패널의 「보내기」가 글자만 떠 있었다).
          _ when !enabled => (
            c.textSecondary.withValues(alpha: .12),
            c.borderStrong,
            null,
          ),
          NxButtonKind.primary => (
            s.pressed || s.hovered ? c.accentPress : c.accent,
            c.onAccent,
            null,
          ),
          NxButtonKind.secondary => (
            s.pressed
                ? c.bgElevated
                : (s.hovered
                      ? c.bgElevated.withValues(alpha: .6)
                      : NxColors.transparent),
            c.textPrimary,
            c.borderStrong,
          ),
          NxButtonKind.ghost => (
            s.pressed || s.hovered ? c.accentSubtle : NxColors.transparent,
            c.accent,
            null,
          ),
          NxButtonKind.danger => (
            s.pressed || s.hovered
                ? c.danger.withValues(alpha: .12)
                : NxColors.transparent,
            c.danger,
            c.danger.withValues(alpha: .45),
          ),
        };

        return AnimatedContainer(
          duration: NxMotion.micro,
          curve: NxMotion.ease,
          height: height,
          width: expand ? double.infinity : null,
          padding: EdgeInsets.symmetric(
            horizontal: kind == NxButtonKind.ghost
                ? padding - NxSpacing.sp2
                : padding,
          ),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(radius),
            border: border == null ? null : Border.all(color: border),
          ),
          child: Row(
            mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (loading) ...[
                NxSpinner(size: fontSize, color: fg),
                const SizedBox(width: NxSpacing.sp4),
              ] else if (icon != null) ...[
                NxIcon(icon!, size: fontSize, color: fg),
                const SizedBox(width: NxSpacing.sp3),
              ],
              Text(
                label,
                style: theme.text.base.copyWith(
                  fontSize: fontSize,
                  color: fg,
                  fontWeight: kind == NxButtonKind.primary
                      ? FontWeight.w600
                      : FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// 아이콘만 있는 버튼. **라벨이 필수다** — 글자가 없으니 보조 기술이 읽을 이름이 곧 뜻이다.
class NxIconButton extends StatelessWidget {
  const NxIconButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.size = NxSize.md,
    this.selected = false,
    this.color,
    this.filled = false,
  });

  final NxIcons icon;
  final String label;
  final VoidCallback? onPressed;
  final NxSize size;
  final bool selected;
  final Color? color;

  /// 채운 바탕(보내기 버튼).
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final c = NxTheme.of(context).colors;
    final (box, glyph) = switch (size) {
      NxSize.sm => (28.0, 15.0),
      NxSize.md => (32.0, 16.0),
      NxSize.lg => (44.0, 18.0),
    };

    return NxPressable(
      onPressed: onPressed,
      semanticLabel: label,
      selected: selected,
      excludeChildSemantics: true,
      focusRingRadius: NxRadius.md,
      builder: (context, s) {
        final enabled = onPressed != null;
        final Color bg;
        final Color fg;
        if (filled) {
          bg = !enabled
              ? c.textSecondary.withValues(alpha: .12)
              : (s.pressed || s.hovered ? c.accentPress : c.accent);
          fg = enabled ? c.onAccent : c.borderStrong;
        } else {
          bg = selected
              ? c.accentSubtle
              : (s.pressed || s.hovered ? c.bgElevated : NxColors.transparent);
          fg = !enabled
              ? c.borderStrong
              : (color ??
                    (selected || s.hovered ? c.textPrimary : c.textSecondary));
        }
        return AnimatedContainer(
          duration: NxMotion.micro,
          width: box,
          height: box,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(NxRadius.md),
          ),
          child: NxIcon(icon, size: glyph, color: fg),
        );
      },
    );
  }
}
