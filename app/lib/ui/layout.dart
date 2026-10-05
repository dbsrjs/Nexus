import 'package:flutter/widgets.dart';

import 'pressable.dart';
import 'theme.dart';

/// 구분선(Divider 의 자리). 거의 보이지 않아야 한다.
class NxDivider extends StatelessWidget {
  const NxDivider({super.key, this.vertical = false, this.indent = 0});

  final bool vertical;
  final double indent;

  @override
  Widget build(BuildContext context) {
    final c = NxTheme.of(context).colors;
    return vertical
        ? Container(
            width: 1,
            margin: EdgeInsets.symmetric(vertical: indent),
            color: c.divider,
          )
        : Container(
            height: 1,
            margin: EdgeInsets.symmetric(horizontal: indent),
            color: c.divider,
          );
  }
}

/// 화면 머리 줄(AppBar 의 자리). 52px · 아래 구분선.
///
/// [leading] 은 뒤로 가기 같은 **동작**만 둔다 — 햄버거는 쓰지 않는다(15단계 설계 D12).
class NxHeader extends StatelessWidget {
  const NxHeader({
    super.key,
    this.title,
    this.titleWidget,
    this.subtitle,
    this.leading,
    this.actions = const [],
  });

  final String? title;
  final Widget? titleWidget;
  final String? subtitle;
  final Widget? leading;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final theme = NxTheme.of(context);
    final c = theme.colors;
    return Container(
      height: 52,
      padding: EdgeInsets.only(
        left: leading == null ? NxSpacing.sp7 : NxSpacing.sp4,
        right: NxSpacing.sp5,
      ),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: c.divider)),
      ),
      child: Row(
        children: [
          if (leading != null) ...[
            leading!,
            const SizedBox(width: NxSpacing.sp3),
          ],
          Expanded(
            child:
                titleWidget ??
                Row(
                  children: [
                    if (title != null)
                      Flexible(
                        child: Semantics(
                          header: true,
                          child: Text(
                            title!,
                            style: theme.text.header,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    if (subtitle != null) ...[
                      const SizedBox(width: NxSpacing.sp5),
                      Flexible(
                        child: Text(
                          subtitle!,
                          style: theme.text.secondary,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
          ),
          for (final a in actions) ...[const SizedBox(width: NxSpacing.sp2), a],
        ],
      ),
    );
  }
}

/// 화면 틀(Scaffold 의 자리, 15단계 설계 D11). 머리 줄 + 본문, 바탕색.
///
/// **키보드만큼 본문을 올린다** — Scaffold 가 공짜로 하던 일이다. 없으면 모바일에서 입력창이
/// 키보드에 가린다.
class NxPage extends StatelessWidget {
  const NxPage({
    super.key,
    this.header,
    required this.body,
    this.background,
    this.bottom,
  });

  final Widget? header;
  final Widget body;
  final Color? background;

  /// 본문 아래 고정(모바일 탭).
  final Widget? bottom;

  @override
  Widget build(BuildContext context) {
    final c = NxTheme.of(context).colors;
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    return ColoredBox(
      color: background ?? c.bgBase,
      child: SafeArea(
        bottom: keyboard == 0,
        child: Padding(
          padding: EdgeInsets.only(bottom: keyboard),
          // 올린 만큼을 안쪽에서 지운다 — 셸의 NxPage 안에 화면의 NxPage 가 겹치면 둘 다
          // 키보드만큼 올려 입력창이 키보드 위로 한 번 더 떴다(Android, 17단계에서 잡음).
          // SafeArea 안쪽의 MediaQuery 에서 지워야 한다 — 바깥 것을 복사하면 SafeArea 가 지운
          // 상태 표시줄 여백이 되살아나 머리 줄이 한 번 더 내려간다.
          child: Builder(
            builder: (inner) => MediaQuery.removeViewInsets(
              context: inner,
              removeBottom: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ?header,
                  Expanded(child: body),
                  if (keyboard == 0) ?bottom,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 목록 한 줄(ListTile 의 자리). **앞 장식 아이콘을 두지 않는다** — [leading] 은 아바타 ·
/// 상태처럼 뜻이 있는 것만.
class NxRow extends StatelessWidget {
  const NxRow({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onPressed,
    this.onLongPress,
    this.selected = false,
    this.dense = false,
    this.titleStyle,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onPressed;
  final VoidCallback? onLongPress;
  final bool selected;

  /// 32px(채널 목록). 아니면 부제에 맞춰 높이가 는다.
  final bool dense;
  final TextStyle? titleStyle;

  @override
  Widget build(BuildContext context) {
    final theme = NxTheme.of(context);
    final c = theme.colors;
    Widget content(NxPressState s) => AnimatedContainer(
      duration: NxMotion.micro,
      constraints: BoxConstraints(minHeight: dense ? 32 : 44),
      padding: EdgeInsets.symmetric(
        horizontal: NxSpacing.inset,
        vertical: dense ? 0 : NxSpacing.sp3,
      ),
      decoration: BoxDecoration(
        color: selected
            ? c.accentSubtle
            : (s.hovered || s.pressed ? c.bgElevated : NxColors.transparent),
        borderRadius: BorderRadius.circular(NxRadius.md),
      ),
      child: Row(
        children: [
          if (leading != null) ...[
            leading!,
            const SizedBox(width: NxSpacing.inset),
          ],
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  overflow: TextOverflow.ellipsis,
                  style:
                      titleStyle ??
                      theme.text.base.copyWith(
                        color: selected ? c.textPrimary : c.textPrimary,
                        fontWeight: selected ? FontWeight.w600 : null,
                      ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: theme.text.meta,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: NxSpacing.sp4),
            trailing!,
          ],
        ],
      ),
    );

    if (onPressed == null && onLongPress == null) {
      return content(
        const NxPressState(
          enabled: false,
          hovered: false,
          pressed: false,
          focused: false,
          selected: false,
        ),
      );
    }
    return NxPressable(
      onPressed: onPressed,
      onLongPress: onLongPress,
      selected: selected,
      builder: (context, s) => content(s),
    );
  }
}

class NxTab {
  const NxTab(this.label, {this.count});

  final String label;

  /// 오른쪽 작은 모노 숫자(열린 이슈 수 등). 없으면 안 보인다.
  final int? count;
}

/// 모바일 아래 탭(15단계 설계 D12). **Material NavigationBar(아이콘 + 알약)가 아니라**
/// 글자 탭에 고른 탭 위 막대다.
class NxTabBar extends StatelessWidget {
  const NxTabBar({
    super.key,
    required this.tabs,
    required this.index,
    required this.onChanged,
  });

  final List<NxTab> tabs;
  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = NxTheme.of(context);
    final c = theme.colors;
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: c.bgBase,
        border: Border(top: BorderSide(color: c.divider)),
      ),
      child: Row(
        children: [
          for (var i = 0; i < tabs.length; i++)
            Expanded(
              child: NxPressable(
                selected: i == index,
                onPressed: () => onChanged(i),
                focusRingRadius: NxRadius.sm,
                builder: (context, s) => Stack(
                  alignment: Alignment.center,
                  children: [
                    if (i == index)
                      Positioned(
                        key: const ValueKey('nx-tab-indicator'),
                        top: 0,
                        child: Container(
                          width: 28,
                          height: 2,
                          decoration: BoxDecoration(
                            color: c.accent,
                            borderRadius: const BorderRadius.vertical(
                              bottom: Radius.circular(
                                NxSpacing.sp1,
                              ), // 토큰 밖: 탭 표시줄 두께(2)의 반원
                            ),
                          ),
                        ),
                      ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          tabs[i].label,
                          style: theme.text.base.copyWith(
                            color: i == index ? c.textPrimary : c.textSecondary,
                            fontWeight: i == index ? FontWeight.w700 : null,
                          ),
                        ),
                        if (tabs[i].count != null) ...[
                          const SizedBox(width: NxSpacing.sp3),
                          Text('${tabs[i].count}', style: theme.text.mono),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// 스크롤 동작(15단계 설계 D13). **안드로이드의 글로 · 늘어남을 그리지 않고**, 데스크톱은 얇은
/// 자체 스크롤바를 쓴다. `WidgetsApp` 의 기본 `ScrollBehavior` 도 안드로이드에서 글로를 그린다 —
/// 빼먹기 쉬운 기본 UI 다.
class NxScrollBehavior extends ScrollBehavior {
  const NxScrollBehavior();

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) => child;

  @override
  Widget buildScrollbar(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    switch (getPlatform(context)) {
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.macOS:
        return RawScrollbar(
          controller: details.controller,
          thickness: 6,
          radius: const Radius.circular(NxRadius.full),
          thumbColor: NxTheme.of(
            context,
          ).colors.borderStrong.withValues(alpha: NxAlpha.hover),
          child: child,
        );
      case TargetPlatform.android:
      case TargetPlatform.iOS:
      case TargetPlatform.fuchsia:
        return child;
    }
  }
}
