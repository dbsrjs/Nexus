import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/api/api_failure.dart';
import '../../shared/markdown/plain_text.dart';
import '../../shared/widgets/user_avatar.dart';
import '../../ui/ui.dart';
import '../shell/app_shell.dart';
import '../space/members_controller.dart';
import 'notifications_controller.dart';

/// `/s/:spaceId/notifications` — 알림함(18단계 N19 · N22). 셸 안에 둔다 — 자주 들르는 곳이다.
class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key, required this.spaceId});

  final String spaceId;

  Future<void> _readAll(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(notificationsProvider.notifier).markAllRead();
    } on ApiException catch (e) {
      if (context.mounted) {
        NxToast.show(context, messageFor(e.failure), kind: NxToastKind.error);
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nx = NxTheme.of(context);
    final state = ref.watch(notificationsProvider);
    final anyUnread = state.items.any((n) => !n.read);

    final Widget body;
    if (state.loading && state.items.isEmpty) {
      body = const Padding(
        padding: EdgeInsets.all(NxSpacing.sp7),
        child: NxSkeleton(lines: 6, lineHeight: 40),
      );
    } else if (state.failure != null && state.items.isEmpty) {
      body = Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 서버 문구를 그대로 쓰지 않는다 — 실패 종류만 받아 앱이 자기 문구를 쓴다.
            Text(
              state.failure == ApiFailure.network
                  ? '알림은 서버에 연결되면 보입니다.'
                  : messageFor(state.failure!),
              style: nx.text.secondary,
            ),
            const SizedBox(height: NxSpacing.sp4),
            NxButton(
              label: '다시 시도',
              kind: NxButtonKind.secondary,
              onPressed: () => ref.read(notificationsProvider.notifier).refresh(),
            ),
          ],
        ),
      );
    } else if (state.items.isEmpty) {
      body = Center(
        child: Padding(
          padding: const EdgeInsets.all(NxSpacing.sp6),
          child: Text(
            '아직 알림이 없습니다.\n나를 부른 멘션 · DM · 내 글의 답글이 여기 모입니다.',
            textAlign: TextAlign.center,
            style: nx.text.secondary,
          ),
        ),
      );
    } else {
      body = NotificationListener<ScrollNotification>(
        // 끝에 가까워지면 다음 쪽 — 「더 보기」 버튼을 누르게 하지 않는다.
        onNotification: (n) {
          if (n.metrics.extentAfter < 400) {
            ref.read(notificationsProvider.notifier).loadMore();
          }
          return false;
        },
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(
            horizontal: NxSpacing.sp7,
            vertical: NxSpacing.sp4,
          ),
          itemCount: state.items.length,
          separatorBuilder: (_, _) => const NxDivider(),
          itemBuilder: (_, index) => NotificationTile(
            item: state.items[index],
            onPressed: () {
              final item = state.items[index];
              ref.read(notificationsProvider.notifier).markRead(item);
              // 답글은 스레드(셸 밖, 덮어서 — §3-13), 나머지는 채널(셸 안).
              final target = notificationTarget(spaceId, item);
              item.threadId == null ? context.go(target) : context.push(target);
            },
          ),
        ),
      );
    }

    return NxPage(
      header: ShellHeader(
        title: '알림',
        actions: [
          // 눌러 봐야 할 일이 없으면 감춘다(§3-7).
          if (anyUnread)
            NxButton(
              label: '모두 읽음',
              kind: NxButtonKind.ghost,
              size: NxSize.sm,
              onPressed: () => _readAll(context, ref),
            ),
          NxIconButton(
            icon: NxIcons.refresh,
            label: '새로고침',
            onPressed: () => ref.read(notificationsProvider.notifier).refresh(),
          ),
        ],
      ),
      body: body,
    );
  }
}

/// 알림 한 줄(N22) — 작성자 아바타 · 머리 문구 · 본문 두 줄 · 시각. 안 읽은 줄은 앞에 점.
class NotificationTile extends ConsumerWidget {
  const NotificationTile({super.key, required this.item, required this.onPressed});

  final NotificationItem item;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nx = NxTheme.of(context);
    final c = nx.colors;
    final names = ref.watch(memberNamesProvider);

    // 본문은 원문 마크다운이다 — 서식을 벗기고 `<@id>` 를 이름으로 바꿔 한 줄로.
    final preview = item.deleted
        ? '삭제된 메시지입니다'
        : item.body.isEmpty
            ? '파일을 보냈습니다'
            : toPlainText(item.body, names: names);

    return NxPressable(
      onPressed: onPressed,
      semanticLabel: '${item.read ? '' : '안 읽음, '}${notificationHeadline(item)}',
      builder: (context, s) => AnimatedContainer(
        duration: NxMotion.micro,
        padding: const EdgeInsets.symmetric(
          horizontal: NxSpacing.sp3,
          vertical: NxSpacing.sp4,
        ),
        decoration: BoxDecoration(
          color: s.hovered || s.pressed ? c.bgElevated : const Color(0x00000000),
          borderRadius: BorderRadius.circular(NxRadius.md),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 안 읽음 점 — 줄 앞의 유일한 표시다. 읽은 줄도 자리를 비워 두어 줄이 들썩이지 않게.
            SizedBox(
              width: 12,
              height: 32,
              child: item.read
                  ? null
                  : Center(
                      child: Container(
                        key: const ValueKey('notification-unread-dot'),
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: c.accent,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
            ),
            const SizedBox(width: NxSpacing.sp3),
            UserAvatar(
              userId: item.actorId,
              name: item.actorName,
              avatarUrl: item.actorAvatarUrl,
              size: 32,
            ),
            const SizedBox(width: NxSpacing.sp5),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Expanded(
                        child: Text(
                          notificationHeadline(item),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: nx.text.sm.copyWith(
                            color: item.read ? c.textSecondary : c.textPrimary,
                            fontWeight: item.read ? null : FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: NxSpacing.sp3),
                      Text(notificationTime(item.createdAt), style: nx.text.mono),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    preview,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: item.deleted
                        ? nx.text.secondary.copyWith(fontStyle: FontStyle.italic)
                        : nx.text.secondary,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 오늘이면 `14:05`, 아니면 `10/3`. 지난 해면 `2025/10/3`. 기기 시간대로 보인다.
String notificationTime(DateTime at, {DateTime? now}) {
  final local = at.toLocal();
  final today = (now ?? DateTime.now()).toLocal();
  String two(int v) => v.toString().padLeft(2, '0');
  if (local.year == today.year && local.month == today.month && local.day == today.day) {
    return '${two(local.hour)}:${two(local.minute)}';
  }
  final md = '${local.month}/${local.day}';
  return local.year == today.year ? md : '${local.year}/$md';
}
