import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/breakpoints.dart';
import '../../core/theme.dart';
import '../../shared/widgets/nexus_avatar.dart';
import '../auth/auth_controller.dart';
import '../space/space_controller.dart';

/// 왼쪽 끝 72px 레일. 스페이스 전환과 내 계정이 여기 있다.
class SpaceRail extends ConsumerWidget {
  const SpaceRail({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final spaces = ref.watch(spacesProvider).value ?? const [];
    final currentId = ref.watch(currentSpaceIdProvider);

    return Container(
      width: NexusPaneWidth.rail,
      color: theme.scaffoldBackgroundColor,
      child: Column(
        children: [
          const SizedBox(height: NexusSpacing.sp5),
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.zero,
              itemCount: spaces.length,
              separatorBuilder: (_, _) => const SizedBox(height: NexusSpacing.sp4),
              itemBuilder: (_, i) {
                final space = spaces[i];
                return Center(
                  child: Tooltip(
                    message: space.name,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(NexusRadius.md * 2),
                      onTap: () => context.go('/s/${space.id}'),
                      child: NexusAvatar(
                        seed: space.id,
                        label: space.name,
                        squircle: true,
                        selected: space.id == currentId,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: NexusSpacing.sp5),
            child: _AccountButton(),
          ),
        ],
      ),
    );
  }
}

/// 레일 맨 아래의 내 계정. 로그아웃이 여기 들어간다.
class _AccountButton extends ConsumerWidget {
  const _AccountButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    if (auth is! AuthSignedIn) return const SizedBox.shrink();
    final user = auth.user;

    return PopupMenuButton<String>(
      tooltip: user.name,
      offset: const Offset(NexusPaneWidth.rail, 0),
      onSelected: (value) {
        if (value == 'signOut') {
          ref.read(authControllerProvider.notifier).signOut();
        }
      },
      itemBuilder: (_) => [
        PopupMenuItem<String>(
          enabled: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(user.name, style: Theme.of(context).textTheme.titleSmall),
              Text(user.email, style: Theme.of(context).textTheme.labelSmall),
            ],
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem<String>(value: 'signOut', child: Text('로그아웃')),
      ],
      child: NexusAvatar(seed: user.id, label: user.name, size: 36),
    );
  }
}
