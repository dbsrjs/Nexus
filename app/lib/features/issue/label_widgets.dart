import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../domain/models/issue.dart';
import '../space/space_controller.dart';
import 'board_controller.dart';
import 'issue_detail_controller.dart';

/// 스페이스의 라벨 목록. 라벨은 자주 바뀌지 않아 캐시하지 않는다 —
/// 편집 시트를 열 때만 받는다.
final spaceLabelsProvider = FutureProvider.autoDispose<List<IssueLabel>>((
  ref,
) async {
  final spaceId = ref.watch(currentSpaceIdProvider);
  if (spaceId == null) return const [];
  return ref.watch(issueRepositoryProvider).listLabels(spaceId);
});

/// 라벨 한 칸. 색은 서버가 준 `#RRGGBB` 를 그대로 쓴다.
class LabelChip extends StatelessWidget {
  const LabelChip({super.key, required this.label, this.dense = false});

  final IssueLabel label;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final color = _parseColor(label.color);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? NexusSpacing.sp3 : NexusSpacing.sp4,
        vertical: dense ? NexusSpacing.sp1 : NexusSpacing.sp2,
      ),
      decoration: BoxDecoration(
        // 배경은 옅게, 테두리와 글자는 진하게. 색이 열 개 넘게 섞여도
        // 카드가 알록달록해지지 않는다.
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(NexusRadius.sm),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        label.name,
        style: (dense
                ? Theme.of(context).textTheme.labelSmall
                : Theme.of(context).textTheme.labelMedium)
            ?.copyWith(color: color),
      ),
    );
  }
}

/// `#RRGGBB` → Color. 형식은 서버가 강제하지만, 낡은 캐시가 이상한 값을
/// 들고 있어도 화면이 죽지 않아야 한다.
Color _parseColor(String hex) {
  final value = int.tryParse(hex.replaceFirst('#', ''), radix: 16);
  if (value == null) return NexusColors.success;
  return Color(0xFF000000 | value);
}

/// 이슈에 붙일 라벨을 고르는 시트.
///
/// **고른 것을 통째로 보낸다** — 서버가 교체 방식이라 차집합을 계산할 일이 없다.
Future<void> showLabelPicker(BuildContext context, Issue issue) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _LabelPicker(issue: issue),
    );

class _LabelPicker extends ConsumerStatefulWidget {
  const _LabelPicker({required this.issue});

  final Issue issue;

  @override
  ConsumerState<_LabelPicker> createState() => _LabelPickerState();
}

class _LabelPickerState extends ConsumerState<_LabelPicker> {
  late final Set<String> _selected = {
    for (final l in widget.issue.labels) l.id,
  };
  final _newLabel = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _newLabel.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_busy) return;
    setState(() => _busy = true);

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final spaceId = ref.read(currentSpaceIdProvider);
    if (spaceId == null) return;

    final ok = await ref
        .read(issueRepositoryProvider)
        .setLabels(spaceId, widget.issue, _selected.toList());

    if (!mounted) return;
    if (ok) {
      ref.invalidate(currentIssueProvider);
      navigator.pop();
      return;
    }
    setState(() => _busy = false);
    messenger.showSnackBar(
      const SnackBar(content: Text('라벨을 저장하지 못했습니다. 연결을 확인해 주세요.')),
    );
  }

  Future<void> _create() async {
    final name = _newLabel.text.trim();
    if (name.isEmpty || _busy) return;

    final spaceId = ref.read(currentSpaceIdProvider);
    if (spaceId == null) return;

    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);

    // 색은 이름에서 정한다 — 고르게 하면 시트가 색 선택기로 커진다.
    // 같은 이름은 언제나 같은 색이라 사람이 기억할 수 있다.
    final palette = NexusColors.avatars;
    final color = palette[name.hashCode.abs() % palette.length];
    final hex = '#${(color.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';

    final created = await ref
        .read(issueRepositoryProvider)
        .createLabel(spaceId, name: name, color: hex);

    if (!mounted) return;
    setState(() => _busy = false);
    if (created == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('라벨을 만들지 못했습니다. 같은 이름이 있는지 확인해 주세요.')),
      );
      return;
    }
    _newLabel.clear();
    setState(() => _selected.add(created.id));
    ref.invalidate(spaceLabelsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final labels = ref.watch(spaceLabelsProvider);

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
          Text('라벨', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: NexusSpacing.sp5),
          labels.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(NexusSpacing.sp6),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (_, _) => const Text('라벨을 불러오지 못했습니다.'),
            data: (items) => items.isEmpty
                ? const Text('아직 라벨이 없습니다. 아래에서 만들 수 있습니다.')
                : Wrap(
                    spacing: NexusSpacing.sp4,
                    runSpacing: NexusSpacing.sp4,
                    children: [
                      for (final label in items)
                        _SelectableLabel(
                          label: label,
                          selected: _selected.contains(label.id),
                          onTap: () => setState(() {
                            if (!_selected.remove(label.id)) {
                              _selected.add(label.id);
                            }
                          }),
                        ),
                    ],
                  ),
          ),
          const SizedBox(height: NexusSpacing.sp6),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _newLabel,
                  decoration: const InputDecoration(hintText: '새 라벨 이름'),
                  onSubmitted: (_) => _create(),
                ),
              ),
              const SizedBox(width: NexusSpacing.sp4),
              IconButton(
                tooltip: '라벨 만들기',
                icon: const Icon(Icons.add),
                onPressed: _busy ? null : _create,
              ),
            ],
          ),
          const SizedBox(height: NexusSpacing.sp6),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              onPressed: _busy ? null : _save,
              child: const Text('저장'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectableLabel extends StatelessWidget {
  const _SelectableLabel({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IssueLabel label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(NexusRadius.sm),
      onTap: onTap,
      child: Opacity(
        // 고르지 않은 것은 흐리게. 체크박스를 붙이면 칩이 커져 색이 안 보인다.
        opacity: selected ? 1 : 0.4,
        child: LabelChip(label: label),
      ),
    );
  }
}
