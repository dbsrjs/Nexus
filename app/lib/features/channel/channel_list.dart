import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';
import '../../data/api/api_failure.dart';
import '../../domain/models/channel.dart';
import '../space/space_controller.dart';
import 'channel_controller.dart';

/// 채널 패널의 본문. 카테고리 → 채널 순으로 그린다.
class ChannelList extends ConsumerWidget {
  const ChannelList({super.key, this.onChannelTap});

  /// 드로어로 열렸을 때 채널을 고르면 드로어를 닫기 위한 콜백.
  final VoidCallback? onChannelTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final channels = ref.watch(channelsProvider);
    final groups = ref.watch(channelGroupsProvider);

    return channels.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _ErrorBlock(
        error: error,
        onRetry: () => ref.invalidate(channelsProvider),
      ),
      data: (_) {
        if (groups.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(NexusSpacing.sp6),
              child: Text(
                '볼 수 있는 채널이 없습니다.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.symmetric(vertical: NexusSpacing.sp4),
          children: [
            for (final group in groups) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  NexusSpacing.sp5,
                  NexusSpacing.sp4,
                  NexusSpacing.sp5,
                  NexusSpacing.sp2,
                ),
                child: Text(
                  group.title,
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ),
              for (final channel in group.channels)
                _ChannelTile(channel: channel, onTap: onChannelTap),
            ],
          ],
        );
      },
    );
  }
}

class _ChannelTile extends ConsumerWidget {
  const _ChannelTile({required this.channel, this.onTap});

  final Channel channel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final selected = ref.watch(currentChannelIdProvider) == channel.id;
    final spaceId = ref.watch(currentSpaceIdProvider);
    final unread = channel.unreadCount;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: NexusSpacing.sp3,
        vertical: 1,
      ),
      child: Material(
        color: selected ? theme.colorScheme.surfaceContainerHighest : Colors.transparent,
        borderRadius: BorderRadius.circular(NexusRadius.sm),
        child: InkWell(
          borderRadius: BorderRadius.circular(NexusRadius.sm),
          onTap: () {
            if (spaceId != null) {
              context.go('/s/$spaceId/c/${channel.id}');
            }
            onTap?.call();
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: NexusSpacing.sp3,
              vertical: NexusSpacing.sp3,
            ),
            child: Row(
              children: [
                Icon(
                  channel.isPrivate ? Icons.lock_outline : Icons.tag,
                  size: 16,
                  color: theme.textTheme.bodySmall?.color,
                ),
                const SizedBox(width: NexusSpacing.sp2),
                Expanded(
                  child: Text(
                    channel.name,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      // 안 읽은 것이 있으면 굵게 — 뱃지와 함께 두 겹으로 표시한다.
                      fontWeight: unread > 0 ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ),
                // 멘션은 안 읽은 수와 **따로** 보여 준다. 나를 부른 것이라
                // 무게가 다르고, 숫자에 묻히면 놓친다.
                if (channel.mentionCount > 0) ...[
                  _MentionBadge(count: channel.mentionCount),
                  const SizedBox(width: NexusSpacing.sp1),
                ],
                if (unread > 0) _UnreadBadge(count: unread),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 안 읽은 멘션 수. 일반 뱃지와 색을 달리해 한눈에 갈린다.
class _MentionBadge extends StatelessWidget {
  const _MentionBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.error,
        borderRadius: BorderRadius.circular(NexusRadius.full),
      ),
      child: Text(
        // 개수보다 "불렸다"는 사실이 먼저다. 한 건이면 @ 만 보여 준다.
        count > 1 ? '@$count' : '@',
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onError,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _UnreadBadge extends StatelessWidget {
  const _UnreadBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary,
        borderRadius: BorderRadius.circular(NexusRadius.full),
      ),
      child: Text(
        count > 99 ? '99+' : '$count',
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onPrimary,
          fontWeight: FontWeight.w600,
        ),
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
    final text = error is ApiException
        ? messageFor((error as ApiException).failure)
        : messageFor(ApiFailure.server);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(NexusSpacing.sp6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(text,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: NexusSpacing.sp4),
            OutlinedButton(onPressed: onRetry, child: const Text('다시 시도')),
          ],
        ),
      ),
    );
  }
}
