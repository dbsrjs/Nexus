import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../domain/models/issue.dart';
import '../../shared/widgets/nexus_avatar.dart';
import 'package:go_router/go_router.dart';

import '../space/space_controller.dart';
import 'board_controller.dart';
import 'label_widgets.dart';

/// 칸반 카드 한 장.
///
/// 상태 이동은 **메뉴**로 한다(9-1). 드래그는 서버 계약(`PUT .../position`)이
/// 이미 서 있으므로 나중에 화면만 바꾸면 된다 — 좁은 폭에서 가로 스크롤과
/// 드래그 제스처가 겹치는 문제를 푸느라 보드를 보는 일이 밀리는 것을 피했다.
class IssueCard extends ConsumerWidget {
  const IssueCard({super.key, required this.issue});

  final Issue issue;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final assignee = issue.assignee;

    return Card(
      margin: const EdgeInsets.only(bottom: NexusSpacing.sp4),
      child: InkWell(
        borderRadius: BorderRadius.circular(NexusRadius.md),
        onTap: () => context.push(
          '/s/${ref.read(currentSpaceIdProvider)}/issues/${issue.key}',
        ),
        child: Padding(
          padding: const EdgeInsets.all(NexusSpacing.sp5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    issue.key,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.textTheme.bodySmall?.color,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  const Spacer(),
                  _PriorityDot(priority: issue.priority),
                  _MoveMenu(issue: issue),
                ],
              ),
              const SizedBox(height: NexusSpacing.sp2),
              Text(issue.title, style: theme.textTheme.bodyMedium),
              if (issue.labels.isNotEmpty) ...[
                const SizedBox(height: NexusSpacing.sp4),
                Wrap(
                  spacing: NexusSpacing.sp3,
                  runSpacing: NexusSpacing.sp3,
                  children: [
                    for (final label in issue.labels)
                      LabelChip(label: label, dense: true),
                  ],
                ),
              ],
              if (assignee != null || issue.storyPoints != null) ...[
                const SizedBox(height: NexusSpacing.sp5),
                Row(
                  children: [
                    if (assignee != null) ...[
                      NexusAvatar(
                        seed: assignee.id,
                        label: assignee.name,
                        size: 20,
                      ),
                      const SizedBox(width: NexusSpacing.sp3),
                      Flexible(
                        child: Text(
                          assignee.name,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                    ],
                    const Spacer(),
                    if (issue.storyPoints != null)
                      Text(
                        '${issue.storyPoints}p',
                        style: theme.textTheme.labelSmall,
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// 우선순위는 점 하나로 보인다. 카드가 작아 글자를 넣을 자리가 없다.
class _PriorityDot extends StatelessWidget {
  const _PriorityDot({required this.priority});

  final IssuePriority priority;

  @override
  Widget build(BuildContext context) {
    final color = switch (priority) {
      IssuePriority.high => NexusColors.danger,
      IssuePriority.mid => NexusColors.warning,
      IssuePriority.low => NexusColors.success,
    };

    return Tooltip(
      message: '우선순위 ${issuePriorityLabel(priority)}',
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }
}

/// **지금 컬럼은 목록에서 뺀다.** 눌러 봐야 아무 일도 없는 항목은
/// 없느니만 못하다 — 7-5 에서 답글에 핀 항목을 감춘 것과 같은 판단이다.
class _MoveMenu extends ConsumerWidget {
  const _MoveMenu({required this.issue});

  final Issue issue;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final others = IssueStatus.values
        .where((s) => s != issue.status)
        .toList(growable: false);

    return PopupMenuButton<IssueStatus>(
      tooltip: '옮기기',
      icon: const Icon(Icons.more_horiz, size: 18),
      padding: EdgeInsets.zero,
      itemBuilder: (_) => [
        for (final status in others)
          PopupMenuItem(
            value: status,
            child: Text('${issueStatusLabel(status)}(으)로'),
          ),
      ],
      onSelected: (status) async {
        final messenger = ScaffoldMessenger.of(context);
        final ok = await ref.read(boardActionsProvider).moveTo(issue, status);
        if (ok) return;
        // 카드는 이미 제자리로 돌아가 있다(리포지토리가 되돌린다).
        messenger.showSnackBar(
          const SnackBar(content: Text('옮기지 못했습니다. 연결을 확인해 주세요.')),
        );
      },
    );
  }
}
