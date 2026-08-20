import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/breakpoints.dart';
import '../../core/theme.dart';
import '../channel/channel_list.dart';
import '../space/space_controller.dart';

/// 가운데 240px — 스페이스 이름 헤더 + 카테고리/채널 목록.
class ChannelPane extends ConsumerWidget {
  const ChannelPane({super.key, this.onClose, this.onChannelTap});

  /// 드로어로 열렸을 때 닫는 방법. null 이면 닫기 버튼을 감춘다(데스크톱 3단).
  ///
  /// 닫는 동작을 위젯 안에서 하지 않고 밖에서 받는 이유: Scaffold 의 drawer 는
  /// **라우트가 아니라서** `Navigator.pop` 이 드로어가 아니라 현재 페이지를 닫는다.
  final VoidCallback? onClose;

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
                // 보드로 가는 길. 데스크톱·태블릿에서는 하단 탭이 없어
                // 여기가 유일한 진입점이다.
                IconButton(
                  tooltip: '보드',
                  icon: const Icon(Icons.dashboard_outlined, size: 18),
                  onPressed: space == null
                      ? null
                      : () => context.push('/s/${space.id}/issues'),
                ),
                if (onClose != null)
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: onClose,
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
