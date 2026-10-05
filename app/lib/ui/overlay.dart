import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'pressable.dart';
import 'theme.dart';

/// 메뉴 항목들. **목록 행 앞에 장식 아이콘을 두지 않는다**(사용자 지시) — 글자만.
sealed class NxMenuEntry {
  const NxMenuEntry();
}

class NxMenuItem extends NxMenuEntry {
  const NxMenuItem(
    this.label, {
    this.onSelected,
    this.danger = false,
    this.shortcut,
    this.selected = false,
  });

  final String label;
  final VoidCallback? onSelected;
  final bool danger;

  /// 오른쪽에 모노로(`Ctrl ,`).
  final String? shortcut;

  /// 셀렉트에서 지금 고른 값.
  final bool selected;
}

class NxMenuDivider extends NxMenuEntry {
  const NxMenuDivider();
}

/// 메뉴 맨 위의 누를 수 없는 머리(계정 메뉴의 이름 · 이메일).
class NxMenuHeader extends NxMenuEntry {
  const NxMenuHeader(this.title, {this.subtitle});

  final String title;
  final String? subtitle;
}

/// 메뉴 판. 메뉴 · 동작 카드 · 셀렉트가 같은 판을 쓴다.
///
/// 방향키로 항목을 오가고 Esc 로 닫는다. 열리면 첫 항목에 포커스가 간다 —
/// 키보드로 연 사람이 바로 고를 수 있게.
class NxMenuPanel extends StatelessWidget {
  const NxMenuPanel({
    super.key,
    required this.entries,
    required this.onClose,
    this.width = 220,
    this.touch = false,
  });

  final List<NxMenuEntry> entries;
  final VoidCallback onClose;
  final double width;

  /// 모바일 — 항목 높이 44(터치 하한).
  final bool touch;

  @override
  Widget build(BuildContext context) {
    final theme = NxTheme.of(context);
    final c = theme.colors;
    var first = true;

    return Shortcuts(
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.arrowDown): NextFocusIntent(),
        SingleActivator(LogicalKeyboardKey.arrowUp): PreviousFocusIntent(),
        SingleActivator(LogicalKeyboardKey.escape): DismissIntent(),
      },
      child: Actions(
        actions: {
          DismissIntent: CallbackAction<DismissIntent>(
            onInvoke: (_) {
              onClose();
              return null;
            },
          ),
        },
        child: FocusTraversalGroup(
          child: Semantics(
            scopesRoute: true,
            explicitChildNodes: true,
            child: Container(
              width: width,
              padding: const EdgeInsets.all(NxSpacing.sp2),
              decoration: BoxDecoration(
                color: c.bgElevated,
                borderRadius: BorderRadius.circular(
                  touch ? NxRadius.lg : NxRadius.md,
                ),
                border: Border.all(color: c.divider),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final entry in entries)
                    switch (entry) {
                      NxMenuDivider() => Container(
                        height: 1,
                        margin: const EdgeInsets.symmetric(
                          vertical: NxSpacing.sp2,
                          horizontal: NxSpacing.sp4,
                        ),
                        color: c.divider,
                      ),
                      NxMenuHeader(:final title, :final subtitle) => Padding(
                        padding: const EdgeInsets.fromLTRB(
                          NxSpacing.inset,
                          NxSpacing.sp4,
                          NxSpacing.inset,
                          NxSpacing.inset,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(title, style: theme.text.strong),
                            if (subtitle != null)
                              Text(subtitle, style: theme.text.meta),
                          ],
                        ),
                      ),
                      NxMenuItem() => _item(
                        context,
                        entry,
                        autofocus: () {
                          final f = first;
                          first = false;
                          return f;
                        }(),
                      ),
                    },
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _item(
    BuildContext context,
    NxMenuItem item, {
    required bool autofocus,
  }) {
    final theme = NxTheme.of(context);
    final c = theme.colors;
    return NxPressable(
      autofocus: autofocus,
      selected: item.selected,
      focusRingRadius: 6,
      onPressed: item.onSelected == null
          ? null
          : () {
              onClose();
              item.onSelected!();
            },
      builder: (context, s) => AnimatedContainer(
        duration: NxMotion.micro,
        height: touch ? 44 : 32,
        padding: const EdgeInsets.symmetric(horizontal: NxSpacing.inset),
        decoration: BoxDecoration(
          color: s.hovered || s.pressed || s.focused || item.selected
              ? c.accentSubtle
              : NxColors.transparent,
          borderRadius: BorderRadius.circular(NxRadius.inner),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                item.label,
                overflow: TextOverflow.ellipsis,
                style:
                    (touch
                            ? theme.text.body.copyWith(height: 1.3)
                            : theme.text.sm)
                        .copyWith(
                          color: item.onSelected == null
                              ? c.borderStrong
                              : item.danger
                              ? c.danger
                              : c.textPrimary,
                          fontWeight: item.selected ? FontWeight.w600 : null,
                        ),
              ),
            ),
            if (item.shortcut != null)
              Text(item.shortcut!, style: theme.text.mono),
          ],
        ),
      ),
    );
  }
}

bool get _isTouch =>
    defaultTargetPlatform == TargetPlatform.android ||
    defaultTargetPlatform == TargetPlatform.iOS;

/// 누르면 메뉴가 붙어 열리는 것(15단계 설계 D8). PopupMenuButton 의 자리.
///
/// 앵커 아래에 열리고, 화면 밖으로 넘치면 위로 뒤집는다. 바깥을 누르거나 Esc 면 닫힌다.
class NxMenu extends StatefulWidget {
  const NxMenu({
    super.key,
    required this.anchorBuilder,
    required this.entries,
    this.width = 220,
    this.openUp = false,
  });

  final Widget Function(BuildContext context, VoidCallback toggle)
  anchorBuilder;
  final List<NxMenuEntry> entries;
  final double width;

  /// 앵커 위로 연다(레일 맨 아래의 계정 버튼).
  final bool openUp;

  @override
  State<NxMenu> createState() => _NxMenuState();
}

class _NxMenuState extends State<NxMenu> {
  final _portal = OverlayPortalController();
  final _link = LayerLink();

  /// 앵커의 오른쪽 끝에 맞춘다 — 왼쪽 끝에서 펼치면 화면 밖으로 넘칠 때.
  bool _alignEnd = false;

  void _toggle() {
    if (_portal.isShowing) return _portal.hide();
    // 열 때마다 잰다. 카드의 「⋯」처럼 오른쪽 끝에 붙은 앵커에서 폭 220 이 넘쳐
    // 메뉴가 화면 밖으로 잘렸다(Android 에서 발견).
    final box = context.findRenderObject() as RenderBox?;
    final overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox?;
    if (box != null && overlay != null && box.hasSize) {
      final left = box.localToGlobal(Offset.zero, ancestor: overlay).dx;
      _alignEnd = left + widget.width > overlay.size.width - NxSpacing.sp4;
    }
    _portal.show();
  }

  void _close() {
    if (_portal.isShowing) _portal.hide();
  }

  Alignment _corner({required bool top}) => switch ((top, _alignEnd)) {
    (true, false) => Alignment.topLeft,
    (true, true) => Alignment.topRight,
    (false, false) => Alignment.bottomLeft,
    (false, true) => Alignment.bottomRight,
  };

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _link,
      child: OverlayPortal(
        controller: _portal,
        overlayChildBuilder: (context) => Stack(
          children: [
            // 바깥을 누르면 닫는다. 막을 그리지는 않는다 — 메뉴는 백드롭 없이 뜬다.
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _close,
              ),
            ),
            CompositedTransformFollower(
              link: _link,
              showWhenUnlinked: false,
              targetAnchor: _corner(top: widget.openUp),
              followerAnchor: _corner(top: !widget.openUp),
              offset: Offset(0, widget.openUp ? -4 : 4),
              // Align 은 오버레이 전체로 늘어난다 — 위로 열 때는 **아래에** 붙여야 패널이
              // 앵커 바로 위에 온다. topLeft 로 두었더니 계정 메뉴가 화면 맨 위로 튀었다
              // (Android 에서 사용자가 발견). 가로도 같다 — 끝에 맞출 때는 오른쪽에 붙인다.
              child: Align(
                alignment: _corner(top: !widget.openUp),
                child: NxMenuPanel(
                  entries: widget.entries,
                  onClose: _close,
                  width: widget.width,
                  // 손가락으로 누르는 기기에서는 32px 줄이 너무 얇다 — 동작 카드와 같은 44.
                  touch: _isTouch,
                ),
              ),
            ),
          ],
        ),
        child: widget.anchorBuilder(context, _toggle),
      ),
    );
  }
}

/// 누른 자리 곁에 뜨는 동작 카드(15단계 캔버스). **안드로이드식 바텀시트 대신이다** —
/// 손잡이가 없고 화면 아래에서 올라오지 않는다. 누른 것([header])을 막 위로 띄워 무엇에
/// 대한 동작인지 보이고, 그 아래(자리가 없으면 위)에 동작이 붙는다.
class NxActionCard {
  NxActionCard._();

  static Future<void> show(
    BuildContext context, {
    required Rect anchor,
    required List<NxMenuEntry> entries,
    Widget? header,
    Widget Function(VoidCallback close)? above,
  }) {
    final done = Completer<void>();
    // 동작 카드는 가장 바깥 Overlay 에 뜬다 — 테마가 화면 쪽에만 깔려 있으면 거기서는
    // 보이지 않는다. 부른 자리의 테마를 들고 가서 다시 깐다(InheritedTheme 과 같은 까닭).
    final theme = NxTheme.of(context);
    late OverlayEntry entry;
    void close() {
      if (entry.mounted) entry.remove();
      if (!done.isCompleted) done.complete();
    }

    entry = OverlayEntry(
      builder: (context) => NxTheme(
        data: theme,
        child: _ActionCardLayer(
          anchor: anchor,
          entries: entries,
          header: header,
          above: above,
          onClose: close,
        ),
      ),
    );
    // **가장 바깥 오버레이에** 띄운다. 셸 안 화면은 ShellRoute 의 안쪽 내비게이터 속이라
    // 가까운 오버레이에 넣으면 막이 탭 줄 · 상태 표시줄을 덮지 못하고 위쪽 리액션 줄이
    // 잘렸다(Android 에뮬레이터에서 발견). 앵커도 전역 좌표라 바깥 쪽이 맞다.
    Overlay.of(context, rootOverlay: true).insert(entry);
    return done.future;
  }
}

class _ActionCardLayer extends StatelessWidget {
  const _ActionCardLayer({
    required this.anchor,
    required this.entries,
    required this.header,
    required this.above,
    required this.onClose,
  });

  final Rect anchor;
  final List<NxMenuEntry> entries;
  final Widget? header;

  /// 메뉴 위에 붙는 줄(리액션 고르기). 고르면 카드를 닫을 수 있게 닫기를 받는다.
  final Widget Function(VoidCallback close)? above;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final c = NxTheme.of(context).colors;
    final screen = MediaQuery.sizeOf(context);
    final padding = MediaQuery.paddingOf(context);
    const margin = 12.0;
    final width = (screen.width - margin * 2).clamp(0.0, 360.0);
    final left = anchor.left.clamp(margin, screen.width - width - margin);
    // 아래에 둘 자리가 넉넉하지 않으면 위로.
    final spaceBelow = screen.height - anchor.bottom;
    final below = spaceBelow > 280;

    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            onTap: onClose,
            child: ColoredBox(color: c.scrim),
          ),
        ),
        if (header != null)
          Positioned(left: left, width: width, top: anchor.top, child: header!),
        // 남은 자리 안에서만 그린다 — 넘치면 잘리지 않고 밀어 볼 수 있게. 위로 열 때는
        // 상태 표시줄 아래까지만 쓴다.
        Positioned(
          left: left,
          right: margin,
          top: below ? anchor.bottom + 8 : padding.top + margin,
          bottom: below
              ? padding.bottom + margin
              : screen.height - anchor.top + 8,
          child: Align(
            alignment: below ? Alignment.topLeft : Alignment.bottomLeft,
            child: SingleChildScrollView(
              reverse: !below,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (above != null) ...[
                    above!(onClose),
                    const SizedBox(height: NxSpacing.sp4),
                  ],
                  NxMenuPanel(
                    entries: entries,
                    onClose: onClose,
                    width: 240,
                    touch: true,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// 마우스를 올리면 잠시 뒤 위에 뜨는 설명(Tooltip 의 자리). 보조 기술에는 늘 실린다.
class NxTooltip extends StatefulWidget {
  const NxTooltip({super.key, required this.message, required this.child});

  final String message;
  final Widget child;

  @override
  State<NxTooltip> createState() => _NxTooltipState();
}

class _NxTooltipState extends State<NxTooltip> {
  final _portal = OverlayPortalController();
  final _link = LayerLink();
  Timer? _timer;

  void _enter() {
    _timer?.cancel();
    _timer = Timer(const Duration(milliseconds: 500), () {
      if (mounted) _portal.show();
    });
  }

  void _exit() {
    _timer?.cancel();
    if (_portal.isShowing) _portal.hide();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = NxTheme.of(context);
    return Semantics(
      tooltip: widget.message,
      child: CompositedTransformTarget(
        link: _link,
        child: OverlayPortal(
          controller: _portal,
          overlayChildBuilder: (context) => CompositedTransformFollower(
            link: _link,
            showWhenUnlinked: false,
            targetAnchor: Alignment.topCenter,
            followerAnchor: Alignment.bottomCenter,
            offset: const Offset(0, -6),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: IgnorePointer(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: NxSpacing.sp4,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colors.textPrimary,
                    borderRadius: BorderRadius.circular(NxRadius.sm),
                  ),
                  child: Text(
                    widget.message,
                    style: theme.text.xs.copyWith(
                      color: theme.colors.bgBase,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          ),
          child: MouseRegion(
            onEnter: (_) => _enter(),
            onExit: (_) => _exit(),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
