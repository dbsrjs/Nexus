/// 보드의 컬럼 하나 — 머리(상태 점 · 개수) · 카드 목록 · 놓일 자리(점선 칸) · 빈 컬럼.
/// `board_screen.dart`(612줄)에서 2026-10-06 에 떼어 냈다. 끌기 상태와 키보드 조작은 화면에
/// 남고, 여기는 받은 상태를 그리기만 한다.
library;

import 'package:flutter/widgets.dart';
import '../../domain/models/issue.dart';
import '../../ui/ui.dart';
import 'board_controller.dart';
import 'issue_card.dart';

/// 컬럼 머리의 점 색 — 캔버스 「보드」의 상태 표시(백로그는 빈 고리).
Color? _statusColor(NxColors c, IssueStatus status) => switch (status) {
  IssueStatus.backlog => null,
  IssueStatus.doing => c.accent,
  IssueStatus.review => c.warning,
  IssueStatus.done => c.success,
};

/// 터치 화면은 길게 눌러 끈다 — 바로 끌면 가로 스크롤과 겹친다. 폭이 아니라 입력 방식의
/// 차이라 셸의 폭 분기와 무관하다.
bool get _touchFirst => nxTouchFirst;

class BoardColumn extends StatelessWidget {
  const BoardColumn({
    super.key,
    required this.status,
    required this.issues,
    required this.truncated,
    required this.moving,
    required this.spotIndex,
    required this.cardWidth,
    required this.keyFor,
    required this.keysFor,
    required this.onDragStart,
    required this.onDragEnd,
    required this.onHover,
    required this.onDrop,
  });

  final IssueStatus status;
  final List<Issue> issues;
  final bool truncated;
  final Issue? moving;

  /// 이 컬럼에 놓일 자리가 있으면 그 번호(끄는 카드를 뺀 목록 기준).
  final int? spotIndex;
  final double cardWidth;
  final GlobalKey Function(String id) keyFor;
  final (Map<ShortcutActivator, Intent>, Map<Type, Action<Intent>>) Function(
    Issue issue,
  )
  keysFor;
  final ValueChanged<Issue> onDragStart;
  final VoidCallback onDragEnd;
  final VoidCallback onHover;
  final VoidCallback onDrop;

  @override
  Widget build(BuildContext context) {
    final nx = NxTheme.of(context);
    final c = nx.colors;
    final dot = _statusColor(c, status);
    final hovering = spotIndex != null && moving != null;

    // 카드 사이에 놓일 자리(점선)를 끼운다. 끄는 카드 자신은 흐리게 제자리에 남는다.
    final children = <Widget>[];
    var k = 0;
    for (final issue in issues) {
      final isMoving = issue.id == moving?.id;
      if (!isMoving && spotIndex == k) {
        children.add(const _Placeholder(key: ValueKey('spot')));
      }
      children.add(_card(issue, isMoving));
      if (!isMoving) k++;
    }
    if (spotIndex == k) children.add(const _Placeholder(key: ValueKey('spot')));

    return Padding(
      padding: const EdgeInsets.only(right: NxSpacing.sp6),
      child: DragTarget<Issue>(
        onMove: (_) => onHover(),
        onAcceptWithDetails: (_) => onDrop(),
        builder: (context, candidates, _) => AnimatedContainer(
          duration: NxMotion.micro,
          // 끌어 온 카드가 들어갈 컬럼은 옅은 액센트 바탕 + 점선 테두리(캔버스 「보드」).
          padding: const EdgeInsets.all(NxSpacing.sp3),
          decoration: BoxDecoration(
            color: hovering
                ? c.accent.withValues(alpha: NxAlpha.wash)
                : NxColors.transparent,
            borderRadius: BorderRadius.circular(NxRadius.lg),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 28,
                child: Row(
                  children: [
                    const SizedBox(width: NxSpacing.sp2),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: dot,
                        shape: BoxShape.circle,
                        border: dot == null
                            ? Border.all(color: c.textSecondary, width: 1.5)
                            : null,
                      ),
                    ),
                    const SizedBox(width: NxSpacing.sp4),
                    Semantics(
                      header: true,
                      child: Text(
                        issueStatusLabel(status),
                        style: nx.text.sm.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(width: NxSpacing.sp4),
                    Text(
                      // 상한에 걸려 잘렸으면 그렇다고 말한다. 조용히 자르면
                      // 다 봤다고 오해한다.
                      truncated ? '${issues.length}+' : '${issues.length}',
                      style: nx.text.mono.copyWith(fontSize: NxFontSize.xs),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: NxSpacing.sp4),
              Expanded(
                child: issues.isEmpty && !hovering
                    // 빈 컬럼도 자리를 지킨다 — 사라지면 거기로 옮길 수 없다.
                    ? _EmptyColumn(status: status)
                    // **키로 짝을 짓는다**(findChildIndexCallback). 놓일 자리가 끼어들면
                    // 줄 번호가 밀리는데, 번호로 짝을 지으면 끄는 중인 Draggable 의 상태가
                    // 옆 카드로 넘어가 엉뚱한 카드가 흐려졌다(Android 에서 발견).
                    : ListView.builder(
                        itemCount: children.length,
                        findChildIndexCallback: (key) {
                          final i = children.indexWhere((w) => w.key == key);
                          return i < 0 ? null : i;
                        },
                        itemBuilder: (_, i) => Padding(
                          key: children[i].key,
                          padding: EdgeInsets.only(
                            top: i == 0 ? 0 : NxSpacing.sp4,
                          ),
                          child: children[i],
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _card(Issue issue, bool isMoving) {
    final (shortcuts, actions) = keysFor(issue);
    final card = IssueCard(
      key: keyFor(issue.id),
      issue: issue,
      dragging: isMoving,
      shortcuts: shortcuts,
      actions: actions,
    );
    // 끄는 동안 손에 들린 카드 — 한 단 밝은 표면 · 액센트 테두리 · 살짝 기울임(캔버스 「보드」).
    final feedback = SizedBox(
      width: cardWidth,
      child: Transform.rotate(
        angle: -0.026,
        child: IssueCard(issue: issue, dragging: true),
      ),
    );
    final faded = Opacity(opacity: .35, child: card);

    if (_touchFirst) {
      return LongPressDraggable<Issue>(
        key: ValueKey('drag-${issue.id}'),
        data: issue,
        feedback: feedback,
        childWhenDragging: faded,
        onDragStarted: () => onDragStart(issue),
        onDraggableCanceled: (_, _) => onDragEnd(),
        child: isMoving ? faded : card,
      );
    }
    return Draggable<Issue>(
      key: ValueKey('drag-${issue.id}'),
      data: issue,
      feedback: feedback,
      childWhenDragging: faded,
      onDragStarted: () => onDragStart(issue),
      onDraggableCanceled: (_, _) => onDragEnd(),
      child: isMoving ? faded : card,
    );
  }
}

/// 놓일 자리 — 점선 칸(캔버스 「보드」).
class _Placeholder extends StatelessWidget {
  const _Placeholder({super.key});

  @override
  Widget build(BuildContext context) {
    final c = NxTheme.of(context).colors;
    return Semantics(
      label: '여기에 놓입니다',
      child: CustomPaint(
        key: const ValueKey('board-drop-spot'),
        painter: _DashedBox(color: c.accent),
        child: Container(
          height: 64,
          decoration: BoxDecoration(
            color: c.accent.withValues(alpha: NxAlpha.tint),
            borderRadius: BorderRadius.circular(NxRadius.md),
          ),
        ),
      ),
    );
  }
}

class _DashedBox extends CustomPainter {
  _DashedBox({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          (Offset.zero & size).deflate(.75),
          const Radius.circular(NxRadius.md),
        ),
      );
    for (final metric in path.computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += 9) {
        canvas.drawPath(metric.extractPath(d, d + 5), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBox old) => old.color != color;
}

class _EmptyColumn extends StatelessWidget {
  const _EmptyColumn({required this.status});

  final IssueStatus status;

  @override
  Widget build(BuildContext context) {
    final nx = NxTheme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(NxRadius.md),
        border: Border.all(color: nx.colors.divider),
      ),
      child: Center(
        child: Text('${issueStatusLabel(status)} 없음', style: nx.text.secondary),
      ),
    );
  }
}
