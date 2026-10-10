import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/breakpoints.dart';
import '../../domain/models/channel.dart';
import '../../shared/widgets/nexus_avatar.dart';
import '../../ui/ui.dart';
import '../channel/channel_controller.dart';
import '../notifications/notifications_controller.dart';
import '../settings/settings_widgets.dart';
import '../space/space_actions.dart';
import '../space/space_controller.dart';
import '../settings/theme_controller.dart';
import 'channel_pane.dart';
import 'side_panel.dart';
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
/// | 600~1023 | 본문만. 레일+채널은 왼쪽에서 밀려 나오는 패널 |
/// | <600 | 본문 + 아래 글자 탭. 채널은 밀려 나오는 패널 |
///
/// **햄버거 · Drawer · NavigationBar 를 쓰지 않는다**(15단계 D12). 패널은 본문 머리의
/// [ShellPaneTrigger](채널 · 화면 이름 버튼)가 연다.
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
  @override
  void initState() {
    super.initState();
    _sidePanel = ref.read(sidePanelProvider.notifier);
    _syncRoute();
  }

  @override
  void didUpdateWidget(AppShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.spaceId != widget.spaceId ||
        oldWidget.channelId != widget.channelId) {
      // 오른쪽 판은 보던 채널의 곁가지다 — 채널을 옮기면 닫는다(build 밖에서).
      Future.microtask(() {
        if (mounted) ref.read(sidePanelProvider.notifier).close();
      });
      _syncRoute();
    }
  }

  late final SidePanelNotifier _sidePanel;

  @override
  void dispose() {
    // 셸을 떠나면(설정 창 · 로그아웃) 판도 닫는다 — 돌아왔을 때 옛 스레드가 다시 뜨지 않게.
    // dispose 에서는 ref 를 못 쓰므로 미리 잡아 둔 notifier 로, 프레임 밖에서.
    // 앱 전체가 내려갈 때는 그 사이 notifier 가 먼저 버려진다 — closeIfAlive 가 그때는 조용하다.
    final panel = _sidePanel;
    Future.microtask(panel.closeIfAlive);
    super.dispose();
  }

  /// 멤버 확인을 마지막으로 한 스페이스. 채널만 옮길 때는 다시 묻지 않는다.
  String? _checkedSpaceId;

  /// 멤버가 아닌 스페이스면 나가고 알린다. 그대로 두면 이름 자리가 「…」 인 빈 셸이 뜬다.
  Future<void> _leaveIfOutsider(String spaceId) async {
    final outsider = await isConfirmedOutsider(
      ref.read(workspaceRepositoryProvider),
      spaceId,
    );
    if (!outsider || !mounted || widget.spaceId != spaceId) return;
    NxToast.show(context, '이 스페이스를 볼 수 없습니다');
    context.go('/spaces');
  }

  /// 라우트가 진실의 원천이다. 셸이 그 값을 컨트롤러에 실어 준다.
  /// build 안에서 하면 build 중 상태 변경이라 예외가 난다.
  void _syncRoute() {
    if (_checkedSpaceId != widget.spaceId) {
      _checkedSpaceId = widget.spaceId;
      _leaveIfOutsider(widget.spaceId);
    }
    // 다음에 켤 때 곧장 여기로 온다(ShellHome · 스페이스 고르기의 auto).
    final storage = ref.read(settingsStorageProvider);
    storage.writeLastSpace(widget.spaceId);
    final channelId = widget.channelId;
    if (channelId != null) storage.writeLastChannel(widget.spaceId, channelId);
    Future.microtask(() {
      if (!mounted) return;
      ref.read(currentSpaceIdProvider.notifier).set(widget.spaceId);
      ref.read(currentChannelIdProvider.notifier).set(widget.channelId);
      // 빠졌던 스페이스에 다시 들어왔다(재초대) — 지난 사건을 비워 채널 리스너가 다시 듣게 한다.
      final removed = ref.read(removedSpaceProvider);
      if (removed?.spaceId == widget.spaceId) {
        ref.read(removedSpaceProvider.notifier).clear();
      }
    });
  }

  /// 탭은 셸 안의 갈래를 고른다. **`go` 로 민다** — 다섯 다 셸 안에 있다.
  ///
  /// 순서는 데스크톱 판의 「작업」 갈래와 같다(알림 · 이슈 · 파일 · 저장소) — 플랫폼마다 순서가
  /// 다르면 손이 기억한 자리가 깨진다(2026-10-10 UI/UX 검토).
  void _onTab(int index) {
    final base = '/s/${widget.spaceId}';
    switch (index) {
      case 0:
        // 「대화」는 채널 목록(셸 홈)이다 — 모바일 메신저의 첫 화면. 채널 안에서 다시 누르면
        // 목록으로 돌아간다.
        context.go(base);
      case 1:
        context.go('$base/notifications');
      case 2:
        context.go('$base/issues');
      case 3:
        context.go('$base/files');
      case 4:
        context.go('$base/repos');
    }
  }

  @override
  Widget build(BuildContext context) {
    // 지금 보고 있는 스페이스에서 빠졌으면 나가고 알린다(16단계 설계 D13). 소켓 리스너는
    // 화면을 모르므로 여기서 받는다. 메뉴의 「나가기」로 나온 경우도 같은 길이다.
    ref.listen<SpaceRemoval?>(removedSpaceProvider, (_, removed) {
      if (removed == null || removed.spaceId != widget.spaceId) return;
      NxToast.show(context, '스페이스에서 나왔습니다');
      context.go('/spaces');
    });

    // 보고 있던 채널이 목록에서 **빠지는 순간** 스페이스 홈으로 보낸다(16단계 — 명단에서 빠졌거나
    // 역할로 가려졌다). 처음 받은 목록에 없는 것은 따지지 않는다 — 빠진 것만 본다. 그래야
    // 방금 만든 채널 · 첫 진입처럼 목록이 아직 따라오지 못한 때에 엉뚱하게 내보내지 않는다.
    ref.listen<AsyncValue<List<Channel>>>(channelsProvider, (previous, next) {
      final channelId = widget.channelId;
      final before = previous?.value;
      final after = next.value;
      if (channelId == null || before == null || after == null) return;
      final was = before.any((c) => c.id == channelId);
      final still = after.any((c) => c.id == channelId);
      if (!was || still) return;
      // 스페이스째 빠진 것이면 위 리스너가 이미 알렸다 — 같은 사건에 두 번 말하지 않는다.
      if (ref.read(removedSpaceProvider)?.spaceId == widget.spaceId) return;
      NxToast.show(context, '이 채널을 더는 볼 수 없습니다');
      context.go('/s/${widget.spaceId}');
    });

    final layout = Layout.ofContext(context);

    return switch (layout) {
      Layout.desktop => _DesktopShell(child: widget.child),
      Layout.tablet => _CompactShell(showTabs: false, child: widget.child),
      Layout.mobile => _CompactShell(
        showTabs: true,
        onTab: _onTab,
        child: widget.child,
      ),
    };
  }
}

/// 3단 고정 + 열면 오른쪽 판(스레드 · AI).
class _DesktopShell extends ConsumerWidget {
  const _DesktopShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final panel = ref.watch(sidePanelProvider);
    final rail = showSpaceRail(ref);
    // 데스크톱 OS 에는 상태 표시줄이 없지만, **Android 태블릿은 폭이 1024dp 를
    // 넘으면 이 분기를 탄다.** NxPage 의 SafeArea 가 레일 · 채널 머리를 시계와
    // 겹치지 않게 한다.
    return NxPage(
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (rail) const SpaceRail(),
          ChannelPane(showAccountFooter: !rail),
          const NxDivider(vertical: true),
          Expanded(child: SidePanelScope(child: child)),
          if (panel != null) ...[
            const NxDivider(vertical: true),
            SizedBox(
              width: NexusPaneWidth.side,
              child: SidePanelView(panel: panel),
            ),
          ],
        ],
      ),
    );
  }
}

/// 밀려 나오는 패널을 여는 방법. **셸만 안다** — 좁은 셸이 깔고, 넓은 셸에는 없다.
class _PaneScope extends InheritedWidget {
  const _PaneScope({
    required this.open,
    required this.hasTabs,
    required super.child,
  });

  final VoidCallback open;

  /// 아래 탭 줄이 있는가(모바일). 있으면 「작업」 갈래가 탭과 겹치므로 목록에서 뺀다.
  final bool hasTabs;

  @override
  bool updateShouldNotify(_PaneScope old) => false;
}

/// 좁은 셸(태블릿 · 모바일) 안인가. 머리 줄이 버튼을 접을지 정할 때만 쓴다 — **폭을 묻지
/// 않고** 셸이 깐 표식으로 안다(폭 분기는 이 파일 한 곳).
bool isCompactShell(BuildContext context) =>
    context.dependOnInheritedWidgetOfExactType<_PaneScope>() != null;

/// 본문 머리의 제목 자리. 좁은 셸에서는 **누르면 채널 패널이 열리는 버튼**이 되고
/// (스페이스 아바타 + 제목 + ▾ — 햄버거의 자리, 캔버스 「채널 · 모바일」), 넓은 셸에서는
/// 제목 그대로다. 안쪽 화면은 자기가 어느 폭에 있는지 모른 채 이것으로 제목을 감싼다.
class ShellPaneTrigger extends ConsumerWidget {
  const ShellPaneTrigger({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scope = context.dependOnInheritedWidgetOfExactType<_PaneScope>();
    if (scope == null) return child;
    final c = NxTheme.of(context).colors;
    final space = ref.watch(currentSpaceProvider);

    return NxHoverSurface(
      onPressed: scope.open,
      semanticLabel: '채널 바꾸기',
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: NxSpacing.sp3),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (space != null) ...[
            NexusAvatar(
              seed: space.id,
              label: space.name,
              size: 24,
              squircle: true,
            ),
            const SizedBox(width: NxSpacing.sp4),
          ],
          Flexible(child: child),
          const SizedBox(width: NxSpacing.sp3),
          NxIcon(
            NxIcons.chevronDown,
            size: NxIconSize.xs,
            color: c.textSecondary,
          ),
        ],
      ),
    );
  }
}

/// 셸 안 화면의 머리 줄 — 제목이 [ShellPaneTrigger] 로 감싸인 [NxHeader].
/// 보드 · 스프린트 · 파일 · 저장소 · 셸 홈이 같은 모양을 쓴다.
class ShellHeader extends StatelessWidget {
  const ShellHeader({super.key, required this.title, this.actions = const []});

  final String title;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final nx = NxTheme.of(context);
    return NxHeader(
      titleWidget: Align(
        alignment: Alignment.centerLeft,
        child: ShellPaneTrigger(
          child: Semantics(
            header: true,
            child: Text(
              title,
              overflow: TextOverflow.ellipsis,
              style: nx.text.header,
            ),
          ),
        ),
      ),
      actions: actions,
    );
  }
}

/// 셸 안의 경로가 어느 탭에 속하는지(대화 0 · 알림 1 · 이슈 2 · 파일 3 · 저장소 4).
///
/// **스프린트는 이슈 탭이다** — 보드 머리 줄에서 들어가는 갈래라, 빠뜨렸더니 스프린트
/// 화면에서 「대화」 탭이 켜져 있었다(Android 에서 발견).
int shellTabFor(String path) => switch (path) {
  final p when p.contains('/notifications') => 1,
  final p when p.contains('/issues') || p.contains('/sprints') => 2,
  final p when p.contains('/files') => 3,
  final p when p.contains('/repos') => 4,
  _ => 0,
};

/// 태블릿 · 모바일 공용. 레일 + 채널 패널은 왼쪽에서 밀려 나온다.
class _CompactShell extends ConsumerStatefulWidget {
  const _CompactShell({
    required this.showTabs,
    required this.child,
    this.onTab,
  });

  final bool showTabs;
  final Widget child;
  final ValueChanged<int>? onTab;

  @override
  ConsumerState<_CompactShell> createState() => _CompactShellState();
}

class _CompactShellState extends ConsumerState<_CompactShell> {
  bool _open = false;

  void _setOpen(bool open) {
    if (_open != open) setState(() => _open = open);
  }

  @override
  Widget build(BuildContext context) {
    final c = NxTheme.of(context).colors;

    // **고른 탭을 셸이 들고 있지 않는다.** 라우트에서 읽어야 채널 패널에서
    // 직접 이동해도 탭이 따라온다.
    final location = GoRouterState.of(context).uri.path;
    final selectedTab = shellTabFor(location);
    final unread = ref.watch(unreadNotificationsProvider);
    final rail = showSpaceRail(ref);
    final paneWidth =
        (rail ? NexusPaneWidth.rail : 0) + NexusPaneWidth.channels;

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): () => _setOpen(false),
      },
      child: Stack(
        children: [
          Positioned.fill(
            child: _PaneScope(
              open: () => _setOpen(true),
              hasTabs: widget.showTabs,
              child: NxPage(
                body: widget.child,
                // 데스크톱 두 번째 판의 「작업」 갈래와 같은 곳을 담는다.
                bottom: widget.showTabs
                    ? NxTabBar(
                        tabs: [
                          const NxTab('대화'),
                          // 안 읽은 수(18단계 N19). 판 안에만 두면 모바일에서 수가 안 보인다.
                          NxTab('알림', count: unread > 0 ? unread : null),
                          const NxTab('이슈'),
                          const NxTab('파일'),
                          const NxTab('저장소'),
                        ],
                        index: selectedTab,
                        onChanged: widget.onTab ?? (_) {},
                      )
                    : null,
              ),
            ),
          ),
          // 막 — 누르면 닫힌다. 열려 있을 때만 누름을 받는다.
          Positioned.fill(
            child: IgnorePointer(
              ignoring: !_open,
              child: GestureDetector(
                onTap: () => _setOpen(false),
                child: AnimatedOpacity(
                  duration: NxMotion.panel,
                  curve: NxMotion.ease,
                  opacity: _open ? 1 : 0,
                  child: ColoredBox(color: c.scrim),
                ),
              ),
            ),
          ),
          AnimatedPositioned(
            duration: NxMotion.panel,
            curve: NxMotion.ease,
            top: 0,
            bottom: 0,
            left: _open ? 0 : -paneWidth - 1,
            width: paneWidth + 1,
            // 닫힌 패널은 포커스 · 보조 기술에서 빠진다. 밀려 들어가는 동안에는 그린다.
            child: ExcludeFocus(
              excluding: !_open,
              child: ExcludeSemantics(
                excluding: !_open,
                child: ColoredBox(
                  color: c.bgSurface,
                  child: SafeArea(
                    right: false,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (rail) const SpaceRail(),
                        Expanded(
                          child: ChannelPane(
                            showAccountFooter: !rail,
                            // 모바일은 아래 탭이 같은 곳을 담는다 — 두 번 보이지 않는다.
                            showWorkSection: !widget.showTabs,
                            onClose: () => _setOpen(false),
                            // 채널 · 작업 갈래를 고르면 닫는다. 안 닫으면 고른 곳이 가려진다.
                            onChannelTap: () => _setOpen(false),
                          ),
                        ),
                        const NxDivider(vertical: true),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// `/s/:spaceId` — 채널을 아직 고르지 않은 상태.
///
/// 무엇을 그릴지는 라우터가 정하므로, 이 화면이 그 자리에 오는 라우트가 된다.
///
/// 예전에는 「채널을 선택하세요」 한 줄뿐이었다 — 앱을 켤 때마다 빈 본문을 지났고, 모바일은
/// 채널 목록이 머리의 ▾ 뒤에 숨어 처음 쓰는 사람이 못 찾았다(2026-10-10 UI/UX 검토).
///
/// - **넓은 셸**: 채널 목록은 이미 옆에 있다. 마지막으로 본 채널(없으면 첫 채널)로 곧장 연다.
/// - **좁은 셸**: 채널 목록 자체가 본문이다 — 모바일 메신저의 첫 화면.
class ShellHome extends ConsumerStatefulWidget {
  const ShellHome({super.key});

  @override
  ConsumerState<ShellHome> createState() => _ShellHomeState();
}

class _ShellHomeState extends ConsumerState<ShellHome> {
  /// 이 스페이스에서 곧장 열 채널을 이미 정했다. 한 번만 정한다 — 목록이 다시 와도
  /// (실시간 갱신) 사용자를 다시 옮기지 않는다.
  String? _openedFor;

  /// 저장소에서 읽은 마지막 채널. 아직 못 읽었으면 [_lastLoaded] 가 false.
  String? _last;
  bool _lastLoaded = false;
  String? _lastFor;

  void _loadLast(String spaceId) {
    if (_lastFor == spaceId) return;
    _lastFor = spaceId;
    _lastLoaded = false;
    ref.read(settingsStorageProvider).readLastChannel(spaceId).then((id) {
      if (!mounted || _lastFor != spaceId) return;
      setState(() {
        _last = id;
        _lastLoaded = true;
      });
    });
  }

  /// 넓은 셸에서 열 채널. 목록이 아직 없거나 마지막 채널을 아직 못 읽었으면 null(기다린다).
  String? _target(String spaceId) {
    if (!_lastLoaded) return null;
    final channels = ref.read(channelsProvider).value;
    if (channels == null) return null;
    final last = _last;
    if (last != null && channels.any((c) => c.id == last)) return last;
    return firstHomeChannel(ref.read(channelGroupsProvider))?.id;
  }

  @override
  Widget build(BuildContext context) {
    final nx = NxTheme.of(context);
    final scope = context.dependOnInheritedWidgetOfExactType<_PaneScope>();
    final space = ref.watch(currentSpaceProvider);
    final spaceId = GoRouterState.of(context).pathParameters['spaceId'];

    if (scope == null && spaceId != null) {
      _loadLast(spaceId);
      // 목록 · 카테고리가 오면 다시 그려 정한다.
      ref.watch(channelsProvider);
      ref.watch(channelGroupsProvider);
      final target = _openedFor == spaceId ? null : _target(spaceId);
      if (target != null) {
        _openedFor = spaceId;
        // build 중에 옮기지 않는다 — 프레임이 끝난 뒤.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) context.go('/s/$spaceId/c/$target');
        });
      }
    }

    return ColoredBox(
      color: nx.colors.bgBase,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 좁은 셸에서는 이 머리가 채널 패널(스페이스 바꾸기 · 레일)을 여는 길이다.
          ShellHeader(title: space?.name ?? '대화'),
          Expanded(
            child: scope != null
                ? ChannelPaneList(showWorkSection: !scope.hasTabs)
                : _HomeEmpty(spaceId: spaceId),
          ),
        ],
      ),
    );
  }
}

/// 넓은 셸에서 곧장 열 채널이 없을 때(볼 수 있는 채널이 하나도 없다 · 아직 받는 중).
/// 할 일을 보인다 — 만들 수 있으면 만들기, 아니면 DM.
class _HomeEmpty extends ConsumerWidget {
  const _HomeEmpty({required this.spaceId});

  final String? spaceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final channels = ref.watch(channelsProvider).value;
    final groups = ref.watch(channelGroupsProvider);
    // 받는 중이거나 곧 옮겨 갈 참이면 비워 둔다 — 빈 화면 문구가 한 번 비쳤다 사라지지 않게.
    if (channels == null || firstHomeChannel(groups) != null) {
      return const SizedBox.shrink();
    }
    return const NxEmptyState(
      title: '아직 채널이 없습니다',
      description: '왼쪽 목록의 + 로 채널을 만들거나, 다이렉트 메시지로 대화를 시작하세요.',
    );
  }
}

/// 곧장 열 첫 채널 — 사이드바에 보이는 순서대로 **글 채널만** 본다. DM 은 남의 대화가 첫
/// 화면이면 어색하고, 다른 종류(음성 등)는 여는 순간 그 채널의 동작이 시작될 수 있다.
/// 마지막으로 본 채널은 종류를 가리지 않는다 — 사람이 직접 고른 곳이다.
Channel? firstHomeChannel(List<ChannelGroup> groups) {
  for (final group in groups) {
    for (final channel in group.channels) {
      if (channel.kind == 'text') return channel;
    }
  }
  return null;
}

/// 설정 창의 틀(14단계 설계 D2). **폭 분기는 이 파일에서만 한다**는 규칙을 지키려고
/// 셸 밖 화면이지만 여기에 둔다.
///
/// - 태블릿 · 데스크톱: 왼쪽 목록 + 오른쪽 내용 + 오른쪽 위 닫기(디스코드)
/// - 모바일: 섹션을 고르지 않았으면 목록, 골랐으면 그 섹션 + 뒤로
class SettingsFrame extends StatelessWidget {
  const SettingsFrame({
    super.key,
    required this.nav,
    required this.content,
    required this.fallback,
    required this.onClose,
    required this.onBack,
    this.title = '설정',
  });

  /// 좁은 화면 머리 줄의 제목 — 「설정」 또는 「스페이스 설정」(16단계).
  final String title;
  final Widget nav;

  /// 고른 섹션. null 이면 모바일은 목록을, 넓은 화면은 [fallback] 을 보인다.
  final Widget? content;
  final Widget fallback;
  final VoidCallback onClose;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final c = NxTheme.of(context).colors;
    if (Layout.ofContext(context) == Layout.mobile) {
      final body = content;
      return NxPage(
        // 제목은 늘 「설정」이다 — 섹션 이름은 본문 머리가 이미 크게 보인다.
        header: NxHeader(
          title: title,
          leading: body == null
              ? NxIconButton(
                  icon: NxIcons.close,
                  label: '설정 닫기',
                  onPressed: onClose,
                )
              : NxIconButton(
                  icon: NxIcons.back,
                  label: '뒤로',
                  onPressed: onBack,
                ),
        ),
        body: SettingsInsets(
          insets: const EdgeInsets.fromLTRB(
            NxSpacing.sp7,
            NxSpacing.sp8,
            NxSpacing.sp7,
            NxSpacing.sp9,
          ),
          child: body ?? nav,
        ),
      );
    }

    return NxPage(
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 260,
            child: ColoredBox(color: c.bgSurface, child: nav),
          ),
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(child: content ?? fallback),
                Positioned(
                  top: NxSpacing.sp9,
                  right: NxSpacing.sp9,
                  child: _CloseEsc(onPressed: onClose),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 설정 닫기 — 동그란 × 아래 `ESC`(디스코드 · 캔버스 「설정」).
class _CloseEsc extends StatelessWidget {
  const _CloseEsc({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final nx = NxTheme.of(context);
    final c = nx.colors;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        NxPressable(
          onPressed: onPressed,
          semanticLabel: '설정 닫기',
          focusRingRadius: NxRadius.full,
          builder: (context, s) => AnimatedContainer(
            duration: NxMotion.micro,
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: s.hovered ? c.bgElevated : NxColors.transparent,
              border: Border.all(
                color: s.hovered ? c.textSecondary : c.borderStrong,
              ),
            ),
            child: NxIcon(
              NxIcons.close,
              size: NxIconSize.sm,
              color: s.hovered ? c.textPrimary : c.textSecondary,
            ),
          ),
        ),
        const SizedBox(height: NxSpacing.sp3),
        ExcludeSemantics(
          child: Text(
            'ESC',
            // 선 토큰(borderStrong)을 글자에 쓰면 라이트에서 2.0:1 이었다 — 글자는 글자 토큰으로.
            style: nx.text.mono,
          ),
        ),
      ],
    );
  }
}
