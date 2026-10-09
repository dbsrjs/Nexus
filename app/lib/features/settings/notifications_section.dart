import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/api/api_failure.dart';
import '../../domain/models/channel.dart';
import '../../ui/ui.dart';
import '../desktop/desktop_shell.dart';
import '../desktop/os_notifications.dart';
import '../notifications/notifications_controller.dart';
import '../space/space_controller.dart';
import 'settings_controller.dart';
import 'settings_widgets.dart';

/// 알림 — **이 기기의 데스크톱 알림**(«마지막»), **종류별 스위치**(18단계 N23),
/// **채널 음소거**(14단계 D17 · D18).
///
/// 동작하지 않는 스위치는 두지 않는다(CLAUDE.md §3-7) — 데스크톱 알림을 못 띄우는
/// 기기(Android · iOS — 모바일 푸시는 이 단계에서 뺐다)에서는 스위치 대신 그 사실을 적는다.
/// 종류별 스위치는 서버가 알림을 만들지부터 정하므로 알림함과 데스크톱 알림에 함께 듣는다.
class NotificationsSection extends ConsumerStatefulWidget {
  const NotificationsSection({super.key, this.initialSpaceId});

  /// 설정을 연 스페이스. 없으면 첫 스페이스.
  final String? initialSpaceId;

  @override
  ConsumerState<NotificationsSection> createState() =>
      _NotificationsSectionState();
}

class _NotificationsSectionState extends ConsumerState<NotificationsSection> {
  String? _spaceId;
  final _pending = <String>{};
  String? _error;

  @override
  void initState() {
    super.initState();
    _spaceId = widget.initialSpaceId;
  }

  Future<void> _toggle(String spaceId, Channel channel, bool muted) async {
    setState(() {
      _pending.add(channel.id);
      _error = null;
    });
    try {
      final saved = await ref
          .read(settingsApiProvider)
          .setMuted(spaceId: spaceId, channelId: channel.id, muted: muted);
      await ref.read(appDatabaseProvider).setChannelMuted(channel.id, saved);
    } on ApiException catch (e) {
      _error = settingsMessageFor(e.failure);
    } finally {
      if (mounted) setState(() => _pending.remove(channel.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final nx = NxTheme.of(context);
    final spaces = ref.watch(spacesProvider).value ?? const [];
    final spaceId = _spaceId ?? (spaces.isEmpty ? null : spaces.first.id);

    return SettingsPage(
      title: '알림',
      children: [
        const SettingsLabel('이 기기'),
        const _DeviceSwitch(),
        const SettingsGap(),
        const SettingsLabel('받을 알림'),
        Text(
          '끄면 그 종류의 새 알림이 알림함에도 데스크톱 알림으로도 오지 않습니다. '
          '이미 온 알림은 남습니다.',
          style: nx.text.secondary,
        ),
        const SizedBox(height: NxSpacing.sp5),
        const _TypeSwitches(),
        const SettingsGap(),
        const SettingsLabel('채널 음소거'),
        Text(
          '음소거한 채널은 목록에서 흐리게 보이고 안 읽음 표시와 알림이 꺼집니다. '
          '나를 부른 멘션은 그대로 보이고 알립니다.',
          style: nx.text.secondary,
        ),
        const SizedBox(height: NxSpacing.sp6),
        if (spaces.length > 1) ...[
          NxSelect<String>(
            value: spaceId,
            options: [for (final space in spaces) (space.id, space.name)],
            onChanged: (id) => setState(() => _spaceId = id),
          ),
          const SizedBox(height: NxSpacing.sp5),
        ],
        if (spaceId == null)
          Text('속한 스페이스가 없습니다.', style: nx.text.secondary)
        else
          _ChannelSwitches(
            spaceId: spaceId,
            pending: _pending,
            onChanged: (channel, muted) => _toggle(spaceId, channel, muted),
          ),
        if (_error != null) SettingsError(_error!),
      ],
    );
  }
}

class _ChannelSwitches extends ConsumerWidget {
  const _ChannelSwitches({
    required this.spaceId,
    required this.pending,
    required this.onChanged,
  });

  final String spaceId;
  final Set<String> pending;
  final void Function(Channel channel, bool muted) onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nx = NxTheme.of(context);
    final c = nx.colors;
    final channels =
        ref.watch(settingsChannelsProvider(spaceId)).value ?? const [];
    return Column(
      children: [
        for (final channel in channels)
          SizedBox(
            height: 40,
            child: Row(
              children: [
                // 채널 앞 표시는 채널 목록과 같다 — `#` 는 글자, 비공개만 자물쇠.
                SizedBox(
                  width: 20,
                  child: channel.isPrivate
                      ? NxIcon(
                          NxIcons.lock,
                          size: NxIconSize.sm,
                          color: c.textSecondary,
                        )
                      : Text(
                          '#',
                          style: nx.text.mono.copyWith(
                            fontSize: NxFontSize.base,
                          ),
                        ),
                ),
                Expanded(
                  child: Text(
                    channel.name,
                    overflow: TextOverflow.ellipsis,
                    style: nx.text.base,
                  ),
                ),
                NxSwitch(
                  value: channel.muted,
                  label: '${channel.name} 음소거',
                  onChanged: pending.contains(channel.id)
                      ? null
                      : (v) => onChanged(channel, v),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// 알림 스위치(18단계 N9 · N23). 사용자 단위라 스페이스를 고르지 않는다. 캐시하지 않는다 —
/// 설정 창을 열 때 받는다.
final notificationSettingsProvider =
    FutureProvider.autoDispose<NotificationSettings>(
      (ref) => ref.watch(notificationsApiProvider).settings(),
    );

class _TypeSwitches extends ConsumerStatefulWidget {
  const _TypeSwitches();

  @override
  ConsumerState<_TypeSwitches> createState() => _TypeSwitchesState();
}

class _TypeSwitchesState extends ConsumerState<_TypeSwitches> {
  /// 저장된 값. 누르면 먼저 바꾸고, 응답으로 덮는다.
  NotificationSettings? _local;
  bool _saving = false;
  String? _error;

  Future<void> _set({
    bool? mentions,
    bool? broadcast,
    bool? dms,
    bool? replies,
  }) async {
    final before = _local;
    if (before == null) return;
    setState(() {
      _saving = true;
      _error = null;
      _local = NotificationSettings(
        mentions: mentions ?? before.mentions,
        broadcast: broadcast ?? before.broadcast,
        dms: dms ?? before.dms,
        replies: replies ?? before.replies,
      );
    });
    try {
      final saved = await ref
          .read(notificationsApiProvider)
          .updateSettings(
            mentions: mentions,
            broadcast: broadcast,
            dms: dms,
            replies: replies,
          );
      if (mounted) setState(() => _local = saved);
    } on ApiException catch (e) {
      // 저장하지 못한 값을 켜진 채로 두면 거짓말이다 — 되돌리고 곁에 남긴다.
      if (mounted) {
        setState(() {
          _local = before;
          _error = settingsMessageFor(e.failure);
        });
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final nx = NxTheme.of(context);
    final remote = ref.watch(notificationSettingsProvider);
    _local ??= remote.value;
    final s = _local;

    if (s == null) {
      if (remote.hasError) {
        final failure = remote.error is ApiException
            ? (remote.error as ApiException).failure
            : ApiFailure.server;
        return SettingsError(settingsMessageFor(failure));
      }
      return const NxSkeleton(lines: 4, lineHeight: 28);
    }

    Widget row(
      String title,
      String hint,
      bool value,
      ValueChanged<bool> onChanged,
    ) => Padding(
      padding: const EdgeInsets.symmetric(vertical: NxSpacing.sp3),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: nx.text.base),
                Text(hint, style: nx.text.meta),
              ],
            ),
          ),
          NxSwitch(
            value: value,
            label: '$title 알림',
            onChanged: _saving ? null : onChanged,
          ),
        ],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        row('멘션', '누군가 나를 @이름 으로 불렀을 때', s.mentions, (v) => _set(mentions: v)),
        row(
          '@channel · @everyone',
          '채널 전체를 불렀을 때',
          s.broadcast,
          (v) => _set(broadcast: v),
        ),
        row('다이렉트 메시지', 'DM 에 새 메시지가 왔을 때', s.dms, (v) => _set(dms: v)),
        row('스레드 답글', '내 글에 답글이 달렸을 때', s.replies, (v) => _set(replies: v)),
        if (_error != null) SettingsError(_error!),
      ],
    );
  }
}

/// 이 기기에서 데스크톱 알림을 띄울지(«마지막»). 값은 기기에 둔다 — 서버에 묻지 않는다.
///
/// 웹은 브라우저의 허락이 따로 있다. 스위치는 「켜 두었고 **허락도 받았다**」일 때만 켜져
/// 보인다 — 켜져 보이는데 알림이 안 오는 것이 가장 나쁜 거짓말이다.
class _DeviceSwitch extends ConsumerStatefulWidget {
  const _DeviceSwitch();

  @override
  ConsumerState<_DeviceSwitch> createState() => _DeviceSwitchState();
}

class _DeviceSwitchState extends ConsumerState<_DeviceSwitch> {
  bool _asking = false;

  Future<void> _turnOn(DesktopShell shell) async {
    if (shell.permission == NotifyPermission.notYet) {
      setState(() => _asking = true);
      // 누른 직후에 묻는다 — 브라우저는 사용자 동작 없이 묻는 요청을 거절한다.
      await shell.requestPermission();
      if (!mounted) return;
      setState(() => _asking = false);
    }
    if (shell.permission == NotifyPermission.granted) {
      ref.read(desktopNotifyEnabledProvider.notifier).set(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final nx = NxTheme.of(context);
    final shell = ref.watch(desktopShellProvider);
    final enabled = ref.watch(desktopNotifyEnabledProvider);
    final permission = shell.permission;

    if (shell.kind == DesktopShellKind.none) {
      return Text(
        '이 기기는 데스크톱 알림을 띄우지 않습니다. 새 알림은 알림함에서 확인하세요.',
        style: nx.text.secondary,
      );
    }

    final hint = switch (shell.kind) {
      DesktopShellKind.windows =>
        'Nexus 창을 보고 있지 않을 때 Windows 알림으로 띄웁니다. '
            '창을 닫아도 트레이에서 계속 받고, 끝내려면 트레이 메뉴의 「종료」를 누릅니다.',
      _ => '이 탭을 보고 있지 않을 때 브라우저 알림으로 띄웁니다.',
    };
    final denied = permission == NotifyPermission.denied;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: NxSpacing.sp3),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('데스크톱 알림', style: nx.text.base),
                    Text(hint, style: nx.text.meta),
                  ],
                ),
              ),
              NxSwitch(
                value: enabled && permission == NotifyPermission.granted,
                label: '데스크톱 알림',
                onChanged: denied || _asking
                    ? null
                    : (v) => v
                          ? _turnOn(shell)
                          : ref
                                .read(desktopNotifyEnabledProvider.notifier)
                                .set(false),
              ),
            ],
          ),
        ),
        if (denied)
          // 한 번 거절하면 사이트가 다시 물을 수 없다 — 사용자가 직접 풀어야 한다.
          SettingsError(
            '브라우저가 이 사이트의 알림을 막고 있습니다. '
            '주소창 왼쪽의 사이트 설정에서 알림을 허용한 뒤 다시 켜세요.',
          ),
      ],
    );
  }
}
