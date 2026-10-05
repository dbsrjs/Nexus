import 'package:flutter/widgets.dart';

import 'icons.dart';
import 'pressable.dart';
import 'theme.dart';

/// 알약 모양의 누르는 것(Chip · InputChip 의 자리) — 컨텍스트 칩 · 필터 · 리액션.
class NxChip extends StatelessWidget {
  const NxChip({
    super.key,
    required this.label,
    this.onPressed,
    this.selected = false,
    this.icon,
    this.trailing,
    this.onRemove,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool selected;

  /// 뜻을 더하는 아이콘만(리액션 · 저장소). 장식 아이콘은 두지 않는다.
  final NxIcons? icon;

  /// 오른쪽 모노 숫자(리액션 수).
  final String? trailing;

  /// 있으면 오른쪽에 ×.
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = NxTheme.of(context);
    final c = theme.colors;
    return NxPressable(
      onPressed: onPressed,
      selected: selected,
      focusRingRadius: NxRadius.full,
      builder: (context, s) => AnimatedContainer(
        duration: NxMotion.micro,
        height: 28,
        padding: EdgeInsets.only(
          left: NxSpacing.inset,
          right: onRemove == null ? NxSpacing.inset : NxSpacing.sp2,
        ),
        decoration: BoxDecoration(
          color: selected
              ? c.accentSubtle
              : (s.hovered ? c.bgElevated : NxColors.transparent),
          borderRadius: BorderRadius.circular(NxRadius.full),
          border: Border.all(color: selected ? c.accent : c.borderStrong),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              NxIcon(
                icon!,
                size: NxIconSize.xs,
                color: selected ? c.accent : c.textSecondary,
              ),
              const SizedBox(width: NxSpacing.sp3),
            ],
            Text(
              label,
              style: theme.text.xs.copyWith(
                color: selected ? c.textPrimary : c.textSecondary,
              ),
            ),
            if (trailing != null) ...[
              // 토큰 밖: 라벨과 개수 사이 — 4 는 붙고 6 은 떨어져 보인다(광학 보정).
              const SizedBox(width: 5),
              Text(
                trailing!,
                style: theme.text.mono.copyWith(fontSize: NxFontSize.xs),
              ),
            ],
            if (onRemove != null) ...[
              const SizedBox(width: NxSpacing.sp1),
              GestureDetector(
                onTap: onRemove,
                child: Semantics(
                  button: true,
                  label: '$label 빼기',
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: Center(
                      child: NxIcon(
                        NxIcons.close,
                        size: NxIconSize.xs,
                        color: c.textSecondary,
                      ),
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

/// 안 읽은 수 · 멘션 뱃지(Badge 의 자리).
class NxBadge extends StatelessWidget {
  const NxBadge({super.key, required this.count, this.mention = false});

  final int count;

  /// 멘션은 위험색에 `@`. **개수보다 「불렸다」가 먼저**라 한 건이면 `@` 만 보인다.
  final bool mention;

  @override
  Widget build(BuildContext context) {
    final theme = NxTheme.of(context);
    final c = theme.colors;
    final text = mention
        ? (count > 1 ? '@${count > 99 ? '99+' : count}' : '@')
        : (count > 99 ? '99+' : '$count');
    // alignment 를 주면 Container 가 부모 폭만큼 늘어난다 — 폭이 정해진 곳(Wrap · Column)에서
    // 뱃지가 가로로 길게 퍼졌다(갤러리 스크린샷). 가운데 맞춤은 Center(widthFactor: 1)로.
    return Container(
      height: 18,
      constraints: const BoxConstraints(minWidth: 18),
      padding: const EdgeInsets.symmetric(horizontal: NxSpacing.sp3),
      decoration: BoxDecoration(
        color: mention ? c.danger : c.accent,
        borderRadius: BorderRadius.circular(NxRadius.full),
      ),
      child: Center(
        widthFactor: 1,
        child: Text(
          text,
          style: theme.text.xs2.copyWith(
            color: mention ? c.onDanger : c.onAccent,
            fontWeight: FontWeight.w700,
            height: 1,
          ),
        ),
      ),
    );
  }
}

/// 작은 표지 — 이슈 키(`NEXUS-42`) · 상태 · 우선순위. 누를 수 없다.
class NxTag extends StatelessWidget {
  const NxTag(
    this.text, {
    super.key,
    this.color,
    this.dot = false,
    this.mono = false,
  });

  final String text;

  /// 글자와 점의 색(우선순위 · PR 상태). 없으면 보조 글자색.
  final Color? color;

  /// 앞에 색 점(색만으로 상태를 말하지 않게 글자와 함께 쓴다 — 디자인 시스템 §6).
  final bool dot;
  final bool mono;

  @override
  Widget build(BuildContext context) {
    final theme = NxTheme.of(context);
    final c = theme.colors;
    final tint = color ?? c.textSecondary;
    final style = (mono ? theme.text.mono : theme.text.xs2).copyWith(
      color: tint,
      fontWeight: FontWeight.w600,
    );
    return Container(
      height: 20,
      padding: const EdgeInsets.symmetric(horizontal: NxSpacing.sp3),
      decoration: mono
          ? BoxDecoration(
              borderRadius: BorderRadius.circular(NxRadius.sm),
              border: Border.all(color: c.borderStrong),
            )
          : null,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dot) ...[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: tint, shape: BoxShape.circle),
            ),
            const SizedBox(width: NxSpacing.sp2),
          ],
          Text(text, style: style),
        ],
      ),
    );
  }
}
