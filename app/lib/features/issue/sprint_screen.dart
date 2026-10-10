import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../shell/app_shell.dart';
import '../../shared/josa.dart';
import '../../domain/models/sprint.dart';
import '../../ui/ui.dart';
import 'burndown_chart.dart';
import 'sprint_controller.dart';

/// 스프린트 목록과 번다운. 셸 안에 머무는 화면이다.
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

    return NxPage(
      header: ShellHeader(
        title: '스프린트',
        actions: [
          NxIconButton(
            icon: NxIcons.refresh,
            label: '새로고침',
            onPressed: () => ref.read(sprintActionsProvider).refresh(),
          ),
          NxButton(
            label: '새 스프린트',
            icon: NxIcons.plus,
            size: NxSize.sm,
            onPressed: () => NxDialog.panel<void>(
              context,
              title: '새 스프린트',
              builder: (_) => const _NewSprintSheet(),
            ),
          ),
        ],
      ),
      body: sprints.isEmpty
          ? const NxEmptyState(
              title: '아직 스프린트가 없습니다',
              description: '기간을 정해 이슈를 묶으면 번다운으로 진행을 볼 수 있습니다.',
            )
          : ListView.separated(
              padding: const EdgeInsets.all(NxSpacing.sp7),
              itemCount: sprints.length,
              separatorBuilder: (_, _) => const SizedBox(height: NxSpacing.sp5),
              itemBuilder: (_, i) => Align(
                alignment: Alignment.topLeft,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 880),
                  child: _SprintCard(sprint: sprints[i]),
                ),
              ),
            ),
    );
  }
}

class _SprintCard extends ConsumerWidget {
  const _SprintCard({required this.sprint});

  final Sprint sprint;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nx = NxTheme.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(
        NxSpacing.sp7,
        NxSpacing.sp6,
        NxSpacing.sp4,
        NxSpacing.sp7,
      ),
      decoration: BoxDecoration(
        color: nx.colors.bgSurface,
        borderRadius: BorderRadius.circular(NxRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(sprint.name, style: nx.text.title)),
              _StateTag(state: sprint.state),
              const SizedBox(width: NxSpacing.sp2),
              _SprintMenu(sprint: sprint),
            ],
          ),
          if (sprint.goal != null && sprint.goal!.isNotEmpty) ...[
            const SizedBox(height: NxSpacing.sp3),
            Text(sprint.goal!, style: nx.text.secondary),
          ],
          const SizedBox(height: NxSpacing.sp3),
          Text(_periodLabel(sprint), style: nx.text.mono),
          const SizedBox(height: NxSpacing.sp6),
          Padding(
            padding: const EdgeInsets.only(right: NxSpacing.sp4),
            child: _Burndown(sprint: sprint),
          ),
        ],
      ),
    );
  }

  /// 기간이 없으면 번다운을 그릴 수 없다. 그 사실을 여기서 미리 말한다.
  String _periodLabel(Sprint sprint) {
    final start = sprint.startsAt;
    final end = sprint.endsAt;
    if (start == null || end == null) return '기간 미정';
    return '${_fmt(start.toLocal())} — ${_fmt(end.toLocal())}';
  }
}

String _fmt(DateTime d) =>
    '${d.year}.${d.month.toString().padLeft(2, '0')}.'
    '${d.day.toString().padLeft(2, '0')}';

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
    final nx = NxTheme.of(context);
    if (widget.sprint.startsAt == null || widget.sprint.endsAt == null) {
      return Text('기간을 정하면 번다운이 그려집니다.', style: nx.text.secondary);
    }

    final burndown = ref.watch(burndownProvider(widget.sprint.id));
    final failed = SizedBox(
      height: 180,
      child: Center(child: Text('번다운을 불러오지 못했습니다.', style: nx.text.secondary)),
    );

    return burndown.when(
      loading: () => const NxSkeleton(lines: 1, lineHeight: 180),
      error: (_, _) => failed,
      data: (data) => data == null
          ? failed
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const BurndownLegend(),
                    const Spacer(),
                    // 포인트를 안 매기면 포인트 계열이 평평하다. 개수로
                    // 바꿔 볼 수 있어야 그때도 읽힌다.
                    NxSegmented<BurndownSeries>(
                      label: '번다운 계열',
                      expand: false,
                      value: _series,
                      segments: const [
                        (BurndownSeries.points, '포인트'),
                        (BurndownSeries.count, '개수'),
                      ],
                      onChanged: (v) => setState(() => _series = v),
                    ),
                  ],
                ),
                const SizedBox(height: NxSpacing.sp4),
                BurndownChart(burndown: data, series: _series),
              ],
            ),
    );
  }
}

class _StateTag extends StatelessWidget {
  const _StateTag({required this.state});

  final SprintState state;

  @override
  Widget build(BuildContext context) {
    final c = NxTheme.of(context).colors;
    final color = switch (state) {
      SprintState.active => c.success,
      SprintState.planned => c.warning,
      SprintState.closed => c.textSecondary,
    };
    return NxTag(sprintStateLabel(state), dot: true, color: color);
  }
}

/// **상태는 한 방향이다.** 갈 수 없는 곳은 메뉴에 넣지 않는다 — 눌러 봐야
/// 실패하는 항목은 없느니만 못하다(7-5 와 같은 판단).
class _SprintMenu extends ConsumerWidget {
  const _SprintMenu({required this.sprint});

  final Sprint sprint;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Future<void> run(String action) async {
      final actions = ref.read(sprintActionsProvider);
      if (action == 'delete') {
        final sure = await NxDialog.confirm(
          context,
          title: '${withJosa(sprint.name, '을', '를')} 지울까요?',
          body: '이슈는 지워지지 않고 백로그로 돌아갑니다.',
          confirmLabel: '지우기',
          danger: true,
        );
        if (!sure) return;
      }
      final ok = switch (action) {
        'start' => await actions.setState(sprint.id, SprintState.active),
        'close' => await actions.setState(sprint.id, SprintState.closed),
        _ => await actions.remove(sprint.id),
      };
      if (ok || !context.mounted) return;
      NxToast.show(
        context,
        action == 'start'
            // 서버가 409 를 주는 유일한 경우다. 그 뜻을 그대로 말한다.
            ? '이미 진행 중인 스프린트가 있습니다.'
            : '바꾸지 못했습니다. 연결을 확인해 주세요.',
        kind: NxToastKind.error,
      );
    }

    return NxMenu(
      width: 160,
      entries: [
        if (sprint.state == SprintState.planned)
          NxMenuItem('시작하기', onSelected: () => run('start')),
        if (sprint.state == SprintState.active)
          NxMenuItem('끝내기', onSelected: () => run('close')),
        if (sprint.state != SprintState.closed) const NxMenuDivider(),
        NxMenuItem('지우기', danger: true, onSelected: () => run('delete')),
      ],
      anchorBuilder: (context, toggle) => NxIconButton(
        icon: NxIcons.more,
        label: '${sprint.name} 더 보기',
        onPressed: toggle,
      ),
    );
  }
}

/// 스프린트 길이. 달력 대신 **시작일 + 길이**로 정한다 — Material 의 기간 달력
/// (`showDateRangePicker`)을 걷었고, 스프린트는 보통 1~4주 단위라 이쪽이 더 빠르다.
enum _Length { none, w1, w2, w3, w4 }

class _NewSprintSheet extends ConsumerStatefulWidget {
  const _NewSprintSheet();

  @override
  ConsumerState<_NewSprintSheet> createState() => _NewSprintSheetState();
}

class _NewSprintSheetState extends ConsumerState<_NewSprintSheet> {
  final _name = TextEditingController();
  final _goal = TextEditingController();
  late final _start = TextEditingController(text: _fmt(DateTime.now()));
  _Length _length = _Length.w2;
  String? _startError;
  bool _sending = false;

  @override
  void dispose() {
    _name.dispose();
    _goal.dispose();
    _start.dispose();
    super.dispose();
  }

  /// `2026.09.28` · `2026-09-28` · `2026/9/28` 을 받는다. 못 읽으면 null.
  static DateTime? _parse(String text) {
    final parts = text.trim().split(RegExp(r'[.\-/ ]+'));
    if (parts.length != 3) return null;
    final y = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    final d = int.tryParse(parts[2]);
    if (y == null || m == null || d == null) return null;
    final date = DateTime(y, m, d);
    // 2월 30일처럼 넘어가는 값은 거른다.
    if (date.month != m || date.day != d) return null;
    return date;
  }

  Future<void> _submit() async {
    final name = _name.text.trim();
    if (name.isEmpty || _sending) return;

    DateTime? start;
    DateTime? end;
    if (_length != _Length.none) {
      start = _parse(_start.text);
      if (start == null) {
        setState(() => _startError = '날짜를 2026.09.28 처럼 적어 주세요');
        return;
      }
      // 끝 날은 포함한다 — 2주면 시작일 + 13일.
      end = start.add(Duration(days: _length.index * 7 - 1));
    }

    setState(() {
      _sending = true;
      _startError = null;
    });
    final navigator = Navigator.of(context);

    final ok = await ref
        .read(sprintActionsProvider)
        .create(
          name: name,
          goal: _goal.text.trim(),
          startsAt: start,
          endsAt: end,
        );

    if (!mounted) return;
    if (ok) {
      navigator.pop();
      return;
    }
    setState(() => _sending = false);
    NxToast.show(context, '만들지 못했습니다. 연결을 확인해 주세요.', kind: NxToastKind.error);
  }

  @override
  Widget build(BuildContext context) {
    final nx = NxTheme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        NxSpacing.sp7,
        0,
        NxSpacing.sp7,
        NxSpacing.sp7,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          NxField(
            label: '이름',
            controller: _name,
            autofocus: true,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: NxSpacing.sp6),
          NxField(label: '목표 (선택)', controller: _goal),
          const SizedBox(height: NxSpacing.sp6),
          Text(
            '기간',
            style: nx.text.xs.copyWith(
              fontWeight: FontWeight.w600,
              color: nx.colors.textSecondary,
            ),
          ),
          const SizedBox(height: NxSpacing.sp3),
          NxSegmented<_Length>(
            label: '기간',
            value: _length,
            segments: const [
              (_Length.none, '미정'),
              (_Length.w1, '1주'),
              (_Length.w2, '2주'),
              (_Length.w3, '3주'),
              (_Length.w4, '4주'),
            ],
            onChanged: (v) => setState(() => _length = v),
          ),
          const SizedBox(height: NxSpacing.sp5),
          // 기간은 비워 둘 수 있다 — 계획 단계에서는 아직 정해지지 않는다.
          // 다만 없으면 번다운을 그릴 수 없으므로 그 사실을 적어 둔다.
          if (_length == _Length.none)
            Text('기간이 없으면 번다운을 그릴 수 없습니다.', style: nx.text.secondary)
          else
            NxField(
              label: '시작일',
              controller: _start,
              error: _startError,
              keyboardType: TextInputType.datetime,
              style: nx.text.codeLine.copyWith(fontSize: NxFontSize.base),
            ),
          const SizedBox(height: NxSpacing.sp7),
          Align(
            alignment: Alignment.centerRight,
            child: NxButton(
              label: '만들기',
              loading: _sending,
              onPressed: _submit,
            ),
          ),
        ],
      ),
    );
  }
}
