import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/models/issue.dart';
import '../../shared/widgets/user_avatar.dart';
import '../../ui/ui.dart';
import '../space/space_controller.dart';
import 'board_controller.dart';
import 'label_widgets.dart';
import 'priority_mark.dart';

/// 칸반 카드 한 장(캔버스 「보드」). 제목이 먼저, 아래 한 줄에 키 · 우선순위 · 담당 · 포인트.
///
/// 상태 이동은 **메뉴**로도 한다 — 끌어 옮기기(D15)가 닿지 않는 보조 기술 · 키보드의 길이다.
class IssueCard extends ConsumerWidget {
  const IssueCard({
    super.key,
    required this.issue,
    this.dragging = false,
    this.shortcuts,
    this.actions,
  });

  final Issue issue;

  /// 끌고 있는(또는 키보드로 집은) 카드 — 한 단 밝은 표면 + 액센트 테두리(그림자 대신,
  /// 캔버스 「보드」).
  final bool dragging;

  /// 보드가 주는 키 — Space 로 집고 방향키로 옮긴다(D15).
  final Map<ShortcutActivator, Intent>? shortcuts;
  final Map<Type, Action<Intent>>? actions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nx = NxTheme.of(context);
    final c = nx.colors;
    final assignee = issue.assignee;

    return NxHoverSurface(
      onPressed: () => context.push(
        '/s/${ref.read(currentSpaceIdProvider)}/issues/${issue.key}',
      ),
      semanticLabel: '${issue.key} ${issue.title}',
      shortcuts: shortcuts,
      actions: actions,
      padding: const EdgeInsets.fromLTRB(
        NxSpacing.sp5,
        NxSpacing.sp5,
        NxSpacing.sp3,
        NxSpacing.inset,
      ),
      base: dragging ? c.bgElevated : c.bgSurface,
      border: (_) =>
          Border.all(color: dragging ? c.accent : NxColors.transparent),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: NxSpacing.sp1),
                  child: Text(
                    issue.title,
                    style: nx.text.base.copyWith(height: 1.45),
                  ),
                ),
              ),
              _MoveMenu(issue: issue),
            ],
          ),
          if (issue.labels.isNotEmpty) ...[
            const SizedBox(height: NxSpacing.sp4),
            Wrap(
              spacing: NxSpacing.sp3,
              runSpacing: NxSpacing.sp3,
              children: [
                for (final label in issue.labels)
                  LabelChip(label: label, dense: true),
              ],
            ),
          ],
          const SizedBox(height: NxSpacing.sp5),
          Padding(
            padding: const EdgeInsets.only(right: NxSpacing.sp3),
            child: Row(
              children: [
                Text(issue.key, style: nx.text.mono),
                const SizedBox(width: NxSpacing.sp4),
                IssuePriorityTag(priority: issue.priority),
                const Spacer(),
                if (issue.storyPoints != null) ...[
                  Text('${issue.storyPoints}p', style: nx.text.mono),
                  if (assignee != null) const SizedBox(width: NxSpacing.sp4),
                ],
                if (assignee != null)
                  NxTooltip(
                    message: '담당 ${assignee.name}',
                    child: UserAvatar(
                      userId: assignee.id,
                      name: assignee.name,
                      avatarUrl: assignee.avatarUrl,
                      size: 20,
                    ),
                  ),
              ],
            ),
          ),
        ],
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

    Future<void> move(IssueStatus status) async {
      final ok = await ref.read(boardActionsProvider).moveTo(issue, status);
      if (ok || !context.mounted) return;
      // 카드는 이미 제자리로 돌아가 있다(리포지토리가 되돌린다).
      NxToast.show(context, '옮기지 못했습니다. 연결을 확인해 주세요.', kind: NxToastKind.error);
    }

    return NxMenu(
      width: 180,
      entries: [
        for (final status in others)
          NxMenuItem(
            '${issueStatusLabel(status)}(으)로',
            onSelected: () => move(status),
          ),
      ],
      anchorBuilder: (context, toggle) => NxIconButton(
        icon: NxIcons.more,
        label: '${issue.key} 옮기기',
        size: NxSize.sm,
        onPressed: toggle,
      ),
    );
  }
}
