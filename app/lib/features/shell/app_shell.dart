import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/breakpoints.dart';
import '../../core/theme.dart';
import '../space/space_controller.dart';
import 'channel_pane.dart';
import 'space_rail.dart';

/// `/s/:spaceId` — 반응형 셸.
///
/// **폭 분기는 여기 한 곳에서만 한다** (docs/앱-설계.md §4). 안쪽 위젯
/// (SpaceRail · ChannelPane · 본문)은 셋이 공유하고 자기가 어떤 폭에 있는지
/// 모른다. 이 규칙이 깨지면 반응형 분기가 화면마다 흩어져 손댈 수 없게 된다.
///
/// | 폭 | 구성 |
/// |---|---|
/// | ≥1024 | 레일 + 채널 + 본문 3단 고정 |
/// | 600~1023 | 본문만. 레일+채널은 드로어 |
/// | <600 | 본문 + 하단 탭. 채널은 드로어 |
class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key, required this.spaceId});

  final String spaceId;

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    _syncSpaceId();
  }

  @override
  void didUpdateWidget(AppShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.spaceId != widget.spaceId) _syncSpaceId();
  }

  /// 라우트가 진실의 원천이다. 셸이 그 값을 컨트롤러에 실어 준다.
  /// build 안에서 하면 build 중 상태 변경이라 예외가 난다.
  void _syncSpaceId() {
    Future.microtask(() {
      if (!mounted) return;
      ref.read(currentSpaceIdProvider.notifier).set(widget.spaceId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final layout = Layout.ofContext(context);

    return switch (layout) {
      Layout.desktop => const _DesktopShell(),
      Layout.tablet => const _CompactShell(showBottomTabs: false),
      Layout.mobile => _CompactShell(
          showBottomTabs: true,
          tab: _tab,
          onTab: (i) => setState(() => _tab = i),
        ),
    };
  }
}

/// 3단 고정.
class _DesktopShell extends StatelessWidget {
  const _DesktopShell();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      // 데스크톱 OS 에는 상태 표시줄이 없지만, **Android 태블릿은 폭이 1024dp 를
      // 넘으면 이 분기를 탄다.** SafeArea 가 없으면 레일 첫 아바타와 채널 헤더가
      // 시계·배터리와 겹친다.
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SpaceRail(),
            VerticalDivider(width: 1),
            ChannelPane(),
            VerticalDivider(width: 1),
            Expanded(child: _ContentPlaceholder()),
          ],
        ),
      ),
    );
  }
}

/// 태블릿·모바일 공용. 좌측은 드로어로 접는다.
class _CompactShell extends ConsumerWidget {
  const _CompactShell({
    required this.showBottomTabs,
    this.tab = 0,
    this.onTab,
  });

  final bool showBottomTabs;
  final int tab;
  final ValueChanged<int>? onTab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final space = ref.watch(currentSpaceProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(space?.name ?? '…'),
        // Drawer 가 있으면 Flutter 가 햄버거 버튼을 자동으로 넣는다.
      ),
      drawer: Drawer(
        width: NexusPaneWidth.rail + NexusPaneWidth.channels + 1,
        // Drawer 는 상태 표시줄 아래까지 그린다. SafeArea 가 없으면 레일의 첫
        // 아바타와 채널 헤더가 시계·배터리와 겹친다.
        child: const SafeArea(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SpaceRail(),
              VerticalDivider(width: 1),
              Expanded(child: ChannelPane(showCloseButton: true)),
            ],
          ),
        ),
      ),
      body: const _ContentPlaceholder(),
      bottomNavigationBar: showBottomTabs
          ? NavigationBar(
              selectedIndex: tab,
              onDestinationSelected: onTab,
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.forum_outlined),
                  selectedIcon: Icon(Icons.forum),
                  label: '대화',
                ),
                NavigationDestination(
                  icon: Icon(Icons.dashboard_outlined),
                  selectedIcon: Icon(Icons.dashboard),
                  label: '보드',
                ),
                NavigationDestination(
                  icon: Icon(Icons.notifications_outlined),
                  selectedIcon: Icon(Icons.notifications),
                  label: '알림',
                ),
                NavigationDestination(
                  icon: Icon(Icons.person_outline),
                  selectedIcon: Icon(Icons.person),
                  label: '내정보',
                ),
              ],
            )
          : null,
    );
  }
}

/// 메시지 리스트가 들어갈 자리. 슬라이스 3 에서 대체된다.
class _ContentPlaceholder extends ConsumerWidget {
  const _ContentPlaceholder();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final space = ref.watch(currentSpaceProvider);
    final layout = Layout.ofContext(context);

    return ColoredBox(
      color: theme.scaffoldBackgroundColor,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              space?.name ?? '스페이스를 불러오는 중',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: NexusSpacing.sp2),
            Text('메시지는 슬라이스 3 에서', style: theme.textTheme.bodySmall),
            const SizedBox(height: NexusSpacing.sp8),
            // 반응형이 실제로 동작하는지 눈으로 확인하기 위한 표시.
            // 슬라이스 3 에서 메시지 리스트로 대체되며 함께 사라진다.
            Text('레이아웃: ${layout.name}', style: theme.textTheme.labelSmall),
          ],
        ),
      ),
    );
  }
}
