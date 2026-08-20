import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../domain/models/issue.dart';
import '../../domain/models/sprint.dart';
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
      spacing: NexusSpacing.sp4,
      runSpacing: NexusSpacing.sp4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _SprintPicker(issue: issue),
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sprints = ref.watch(sprintListProvider).value ?? const <Sprint>[];
    final open = sprints
        .where((s) => s.state != SprintState.closed)
        .toList(growable: false);

    final current = sprints.where((s) => s.id == issue.sprintId).firstOrNull;

    return PopupMenuButton<String?>(
      tooltip: '스프린트',
      // 값이 null 인 항목을 쓰므로 선택 결과를 구분하기 위해 래핑하지 않고
      // '백로그' 를 빈 문자열로 표현한다 — null 은 "취소"와 겹친다.
      itemBuilder: (_) => [
        const PopupMenuItem<String?>(value: '', child: Text('백로그 (스프린트 없음)')),
        for (final sprint in open)
          PopupMenuItem<String?>(
            value: sprint.id,
            child: Text(
              '${sprint.name} · ${sprintStateLabel(sprint.state)}',
            ),
          ),
      ],
      onSelected: (value) async {
        final messenger = ScaffoldMessenger.of(context);
        final spaceId = ref.read(currentSpaceIdProvider);
        if (spaceId == null) return;

        final ok = await ref
            .read(issueRepositoryProvider)
            .setSprint(spaceId, issue, value!.isEmpty ? null : value);

        if (ok) {
          ref.invalidate(currentIssueProvider);
          return;
        }
        messenger.showSnackBar(
          const SnackBar(content: Text('스프린트를 바꾸지 못했습니다. 연결을 확인해 주세요.')),
        );
      },
      child: _Field(
        icon: Icons.flag_outlined,
        label: current?.name ?? '백로그',
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<int>(
      tooltip: '스토리 포인트',
      itemBuilder: (_) => [
        // -1 은 "지우기"다. 안 매기는 것도 뜻이 있어 되돌릴 길을 둔다.
        const PopupMenuItem(value: -1, child: Text('포인트 없음')),
        for (final points in _pointChoices)
          PopupMenuItem(value: points, child: Text('$points')),
      ],
      onSelected: (value) async {
        final messenger = ScaffoldMessenger.of(context);
        final spaceId = ref.read(currentSpaceIdProvider);
        if (spaceId == null) return;

        final ok = await ref
            .read(issueRepositoryProvider)
            .setStoryPoints(spaceId, issue, value < 0 ? null : value);

        if (ok) {
          ref.invalidate(currentIssueProvider);
          return;
        }
        messenger.showSnackBar(
          const SnackBar(content: Text('포인트를 바꾸지 못했습니다. 연결을 확인해 주세요.')),
        );
      },
      child: _Field(
        icon: Icons.timeline_outlined,
        label: issue.storyPoints == null ? '포인트 없음' : '${issue.storyPoints}p',
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: NexusSpacing.sp5,
        vertical: NexusSpacing.sp3,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(NexusRadius.md),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: NexusSpacing.sp3),
          Text(label, style: theme.textTheme.labelMedium),
          const Icon(Icons.arrow_drop_down, size: 16),
        ],
      ),
    );
  }
}
