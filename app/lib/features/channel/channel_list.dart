import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/api/api_failure.dart';
import '../../domain/models/channel.dart';
import '../../ui/ui.dart';
import '../space/space_controller.dart';
import 'channel_controller.dart';
import '../../domain/models/space.dart';
import 'channel_dialogs.dart';

/// 채널 패널의 채널 부분. 카테고리 → 채널 순으로 그린다.
///
/// **스스로 스크롤하지 않는다** — 채널 패널이 작업 갈래와 함께 한 목록으로 민다.
class ChannelList extends ConsumerWidget {
  const ChannelList({super.key, this.onChannelTap});

  /// 밀려 나온 패널에서 채널을 고르면 패널을 닫기 위한 콜백.
  final VoidCallback? onChannelTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final channels = ref.watch(channelsProvider);
    final groups = ref.watch(channelGroupsProvider);
    final space = ref.watch(currentSpaceProvider);
    final spaceId = space?.id;
    final admin = space?.role.atLeast(SpaceRole.admin) ?? false;

    return channels.when(
      // 자리를 지키는 뼈대(15단계 D10).
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: NxSpacing.sp6),
        child: NxSkeleton(lines: 5, lineHeight: 14),
      ),
      error: (error, _) => _ErrorBlock(
        error: error,
        onRetry: () => ref.invalidate(channelsProvider),
      ),
      data: (_) {
        if (groups.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(NxSpacing.sp6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '볼 수 있는 채널이 없습니다.',
                  textAlign: TextAlign.center,
                  style: NxTheme.of(context).text.secondary,
                ),
                if (admin && spaceId != null) ...[
                  const SizedBox(height: NxSpacing.sp5),
                  NxButton(
                    label: '채널 만들기',
                    kind: NxButtonKind.secondary,
                    size: NxSize.sm,
                    onPressed: () => showCreateChannelDialog(
                      context,
                      ref,
                      spaceId: spaceId,
                      onCreated: onChannelTap,
                    ),
                  ),
                ],
              ],
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final group in groups) ...[
              PaneSectionTitle(
                group.title,
                // 채널 구조는 admin+ 가 바꾼다(§3-9) — 볼 수 없는 버튼은 두지 않는다.
                trailing: admin && spaceId != null
                    ? NxIconButton(
                        icon: NxIcons.plus,
                        label: '${group.title}에 채널 만들기',
                        size: NxSize.sm,
                        onPressed: () => showCreateChannelDialog(
                          context,
                          ref,
                          spaceId: spaceId,
                          categoryId: group.categoryId,
                          onCreated: onChannelTap,
                        ),
                      )
                    : null,
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

/// 목록 묶음의 제목(「작업」 · 카테고리 이름). 11px · 굵게 · 넓은 자간.
class PaneSectionTitle extends StatelessWidget {
  const PaneSectionTitle(this.text, {super.key, this.first = false, this.trailing});

  final String text;

  /// 맨 위 묶음은 위 여백을 줄인다.
  final bool first;

  /// 제목 끝의 작은 동작(카테고리의 「채널 만들기」, 16단계).
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final title = Semantics(
      header: true,
      child: Text(text, style: NxTheme.of(context).text.label),
    );
    final extra = trailing;
    return Padding(
      padding: EdgeInsets.fromLTRB(10, first ? 4 : NxSpacing.sp6, extra == null ? 10 : 2, 6),
      child: extra == null ? title : Row(children: [Expanded(child: title), extra]),
    );
  }
}

class _ChannelTile extends ConsumerWidget {
  const _ChannelTile({required this.channel, this.onTap});

  final Channel channel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nx = NxTheme.of(context);
    final c = nx.colors;
    final selected = ref.watch(currentChannelIdProvider) == channel.id;
    final spaceId = ref.watch(currentSpaceIdProvider);
    // **음소거면 안 읽음을 없는 것으로 친다** — 굵기 · 뱃지 둘 다. 멘션은 나를
    // 부른 것이라 음소거해도 남긴다(디스코드와 같다, 14단계 설계 D17).
    final unread = channel.muted ? 0 : channel.unreadCount;
    final bold = selected || unread > 0;

    // 채널 앞 표시는 **뜻이 있는 것**만 — `#` 는 글자, 비공개는 자물쇠, 음소거는 종.
    final Widget mark = channel.muted
        ? NxIcon(NxIcons.mutedBell, size: 13, color: c.borderStrong)
        : channel.isPrivate
        ? NxIcon(
            NxIcons.lock,
            size: 13,
            color: selected ? c.accent : c.borderStrong,
          )
        : Text(
            '#',
            style: nx.text.mono.copyWith(
              fontSize: 14,
              color: selected ? c.accent : c.borderStrong,
            ),
          );

    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: NxPressable(
        selected: selected,
        semanticLabel: channel.name,
        onPressed: () {
          if (spaceId != null) context.go('/s/$spaceId/c/${channel.id}');
          onTap?.call();
        },
        builder: (context, s) => AnimatedContainer(
          duration: NxMotion.micro,
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: selected
                ? c.accentSubtle
                : (s.hovered || s.pressed
                      ? c.bgElevated
                      : const Color(0x00000000)),
            borderRadius: BorderRadius.circular(NxRadius.md),
          ),
          child: Row(
            children: [
              SizedBox(width: 14, child: Center(child: mark)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  channel.name,
                  overflow: TextOverflow.ellipsis,
                  style: nx.text.base.copyWith(
                    // 안 읽은 것이 있으면 굵게 — 뱃지와 함께 두 겹으로 표시한다.
                    fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
                    // 음소거는 가장 흐리게, 읽은 채널은 보조 글자색.
                    color: channel.muted
                        ? c.borderStrong
                        : (bold ? c.textPrimary : c.textSecondary),
                  ),
                ),
              ),
              // 멘션은 안 읽은 수와 **따로** 보여 준다. 나를 부른 것이라
              // 무게가 다르고, 숫자에 묻히면 놓친다.
              if (channel.mentionCount > 0) ...[
                const SizedBox(width: 6),
                NxBadge(count: channel.mentionCount, mention: true),
              ],
              if (unread > 0) ...[
                const SizedBox(width: 6),
                NxBadge(count: unread),
              ],
            ],
          ),
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

    return Padding(
      padding: const EdgeInsets.all(NxSpacing.sp6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            text,
            textAlign: TextAlign.center,
            style: NxTheme.of(context).text.secondary,
          ),
          const SizedBox(height: NxSpacing.sp4),
          NxButton(
            label: '다시 시도',
            kind: NxButtonKind.secondary,
            size: NxSize.sm,
            onPressed: onRetry,
          ),
        ],
      ),
    );
  }
}
