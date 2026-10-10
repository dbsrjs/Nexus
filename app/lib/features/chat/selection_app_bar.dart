import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../ui/ui.dart';
import 'selection_controller.dart';

/// 선택 모드일 때 채널 머리 줄을 덮는다.
///
/// 흔한 메신저의 모양이다 — 「n개 선택」 과 할 수 있는 일들, 그리고 닫기.
class SelectionAppBar extends ConsumerWidget {
  const SelectionAppBar({super.key, required this.onAsk});

  /// 고른 메시지를 붙인 채로 AI 패널을 연다(13-2). 13-1 의 「요약」 버튼을
  /// 바꿨다 — 요약은 패널의 프리셋이다.
  final VoidCallback onAsk;

  /// 평소 채널 머리 줄(`chat_screen.dart` 의 `_ChannelHeader`)과 높이를 맞춘다 —
  /// 어긋나면 선택 모드를 켜고 끌 때 본문이 튄다. **두 곳이 이 상수 하나를
  /// 같이 본다** — 한쪽만 바뀌면 다시 어긋난다.
  static const double height = 52;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nx = NxTheme.of(context);
    final c = nx.colors;
    final selection = ref.watch(selectionControllerProvider);

    return Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: NxSpacing.sp4),
      decoration: BoxDecoration(
        // 평소 머리 줄과 한눈에 갈리게 액센트 옅은 바탕.
        color: c.accentSubtle,
        border: Border(bottom: BorderSide(color: c.divider)),
      ),
      child: Row(
        children: [
          NxIconButton(
            icon: NxIcons.close,
            label: '선택 해제',
            onPressed: () =>
                ref.read(selectionControllerProvider.notifier).clear(),
          ),
          const SizedBox(width: NxSpacing.sp3),
          Expanded(
            child: Semantics(
              liveRegion: true,
              child: Text('${selection.count}개 선택', style: nx.text.strong),
            ),
          ),
          NxButton(
            label: 'AI에게 묻기',
            icon: NxIcons.ai,
            size: NxSize.sm,
            onPressed: selection.count > 0 ? onAsk : null,
          ),
        ],
      ),
    );
  }
}
