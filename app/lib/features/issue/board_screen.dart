import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../shell/app_shell.dart';
import '../../domain/models/issue.dart';
import '../../ui/ui.dart';
import 'board_controller.dart';
import 'issue_card.dart';
import 'new_issue_sheet.dart';
import 'sprint_controller.dart';

/// 칸반 보드. 셸 안에 머무는 화면이다.
///
/// 열 넷을 가로 스크롤로 그린다. 폭에 따라 달라지는 것은 열 너비뿐이고
/// **분기가 아니라 제약이다** — 반응형 분기는 `app_shell.dart` 한 곳에서만 한다.
///
/// **끌어 옮긴다**(15단계 D15, 캔버스 「보드」). 마우스는 바로 끌고, 터치는 길게 눌러
/// 끈다 — 가로 스크롤과 겹치지 않게. 키보드는 카드에서 Space 로 집고 방향키로 옮긴 뒤
/// Space · Enter 로 놓고 Esc 로 취소한다. 놓일 자리는 점선 칸이 미리 보인다.
class BoardScreen extends ConsumerStatefulWidget {
  const BoardScreen({super.key, required this.spaceId});

  final String spaceId;

  @override
  ConsumerState<BoardScreen> createState() => _BoardScreenState();
}

/// 놓일 자리 — 컬럼과, 그 컬럼에서 **끄는 카드를 뺀** 목록의 몇 번째 앞인지.
typedef _Spot = ({IssueStatus status, int index});

class _BoardScreenState extends ConsumerState<BoardScreen> {
  /// 끄는(또는 키보드로 집은) 카드.
  Issue? _moving;
  _Spot? _spot;

  /// 끄는 동안의 손가락 · 마우스 위치. 놓일 자리를 카드 가운데와 견주어 정한다.
  Offset? _pointer;

  final _cardKeys = <String, GlobalKey>{};

  GlobalKey _keyFor(String id) => _cardKeys.putIfAbsent(id, GlobalKey.new);

  @override
  void initState() {
    super.initState();
    // 캐시가 먼저 그려지고 서버 값이 뒤따른다. 오프라인이면 캐시가 그대로 남는다.
    Future.microtask(() {
      ref.read(boardActionsProvider).refresh();
      // 필터가 쓰는 값이라 함께 받는다.
      ref.read(sprintActionsProvider).refresh();
    });
  }

  List<Issue> _column(IssueStatus status) =>
      ref.read(scopedBoardProvider)[status] ?? const [];

  /// 끄는 카드를 뺀 목록에서 그 카드가 지금 선 자리.
  int _originIndex(Issue issue) {
    final column = _column(issue.status);
    final at = column.indexWhere((i) => i.id == issue.id);
    return at < 0 ? 0 : at;
  }

  void _start(Issue issue) => setState(() {
    _moving = issue;
    _spot = (status: issue.status, index: _originIndex(issue));
  });

  void _cancel() => setState(() {
    _moving = null;
    _spot = null;
  });

  /// 손가락 위치를 그 컬럼 카드들의 가운데와 견주어 몇 번째 앞인지 정한다.
  void _hover(IssueStatus status) {
    final moving = _moving;
    final pointer = _pointer;
    if (moving == null || pointer == null) return;
    final others = [
      for (final issue in _column(status))
        if (issue.id != moving.id) issue,
    ];
    var index = others.length;
    for (var i = 0; i < others.length; i++) {
      final box =
          _cardKeys[others[i].id]?.currentContext?.findRenderObject()
              as RenderBox?;
      if (box == null || !box.hasSize) continue;
      final middle = box.localToGlobal(box.size.center(Offset.zero)).dy;
      if (pointer.dy < middle) {
        index = i;
        break;
      }
    }
    final next = (status: status, index: index);
    if (next != _spot) setState(() => _spot = next);
  }

  Future<void> _drop() async {
    final moving = _moving;
    final spot = _spot;
    _cancel();
    if (moving == null || spot == null) return;

    // 제자리에 도로 놓았으면 아무것도 하지 않는다.
    if (spot.status == moving.status && spot.index == _originIndex(moving)) {
      return;
    }
    final at = dropNeighbours(_column(spot.status), moving.id, spot.index);
    final ok = await ref
        .read(boardActionsProvider)
        .place(moving, spot.status, after: at.after, before: at.before);
    if (ok || !mounted) return;
    // 카드는 이미 제자리로 돌아가 있다(리포지토리가 되돌린다).
    NxToast.show(context, '옮기지 못했습니다. 연결을 확인해 주세요.', kind: NxToastKind.error);
  }

  /// 키보드로 집은 카드를 옮긴다. 위아래는 같은 컬럼 안, 좌우는 옆 컬럼으로.
  void _step(int dx, int dy) {
    final moving = _moving;
    final spot = _spot;
    if (moving == null || spot == null) return;
    final statuses = IssueStatus.values;
    final col = (statuses.indexOf(spot.status) + dx).clamp(
      0,
      statuses.length - 1,
    );
    final status = statuses[col];
    final size = _column(status).where((i) => i.id != moving.id).length;
    setState(() {
      _spot = (status: status, index: (spot.index + dy).clamp(0, size));
    });
  }

  /// 카드에 주는 키. 집기 전에는 Space 가 「집기」, 집은 뒤에는 방향키 · 놓기 · 취소.
  (Map<ShortcutActivator, Intent>, Map<Type, Action<Intent>>) _keysFor(
    Issue issue,
  ) {
    final grabbed = _moving?.id == issue.id;
    if (!grabbed) {
      return (
        const {SingleActivator(LogicalKeyboardKey.space): _GrabIntent()},
        {
          _GrabIntent: CallbackAction<_GrabIntent>(
            onInvoke: (_) {
              _start(issue);
              return null;
            },
          ),
        },
      );
    }
    return (
      const {
        SingleActivator(LogicalKeyboardKey.space): _DropIntent(),
        SingleActivator(LogicalKeyboardKey.enter): _DropIntent(),
        SingleActivator(LogicalKeyboardKey.escape): _CancelIntent(),
        SingleActivator(LogicalKeyboardKey.arrowUp): _StepIntent(0, -1),
        SingleActivator(LogicalKeyboardKey.arrowDown): _StepIntent(0, 1),
        SingleActivator(LogicalKeyboardKey.arrowLeft): _StepIntent(-1, 0),
        SingleActivator(LogicalKeyboardKey.arrowRight): _StepIntent(1, 0),
      },
      {
        _DropIntent: CallbackAction<_DropIntent>(
          onInvoke: (_) {
            _drop();
            return null;
          },
        ),
        _CancelIntent: CallbackAction<_CancelIntent>(
          onInvoke: (_) {
            _cancel();
            return null;
          },
        ),
        _StepIntent: CallbackAction<_StepIntent>(
          onInvoke: (i) {
            _step(i.dx, i.dy);
            return null;
          },
        ),
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final board = ref.watch(scopedBoardProvider);
    final truncated = ref.watch(truncatedColumnsProvider);

    return NxPage(
      header: ShellHeader(
        title: '보드',
        actions: [
          if (ref.watch(sprintsEnabledProvider))
            NxButton(
              label: '스프린트',
              kind: NxButtonKind.ghost,
              size: NxSize.sm,
              onPressed: () => context.go('/s/${widget.spaceId}/sprints'),
            ),
          NxIconButton(
            icon: NxIcons.refresh,
            label: '새로고침',
            onPressed: () => ref.read(boardActionsProvider).refresh(),
          ),
          // 떠 있는 버튼(FAB)을 두지 않는다 — 머리 줄이 언제나 닿는 자리다(캔버스 「보드」).
          NxButton(
            label: '새 이슈',
            icon: NxIcons.plus,
            size: NxSize.sm,
            onPressed: () => showNewIssueSheet(context),
          ),
        ],
      ),
      body: Listener(
        // 끄는 동안 위치를 따라간다 — 놓일 자리를 정하는 기준이다.
        onPointerMove: (e) => _pointer = e.position,
        child: Column(
          children: [
            if (ref.watch(sprintsEnabledProvider)) const _ScopeBar(),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // 좁으면 한 열이 화면의 대부분을 쓰고, 넓으면 넷이 한눈에 들어온다.
                  //
                  // **리스트 좌우 패딩을 먼저 뺀다.** 빼지 않으면 네 컬럼의 합이
                  // 화면보다 딱 그만큼 넓어져, 폭이 충분한데도 마지막 컬럼이
                  // 잘린 채 가로 스크롤이 생긴다.
                  final usable = constraints.maxWidth - _boardPadding * 2;
                  final columnWidth = constraints.maxWidth < 720
                      ? usable * 0.85
                      : (usable / IssueStatus.values.length).clamp(
                          240.0,
                          360.0,
                        );

                  return ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.all(_boardPadding),
                    children: [
                      for (final status in IssueStatus.values)
                        SizedBox(
                          width: columnWidth,
                          child: _BoardColumn(
                            status: status,
                            issues: board[status] ?? const [],
                            truncated: truncated.contains(status),
                            moving: _moving,
                            spotIndex: _spot?.status == status
                                ? _spot!.index
                                : null,
                            cardWidth: columnWidth - NxSpacing.sp6,
                            keyFor: _keyFor,
                            keysFor: _keysFor,
                            onDragStart: _start,
                            onDragEnd: _cancel,
                            onHover: () => _hover(status),
                            onDrop: _drop,
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GrabIntent extends Intent {
  const _GrabIntent();
}

class _DropIntent extends Intent {
  const _DropIntent();
}

class _CancelIntent extends Intent {
  const _CancelIntent();
}

class _StepIntent extends Intent {
  const _StepIntent(this.dx, this.dy);
  final int dx;
  final int dy;
}

/// 무엇을 보여 줄지 고르는 줄.
///
/// **백로그는 별도 목록이 아니라 필터다** — `sprintId` 가 비어 있는 이슈의
/// 집합이 곧 백로그이기 때문이다. 거르는 일은 캐시 위에서 한다: 서버를 한 번
/// 더 부르면 오프라인에서 필터가 동작하지 않는다.
class _ScopeBar extends ConsumerWidget {
  const _ScopeBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scope = ref.watch(boardScopeProvider);
    final active = ref.watch(activeSprintProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        _boardPadding,
        _boardPadding,
        _boardPadding,
        0,
      ),
      child: Row(
        children: [
          NxSegmented<BoardScope>(
            label: '보기',
            expand: false,
            value: scope,
            segments: [
              for (final value in BoardScope.values)
                (value, boardScopeLabel(value)),
            ],
            onChanged: (v) => ref.read(boardScopeProvider.notifier).set(v),
          ),
          const SizedBox(width: NxSpacing.sp5),
          // 도는 스프린트가 없으면 '이번 스프린트'가 빈 보드가 된다.
          // 왜 비었는지 여기서 말해 준다.
          Expanded(
            child: Text(
              active == null ? '진행 중인 스프린트 없음' : active.name,
              overflow: TextOverflow.ellipsis,
              style: NxTheme.of(context).text.secondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// 보드 바깥 여백. 컬럼 폭 계산이 이 값을 빼야 하므로 상수로 묶어 둔다 —
/// 둘이 갈라지면 마지막 컬럼이 잘린다.
const double _boardPadding = NxSpacing.sp6;

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

class _BoardColumn extends StatelessWidget {
  const _BoardColumn({
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
