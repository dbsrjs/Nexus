import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/breakpoints.dart';
import '../../core/theme.dart';
import '../../shared/widgets/nexus_avatar.dart';
import '../auth/auth_controller.dart';
import '../space/space_controller.dart';
import '../settings/theme_controller.dart';

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

    final theme = Theme.of(context);
    final mode = ref.watch(themeModeProvider);

    // 설정 화면이 아직 없다. 갈 곳을 새로 만드는 대신 이미 있는 계정 메뉴에
    // 넣는다 — 테마는 계정처럼 "나"에 붙는 값이라 자리가 어색하지 않다.
    PopupMenuItem<String> themeItem(String label, ThemeMode value) {
      final selected = mode == value;
      return PopupMenuItem<String>(
        value: 'theme.${value.name}',
        child: Row(
          children: [
            SizedBox(
              width: 24,
              child: selected
                  ? Icon(Icons.check, size: 16, color: theme.colorScheme.primary)
                  : null,
            ),
            Text(
              label,
              style: selected
                  ? theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    )
                  : theme.textTheme.bodyMedium,
            ),
          ],
        ),
      );
    }

    return PopupMenuButton<String>(
      tooltip: user.name,
      offset: const Offset(NexusPaneWidth.rail, 0),
      onSelected: (value) {
        switch (value) {
          case 'signOut':
            ref.read(authControllerProvider.notifier).signOut();
          case 'theme.system':
            ref.read(themeModeProvider.notifier).set(ThemeMode.system);
          case 'theme.light':
            ref.read(themeModeProvider.notifier).set(ThemeMode.light);
          case 'theme.dark':
            ref.read(themeModeProvider.notifier).set(ThemeMode.dark);
        }
      },
      itemBuilder: (_) => [
        PopupMenuItem<String>(
          enabled: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(user.name, style: theme.textTheme.titleSmall),
              Text(user.email, style: theme.textTheme.labelSmall),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem<String>(
          enabled: false,
          height: 32,
          child: Text('테마', style: theme.textTheme.labelSmall),
        ),
        themeItem('시스템 설정', ThemeMode.system),
        themeItem('라이트', ThemeMode.light),
        themeItem('다크', ThemeMode.dark),
        const PopupMenuDivider(),
        const PopupMenuItem<String>(value: 'signOut', child: Text('로그아웃')),
      ],
      child: NexusAvatar(seed: user.id, label: user.name, size: 36),
    );
  }
}
