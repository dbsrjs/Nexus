import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/api/api_failure.dart';
import '../../domain/models/channel_access.dart';
import '../../ui/ui.dart';
import '../settings/settings_widgets.dart';
import '../space/members_controller.dart';
import '../space/space_controller.dart';
import '../space_settings/space_settings_controller.dart';
import 'channel_settings_controller.dart';

/// 채널 설정 「권한」 — 공개 채널의 역할별 예외(16단계 D21 · D24). admin+ 에게만 보인다.
///
/// 손님 · 멤버 두 줄만 있다 — 관리자 · 소유자는 늘 보고 보낸다(관리자가 스스로 잠기는 길을
/// 없앤다). 「보기」를 끄면 「보내기」도 뜻을 잃어 함께 꺼진다.
class PermissionsSection extends ConsumerStatefulWidget {
  const PermissionsSection({super.key, required this.spaceId, required this.channelId});

  final String spaceId;
  final String channelId;

  @override
  ConsumerState<PermissionsSection> createState() => _PermissionsSectionState();
}

class _PermissionsSectionState extends ConsumerState<PermissionsSection> {
  bool _busy = false;

  ChannelKey get _key => (spaceId: widget.spaceId, channelId: widget.channelId);

  Future<void> _run(Future<void> Function() call) async {
    setState(() => _busy = true);
    try {
      await call();
      ref.invalidate(channelPermissionsProvider(_key));
      // 내 채널 목록의 canSend 는 서버가 rooms:invalidate 로 다시 받게 한다. 그래도 바로 맞춘다.
      await ref.read(workspaceRepositoryProvider).refreshChannels(widget.spaceId);
    } on ApiException catch (e) {
      if (mounted) NxToast.show(context, messageFor(e.failure), kind: NxToastKind.error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _set(RolePermission p, {required bool canView, required bool canSend}) => _run(
        () => ref.read(channelsApiProvider).setPermission(
              widget.spaceId,
              widget.channelId,
              p.role,
              canView: canView,
              // 보지 못하는데 보낼 수는 없다.
              canSend: canView && canSend,
            ),
      );

  void _reset(RolePermission p) => _run(
        () => ref.read(channelsApiProvider).resetPermission(widget.spaceId, widget.channelId, p.role),
      );

  @override
  Widget build(BuildContext context) {
    final nx = NxTheme.of(context);
    final perms = ref.watch(channelPermissionsProvider(_key));

    return SettingsPage(
      title: '권한',
      children: [
        Text(
          '역할마다 이 채널을 가리거나 읽기 전용으로 만듭니다. 관리자와 소유자는 언제나 보고 보냅니다. '
          '읽기 전용이어도 리액션은 남길 수 있습니다.',
          style: nx.text.secondary,
        ),
        const SizedBox(height: NxSpacing.sp7),
        if (perms.hasError)
          SettingsError(errorMessageOf(perms.error))
        else if (!perms.hasValue)
          const NxSkeleton(lines: 2, lineHeight: 56)
        else
          for (final p in perms.value!)
            PermissionRow(
              permission: p,
              enabled: !_busy,
              onView: (v) => _set(p, canView: v, canSend: p.canSend || v),
              onSend: (v) => _set(p, canView: p.canView, canSend: v),
              onReset: () => _reset(p),
            ),
      ],
    );
  }
}

/// 한 역할의 줄 — 「보기」 · 「보내기」 스위치와 「기본값으로」.
class PermissionRow extends StatelessWidget {
  const PermissionRow({
    super.key,
    required this.permission,
    required this.enabled,
    required this.onView,
    required this.onSend,
    required this.onReset,
  });

  final RolePermission permission;
  final bool enabled;
  final ValueChanged<bool> onView;
  final ValueChanged<bool> onSend;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final nx = NxTheme.of(context);
    final p = permission;
    final role = roleLabel(p.role);

    Widget toggle(String label, bool value, ValueChanged<bool>? onChanged) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: nx.text.secondary),
            const SizedBox(width: NxSpacing.sp3),
            NxSwitch(value: value, label: '$role $label', onChanged: onChanged),
          ],
        );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: NxSpacing.sp4),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: NxSpacing.sp7,
        runSpacing: NxSpacing.sp4,
        children: [
          SizedBox(
            width: 120,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(role, style: nx.text.strong),
                Text(p.explicit ? '예외 적용 중' : '기본값', style: nx.text.meta),
              ],
            ),
          ),
          toggle('보기', p.canView, enabled ? onView : null),
          // 가린 역할은 보내기를 고를 뜻이 없다 — 꺼진 채로 둔다.
          toggle('보내기', p.canSend, enabled && p.canView ? onSend : null),
          if (p.explicit)
            NxButton(
              label: '기본값으로',
              kind: NxButtonKind.ghost,
              size: NxSize.sm,
              onPressed: enabled ? onReset : null,
            ),
        ],
      ),
    );
  }
}
