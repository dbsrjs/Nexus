import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/breakpoints.dart';
import '../../core/theme.dart';
import '../space/space_controller.dart';

/// 가운데 240px — 카테고리와 채널 목록이 들어갈 자리.
///
/// **슬라이스 2 에서는 껍데기다.** 실제 채널 목록은 슬라이스 3 에서
/// `GET /api/spaces/:spaceId/channels` 를 붙이며 채운다. 지금은 셸이 세 칸으로
/// 갈라지는 것과 스페이스 전환이 반영되는 것까지만 보인다.
class ChannelPane extends ConsumerWidget {
  const ChannelPane({super.key, this.showCloseButton = false});

  /// 드로어로 열렸을 때 닫기 버튼을 보여 준다.
  final bool showCloseButton;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final space = ref.watch(currentSpaceProvider);

    return Container(
      width: NexusPaneWidth.channels,
      color: theme.colorScheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 스페이스 이름 헤더
          Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: NexusSpacing.sp5),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: theme.dividerColor, width: 1),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    space?.name ?? '…',
                    style: theme.textTheme.titleSmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (showCloseButton)
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(NexusSpacing.sp6),
                child: Text(
                  '채널 목록은\n슬라이스 3 에서',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
