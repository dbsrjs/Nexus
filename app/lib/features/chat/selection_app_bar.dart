import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import 'selection_controller.dart';

/// 선택 모드일 때 채널 앱바를 덮는다.
///
/// 흔한 메신저의 모양이다 — 「n개 선택」 과 할 수 있는 일들, 그리고 닫기.
class SelectionAppBar extends ConsumerWidget implements PreferredSizeWidget {
  const SelectionAppBar({super.key, required this.onSummarize});

  final VoidCallback onSummarize;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selection = ref.watch(selectionControllerProvider);

    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.close),
        tooltip: '선택 해제',
        onPressed: () =>
            ref.read(selectionControllerProvider.notifier).clear(),
      ),
      title: Text('${selection.count}개 선택'),
      actions: [
        TextButton.icon(
          onPressed: selection.count > 0 ? onSummarize : null,
          icon: const Icon(Icons.auto_awesome_outlined),
          label: const Text('요약'),
        ),
        const SizedBox(width: NexusSpacing.sp2),
      ],
    );
  }
}
