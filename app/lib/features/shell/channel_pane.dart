import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/breakpoints.dart';
import '../../ui/ui.dart';
import '../channel/channel_list.dart';
import '../notifications/notifications_controller.dart';
import '../space/space_controller.dart';
import '../space/space_menu.dart';
import 'space_rail.dart';

/// 가운데 240px — 스페이스 이름 헤더 + 작업 갈래 + 카테고리/채널 목록.
class ChannelPane extends ConsumerWidget {
  const ChannelPane({
    super.key,
    this.onClose,
    this.onChannelTap,
    this.showWorkSection = true,
    this.showAccountFooter = false,
  });

  /// 「작업」 갈래(알림 · 이슈 · 파일 · 저장소)를 그릴지. 아래 탭 줄이 같은 곳을 담는 모바일은 끈다.
  final bool showWorkSection;

  /// 레일이 없을 때(스페이스 하나) 맨 아래에 계정 · 스페이스 더하기를 둔다.
  final bool showAccountFooter;

  /// 밀려 나온 패널로 열렸을 때 닫는 방법. null 이면 닫기 버튼을 감춘다(데스크톱 3단).
  final VoidCallback? onClose;

  /// 밀려 나온 패널에서 채널 · 작업 갈래를 고르면 패널을 닫기 위한 콜백.
  final VoidCallback? onChannelTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nx = NxTheme.of(context);
    final c = nx.colors;
    final space = ref.watch(currentSpaceProvider);

    return Container(
      width: NexusPaneWidth.channels,
      color: c.bgSurface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 52,
            padding: EdgeInsets.only(
              left: NxSpacing.sp6,
              right: onClose == null ? NxSpacing.sp6 : NxSpacing.sp3,
            ),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: c.divider)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Semantics(
                    header: true,
                    // 이름을 누르면 스페이스 메뉴(16단계 설계 D6).
                    child: space == null
                        ? Text('…', style: nx.text.header)
                        : Align(
                            alignment: Alignment.centerLeft,
                            child: SpaceMenu(space: space),
                          ),
                  ),
                ),
                if (onClose != null)
                  NxIconButton(
                    icon: NxIcons.close,
                    label: '채널 목록 닫기',
                    onPressed: onClose,
                  ),
              ],
            ),
          ),
          Expanded(
            child: ChannelPaneList(
              showWorkSection: showWorkSection,
              onChannelTap: onChannelTap,
            ),
          ),
          if (showAccountFooter) const SpaceAccountFooter(),
        ],
      ),
    );
  }
}

/// 판의 목록 부분 — 「작업」 갈래 + 카테고리 · 채널 · DM. 판 머리 없이 따로 쓰는 곳이 있다:
/// 좁은 셸의 홈(채널을 아직 고르지 않은 「대화」)이 이것을 본문으로 그린다.
class ChannelPaneList extends ConsumerWidget {
  const ChannelPaneList({
    super.key,
    this.showWorkSection = true,
    this.onChannelTap,
  });

  final bool showWorkSection;
  final VoidCallback? onChannelTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final space = ref.watch(currentSpaceProvider);
    return ListView(
      padding: const EdgeInsets.symmetric(
        horizontal: NxSpacing.sp4,
        vertical: NxSpacing.sp5,
      ),
      children: [
        if (space != null && showWorkSection)
          _WorkSection(
            spaceId: space.id,
            sprintsEnabled: space.sprintsEnabled,
            onTap: onChannelTap,
          ),
        ChannelList(onChannelTap: onChannelTap),
      ],
    );
  }
}

/// 셸 안에서 갈 수 있는 곳 — 알림 · 이슈 · 스프린트 · 파일 · 저장소.
///
/// **글자만 둔다**(15단계 D5 — 목록 줄 앞 장식 아이콘을 두지 않는다). 이 판에는 이미
/// 채널이 카테고리로 묶여 있다. 구조를 새로 만드는 것이 아니라 있던 것을 끝까지 쓴다.
class _WorkSection extends ConsumerWidget {
  const _WorkSection({
    required this.spaceId,
    required this.sprintsEnabled,
    this.onTap,
  });

  final String spaceId;

  /// 스프린트를 끈 스페이스는 갈래를 감춘다(16단계 D32).
  final bool sprintsEnabled;

  /// 밀려 나온 패널에서 고르면 패널을 닫기 위한 콜백. 채널을 고를 때와 같다.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nx = NxTheme.of(context);
    final c = nx.colors;
    // 지금 어디에 있는지는 라우트가 안다. 셸이 따로 상태를 들지 않는다.
    final location = GoRouterState.of(context).uri.path;
    final unread = ref.watch(unreadNotificationsProvider);

    Widget item(String label, String suffix, {Widget? trailing}) {
      final path = '/s/$spaceId$suffix';
      final selected = location == path || location.startsWith('$path/');
      return Padding(
        padding: const EdgeInsets.only(bottom: NxSpacing.sp1),
        child: NxRow(
          title: label,
          dense: true,
          selected: selected,
          trailing: trailing,
          titleStyle: nx.text.sm.copyWith(
            color: selected ? c.textPrimary : c.textSecondary,
            fontWeight: selected ? FontWeight.w600 : null,
          ),
          onPressed: () {
            context.go(path);
            onTap?.call();
          },
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const PaneSectionTitle('작업', first: true),
        // 맨 위 — 놓친 것이 여기 모인다(18단계 N19). 0 이면 뱃지를 감춘다.
        item(
          '알림',
          '/notifications',
          trailing: unread > 0 ? NxBadge(count: unread) : null,
        ),
        // 화면 머리 · 모바일 탭과 같은 이름(「이슈」) — 세 곳이 세 이름이었다(2026-10-10 UI/UX 검토).
        item('이슈', '/issues'),
        if (sprintsEnabled) item('스프린트', '/sprints'),
        item('파일', '/files'),
        item('저장소', '/repos'),
      ],
    );
  }
}
