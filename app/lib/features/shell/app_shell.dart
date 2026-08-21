import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/breakpoints.dart';
import '../../core/theme.dart';
import '../channel/channel_controller.dart';
import '../space/space_controller.dart';
import 'channel_pane.dart';
import 'space_rail.dart';

/// `/s/:spaceId` · `/s/:spaceId/c/:channelId` — 반응형 셸.
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
  const AppShell({
    super.key,
    required this.spaceId,
    this.channelId,
    required this.child,
  });

  final String spaceId;
  final String? channelId;

  /// 본문. **무엇을 그릴지는 라우터가 정한다.**
  ///
  /// 셸이 본문을 탭으로 갈아 끼우면 "라우트가 진실의 원천"이라는 이 셸의
  /// 전제가 깨진다. ShellRoute 를 쓰는 이유가 그것이다 — 셸은 마운트된 채로
  /// 남고 무엇을 그릴지는 여전히 라우터가 정한다.
  final Widget child;

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    _syncRoute();
  }

  @override
  void didUpdateWidget(AppShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.spaceId != widget.spaceId ||
        oldWidget.channelId != widget.channelId) {
      _syncRoute();
    }
  }

  /// 라우트가 진실의 원천이다. 셸이 그 값을 컨트롤러에 실어 준다.
  /// build 안에서 하면 build 중 상태 변경이라 예외가 난다.
  void _syncRoute() {
    Future.microtask(() {
      if (!mounted) return;
      ref.read(currentSpaceIdProvider.notifier).set(widget.spaceId);
      ref.read(currentChannelIdProvider.notifier).set(widget.channelId);
    });
  }

  /// '보드' 탭은 셸 본문을 갈아 끼우는 대신 **보드 화면을 덮어서 연다.**
  /// 본문을 탭으로 바꾸면 "라우트가 진실의 원천"이라는 이 셸의 전제가 깨진다.
  /// 돌아오면 탭은 대화로 되돌린다 — 보드가 열려 있지 않은데 '보드'가
  /// 선택돼 있으면 지금 무엇을 보고 있는지 읽을 수 없다.
  void _onTab(int index) {
    if (index == 1) {
      context.push('/s/${widget.spaceId}/issues');
      return;
    }
    setState(() => _tab = index);
  }

  @override
  Widget build(BuildContext context) {
    final layout = Layout.ofContext(context);

    return switch (layout) {
      Layout.desktop => _DesktopShell(child: widget.child),
      Layout.tablet =>
        _CompactShell(showBottomTabs: false, child: widget.child),
      Layout.mobile => _CompactShell(
          showBottomTabs: true,
          tab: _tab,
          onTab: _onTab,
          child: widget.child,
        ),
    };
  }
}

/// 3단 고정.
class _DesktopShell extends StatelessWidget {
  const _DesktopShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 데스크톱 OS 에는 상태 표시줄이 없지만, **Android 태블릿은 폭이 1024dp 를
      // 넘으면 이 분기를 탄다.** SafeArea 가 없으면 레일 첫 아바타와 채널 헤더가
      // 시계·배터리와 겹친다.
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SpaceRail(),
            const VerticalDivider(width: 1),
            const ChannelPane(),
            const VerticalDivider(width: 1),
            Expanded(child: child),
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
    required this.child,
    this.tab = 0,
    this.onTab,
  });

  final bool showBottomTabs;
  final Widget child;
  final int tab;
  final ValueChanged<int>? onTab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final space = ref.watch(currentSpaceProvider);
    final channel = ref.watch(currentChannelProvider);

    return Scaffold(
      appBar: AppBar(
        // 채널이 열려 있으면 채널 이름이 더 유용하다. 스페이스 이름은 드로어에 있다.
        title: Text(channel?.name ?? space?.name ?? '…'),
      ),
      drawer: Builder(
        builder: (drawerContext) => Drawer(
          width: NexusPaneWidth.rail + NexusPaneWidth.channels + 1,
          // Drawer 는 상태 표시줄 아래까지 그린다. SafeArea 가 없으면 레일의 첫
          // 아바타와 채널 헤더가 시계·배터리와 겹친다.
          child: SafeArea(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SpaceRail(),
                const VerticalDivider(width: 1),
                Expanded(
                  child: ChannelPane(
                    onClose: () => Scaffold.of(drawerContext).closeDrawer(),
                    // 채널을 고르면 드로어를 닫는다. 안 닫으면 고른 대화가 가려진다.
                    //
                    // **Navigator.pop 을 쓰면 안 된다.** Scaffold 의 drawer 는
                    // 라우트가 아니라서 pop 이 드로어가 아니라 현재 페이지를 닫는다.
                    // 채널 탭이 context.go 로 라우트를 민 직후라, pop 하면 방금 연
                    // 채널 라우트가 닫혀 선택이 취소된다.
                    onChannelTap: () => Scaffold.of(drawerContext).closeDrawer(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: child,
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

/// `/s/:spaceId` — 채널을 아직 고르지 않은 상태.
///
/// 이전에는 셸이 `channelId` 를 보고 대화와 안내 중 하나를 골랐다. 이제
/// 무엇을 그릴지는 라우터가 정하므로, 이 화면이 그 자리에 오는 라우트가 된다.
class ShellHome extends StatelessWidget {
  const ShellHome({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ColoredBox(
      color: theme.scaffoldBackgroundColor,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(NexusSpacing.sp6),
          child: Text(
            '채널을 선택하세요',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
        ),
      ),
    );
  }
}
