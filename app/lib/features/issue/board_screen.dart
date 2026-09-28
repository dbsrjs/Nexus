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
class BoardScreen extends ConsumerStatefulWidget {
  const BoardScreen({super.key, required this.spaceId});

  final String spaceId;

  @override
  ConsumerState<BoardScreen> createState() => _BoardScreenState();
}

class _BoardScreenState extends ConsumerState<BoardScreen> {
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

  @override
  Widget build(BuildContext context) {
    final board = ref.watch(scopedBoardProvider);
    final truncated = ref.watch(truncatedColumnsProvider);

    return NxPage(
      header: ShellHeader(
        title: '보드',
        actions: [
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
      body: Column(
        children: [
          const _ScopeBar(),
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
                    : (usable / IssueStatus.values.length).clamp(240.0, 360.0);

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
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
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

class _BoardColumn extends StatelessWidget {
  const _BoardColumn({
    required this.status,
    required this.issues,
    required this.truncated,
  });

  final IssueStatus status;
  final List<Issue> issues;
  final bool truncated;

  @override
  Widget build(BuildContext context) {
    final nx = NxTheme.of(context);
    final c = nx.colors;
    final dot = _statusColor(c, status);

    return Padding(
      padding: const EdgeInsets.only(right: NxSpacing.sp6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 28,
            child: Row(
              children: [
                const SizedBox(width: 4),
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
                  style: nx.text.mono.copyWith(fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: NxSpacing.sp4),
          Expanded(
            child: issues.isEmpty
                // 빈 컬럼도 자리를 지킨다 — 사라지면 거기로 옮길 수 없다.
                ? _EmptyColumn(status: status)
                : ListView.separated(
                    itemCount: issues.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: NxSpacing.sp4),
                    itemBuilder: (_, i) => IssueCard(issue: issues[i]),
                  ),
          ),
        ],
      ),
    );
  }
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
        child: Text(
          '${issueStatusLabel(status)} 없음',
          style: nx.text.secondary,
        ),
      ),
    );
  }
}
