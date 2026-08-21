import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../domain/models/sprint.dart';
import 'burndown_chart.dart';
import 'sprint_controller.dart';

/// 스프린트 목록과 번다운. 보드 위에 덮어서 연다.
class SprintScreen extends ConsumerStatefulWidget {
  const SprintScreen({super.key, required this.spaceId});

  final String spaceId;

  @override
  ConsumerState<SprintScreen> createState() => _SprintScreenState();
}

class _SprintScreenState extends ConsumerState<SprintScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(sprintActionsProvider).refresh());
  }

  @override
  Widget build(BuildContext context) {
    final sprints = ref.watch(sprintListProvider).value ?? const <Sprint>[];

    return Scaffold(
      appBar: AppBar(
        // 셸 안이라 돌아갈 곳이 스택에 없다. 판에서 바로 오는 화면이다.
        automaticallyImplyLeading: false,
        title: const Text('스프린트'),
        actions: [
          IconButton(
            tooltip: '새 스프린트',
            icon: const Icon(Icons.add),
            onPressed: () => _showCreateSheet(context),
          ),
          IconButton(
            tooltip: '새로고침',
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(sprintActionsProvider).refresh(),
          ),
        ],
      ),
      body: sprints.isEmpty
          ? const Center(child: Text('아직 스프린트가 없습니다.'))
          : ListView.builder(
              padding: const EdgeInsets.all(NexusSpacing.sp5),
              itemCount: sprints.length,
              itemBuilder: (_, i) => _SprintCard(sprint: sprints[i]),
            ),
    );
  }

  Future<void> _showCreateSheet(BuildContext context) =>
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (_) => const _NewSprintSheet(),
      );
}

class _SprintCard extends ConsumerWidget {
  const _SprintCard({required this.sprint});

  final Sprint sprint;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: NexusSpacing.sp5),
      child: Padding(
        padding: const EdgeInsets.all(NexusSpacing.sp6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(sprint.name, style: theme.textTheme.titleSmall),
                ),
                _StateChip(state: sprint.state),
                _SprintMenu(sprint: sprint),
              ],
            ),
            if (sprint.goal != null && sprint.goal!.isNotEmpty) ...[
              const SizedBox(height: NexusSpacing.sp3),
              Text(sprint.goal!, style: theme.textTheme.bodySmall),
            ],
            const SizedBox(height: NexusSpacing.sp3),
            Text(_periodLabel(sprint), style: theme.textTheme.labelSmall),
            const SizedBox(height: NexusSpacing.sp5),
            _Burndown(sprint: sprint),
          ],
        ),
      ),
    );
  }

  /// 기간이 없으면 번다운을 그릴 수 없다. 그 사실을 여기서 미리 말한다.
  String _periodLabel(Sprint sprint) {
    final start = sprint.startsAt;
    final end = sprint.endsAt;
    if (start == null || end == null) return '기간 미정';
    String fmt(DateTime d) =>
        '${d.year}.${d.month.toString().padLeft(2, '0')}.'
        '${d.day.toString().padLeft(2, '0')}';
    return '${fmt(start.toLocal())} — ${fmt(end.toLocal())}';
  }
}

class _Burndown extends ConsumerStatefulWidget {
  const _Burndown({required this.sprint});

  final Sprint sprint;

  @override
  ConsumerState<_Burndown> createState() => _BurndownState();
}

class _BurndownState extends ConsumerState<_Burndown> {
  BurndownSeries _series = BurndownSeries.points;

  @override
  Widget build(BuildContext context) {
    if (widget.sprint.startsAt == null || widget.sprint.endsAt == null) {
      return Text(
        '기간을 정하면 번다운이 그려집니다.',
        style: Theme.of(context).textTheme.bodySmall,
      );
    }

    final burndown = ref.watch(burndownProvider(widget.sprint.id));

    return burndown.when(
      loading: () => const SizedBox(
        height: 180,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, _) => const SizedBox(
        height: 180,
        child: Center(child: Text('번다운을 불러오지 못했습니다.')),
      ),
      data: (data) => data == null
          ? const SizedBox(
              height: 180,
              child: Center(child: Text('번다운을 불러오지 못했습니다.')),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const BurndownLegend(),
                    const Spacer(),
                    // 포인트를 안 매기면 포인트 계열이 평평하다. 개수로
                    // 바꿔 볼 수 있어야 그때도 읽힌다.
                    SegmentedButton<BurndownSeries>(
                      style: const ButtonStyle(visualDensity: VisualDensity.compact),
                      segments: const [
                        ButtonSegment(
                          value: BurndownSeries.points,
                          label: Text('포인트'),
                        ),
                        ButtonSegment(
                          value: BurndownSeries.count,
                          label: Text('개수'),
                        ),
                      ],
                      selected: {_series},
                      onSelectionChanged: (v) =>
                          setState(() => _series = v.first),
                    ),
                  ],
                ),
                const SizedBox(height: NexusSpacing.sp4),
                BurndownChart(burndown: data, series: _series),
              ],
            ),
    );
  }
}

class _StateChip extends StatelessWidget {
  const _StateChip({required this.state});

  final SprintState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = switch (state) {
      SprintState.active => NexusColors.success,
      SprintState.planned => NexusColors.warning,
      SprintState.closed => theme.dividerColor,
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: NexusSpacing.sp4,
        vertical: NexusSpacing.sp2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(NexusRadius.sm),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        sprintStateLabel(state),
        style: theme.textTheme.labelSmall?.copyWith(color: color),
      ),
    );
  }
}

/// **상태는 한 방향이다.** 갈 수 없는 곳은 메뉴에 넣지 않는다 — 눌러 봐야
/// 실패하는 항목은 없느니만 못하다(7-5 와 같은 판단).
class _SprintMenu extends ConsumerWidget {
  const _SprintMenu({required this.sprint});

  final Sprint sprint;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<String>(
      tooltip: '스프린트',
      icon: const Icon(Icons.more_horiz, size: 18),
      itemBuilder: (_) => [
        if (sprint.state == SprintState.planned)
          const PopupMenuItem(value: 'start', child: Text('시작하기')),
        if (sprint.state == SprintState.active)
          const PopupMenuItem(value: 'close', child: Text('끝내기')),
        const PopupMenuItem(value: 'delete', child: Text('지우기')),
      ],
      onSelected: (action) async {
        final messenger = ScaffoldMessenger.of(context);
        final actions = ref.read(sprintActionsProvider);

        final ok = switch (action) {
          'start' => await actions.setState(sprint.id, SprintState.active),
          'close' => await actions.setState(sprint.id, SprintState.closed),
          _ => await actions.remove(sprint.id),
        };
        if (ok) return;

        messenger.showSnackBar(
          SnackBar(
            content: Text(
              action == 'start'
                  // 서버가 409 를 주는 유일한 경우다. 그 뜻을 그대로 말한다.
                  ? '이미 진행 중인 스프린트가 있습니다.'
                  : '바꾸지 못했습니다. 연결을 확인해 주세요.',
            ),
          ),
        );
      },
    );
  }
}

class _NewSprintSheet extends ConsumerStatefulWidget {
  const _NewSprintSheet();

  @override
  ConsumerState<_NewSprintSheet> createState() => _NewSprintSheetState();
}

class _NewSprintSheetState extends ConsumerState<_NewSprintSheet> {
  final _name = TextEditingController();
  final _goal = TextEditingController();
  DateTimeRange? _period;
  bool _sending = false;

  @override
  void dispose() {
    _name.dispose();
    _goal.dispose();
    super.dispose();
  }

  Future<void> _pickPeriod() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
      initialDateRange:
          _period ?? DateTimeRange(start: now, end: now.add(const Duration(days: 13))),
    );
    if (picked != null) setState(() => _period = picked);
  }

  Future<void> _submit() async {
    final name = _name.text.trim();
    if (name.isEmpty || _sending) return;

    setState(() => _sending = true);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final ok = await ref
        .read(sprintActionsProvider)
        .create(
          name: name,
          goal: _goal.text.trim(),
          startsAt: _period?.start,
          endsAt: _period?.end,
        );

    if (!mounted) return;
    if (ok) {
      navigator.pop();
      return;
    }
    setState(() => _sending = false);
    messenger.showSnackBar(
      const SnackBar(content: Text('만들지 못했습니다. 연결을 확인해 주세요.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: NexusSpacing.sp6,
        right: NexusSpacing.sp6,
        top: NexusSpacing.sp6,
        bottom: MediaQuery.viewInsetsOf(context).bottom + NexusSpacing.sp6,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('새 스프린트', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: NexusSpacing.sp5),
          TextField(
            controller: _name,
            autofocus: true,
            decoration: const InputDecoration(labelText: '이름'),
          ),
          const SizedBox(height: NexusSpacing.sp5),
          TextField(
            controller: _goal,
            decoration: const InputDecoration(labelText: '목표 (선택)'),
          ),
          const SizedBox(height: NexusSpacing.sp5),
          // 기간은 비워 둘 수 있다 — 계획 단계에서는 아직 정해지지 않는다.
          // 다만 없으면 번다운을 그릴 수 없으므로 그 사실을 적어 둔다.
          OutlinedButton.icon(
            icon: const Icon(Icons.date_range_outlined, size: 18),
            label: Text(
              _period == null
                  ? '기간 정하기 (없으면 번다운을 그릴 수 없습니다)'
                  : '${_period!.start.month}/${_period!.start.day}'
                        ' — ${_period!.end.month}/${_period!.end.day}',
            ),
            onPressed: _pickPeriod,
          ),
          const SizedBox(height: NexusSpacing.sp6),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              onPressed: _sending ? null : _submit,
              child: Text(_sending ? '만드는 중…' : '만들기'),
            ),
          ),
        ],
      ),
    );
  }
}
