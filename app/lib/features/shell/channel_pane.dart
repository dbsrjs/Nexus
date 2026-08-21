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
                if (onClose != null)
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: onClose,
                  ),
              ],
            ),
          ),
          if (space != null)
            _WorkSection(spaceId: space.id, onTap: onChannelTap),
          Expanded(child: ChannelList(onChannelTap: onChannelTap)),
        ],
      ),
    );
  }
}


/// 셸 안에서 갈 수 있는 곳 — 이슈 보드 · 스프린트 · 파일 · 저장소.
///
/// 이전에는 판 **헤더의 아이콘 둘**(보드 · 저장소)이 유일한 진입점이었고
/// 스프린트와 파일로 가는 길은 아예 없었다. 아이콘만으로는 무엇인지 읽히지
/// 않고, 갈래가 늘 때마다 헤더가 좁아진다.
///
/// 이 판에는 이미 채널이 카테고리로 묶여 있다. 구조를 새로 만드는 것이
/// 아니라 있던 것을 끝까지 쓰는 것이다.
class _WorkSection extends StatelessWidget {
  const _WorkSection({required this.spaceId, this.onTap});

  final String spaceId;

  /// 드로어에서 고르면 드로어를 닫기 위한 콜백. 채널을 고를 때와 같다.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // 지금 어디에 있는지는 라우트가 안다. 셸이 따로 상태를 들지 않는다.
    final location = GoRouterState.of(context).uri.path;

    Widget item(String label, IconData icon, String suffix) {
      final path = '/s/$spaceId$suffix';
      final selected = location == path || location.startsWith('$path/');

      return ListTile(
        dense: true,
        visualDensity: VisualDensity.compact,
        selected: selected,
        leading: Icon(icon, size: 18),
        title: Text(
          label,
          style: selected
              ? theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                )
              : theme.textTheme.bodySmall,
        ),
        onTap: () {
          context.go(path);
          onTap?.call();
        },
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            NexusSpacing.sp5,
            NexusSpacing.sp5,
            NexusSpacing.sp5,
            NexusSpacing.sp2,
          ),
          child: Text('작업', style: theme.textTheme.labelSmall),
        ),
        item('이슈 보드', Icons.dashboard_outlined, '/issues'),
        item('스프린트', Icons.timeline_outlined, '/sprints'),
        item('파일', Icons.folder_outlined, '/files'),
        item('저장소', Icons.hub_outlined, '/repos'),
      ],
    );
  }
}
