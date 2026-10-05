import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/issue.dart';
import '../../domain/models/sprint.dart';
import '../../ui/ui.dart';
import '../space/space_controller.dart';
import 'board_controller.dart';
import 'issue_detail_controller.dart';
import 'sprint_controller.dart';

/// 이슈 상세의 **계획 줄** — 스프린트와 스토리 포인트.
///
/// 이 둘이 없으면 번다운이 언제나 비어 있다. 서버 API 는 9-3 에서 다 만들어
/// 두고 화면만 빠져 있었다.
class IssuePlanningRow extends ConsumerWidget {
  const IssuePlanningRow({super.key, required this.issue});

  final Issue issue;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Wrap(
      spacing: NxSpacing.sp4,
      runSpacing: NxSpacing.sp4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (ref.watch(sprintsEnabledProvider)) _SprintPicker(issue: issue),
        _StoryPointsPicker(issue: issue),
      ],
    );
  }
}

/// **닫힌 스프린트는 고를 수 없다.** 이미 끝난 기간에 새 일을 넣으면 그
/// 스프린트의 번다운이 뒤늦게 바뀐다 — 지난 기록이 흔들리면 안 된다.
class _SprintPicker extends ConsumerWidget {
  const _SprintPicker({required this.issue});

  final Issue issue;

  Future<void> _set(
    BuildContext context,
    WidgetRef ref,
    String? sprintId,
  ) async {
    final spaceId = ref.read(currentSpaceIdProvider);
    if (spaceId == null) return;
    final ok = await ref
        .read(issueRepositoryProvider)
        .setSprint(spaceId, issue, sprintId);
    if (ok) {
      ref.invalidate(currentIssueProvider);
      return;
    }
    if (context.mounted) {
      NxToast.show(
        context,
        '스프린트를 바꾸지 못했습니다. 연결을 확인해 주세요.',
        kind: NxToastKind.error,
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sprints = ref.watch(sprintListProvider).value ?? const <Sprint>[];
    final open = sprints
        .where((s) => s.state != SprintState.closed)
        .toList(growable: false);
    final current = sprints.where((s) => s.id == issue.sprintId).firstOrNull;

    return NxMenu(
      width: 240,
      entries: [
        NxMenuItem(
          '백로그 (스프린트 없음)',
          selected: issue.sprintId == null,
          onSelected: () => _set(context, ref, null),
        ),
        for (final sprint in open)
          NxMenuItem(
            '${sprint.name} · ${sprintStateLabel(sprint.state)}',
            selected: sprint.id == issue.sprintId,
            onSelected: () => _set(context, ref, sprint.id),
          ),
      ],
      anchorBuilder: (context, toggle) => _Field(
        caption: '스프린트',
        value: current?.name ?? '백로그',
        onPressed: toggle,
      ),
    );
  }
}

/// 피보나치 수열을 쓴다. 큰 일일수록 추정이 거칠어지는 것을 눈금이 말해 준다 —
/// 7과 8을 나누는 것은 정확이 아니라 착각이다.
const _pointChoices = [1, 2, 3, 5, 8, 13];

class _StoryPointsPicker extends ConsumerWidget {
  const _StoryPointsPicker({required this.issue});

  final Issue issue;

  Future<void> _set(BuildContext context, WidgetRef ref, int? points) async {
    final spaceId = ref.read(currentSpaceIdProvider);
    if (spaceId == null) return;
    final ok = await ref
        .read(issueRepositoryProvider)
        .setStoryPoints(spaceId, issue, points);
    if (ok) {
      ref.invalidate(currentIssueProvider);
      return;
    }
    if (context.mounted) {
      NxToast.show(
        context,
        '포인트를 바꾸지 못했습니다. 연결을 확인해 주세요.',
        kind: NxToastKind.error,
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return NxMenu(
      width: 160,
      entries: [
        // 안 매기는 것도 뜻이 있어 되돌릴 길을 둔다.
        NxMenuItem(
          '포인트 없음',
          selected: issue.storyPoints == null,
          onSelected: () => _set(context, ref, null),
        ),
        for (final points in _pointChoices)
          NxMenuItem(
            '$points',
            selected: issue.storyPoints == points,
            onSelected: () => _set(context, ref, points),
          ),
      ],
      anchorBuilder: (context, toggle) => _Field(
        caption: '포인트',
        value: issue.storyPoints == null ? '포인트 없음' : '${issue.storyPoints}p',
        onPressed: toggle,
      ),
    );
  }
}

/// 고르는 칸 — 작은 이름표 + 지금 값 + ▾. 앞 장식 아이콘 대신 이름표가 무엇을 고르는지 말한다.
class _Field extends StatelessWidget {
  const _Field({
    required this.caption,
    required this.value,
    required this.onPressed,
  });

  final String caption;
  final String value;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final nx = NxTheme.of(context);
    final c = nx.colors;
    return NxPressable(
      onPressed: onPressed,
      semanticLabel: '$caption $value',
      excludeChildSemantics: true,
      builder: (context, s) => AnimatedContainer(
        duration: NxMotion.micro,
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: NxSpacing.inset),
        decoration: BoxDecoration(
          color: s.hovered ? c.bgElevated : NxColors.transparent,
          borderRadius: BorderRadius.circular(NxRadius.md),
          border: Border.all(color: s.hovered ? c.borderStrong : c.divider),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(caption, style: nx.text.meta),
            const SizedBox(width: NxSpacing.sp3),
            Text(value, style: nx.text.sm),
            const SizedBox(width: NxSpacing.sp3),
            NxIcon(
              NxIcons.chevronDown,
              size: NxIconSize.xs,
              color: c.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
