import 'package:flutter/widgets.dart';

import 'pressable.dart';
import 'theme.dart';

/// 선택 핸들(모바일) — Material 의 물방울 핸들 대신 자체 모양(15단계 설계 D6).
///
/// 툴바는 여기서 만들지 않는다 — `EditableText.contextMenuBuilder` 가
/// [NxTextContextMenu] 를 쓴다(`TextSelectionHandleControls` 의 규칙).
class NxTextSelectionControls extends TextSelectionControls
    with TextSelectionHandleControls {
  NxTextSelectionControls(this.color);

  final Color color;

  static const _size = 18.0;

  @override
  Size getHandleSize(double textLineHeight) => const Size(_size, _size);

  @override
  Widget buildHandle(
    BuildContext context,
    TextSelectionHandleType type,
    double textLineHeight, [
    VoidCallback? onTap,
  ]) {
    final handle = CustomPaint(
      size: const Size(_size, _size),
      painter: _HandlePainter(color, type),
    );
    return onTap == null
        ? handle
        : GestureDetector(onTap: onTap, child: handle);
  }

  @override
  Offset getHandleAnchor(TextSelectionHandleType type, double textLineHeight) =>
      switch (type) {
        TextSelectionHandleType.left => const Offset(_size, 0),
        TextSelectionHandleType.right => Offset.zero,
        TextSelectionHandleType.collapsed => const Offset(_size / 2, 0),
      };
}

class _HandlePainter extends CustomPainter {
  _HandlePainter(this.color, this.type);

  final Color color;
  final TextSelectionHandleType type;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final r = size.width / 2;
    final center = Offset(r, r + 1);
    canvas.drawCircle(center, r - 2, paint);
    // 글줄에 닿는 모서리 — 왼쪽 핸들은 오른쪽 위, 오른쪽 핸들은 왼쪽 위가 모난다.
    switch (type) {
      case TextSelectionHandleType.left:
        canvas.drawRect(Rect.fromLTWH(r, 1, r - 2, r), paint);
      case TextSelectionHandleType.right:
        canvas.drawRect(Rect.fromLTWH(2, 1, r - 2, r), paint);
      case TextSelectionHandleType.collapsed:
        canvas.drawRect(Rect.fromLTWH(r - 1, 0, 2, r), paint);
    }
  }

  @override
  bool shouldRepaint(_HandlePainter old) =>
      old.color != color || old.type != type;
}

/// 선택 영역 곁에 뜨는 자체 메뉴(우클릭 · 길게 누르기). 항목 이름은 한국어로 우리가 붙인다 —
/// 표준 항목의 이름은 원래 Material 지역화가 주던 것이다.
class NxTextContextMenu extends StatelessWidget {
  const NxTextContextMenu({
    super.key,
    required this.anchors,
    required this.items,
  });

  final TextSelectionToolbarAnchors anchors;
  final List<ContextMenuButtonItem> items;

  static String labelFor(ContextMenuButtonItem item) => switch (item.type) {
    ContextMenuButtonType.cut => '잘라내기',
    ContextMenuButtonType.copy => '복사',
    ContextMenuButtonType.paste => '붙여넣기',
    ContextMenuButtonType.selectAll => '전체 선택',
    ContextMenuButtonType.delete => '지우기',
    ContextMenuButtonType.lookUp => '찾아보기',
    ContextMenuButtonType.searchWeb => '웹 검색',
    ContextMenuButtonType.share => '공유',
    ContextMenuButtonType.liveTextInput => '글자 인식',
    ContextMenuButtonType.custom => item.label ?? '',
  };

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    final theme = NxTheme.of(context);
    final c = theme.colors;
    return CustomSingleChildLayout(
      delegate: _AboveAnchor(anchors.primaryAnchor),
      child: Container(
        padding: const EdgeInsets.all(NxSpacing.sp2),
        decoration: BoxDecoration(
          color: c.bgElevated,
          borderRadius: BorderRadius.circular(NxRadius.md),
          border: Border.all(color: c.divider),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final item in items)
              NxPressable(
                onPressed: item.onPressed,
                focusRingRadius: 6,
                builder: (context, s) => AnimatedContainer(
                  duration: NxMotion.micro,
                  height: 32,
                  padding: const EdgeInsets.symmetric(
                    horizontal: NxSpacing.sp5,
                  ),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: s.hovered || s.pressed
                        ? c.accentSubtle
                        : const Color(0x00000000),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(labelFor(item), style: theme.text.sm),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// 기준점 위에 두되, 화면 위로 넘치면 아래로 내린다.
class _AboveAnchor extends SingleChildLayoutDelegate {
  _AboveAnchor(this.anchor);

  final Offset anchor;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) =>
      constraints.loosen();

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    const gap = 8.0;
    final x = (anchor.dx - childSize.width / 2).clamp(
      8.0,
      size.width - childSize.width - 8,
    );
    final above = anchor.dy - childSize.height - gap;
    final y = above >= 8 ? above : anchor.dy + gap + 20;
    return Offset(x.toDouble(), y);
  }

  @override
  bool shouldRelayout(_AboveAnchor old) => old.anchor != anchor;
}
