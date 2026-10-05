import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/api/api_failure.dart';
import '../../domain/models/space.dart';
import '../../ui/ui.dart';
import '../space_settings/space_settings_controller.dart';
import 'space_actions.dart';
import 'space_controller.dart';

/// 채널 판 머리 줄의 스페이스 이름 — 누르면 메뉴(16단계 설계 D6).
///
/// 볼 수 없는 항목은 감춘다(CLAUDE.md §3-7). 초대 · 설정은 admin+, 나가기는 owner 가 아닐 때.
class SpaceMenu extends ConsumerWidget {
  const SpaceMenu({super.key, required this.space});

  final Space space;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nx = NxTheme.of(context);
    final c = nx.colors;
    final admin = space.role.atLeast(SpaceRole.admin);
    void open(SpaceSettingsSection s) =>
        context.go(spaceSettingsLocation(space.id, s));

    return NxMenu(
      width: 220,
      entries: [
        NxMenuItem('멤버', onSelected: () => open(SpaceSettingsSection.members)),
        if (admin)
          NxMenuItem(
            '초대하기',
            onSelected: () => open(SpaceSettingsSection.invites),
          ),
        if (admin)
          NxMenuItem(
            '스페이스 설정',
            onSelected: () => open(SpaceSettingsSection.general),
          ),
        if (space.role != SpaceRole.owner) ...[
          const NxMenuDivider(),
          NxMenuItem(
            '스페이스 나가기',
            danger: true,
            onSelected: () => _leave(context, ref),
          ),
        ],
      ],
      anchorBuilder: (context, toggle) => NxPressable(
        onPressed: toggle,
        semanticLabel: '${space.name} 메뉴',
        excludeChildSemantics: true,
        builder: (context, s) => Row(
          children: [
            Flexible(
              child: Text(
                space.name,
                style: nx.text.header,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: NxSpacing.sp2),
            NxIcon(
              NxIcons.chevronDown,
              size: 14,
              color: s.hovered ? c.textPrimary : c.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _leave(BuildContext context, WidgetRef ref) async {
    final ok = await NxDialog.confirm(
      context,
      title: '${space.name}에서 나갈까요?',
      body: '다시 들어오려면 새 초대 코드가 필요합니다. 이 스페이스에서 보내지 못한 메시지도 함께 지워집니다.',
      confirmLabel: '나가기',
      danger: true,
    );
    if (!ok || !context.mounted) return;
    // 소켓 `space:removed` 가 응답보다 먼저 오면 셸이 옮겨 이 위젯이 내려간다 — 미리 잡는다.
    final api = ref.read(spacesApiProvider);
    final forget = ref.read(forgetSpaceProvider);
    try {
      await api.leave(space.id);
      // 소켓 `space:removed` 로도 오지만 응답으로 먼저 정리한다 — 소켓이 끊겨 있어도 나간다.
      await forget(space.id);
    } on ApiException catch (e) {
      if (context.mounted) {
        NxToast.show(context, messageFor(e.failure), kind: NxToastKind.error);
      }
    }
  }
}
