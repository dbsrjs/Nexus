import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/breakpoints.dart';
import '../../core/theme.dart';
import '../channel/channel_list.dart';
import '../space/space_controller.dart';

/// 가운데 240px — 스페이스 이름 헤더 + 카테고리/채널 목록.
class ChannelPane extends ConsumerWidget {
  const ChannelPane({super.key, this.showCloseButton = false, this.onChannelTap});

  /// 드로어로 열렸을 때 닫기 버튼을 보여 준다.
  final bool showCloseButton;

  /// 드로어에서 채널을 고르면 드로어를 닫기 위한 콜백.
  final VoidCallback? onChannelTap;

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
          Expanded(child: ChannelList(onChannelTap: onChannelTap)),
        ],
      ),
    );
  }
}
