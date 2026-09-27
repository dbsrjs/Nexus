import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/api/api_failure.dart';
import '../../domain/models/space.dart';
import '../../shared/widgets/nexus_avatar.dart';
import '../../ui/ui.dart';
import 'space_controller.dart';

/// `/spaces` — 어느 스페이스로 들어갈지 고른다.
///
/// 스페이스 생성은 슬라이스 2 범위 밖이다. 시드가 하나 만들어 두므로 목록이
/// 비는 경우는 초대만 받은 계정 정도인데, 그 안내만 해 둔다.
class SpacePickerScreen extends ConsumerWidget {
  const SpacePickerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nx = NxTheme.of(context);
    final spaces = ref.watch(spacesProvider);

    return NxPage(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(NxSpacing.sp8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Semantics(
                  header: true,
                  child: Text('스페이스', style: nx.text.heading),
                ),
                const SizedBox(height: NxSpacing.sp2),
                Text('들어갈 곳을 고르세요', style: nx.text.secondary),
                const SizedBox(height: NxSpacing.sp8),
                Flexible(
                  child: spaces.when(
                    // 자리를 지키는 뼈대(D10) — 회전 스피너를 두지 않는다.
                    loading: () => const NxSkeleton(lines: 3, lineHeight: 56),
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
                                const SizedBox(height: NxSpacing.sp2),
                            itemBuilder: (_, i) => _SpaceTile(space: list[i]),
                          ),
                  ),
                ),
              ],
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
    final nx = NxTheme.of(context);
    final c = nx.colors;

    return NxPressable(
      onPressed: () => context.go('/s/${space.id}'),
      semanticLabel: space.name,
      builder: (context, s) => AnimatedContainer(
        duration: NxMotion.micro,
        padding: const EdgeInsets.all(NxSpacing.sp5),
        decoration: BoxDecoration(
          color: s.hovered || s.pressed ? c.bgElevated : c.bgSurface,
          borderRadius: BorderRadius.circular(NxRadius.md),
        ),
        child: Row(
          children: [
            NexusAvatar(seed: space.id, label: space.name, squircle: true),
            const SizedBox(width: NxSpacing.sp5),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(space.name, style: nx.text.strong),
                  const SizedBox(height: NxSpacing.sp1),
                  Text('/${space.slug} · ${space.role.wire}', style: nx.text.meta),
                ],
              ),
            ),
            NxIcon(NxIcons.chevronRight, size: 14, color: c.textSecondary),
          ],
        ),
      ),
    );
  }
}

class _EmptyBlock extends StatelessWidget {
  const _EmptyBlock();

  @override
  Widget build(BuildContext context) {
    final nx = NxTheme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: NxSpacing.sp9),
      child: Column(
        children: [
          Text('속한 스페이스가 없습니다.', style: nx.text.body),
          const SizedBox(height: NxSpacing.sp2),
          Text('초대 링크를 받아 참여하세요.', style: nx.text.secondary),
        ],
      ),
    );
  }
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
      padding: const EdgeInsets.symmetric(vertical: NxSpacing.sp9),
      child: Column(
        children: [
          Text(text, style: NxTheme.of(context).text.body),
          const SizedBox(height: NxSpacing.sp5),
          NxButton(
            label: '다시 시도',
            kind: NxButtonKind.secondary,
            onPressed: onRetry,
          ),
        ],
      ),
    );
  }
}
