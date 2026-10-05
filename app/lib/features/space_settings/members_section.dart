import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/api/api_failure.dart';
import '../../domain/models/space.dart';
import '../../domain/models/space_member.dart';
import '../presence/presence_widgets.dart';
import '../../ui/ui.dart';
import '../auth/auth_controller.dart';
import '../channel/dm.dart';
import '../settings/settings_widgets.dart';
import '../space/members_controller.dart';
import 'space_settings_controller.dart';

/// 스페이스 설정 「멤버」(16단계 설계 D7). **전원이 본다** — 역할 바꾸기 · 내보내기는
/// 내가 그 사람보다 높을 때만 보인다(눌러 봐야 실패할 동작을 두지 않는다).
class MembersSection extends ConsumerWidget {
  const MembersSection({super.key, required this.spaceId, required this.me});

  final String spaceId;
  final SpaceRole me;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myId = ref.watch(
      authControllerProvider.select((a) => a is AuthSignedIn ? a.user.id : null),
    );
    final members = ref.watch(spaceMembersOfProvider(spaceId));

    return SettingsPage(
      title: '멤버',
      children: [
        // `hasError` 로 가른다 — Riverpod 3 은 실패한 provider 를 재시도하며 「로딩 +
        // 오류」 상태를 낸다(CLAUDE.md §2, 15-2).
        if (members.hasError)
          SettingsError(errorMessageOf(members.error))
        else if (!members.hasValue)
          const NxSkeleton(lines: 4, lineHeight: 48)
        else ...[
          SettingsLabel('멤버 ${members.value!.length}명'),
          for (final member in members.value!)
            _MemberRow(
              spaceId: spaceId,
              member: member,
              me: me,
              self: member.userId == myId,
              manageable: canManageMember(
                me: me,
                target: member.role,
                self: member.userId == myId,
              ),
            ),
        ],
      ],
    );
  }
}

class _MemberRow extends ConsumerWidget {
  const _MemberRow({
    required this.spaceId,
    required this.member,
    required this.me,
    required this.self,
    required this.manageable,
  });

  final String spaceId;
  final SpaceMemberProfile member;
  final SpaceRole me;
  final bool self;
  final bool manageable;

  Future<void> _run(BuildContext context, WidgetRef ref, Future<void> Function() call) async {
    try {
      await call();
      // 소켓 member:left 로 목록이 먼저 바뀌면 이 줄은 이미 내려가 있다 — 그때 ref 는 못 쓴다.
      if (!context.mounted) return;
      ref.invalidate(spaceMembersOfProvider(spaceId));
    } on ApiException catch (e) {
      if (context.mounted) {
        NxToast.show(context, messageFor(e.failure), kind: NxToastKind.error);
      }
    }
  }

  Future<void> _remove(BuildContext context, WidgetRef ref) async {
    final ok = await NxDialog.confirm(
      context,
      title: '${member.displayName} 님을 내보낼까요?',
      body: '이 스페이스의 채널과 메시지를 더는 볼 수 없습니다. 다시 들어오려면 새 초대 코드가 필요합니다.',
      confirmLabel: '내보내기',
      danger: true,
    );
    if (!ok || !context.mounted) return;
    await _run(
      context,
      ref,
      () => ref.read(membersApiProvider).remove(spaceId, member.userId),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 바꿀 수 있는 역할 — 나보다 낮은 것만, owner 는 이 경로로 줄 수 없다(서버 DTO).
    final assignable = SpaceRole.values
        .where((r) => r != SpaceRole.owner && r.rank < me.rank)
        .toList(growable: false);

    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: NxRow(
        // 사람을 가리키는 내용이라 장식 아이콘 규칙(15단계 D5)에 걸리지 않는다.
        leading: PresenceAvatar(
          userId: member.userId,
          name: member.displayName,
          avatarUrl: member.avatarUrl,
          size: 32,
        ),
        title: member.displayName,
        subtitle: roleLabel(member.role),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 사람을 보는 자리에서 바로 말을 건다(17단계 D11).
            if (!self)
              NxButton(
                label: '메시지',
                kind: NxButtonKind.ghost,
                size: NxSize.sm,
                onPressed: () => openDmIn(context, ref, spaceId, member.userId),
              ),
            if (manageable)
              NxMenu(
                entries: [
                  for (final role in assignable)
                    NxMenuItem(
                      roleLabel(role),
                      selected: role == member.role,
                      onSelected: role == member.role
                          ? null
                          : () => _run(
                                context,
                                ref,
                                () => ref
                                    .read(membersApiProvider)
                                    .updateRole(spaceId, member.userId, role),
                              ),
                    ),
                  const NxMenuDivider(),
                  NxMenuItem(
                    '내보내기',
                    danger: true,
                    onSelected: () => _remove(context, ref),
                  ),
                ],
                anchorBuilder: (context, toggle) => NxIconButton(
                  icon: NxIcons.more,
                  label: '${member.displayName}의 동작',
                  onPressed: toggle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
