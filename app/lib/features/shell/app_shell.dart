import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/breakpoints.dart';
import '../../domain/models/channel.dart';
import '../../shared/widgets/nexus_avatar.dart';
import '../../ui/ui.dart';
import '../channel/channel_controller.dart';
import '../settings/settings_widgets.dart';
import '../space/space_actions.dart';
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

  /// 탭은 셸 안의 갈래를 고른다. **`go` 로 민다** — 넷 다 셸 안에 있다.
  void _onTab(int index) {
    final base = '/s/${widget.spaceId}';
    switch (index) {
      case 0:
        // 보던 채널로 돌아간다. 고른 채널이 없으면 셸 홈이다.
        final channelId = widget.channelId;
        context.go(channelId == null ? base : '$base/c/$channelId');
      case 1:
        context.go('$base/issues');
      case 2:
        context.go('$base/repos');
      case 3:
        context.go('$base/files');
    }
  }

  @override
  Widget build(BuildContext context) {
    // 지금 보고 있는 스페이스에서 빠졌으면 나가고 알린다(16단계 설계 D13). 소켓 리스너는
    // 화면을 모르므로 여기서 받는다. 메뉴의 「나가기」로 나온 경우도 같은 길이다.
    ref.listen<String?>(removedSpaceProvider, (_, removed) {
      if (removed == null || removed != widget.spaceId) return;
      ref.read(removedSpaceProvider.notifier).set(null);
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

/// 3단 고정.
class _DesktopShell extends StatelessWidget {
  const _DesktopShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    // 데스크톱 OS 에는 상태 표시줄이 없지만, **Android 태블릿은 폭이 1024dp 를
    // 넘으면 이 분기를 탄다.** NxPage 의 SafeArea 가 레일 · 채널 머리를 시계와
    // 겹치지 않게 한다.
    return NxPage(
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SpaceRail(),
          const ChannelPane(),
          const NxDivider(vertical: true),
          Expanded(child: child),
        ],
      ),
    );
  }
}

/// 밀려 나오는 패널을 여는 방법. **셸만 안다** — 좁은 셸이 깔고, 넓은 셸에는 없다.
class _PaneScope extends InheritedWidget {
  const _PaneScope({required this.open, required super.child});

  final VoidCallback open;

  @override
  bool updateShouldNotify(_PaneScope old) => false;
}

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

    return NxPressable(
      onPressed: scope.open,
      semanticLabel: '채널 바꾸기',
      builder: (context, s) => AnimatedContainer(
        duration: NxMotion.micro,
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          color: s.hovered || s.pressed
              ? c.bgElevated
              : const Color(0x00000000),
          borderRadius: BorderRadius.circular(NxRadius.md),
        ),
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
            const SizedBox(width: 6),
            NxIcon(NxIcons.chevronDown, size: 12, color: c.textSecondary),
          ],
        ),
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
              style: nx.text.title.copyWith(fontSize: 15),
            ),
          ),
        ),
      ),
      actions: actions,
    );
  }
}

/// 셸 안의 경로가 어느 탭에 속하는지(대화 0 · 이슈 1 · 저장소 2 · 파일 3).
///
/// **스프린트는 이슈 탭이다** — 보드 머리 줄에서 들어가는 갈래라, 빠뜨렸더니 스프린트
/// 화면에서 「대화」 탭이 켜져 있었다(Android 에서 발견).
int shellTabFor(String path) => switch (path) {
  final p when p.contains('/issues') || p.contains('/sprints') => 1,
  final p when p.contains('/repos') => 2,
  final p when p.contains('/files') => 3,
  _ => 0,
};

/// 태블릿 · 모바일 공용. 레일 + 채널 패널은 왼쪽에서 밀려 나온다.
class _CompactShell extends StatefulWidget {
  const _CompactShell({
    required this.showTabs,
    required this.child,
    this.onTab,
  });

  final bool showTabs;
  final Widget child;
  final ValueChanged<int>? onTab;

  @override
  State<_CompactShell> createState() => _CompactShellState();
}

class _CompactShellState extends State<_CompactShell> {
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
    const paneWidth = NexusPaneWidth.rail + NexusPaneWidth.channels;

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): () => _setOpen(false),
      },
      child: Stack(
        children: [
          Positioned.fill(
            child: _PaneScope(
              open: () => _setOpen(true),
              child: NxPage(
                body: widget.child,
                // 데스크톱 두 번째 판의 「작업」 갈래와 같은 곳을 담는다.
                bottom: widget.showTabs
                    ? NxTabBar(
                        tabs: const [
                          NxTab('대화'),
                          NxTab('이슈'),
                          NxTab('저장소'),
                          NxTab('파일'),
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
                        const SpaceRail(),
                        Expanded(
                          child: ChannelPane(
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
class ShellHome extends StatelessWidget {
  const ShellHome({super.key});

  @override
  Widget build(BuildContext context) {
    final nx = NxTheme.of(context);
    return ColoredBox(
      color: nx.colors.bgBase,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 좁은 셸에서는 이 머리가 채널 패널을 여는 길이다.
          const ShellHeader(title: '채널 고르기'),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(NxSpacing.sp6),
                child: Text(
                  '채널을 선택하세요',
                  textAlign: TextAlign.center,
                  style: nx.text.secondary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
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
              ? NxIconButton(icon: NxIcons.close, label: '설정 닫기', onPressed: onClose)
              : NxIconButton(icon: NxIcons.back, label: '뒤로', onPressed: onBack),
        ),
        body: SettingsInsets(
          insets: const EdgeInsets.fromLTRB(20, 24, 20, 32),
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
              color: s.hovered ? c.bgElevated : const Color(0x00000000),
              border: Border.all(color: s.hovered ? c.textSecondary : c.borderStrong),
            ),
            child: NxIcon(
              NxIcons.close,
              size: 14,
              color: s.hovered ? c.textPrimary : c.textSecondary,
            ),
          ),
        ),
        const SizedBox(height: 6),
        ExcludeSemantics(
          child: Text('ESC', style: nx.text.mono.copyWith(color: c.borderStrong)),
        ),
      ],
    );
  }
}
