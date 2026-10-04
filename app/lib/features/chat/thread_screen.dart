import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/message.dart';
import '../../shared/widgets/back_button.dart';
import '../../ui/ui.dart';
import '../channel/channel_controller.dart';
import '../space/space_controller.dart';
import 'chat_screen.dart';
import 'read_only_bar.dart';
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
  // dispose() 에서는 context 로 조상을 찾을 수 없다(디버그 빌드에서 던진다).
  // 조상 조회가 허용되는 didChangeDependencies 에서 미리 잡아 둔다.
  late ProviderContainer _container;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _container = ProviderScope.containerOf(context, listen: false);
  }

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
    final container = _container;
    Future.microtask(
      () => container.read(currentThreadIdProvider.notifier).set(null),
    );
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final parent = ref.watch(threadParentProvider).value;
    final replies = ref.watch(threadRepliesProvider);

    return NxPage(
      header: NxHeader(
        title: '스레드',
        leading: NxBackButton(
          fallback: '/s/${widget.spaceId}/c/${widget.channelId}',
        ),
      ),
      body: Column(
        children: [
          if (parent != null) _ParentBlock(parent: parent),
          Expanded(
            child: replies.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(NxSpacing.sp7),
                child: NxSkeleton(lines: 4),
              ),
              // 답글은 캐시에서 오므로 오류 화면 대신 빈 목록을 보여 준다.
              // 부모는 이미 위에 그려져 있어 화면이 비지 않는다.
              error: (_, _) => const _NoReplies(),
              data: (items) => items.isEmpty
                  ? const _NoReplies()
                  : MessageList(items: items),
            ),
          ),
          // 읽기 전용 채널의 스레드에도 답글을 달 수 없다(서버가 403) — 이유를 말한다.
          if (!ref.watch(channelCanSendProvider(widget.channelId)))
            const ReadOnlyBar()
          else
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
    final c = NxTheme.of(context).colors;

    return Container(
      decoration: BoxDecoration(
        color: c.bgSurface,
        border: Border(bottom: BorderSide(color: c.divider)),
      ),
      padding: const EdgeInsets.symmetric(vertical: NxSpacing.sp4),
      child: MessageTile(
        message: parent,
        grouped: false,
        showThreadSummary: false,
      ),
    );
  }
}

class _NoReplies extends StatelessWidget {
  const _NoReplies();

  @override
  Widget build(BuildContext context) => Center(
    child: Text('첫 답글을 남겨 보세요.', style: NxTheme.of(context).text.secondary),
  );
}
