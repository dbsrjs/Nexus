import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/api/api_failure.dart';
import '../../domain/models/channel_access.dart';
import '../../domain/models/space.dart';
import '../../shared/widgets/user_avatar.dart';
import '../../ui/ui.dart';
import '../auth/auth_controller.dart';
import '../settings/settings_widgets.dart';
import '../space/members_controller.dart';
import '../space/space_controller.dart';
import '../space_settings/space_settings_controller.dart';
import 'channel_settings_controller.dart';

/// 채널 설정 「멤버」 — 비공개 채널의 명단(16단계 D17~D20).
///
/// 들이기는 명단의 **member 이상**, 남을 빼기는 admin+, 본인은 언제나 나갈 수 있다 — 다만
/// **마지막 한 명은 나갈 수 없어** 버튼을 끄고 이유를 말한다(서버는 409).
class ChannelMembersSection extends ConsumerWidget {
  const ChannelMembersSection({
    super.key,
    required this.spaceId,
    required this.channelId,
    required this.me,
  });

  final String spaceId;
  final String channelId;
  final SpaceRole me;

  ChannelKey get _key => (spaceId: spaceId, channelId: channelId);

  Future<void> _run(
    BuildContext context,
    WidgetRef ref,
    Future<void> Function() call,
  ) async {
    try {
      await call();
      if (!context.mounted) return;
      ref.invalidate(channelMembersProvider(_key));
    } on ApiException catch (e) {
      if (context.mounted) {
        NxToast.show(context, messageFor(e.failure), kind: NxToastKind.error);
      }
    }
  }

  Future<void> _leave(BuildContext context, WidgetRef ref, String myId) async {
    final ok = await NxDialog.confirm(
      context,
      title: '이 채널에서 나갈까요?',
      body: '비공개 채널이라 다시 들어오려면 명단의 사람이 들여 줘야 합니다.',
      confirmLabel: '나가기',
      danger: true,
    );
    if (!ok || !context.mounted) return;
    // await 사이에 화면이 내려갈 수 있다(나간 채널이 목록에서 빠지면 셸이 옮긴다) — 미리 잡는다.
    final api = ref.read(channelsApiProvider);
    final repository = ref.read(workspaceRepositoryProvider);
    try {
      await api.removeMember(spaceId, channelId, myId);
      await repository.refreshChannels(spaceId);
      if (context.mounted) context.go('/s/$spaceId');
    } on ApiException catch (e) {
      if (context.mounted) {
        NxToast.show(context, messageFor(e.failure), kind: NxToastKind.error);
      }
    }
  }

  Future<void> _remove(
    BuildContext context,
    WidgetRef ref,
    ChannelMemberView m,
  ) async {
    final ok = await NxDialog.confirm(
      context,
      title: '${m.name} 님을 이 채널에서 뺄까요?',
      body: '이 채널의 메시지를 더는 볼 수 없습니다.',
      confirmLabel: '빼기',
      danger: true,
    );
    if (!ok || !context.mounted) return;
    await _run(
      context,
      ref,
      () => ref
          .read(channelsApiProvider)
          .removeMember(spaceId, channelId, m.userId),
    );
  }

  Future<void> _add(
    BuildContext context,
    WidgetRef ref,
    List<ChannelMemberView> current,
  ) async {
    final picked = await NxDialog.panel<List<String>>(
      context,
      title: '멤버 추가',
      builder: (_) => _AddMembersPicker(
        spaceId: spaceId,
        exclude: {for (final m in current) m.userId},
      ),
    );
    if (picked == null || picked.isEmpty || !context.mounted) return;
    await _run(
      context,
      ref,
      () =>
          ref.read(channelsApiProvider).addMembers(spaceId, channelId, picked),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myId = ref.watch(
      authControllerProvider.select(
        (a) => a is AuthSignedIn ? a.user.id : null,
      ),
    );
    final members = ref.watch(channelMembersProvider(_key));

    return SettingsPage(
      title: '멤버',
      children: [
        if (members.hasError)
          SettingsError(errorMessageOf(members.error))
        else if (!members.hasValue)
          const NxSkeleton(lines: 3, lineHeight: 48)
        else ...[
          Row(
            children: [
              // SettingsLabel 은 아래 여백을 품고 있어 버튼과 나란히 두면 글자가 위로 뜬다
              // (Android 에서 보였다). 같은 글꼴로 여백 없이 그린다.
              Expanded(
                child: Text(
                  '명단 ${members.value!.length}명',
                  style: NxTheme.of(
                    context,
                  ).text.meta.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              // 손님은 들일 수 없다(D17) — 버튼을 두지 않는다.
              if (me.atLeast(SpaceRole.member))
                NxButton(
                  label: '멤버 추가',
                  kind: NxButtonKind.secondary,
                  size: NxSize.sm,
                  onPressed: () => _add(context, ref, members.value!),
                ),
            ],
          ),
          const SizedBox(height: NxSpacing.sp4),
          for (final m in members.value!)
            _Row(
              member: m,
              action: memberRowAction(self: m.userId == myId, me: me),
              last: members.value!.length == 1,
              onLeave: () => _leave(context, ref, m.userId),
              onRemove: () => _remove(context, ref, m),
            ),
        ],
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.member,
    required this.action,
    required this.last,
    required this.onLeave,
    required this.onRemove,
  });

  final ChannelMemberView member;
  final MemberRowAction action;

  /// 명단의 마지막 한 명 — 나갈 수 없다(D18).
  final bool last;
  final VoidCallback onLeave;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final Widget? trailing = switch (action) {
      MemberRowAction.leave =>
        last
            ? Text('마지막 멤버는 나갈 수 없습니다', style: NxTheme.of(context).text.meta)
            : NxButton(
                label: '나가기',
                kind: NxButtonKind.ghost,
                size: NxSize.sm,
                onPressed: onLeave,
              ),
      MemberRowAction.remove => NxButton(
        label: '빼기',
        kind: NxButtonKind.ghost,
        size: NxSize.sm,
        onPressed: onRemove,
      ),
      MemberRowAction.none => null,
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: NxSpacing.sp1),
      child: NxRow(
        leading: UserAvatar(
          userId: member.userId,
          name: member.name,
          avatarUrl: member.avatarUrl,
          size: 32,
        ),
        title: member.name,
        subtitle: roleLabel(member.role),
        trailing: trailing,
      ),
    );
  }
}

/// 스페이스 멤버 중 아직 명단에 없는 사람을 고른다. 고른 id 목록을 돌려준다.
class _AddMembersPicker extends ConsumerStatefulWidget {
  const _AddMembersPicker({required this.spaceId, required this.exclude});

  final String spaceId;
  final Set<String> exclude;

  @override
  ConsumerState<_AddMembersPicker> createState() => _AddMembersPickerState();
}

class _AddMembersPickerState extends ConsumerState<_AddMembersPicker> {
  final _picked = <String>{};

  @override
  Widget build(BuildContext context) {
    final nx = NxTheme.of(context);
    final all = ref.watch(spaceMembersOfProvider(widget.spaceId));
    final candidates = (all.value ?? const [])
        .where((m) => !widget.exclude.contains(m.userId))
        .toList(growable: false);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        NxSpacing.sp7,
        0,
        NxSpacing.sp7,
        NxSpacing.sp7,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (all.hasError)
            SettingsError(errorMessageOf(all.error))
          else if (!all.hasValue)
            const NxSkeleton(lines: 3, lineHeight: 40)
          else if (candidates.isEmpty)
            Text(
              '들일 수 있는 사람이 없습니다 — 스페이스 멤버가 모두 들어와 있습니다.',
              style: nx.text.secondary,
            )
          else
            Flexible(
              child: ListView(
                shrinkWrap: true,
                // 기본값이면 기기의 안전 영역(상태 표시줄 · 내비게이션 바)을 여백으로 가져와
                // 다이얼로그 안에 큰 빈칸이 생긴다(Android 에서 보였다).
                padding: EdgeInsets.zero,
                children: [
                  for (final m in candidates)
                    NxRow(
                      leading: NxCheck(
                        value: _picked.contains(m.userId),
                        label: m.displayName,
                        showLabel: false,
                        onChanged: (v) => setState(() {
                          v ? _picked.add(m.userId) : _picked.remove(m.userId);
                        }),
                      ),
                      title: m.displayName,
                      subtitle: roleLabel(m.role),
                      onPressed: () => setState(() {
                        _picked.contains(m.userId)
                            ? _picked.remove(m.userId)
                            : _picked.add(m.userId);
                      }),
                    ),
                ],
              ),
            ),
          const SizedBox(height: NxSpacing.sp6),
          Align(
            alignment: Alignment.centerRight,
            child: NxButton(
              label: _picked.isEmpty ? '들이기' : '${_picked.length}명 들이기',
              onPressed: _picked.isEmpty
                  ? null
                  : () => Navigator.of(
                      context,
                    ).pop(_picked.toList(growable: false)),
            ),
          ),
        ],
      ),
    );
  }
}
