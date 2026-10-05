import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/api/api_failure.dart';
import '../../domain/models/channel.dart';
import '../../ui/ui.dart';
import '../notifications/notifications_controller.dart';
import '../space/space_controller.dart';
import 'settings_controller.dart';
import 'settings_widgets.dart';

/// 알림 — **종류별 스위치**(18단계 N23)와 **채널 음소거**(14단계 D17 · D18).
///
/// 동작하지 않는 스위치는 두지 않는다(CLAUDE.md §3-7). 푸시 · 데스크톱 알림은
/// 그것을 만드는 단계(«마지막»)가 이 섹션에 더한다. 그래서 설명도 **지금 일어나는
/// 효과**만 적는다 — 스위치는 알림함(인앱)에만 듣는다.
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
        const SettingsLabel('알림함에 받을 것'),
        Text(
          '끄면 그 종류의 새 알림이 알림함에 오지 않습니다. 이미 온 알림은 남습니다.',
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
                      ? NxIcon(NxIcons.lock, size: 13, color: c.textSecondary)
                      : Text('#', style: nx.text.mono.copyWith(fontSize: 14)),
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
final notificationSettingsProvider = FutureProvider.autoDispose<NotificationSettings>(
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

  Future<void> _set({bool? mentions, bool? broadcast, bool? dms, bool? replies}) async {
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
      final saved = await ref.read(notificationsApiProvider).updateSettings(
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

    Widget row(String title, String hint, bool value, ValueChanged<bool> onChanged) => Padding(
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
        row('@channel · @everyone', '채널 전체를 불렀을 때', s.broadcast, (v) => _set(broadcast: v)),
        row('다이렉트 메시지', 'DM 에 새 메시지가 왔을 때', s.dms, (v) => _set(dms: v)),
        row('스레드 답글', '내 글에 답글이 달렸을 때', s.replies, (v) => _set(replies: v)),
        if (_error != null) SettingsError(_error!),
      ],
    );
  }
}
