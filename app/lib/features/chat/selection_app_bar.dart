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

  /// 평소 채널 헤더(`chat_screen.dart` 의 `_ChannelHeader`)와 높이를 맞춘다.
  /// 기본 `kToolbarHeight`(56) 를 그냥 쓰면 `_ChannelHeader` 의 52 와 어긋나
  /// 선택 모드를 켜고 끌 때 본문이 4px 튄다. **두 곳이 이 상수 하나를
  /// 같이 본다** — 한쪽만 바뀌면 다시 어긋난다.
  static const double height = 52;

  @override
  Size get preferredSize => const Size.fromHeight(height);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selection = ref.watch(selectionControllerProvider);

    return AppBar(
      toolbarHeight: height,
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
