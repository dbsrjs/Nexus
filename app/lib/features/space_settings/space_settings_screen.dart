import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../ui/ui.dart';
import '../settings/settings_widgets.dart';
import '../shell/app_shell.dart';
import '../space/space_controller.dart';
import 'general_section.dart';
import 'invites_section.dart';
import 'members_section.dart';
import 'space_settings_controller.dart';

/// 스페이스 설정 창(16단계 설계 D5). 셸 밖에 덮어서 연다 — 사용자 설정 창과 같은 틀이다.
///
/// 폭 분기(두 단 · 한 단)는 `SettingsFrame`(app_shell.dart)이 한다. 섹션은 **내 역할로 볼 수
/// 있는 것만** 싣고, 볼 수 없는 섹션 주소로 들어오면 첫 섹션을 그린다.
class SpaceSettingsScreen extends ConsumerWidget {
  const SpaceSettingsScreen({super.key, required this.spaceId, this.section});

  final String spaceId;

  /// null 이면 목록 — 모바일에서 들어온 첫 화면이다. 넓은 화면은 첫 섹션을 연다.
  final SpaceSettingsSection? section;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spaces = ref.watch(spacesProvider).value;
    final space = spaces?.where((s) => s.id == spaceId).firstOrNull;

    if (space == null) {
      // 목록을 받았는데 없다 — 나갔거나 내보내졌다. build 중에 옮기지 않는다(CLAUDE.md §2).
      if (spaces != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) context.go('/spaces');
        });
      }
      return const NxPage(body: NxSkeleton(lines: 4));
    }

    final visible = SpaceSettingsSection.visibleFor(space.role);
    final asked = section;
    final current = asked == null
        ? null
        : (visible.contains(asked) ? asked : visible.first);
    void close() => context.go('/s/$spaceId');

    Widget content(SpaceSettingsSection s) => switch (s) {
          SpaceSettingsSection.general => GeneralSection(space: space),
          SpaceSettingsSection.members =>
            MembersSection(spaceId: spaceId, me: space.role),
          SpaceSettingsSection.invites => InvitesSection(spaceId: spaceId),
        };

    return CallbackShortcuts(
      bindings: {const SingleActivator(LogicalKeyboardKey.escape): close},
      child: Focus(
        autofocus: true,
        child: SettingsFrame(
          title: '스페이스 설정',
          nav: SettingsNav(
            title: space.name,
            items: [
              for (final s in visible)
                (
                  label: s.label,
                  selected: s == current,
                  onPressed: () => context.go(spaceSettingsLocation(spaceId, s)),
                ),
            ],
          ),
          content: current == null ? null : content(current),
          fallback: content(visible.first),
          onClose: close,
          onBack: () => context.go(spaceSettingsLocation(spaceId, null)),
        ),
      ),
    );
  }
}
