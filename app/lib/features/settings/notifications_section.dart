import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../data/api/api_failure.dart';
import '../../domain/models/channel.dart';
import '../space/space_controller.dart';
import 'settings_controller.dart';
import 'settings_widgets.dart';

/// 알림 — 지금은 **채널 음소거**뿐이다(14단계 설계 D17 · D18).
///
/// 동작하지 않는 스위치는 두지 않는다(CLAUDE.md §3-7). 푸시 · 데스크톱 알림은
/// 그것을 만드는 단계(«마지막»)가 이 섹션에 더한다. 그래서 설명도 **지금 일어나는
/// 효과**만 적는다.
class NotificationsSection extends ConsumerStatefulWidget {
  const NotificationsSection({super.key, this.initialSpaceId});

  /// 설정을 연 스페이스. 없으면 첫 스페이스.
  final String? initialSpaceId;

  @override
  ConsumerState<NotificationsSection> createState() => _NotificationsSectionState();
}

class _NotificationsSectionState extends ConsumerState<NotificationsSection> {
  String? _spaceId;
  final _pending = <String>{};
  SettingsNotice? _notice;

  @override
  void initState() {
    super.initState();
    _spaceId = widget.initialSpaceId;
  }

  Future<void> _toggle(String spaceId, Channel channel, bool muted) async {
    setState(() {
      _pending.add(channel.id);
      _notice = null;
    });
    try {
      final saved = await ref.read(settingsApiProvider).setMuted(
            spaceId: spaceId,
            channelId: channel.id,
            muted: muted,
          );
      await ref.read(appDatabaseProvider).setChannelMuted(channel.id, saved);
    } on ApiException catch (e) {
      _notice = SettingsNotice.error(settingsMessageFor(e.failure));
    } finally {
      if (mounted) setState(() => _pending.remove(channel.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spaces = ref.watch(spacesProvider).value ?? const [];
    final spaceId = _spaceId ?? (spaces.isEmpty ? null : spaces.first.id);

    return SettingsPage(
      title: '알림',
      children: [
        const SettingsLabel('채널 음소거'),
        Text(
          '음소거한 채널은 목록에서 흐리게 보이고 안 읽음 표시가 꺼집니다. '
          '나를 부른 멘션은 그대로 보입니다.',
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: NexusSpacing.sp6),
        if (spaces.length > 1)
          DropdownButton<String>(
            value: spaceId,
            isExpanded: true,
            items: [
              for (final space in spaces)
                DropdownMenuItem(value: space.id, child: Text(space.name)),
            ],
            onChanged: (id) => setState(() => _spaceId = id),
          ),
        if (spaceId == null)
          Text('속한 스페이스가 없습니다.', style: theme.textTheme.bodySmall)
        else
          _ChannelSwitches(
            spaceId: spaceId,
            pending: _pending,
            onChanged: (channel, muted) => _toggle(spaceId, channel, muted),
          ),
        if (_notice != null) SettingsNoticeText(_notice!),
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
    final channels = ref.watch(settingsChannelsProvider(spaceId)).value ?? const [];
    return Column(
      children: [
        for (final channel in channels)
          SwitchListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            secondary: Icon(channel.isPrivate ? Icons.lock_outline : Icons.tag, size: 18),
            title: Text(channel.name),
            value: channel.muted,
            onChanged: pending.contains(channel.id) ? null : (v) => onChanged(channel, v),
          ),
      ],
    );
  }
}
