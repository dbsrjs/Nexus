import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/issue.dart';
import '../../ui/ui.dart';
import '../space/space_controller.dart';
import 'board_controller.dart';
import 'issue_detail_controller.dart';

/// 스페이스의 라벨 목록. 라벨은 자주 바뀌지 않아 캐시하지 않는다 —
/// 편집 패널을 열 때만 받는다.
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
    final nx = NxTheme.of(context);
    final color = _parseColor(label.color, nx.colors.success);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? NxSpacing.sp3 : NxSpacing.sp4,
        vertical: dense ? NxSpacing.sp1 : NxSpacing.sp2,
      ),
      decoration: BoxDecoration(
        // 배경은 옅게, 테두리와 글자는 진하게. 색이 열 개 넘게 섞여도
        // 카드가 알록달록해지지 않는다.
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(NxRadius.sm),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        label.name,
        style: (dense ? nx.text.xs2 : nx.text.xs).copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// `#RRGGBB` → Color. 형식은 서버가 강제하지만, 낡은 캐시가 이상한 값을
/// 들고 있어도 화면이 죽지 않아야 한다.
Color _parseColor(String hex, Color fallback) {
  final value = int.tryParse(hex.replaceFirst('#', ''), radix: 16);
  if (value == null) return fallback;
  return Color(0xFF000000 | value);
}

/// 이슈에 붙일 라벨을 고르는 패널(바텀시트의 자리, 15단계 D8).
///
/// **고른 것을 통째로 보낸다** — 서버가 교체 방식이라 차집합을 계산할 일이 없다.
Future<void> showLabelPicker(BuildContext context, Issue issue) =>
    NxDialog.panel<void>(
      context,
      title: '라벨',
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
    final spaceId = ref.read(currentSpaceIdProvider);
    if (spaceId == null) return;
    setState(() => _busy = true);

    final navigator = Navigator.of(context);
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
    NxToast.show(
      context,
      '라벨을 저장하지 못했습니다. 연결을 확인해 주세요.',
      kind: NxToastKind.error,
    );
  }

  Future<void> _create() async {
    final name = _newLabel.text.trim();
    if (name.isEmpty || _busy) return;

    final spaceId = ref.read(currentSpaceIdProvider);
    if (spaceId == null) return;

    setState(() => _busy = true);

    // 색은 이름에서 정한다 — 고르게 하면 패널이 색 선택기로 커진다.
    // 같은 이름은 언제나 같은 색이라 사람이 기억할 수 있다.
    final palette = NxTheme.of(context).colors.avatars;
    final color = palette[name.hashCode.abs() % palette.length];
    final hex =
        '#${(color.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';

    final created = await ref
        .read(issueRepositoryProvider)
        .createLabel(spaceId, name: name, color: hex);

    if (!mounted) return;
    setState(() => _busy = false);
    if (created == null) {
      NxToast.show(
        context,
        '라벨을 만들지 못했습니다. 같은 이름이 있는지 확인해 주세요.',
        kind: NxToastKind.error,
      );
      return;
    }
    _newLabel.clear();
    setState(() => _selected.add(created.id));
    ref.invalidate(spaceLabelsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final nx = NxTheme.of(context);
    final labels = ref.watch(spaceLabelsProvider);

    return Padding(
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
          Flexible(
            child: SingleChildScrollView(
              child: labels.when(
                loading: () => const NxSkeleton(lines: 2),
                error: (_, _) =>
                    Text('라벨을 불러오지 못했습니다.', style: nx.text.secondary),
                data: (items) => items.isEmpty
                    ? Text(
                        '아직 라벨이 없습니다. 아래에서 만들 수 있습니다.',
                        style: nx.text.secondary,
                      )
                    : Wrap(
                        spacing: NxSpacing.sp4,
                        runSpacing: NxSpacing.sp4,
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
            ),
          ),
          const SizedBox(height: NxSpacing.sp6),
          Row(
            children: [
              Expanded(
                child: NxField(
                  controller: _newLabel,
                  hint: '새 라벨 이름',
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _create(),
                ),
              ),
              const SizedBox(width: NxSpacing.sp4),
              // 입력칸과 같은 높이(36) — dense(32) 옆의 sm(28) 이 어긋나 보였다.
              NxButton(
                label: '만들기',
                kind: NxButtonKind.secondary,
                onPressed: _busy ? null : _create,
              ),
            ],
          ),
          const SizedBox(height: NxSpacing.sp6),
          Align(
            alignment: Alignment.centerRight,
            child: NxButton(label: '저장', loading: _busy, onPressed: _save),
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
    return NxPressable(
      onPressed: onTap,
      checked: selected,
      semanticLabel: label.name,
      excludeChildSemantics: true,
      focusRingRadius: NxRadius.sm,
      builder: (context, s) => Opacity(
        // 고르지 않은 것은 흐리게. 체크 표시를 붙이면 칩이 커져 색이 안 보인다.
        opacity: selected ? 1 : (s.hovered ? .7 : .4),
        child: LabelChip(label: label),
      ),
    );
  }
}
