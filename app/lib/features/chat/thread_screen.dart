import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../domain/models/message.dart';
import '../channel/channel_controller.dart';
import '../space/space_controller.dart';
import 'chat_screen.dart';
import 'thread_controller.dart';

/// 스레드 하나. 부모 메시지 + 답글 목록 + 답글 입력창.
///
/// 셸 위에 덮어서 연다(라우터 참고). 채널 화면과 위젯을 공유하므로 메시지가
/// 그려지는 모양은 양쪽이 같다 — 리액션 · 실패 표시 · 그룹핑이 따로 놀면
/// 같은 대화가 화면마다 달라 보인다.
class ThreadScreen extends ConsumerStatefulWidget {
  const ThreadScreen({
    super.key,
    required this.spaceId,
    required this.channelId,
    required this.messageId,
  });

  final String spaceId;
  final String channelId;
  final String messageId;

  @override
  ConsumerState<ThreadScreen> createState() => _ThreadScreenState();
}

class _ThreadScreenState extends ConsumerState<ThreadScreen> {
  @override
  void initState() {
    super.initState();
    // 라우트가 진실의 원천이다. 컨트롤러에 실어 주는 것은 화면의 일이다 —
    // 채널에서 쓰는 방식과 같다.
    Future.microtask(() {
      if (!mounted) return;
      ref.read(currentSpaceIdProvider.notifier).set(widget.spaceId);
      ref.read(currentChannelIdProvider.notifier).set(widget.channelId);
      ref.read(currentThreadIdProvider.notifier).set(widget.messageId);
    });
  }

  @override
  void dispose() {
    // 스레드를 닫으면 구독을 놓아 준다. 채널 id 는 그대로 둔다 — 돌아갈 곳이다.
    final container = ProviderScope.containerOf(context, listen: false);
    Future.microtask(
      () => container.read(currentThreadIdProvider.notifier).set(null),
    );
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final parent = ref.watch(threadParentProvider).value;
    final replies = ref.watch(threadRepliesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('스레드')),
      body: Column(
        children: [
          if (parent != null) _ParentBlock(parent: parent),
          Expanded(
            child: replies.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              // 답글은 캐시에서 오므로 오류 화면 대신 빈 목록을 보여 준다.
              // 부모는 이미 위에 그려져 있어 화면이 비지 않는다.
              error: (_, _) => const _NoReplies(),
              data: (items) =>
                  items.isEmpty ? const _NoReplies() : MessageList(items: items),
            ),
          ),
          MessageComposer(
            hint: '스레드에 답글 달기',
            onSend: (body, attachments) => ref
                .read(threadActionsProvider)
                .reply(body, attachments: attachments),
          ),
        ],
      ),
    );
  }
}

/// 스레드의 뿌리가 된 메시지. 목록과 구분되게 아래에 경계선을 둔다.
class _ParentBlock extends StatelessWidget {
  const _ParentBlock({required this.parent});

  final Message parent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: theme.dividerColor)),
      ),
      padding: const EdgeInsets.only(bottom: NexusSpacing.sp3),
      child: MessageTile(message: parent, grouped: false),
    );
  }
}

class _NoReplies extends StatelessWidget {
  const _NoReplies();

  @override
  Widget build(BuildContext context) => Center(
        child: Text(
          '첫 답글을 남겨 보세요.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      );
}
