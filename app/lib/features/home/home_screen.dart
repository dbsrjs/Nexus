import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/env.dart';
import '../../core/theme.dart';
import '../auth/auth_controller.dart';

/// 슬라이스 1 의 **자리표시자**다. 로그인이 실제로 되는지 눈으로 보기 위한
/// 최소 화면이며, 슬라이스 2 에서 반응형 셸로 대체된다.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final auth = ref.watch(authControllerProvider);

    if (auth is! AuthSignedIn) {
      // 라우터 redirect 가 곧 로그인 화면으로 보낸다.
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final user = auth.user;

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: NexusColors
                  .avatars[user.id.hashCode.abs() % NexusColors.avatars.length],
              child: Text(
                user.name.isEmpty ? '?' : user.name.characters.first,
                style: theme.textTheme.titleLarge
                    ?.copyWith(color: NexusColors.bgBaseDark),
              ),
            ),
            const SizedBox(height: NexusSpacing.sp6),
            Text(user.name, style: theme.textTheme.titleMedium),
            const SizedBox(height: NexusSpacing.sp2),
            Text(user.email, style: theme.textTheme.bodySmall),
            const SizedBox(height: NexusSpacing.sp8),
            Text('API: ${Env.apiRoot}', style: theme.textTheme.labelSmall),
            const SizedBox(height: NexusSpacing.sp8),
            OutlinedButton(
              onPressed: () =>
                  ref.read(authControllerProvider.notifier).signOut(),
              child: const Text('로그아웃'),
            ),
          ],
        ),
      ),
    );
  }
}
