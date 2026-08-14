import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';
import '../../data/api/api_failure.dart';
import '../../domain/models/space.dart';
import '../../shared/widgets/nexus_avatar.dart';
import 'space_controller.dart';

/// `/spaces` — 어느 스페이스로 들어갈지 고른다.
///
/// 스페이스 생성은 슬라이스 2 범위 밖이다. 시드가 하나 만들어 두므로 목록이
/// 비는 경우는 초대만 받은 계정 정도인데, 그 안내만 해 둔다.
class SpacePickerScreen extends ConsumerWidget {
  const SpacePickerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final spaces = ref.watch(spacesProvider);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(NexusSpacing.sp8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('스페이스', style: theme.textTheme.headlineSmall),
                  const SizedBox(height: NexusSpacing.sp2),
                  Text(
                    '들어갈 곳을 고르세요',
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: NexusSpacing.sp8),
                  Flexible(
                    child: spaces.when(
                      loading: () => const Padding(
                        padding: EdgeInsets.all(NexusSpacing.sp9),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      error: (error, _) => _ErrorBlock(
                        error: error,
                        onRetry: () => ref.invalidate(spacesProvider),
                      ),
                      data: (list) => list.isEmpty
                          ? const _EmptyBlock()
                          : ListView.separated(
                              shrinkWrap: true,
                              itemCount: list.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: NexusSpacing.sp2),
                              itemBuilder: (_, i) => _SpaceTile(space: list[i]),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SpaceTile extends StatelessWidget {
  const _SpaceTile({required this.space});

  final Space space;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(NexusRadius.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(NexusRadius.md),
        onTap: () => context.go('/s/${space.id}'),
        child: Padding(
          padding: const EdgeInsets.all(NexusSpacing.sp5),
          child: Row(
            children: [
              NexusAvatar(
                seed: space.id,
                label: space.name,
                squircle: true,
              ),
              const SizedBox(width: NexusSpacing.sp5),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(space.name, style: theme.textTheme.titleSmall),
                    const SizedBox(height: NexusSpacing.sp1),
                    Text(
                      '/${space.slug} · ${space.role.wire}',
                      style: theme.textTheme.labelSmall,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyBlock extends StatelessWidget {
  const _EmptyBlock();

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: NexusSpacing.sp9),
        child: Column(
          children: [
            Text('속한 스페이스가 없습니다.',
                style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: NexusSpacing.sp2),
            Text(
              '초대 링크를 받아 참여하세요.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      );
}

class _ErrorBlock extends StatelessWidget {
  const _ErrorBlock({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    // 서버 문구를 그대로 쓰지 않는다. 종류만 보고 앱이 자기 문구를 쓴다.
    final text = error is ApiException
        ? messageFor((error as ApiException).failure)
        : messageFor(ApiFailure.server);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: NexusSpacing.sp9),
      child: Column(
        children: [
          Text(text, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: NexusSpacing.sp5),
          OutlinedButton(onPressed: onRetry, child: const Text('다시 시도')),
        ],
      ),
    );
  }
}
