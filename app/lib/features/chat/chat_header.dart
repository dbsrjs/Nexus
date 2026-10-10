/// 채널 · DM 머리 줄과 그 안의 버튼(고정 메시지 · 파일 · 설정 · 연결 상태).
/// `chat_screen.dart` 에서 2026-10-06 에 떼어 냈다 — 1,200줄 넘던 파일을 머리 줄 · 메시지 줄 · 화면으로 나눴다.
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../ui/ui.dart';
import '../../domain/models/channel.dart';
import '../channel/channel_controller.dart';
import '../channel/dm.dart';
import '../realtime/socket_controller.dart';
import '../space/space_controller.dart';
import 'message_controller.dart';
import '../shell/app_shell.dart';
import 'selection_app_bar.dart';
import '../channel_settings/channel_settings_controller.dart';
import 'message_tile.dart';

class ChannelHeader extends StatelessWidget {
  const ChannelHeader({
    super.key,
    required this.name,
    this.topic,
    required this.onAsk,
  });

  final String name;
  final String? topic;

  /// 이 채널의 최근 대화를 붙여 AI 패널을 연다.
  final VoidCallback onAsk;

  @override
  Widget build(BuildContext context) {
    final nx = NxTheme.of(context);
    final c = nx.colors;
    final compact = isCompactShell(context);
    return Container(
      // 선택 모드로 바뀔 때 쓰는 SelectionAppBar 와 높이를 맞춘다 — 한쪽만
      // 고치면 전환할 때 본문이 튄다. 상수는 그쪽이 원본이다.
      height: SelectionAppBar.height,
      padding: const EdgeInsets.only(left: NxSpacing.sp6, right: NxSpacing.sp4),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: c.divider)),
      ),
      child: Row(
        children: [
          // 좁은 셸에서는 채널 이름이 곧 채널 패널을 여는 버튼이다(15단계 D12).
          Flexible(
            flex: 0,
            child: ShellPaneTrigger(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '#',
                    style: nx.text.mono.copyWith(fontSize: NxFontSize.body),
                  ),
                  const SizedBox(width: NxSpacing.sp3),
                  Flexible(
                    child: Semantics(
                      header: true,
                      child: Text(
                        name,
                        overflow: TextOverflow.ellipsis,
                        style: nx.text.header,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // 좁은 셸은 주제를 뺀다 — 폭 390 에 아이콘 넷 · 점 · 주제가 한 줄에 몰렸다.
          if (topic != null && topic!.isNotEmpty && !compact) ...[
            const SizedBox(width: NxSpacing.sp5),
            Expanded(
              child: Text(
                topic!,
                overflow: TextOverflow.ellipsis,
                style: nx.text.secondary,
              ),
            ),
          ] else
            const Spacer(),
          NxIconButton(icon: NxIcons.ai, label: 'AI에게 묻기', onPressed: onAsk),
          if (compact)
            const _MoreMenu(withSettings: true)
          else ...[
            const _PinnedButton(),
            const _ChannelSettingsButton(),
            const _FilesButton(),
          ],
          const _ConnectionDot(),
        ],
      ),
    );
  }
}

/// DM 의 머리 줄(17단계 D12) — `#이름` 대신 상대 아바타 · 이름. 채널 설정이 없다(D7).
class DmHeader extends ConsumerWidget {
  const DmHeader({super.key, required this.channel, required this.onAsk});

  final Channel channel;
  final VoidCallback onAsk;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nx = NxTheme.of(context);
    final c = nx.colors;
    final members = ref.watch(memberProfilesProvider);
    final peer = members[channel.dmUserId];
    final name = dmPeerName(members, channel);
    final compact = isCompactShell(context);
    return Container(
      height: SelectionAppBar.height,
      padding: const EdgeInsets.only(left: NxSpacing.sp6, right: NxSpacing.sp4),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: c.divider)),
      ),
      child: Row(
        children: [
          // flex 0 — 뒤의 Spacer 와 자리를 반씩 나누면 넓은 화면에서도 이름이 잘린다(Android 에서 보였다).
          Flexible(
            flex: 0,
            child: ShellPaneTrigger(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DmAvatar(
                    userId: channel.dmUserId ?? channel.id,
                    name: name,
                    avatarUrl: peer?.avatarUrl,
                    size: 24,
                  ),
                  const SizedBox(width: NxSpacing.sp4),
                  Flexible(
                    child: Semantics(
                      header: true,
                      child: Text(
                        name,
                        overflow: TextOverflow.ellipsis,
                        style: nx.text.header,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),
          NxIconButton(icon: NxIcons.ai, label: 'AI에게 묻기', onPressed: onAsk),
          if (compact)
            const _MoreMenu(withSettings: false)
          else ...[
            const _PinnedButton(),
            const _FilesButton(),
          ],
          const _ConnectionDot(),
        ],
      ),
    );
  }
}

/// 채널 설정 창을 연다(16단계 D16) — 개요는 누구나 보고, 명단 · 권한은 창이 역할로 가린다.
/// 섹션 없는 주소로 간다 — 넓은 화면은 `SettingsFrame` 이 첫 섹션을, 좁은 화면은 목록을 보인다.
class _ChannelSettingsButton extends ConsumerWidget {
  const _ChannelSettingsButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spaceId = ref.watch(currentSpaceIdProvider);
    final channelId = ref.watch(currentChannelIdProvider);
    if (spaceId == null || channelId == null) return const SizedBox.shrink();
    return NxIconButton(
      icon: NxIcons.settings,
      label: '채널 설정',
      onPressed: () =>
          context.go(channelSettingsLocation(spaceId, channelId, null)),
    );
  }
}

/// 실시간 연결 표시 — **끊겼을 때만** 보인다.
///
/// 끊겨 있으면 화면은 그대로 보이지만 **새 메시지가 오지 않는다.** 그 상태를
/// 사용자가 알 수 있어야 한다 — 조용히 멈춘 채팅은 버그로 오인된다. 붙어 있을 때 늘 떠 있던
/// 초록 점은 「무엇의 상태인가」만 궁금하게 했다(2026-10-10 UI/UX 검토) — 정상은 말하지 않는다.
class _ConnectionDot extends ConsumerWidget {
  const _ConnectionDot();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connected = ref.watch(socketConnectedProvider);
    if (connected) return const SizedBox.shrink();
    final nx = NxTheme.of(context);
    final c = nx.colors;
    const message = '연결 끊김 — 새 메시지가 오지 않습니다';

    return NxTooltip(
      message: message,
      child: Semantics(
        label: message,
        child: Padding(
          padding: const EdgeInsets.only(left: NxSpacing.sp3),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: c.danger,
                ),
              ),
              const SizedBox(width: NxSpacing.sp2),
              ExcludeSemantics(
                child: Text(
                  '연결 끊김',
                  style: nx.text.meta.copyWith(color: c.danger),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 좁은 셸의 「⋯」 — 고정된 메시지 · 파일 · 채널 설정을 한 버튼에 접는다.
class _MoreMenu extends ConsumerWidget {
  const _MoreMenu({required this.withSettings});

  /// 채널 설정 항목을 둘지(DM 에는 설정이 없다, 17단계 D7).
  final bool withSettings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spaceId = ref.watch(currentSpaceIdProvider);
    final channelId = ref.watch(currentChannelIdProvider);
    return NxMenu(
      entries: [
        NxMenuItem('고정된 메시지', onSelected: () => _showPinned(context, ref)),
        NxMenuItem(
          '파일',
          onSelected: spaceId == null
              ? null
              : () => context.go('/s/$spaceId/files'),
        ),
        if (withSettings && spaceId != null && channelId != null)
          NxMenuItem(
            '채널 설정',
            onSelected: () =>
                context.go(channelSettingsLocation(spaceId, channelId, null)),
          ),
      ],
      anchorBuilder: (context, toggle) =>
          NxIconButton(icon: NxIcons.more, label: '더 보기', onPressed: toggle),
    );
  }
}

/// 채널 헤더의 고정 목록 버튼. 누르면 패널로 목록을 연다.
class _PinnedButton extends ConsumerWidget {
  const _PinnedButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return NxIconButton(
      icon: NxIcons.pin,
      label: '고정된 메시지',
      onPressed: () => _showPinned(context, ref),
    );
  }
}

/// 스페이스 파일 목록으로 가는 버튼.
///
/// 채널이 아니라 **스페이스** 단위인 이유는 파일을 찾을 때 어느 채널에
/// 올렸는지 기억하지 못하는 편이 흔해서다. 서버가 볼 수 있는 채널의 것만 준다.
class _FilesButton extends ConsumerWidget {
  const _FilesButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spaceId = ref.watch(currentSpaceIdProvider);
    return NxIconButton(
      icon: NxIcons.files,
      label: '파일',
      onPressed: spaceId == null ? null : () => context.go('/s/$spaceId/files'),
    );
  }
}

/// 고정 목록 패널.
///
/// 캐시를 거치지 않고 열 때마다 서버에서 받는다 — 자주 여는 화면이 아니고,
/// 없다고 대화를 읽는 데 지장이 없다.
Future<void> _showPinned(BuildContext context, WidgetRef ref) async {
  final messages = await ref.read(messageActionsProvider).pinnedMessages();
  if (!context.mounted) return;

  await NxDialog.panel<void>(
    context,
    title: '고정된 메시지',
    width: 560,
    builder: (panelContext) => messages.isEmpty
        ? Padding(
            padding: const EdgeInsets.fromLTRB(
              NxSpacing.sp7,
              0,
              NxSpacing.sp7,
              NxSpacing.sp7,
            ),
            child: Text(
              '아직 고정된 메시지가 없습니다.',
              style: NxTheme.of(panelContext).text.secondary,
            ),
          )
        : ListView.builder(
            shrinkWrap: true,
            padding: const EdgeInsets.only(bottom: NxSpacing.sp6),
            itemCount: messages.length,
            itemBuilder: (_, i) =>
                MessageTile(message: messages[i], grouped: false),
          ),
  );
}
