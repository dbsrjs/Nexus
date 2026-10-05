import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/breakpoints.dart';
import '../../shared/widgets/nexus_avatar.dart';
import '../../shared/widgets/user_avatar.dart';
import '../../ui/ui.dart';
import '../auth/auth_controller.dart';
import '../space/space_controller.dart';
import '../space/space_dialogs.dart';
import '../settings/settings_controller.dart';

/// 왼쪽 끝 72px 레일. 스페이스 전환과 내 계정이 여기 있다.
class SpaceRail extends ConsumerWidget {
  const SpaceRail({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = NxTheme.of(context).colors;
    final spaces = ref.watch(spacesProvider).value ?? const [];
    final currentId = ref.watch(currentSpaceIdProvider);

    return Container(
      width: NexusPaneWidth.rail,
      color: c.bgBase,
      child: Column(
        children: [
          const SizedBox(height: NxSpacing.sp6),
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.zero,
              itemCount: spaces.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(height: NxSpacing.inset),
              itemBuilder: (_, i) {
                final space = spaces[i];
                return Center(
                  child: _SpaceButton(
                    id: space.id,
                    name: space.name,
                    selected: space.id == currentId,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: NxSpacing.sp4),
          const _AddSpaceButton(),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: NxSpacing.sp6),
            child: _AccountButton(),
          ),
        ],
      ),
    );
  }
}

/// 스페이스 하나. 고른 것은 둘레에 3px 띄운 2px 고리(캔버스 「채널」).
class _SpaceButton extends StatelessWidget {
  const _SpaceButton({
    required this.id,
    required this.name,
    required this.selected,
  });

  final String id;
  final String name;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final c = NxTheme.of(context).colors;
    return NxTooltip(
      message: name,
      child: NxPressable(
        onPressed: () => context.go('/s/$id'),
        selected: selected,
        semanticLabel: name,
        excludeChildSemantics: true,
        focusRingRadius: 17,
        builder: (context, s) => AnimatedContainer(
          duration: NxMotion.micro,
          // 토큰 밖: 선택 고리 — 안쪽 타일 반경 lg(12) + 여백 3 + 테두리 2 = 17 이 동심원이 된다.
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(17), // 토큰 밖: 위 주석의 동심 반경
            border: Border.all(
              width: 2,
              color: selected
                  ? c.textPrimary
                  : (s.hovered ? c.borderStrong : NxColors.transparent),
            ),
          ),
          child: NexusAvatar(seed: id, label: name, size: 38, squircle: true),
        ),
      ),
    );
  }
}

/// 레일 맨 아래의 내 계정 — 설정 창으로 가는 입구와 로그아웃.
///
/// 테마는 여기 있다가 설정 창 「화면」으로 옮겼다(14단계 설계 D3). 같은 설정이
/// 두 곳에 있으면 어느 쪽이 진짜인지 묻게 된다.
class _AccountButton extends ConsumerWidget {
  const _AccountButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    if (auth is! AuthSignedIn) return const SizedBox.shrink();
    final user = auth.user;

    return NxMenu(
      openUp: true,
      entries: [
        NxMenuHeader(user.name, subtitle: user.email),
        const NxMenuDivider(),
        NxMenuItem(
          '설정',
          onSelected: () {
            // 닫으면 지금 보던 곳으로 돌아오게 주소를 넘긴다.
            context.go(
              settingsLocation(
                SettingsSection.account,
                spaceId: ref.read(currentSpaceIdProvider),
                from: GoRouterState.of(context).uri.toString(),
              ),
            );
          },
        ),
        NxMenuItem(
          '로그아웃',
          danger: true,
          onSelected: () => ref.read(authControllerProvider.notifier).signOut(),
        ),
      ],
      anchorBuilder: (context, toggle) => NxTooltip(
        message: user.name,
        child: NxPressable(
          onPressed: toggle,
          semanticLabel: '내 계정 — ${user.name}',
          excludeChildSemantics: true,
          focusRingRadius: NxRadius.full,
          builder: (context, s) => UserAvatar(
            userId: user.id,
            name: user.name,
            avatarUrl: user.avatarUrl,
            size: 36,
          ),
        ),
      ),
    );
  }
}

/// 스페이스 더하기(16단계 설계 D1) — 만들기 · 초대 코드로 참여.
class _AddSpaceButton extends ConsumerWidget {
  const _AddSpaceButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return NxMenu(
      openUp: true,
      entries: [
        NxMenuItem(
          '스페이스 만들기',
          onSelected: () => showCreateSpaceDialog(context, ref),
        ),
        NxMenuItem(
          '초대 코드로 참여',
          onSelected: () => showJoinSpaceDialog(context, ref),
        ),
      ],
      anchorBuilder: (context, toggle) => NxIconButton(
        icon: NxIcons.plus,
        label: '스페이스 더하기',
        onPressed: toggle,
      ),
    );
  }
}
