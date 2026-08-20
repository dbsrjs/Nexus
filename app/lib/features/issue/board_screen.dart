import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../domain/models/issue.dart';
import 'board_controller.dart';
import 'issue_card.dart';
import 'new_issue_sheet.dart';

/// 칸반 보드. 파일 목록과 같이 **셸 위에 덮어서** 연다.
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
    Future.microtask(() => ref.read(boardActionsProvider).refresh());
  }

  @override
  Widget build(BuildContext context) {
    final board = ref.watch(boardProvider);
    final truncated = ref.watch(truncatedColumnsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('보드'),
        actions: [
          // FAB 과 같은 일을 한다. 떠 있는 버튼은 창 크기나 겹친 창에 따라
          // 화면 밖으로 밀릴 수 있어, 언제나 닿는 자리에도 둔다.
          IconButton(
            tooltip: '새 이슈',
            icon: const Icon(Icons.add),
            onPressed: () => showNewIssueSheet(context),
          ),
          IconButton(
            tooltip: '새로고침',
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(boardActionsProvider).refresh(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showNewIssueSheet(context),
        icon: const Icon(Icons.add),
        label: const Text('새 이슈'),
      ),
      body: SafeArea(
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
    );
  }
}

/// 보드 바깥 여백. 컬럼 폭 계산이 이 값을 빼야 하므로 상수로 묶어 둔다 —
/// 둘이 갈라지면 마지막 컬럼이 잘린다.
const double _boardPadding = NexusSpacing.sp5;

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
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(right: NexusSpacing.sp5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: NexusSpacing.sp4),
            child: Row(
              children: [
                Text(issueStatusLabel(status), style: theme.textTheme.titleSmall),
                const SizedBox(width: NexusSpacing.sp3),
                Text(
                  // 상한에 걸려 잘렸으면 그렇다고 말한다. 조용히 자르면
                  // 다 봤다고 오해한다.
                  truncated ? '${issues.length}+' : '${issues.length}',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.textTheme.bodySmall?.color,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: issues.isEmpty
                // 빈 컬럼도 자리를 지킨다 — 사라지면 거기로 옮길 수 없다.
                ? _EmptyColumn(status: status)
                : ListView.builder(
                    itemCount: issues.length,
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
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(NexusRadius.md),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Center(
        child: Text(
          '${issueStatusLabel(status)} 없음',
          style: theme.textTheme.bodySmall,
        ),
      ),
    );
  }
}
