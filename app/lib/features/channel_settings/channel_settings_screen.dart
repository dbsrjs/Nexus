import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/models/space.dart';
import '../../ui/ui.dart';
import '../settings/settings_controller.dart';
import '../settings/settings_widgets.dart';
import '../shell/app_shell.dart';
import '../space/space_controller.dart';
import 'channel_settings_controller.dart';
import 'members_section.dart';
import 'overview_section.dart';
import 'permissions_section.dart';

/// 채널 설정 창(16단계 설계 D16). 셸 밖에 덮어서 연다 — 스페이스 설정 창과 같은 틀이다.
///
/// 채널은 **스페이스 id 로 받는 캐시**(`settingsChannelsProvider`)에서 찾는다 — 셸 밖이라
/// 현재 스페이스에 기대지 않는다. 볼 수 없게 되면(가려졌거나 명단에서 빠짐) 스페이스로 돌린다.
class ChannelSettingsScreen extends ConsumerWidget {
  const ChannelSettingsScreen({
    super.key,
    required this.spaceId,
    required this.channelId,
    this.section,
  });

  final String spaceId;
  final String channelId;
  final ChannelSettingsSection? section;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spaces = ref.watch(spacesProvider).value;
    final space = spaces?.where((s) => s.id == spaceId).firstOrNull;
    final channels = ref.watch(settingsChannelsProvider(spaceId)).value;
    final channel = channels?.where((c) => c.id == channelId).firstOrNull;

    if (space == null || channel == null) {
      if (spaces == null || channels == null) {
        return const NxPage(body: NxSkeleton(lines: 4));
      }
      // 목록에 없다 — 그렇다고 **곧바로 내보내지 않는다.** 이 캐시는 한동안 구독자가 없으면
      // Riverpod 이 멈춰 두었다가, 다시 깨어난 첫 값으로 옛 목록을 준다. 방금 만든 채널의
      // 설정을 열자마자 쫓겨났다(16-2 app:flow). 이유를 보이고, 새 값이 오면 저절로 바로잡힌다.
      return NxPage(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('이 채널을 볼 수 없습니다.', style: NxTheme.of(context).text.body),
              const SizedBox(height: NxSpacing.sp5),
              NxButton(
                label: '돌아가기',
                kind: NxButtonKind.secondary,
                onPressed: () => context.go(space == null ? '/spaces' : '/s/$spaceId'),
              ),
            ],
          ),
        ),
      );
    }

    final visible = ChannelSettingsSection.visibleFor(
      isPrivate: channel.isPrivate,
      role: space.role,
    );
    final asked = section;
    final current = asked == null ? null : (visible.contains(asked) ? asked : visible.first);
    void close() => context.go('/s/$spaceId/c/$channelId');

    Widget content(ChannelSettingsSection s) => switch (s) {
          ChannelSettingsSection.overview => OverviewSection(
              // 채널 값이 바뀌면 입력칸을 새 값으로 다시 채운다.
              key: ValueKey('${channel.name}|${channel.topic}|${channel.isPrivate}'),
              spaceId: spaceId,
              channel: channel,
              editable: space.role.atLeast(SpaceRole.admin),
            ),
          ChannelSettingsSection.members =>
            ChannelMembersSection(spaceId: spaceId, channelId: channelId, me: space.role),
          ChannelSettingsSection.permissions =>
            PermissionsSection(spaceId: spaceId, channelId: channelId),
        };

    return CallbackShortcuts(
      bindings: {const SingleActivator(LogicalKeyboardKey.escape): close},
      child: Focus(
        autofocus: true,
        child: SettingsFrame(
          title: '채널 설정',
          nav: SettingsNav(
            title: '# ${channel.name}',
            items: [
              for (final s in visible)
                (
                  label: s.label,
                  selected: s == current,
                  onPressed: () =>
                      context.go(channelSettingsLocation(spaceId, channelId, s)),
                ),
            ],
          ),
          content: current == null ? null : content(current),
          fallback: content(visible.first),
          onClose: close,
          onBack: () => context.go(channelSettingsLocation(spaceId, channelId, null)),
        ),
      ),
    );
  }
}
