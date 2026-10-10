import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/time_labels.dart';

import '../../data/api/api_failure.dart';
import '../../domain/models/message.dart';
import '../../ui/ui.dart';
import '../channel/channel_controller.dart';
import '../channel/dm.dart';
import '../presence/presence_widgets.dart';
import '../space/space_controller.dart';
import 'message_composer.dart';
import 'read_only_bar.dart';
import 'message_controller.dart';
import '../issue/new_issue_sheet.dart';
import '../ai/ai_panel.dart';
import '../ai/ai_request.dart';
import 'selection_app_bar.dart';
import 'selection_controller.dart';
import 'chat_header.dart';
import 'message_tile.dart';

export 'message_composer.dart' show MessageComposer;
export 'message_tile.dart' show MessageTile;

/// 채널 하나의 대화. 메시지 리스트 + 입력창.
class ChatScreen extends ConsumerWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final channel = ref.watch(currentChannelProvider);
    final messages = ref.watch(messagesProvider);
    final selection = ref.watch(selectionControllerProvider);

    // 채널을 옮기면 선택이 뜻을 잃는다 — 다른 대화의 메시지를 고른 채로
    // 남으면 안 된다. build 안에서 다른 provider 를 직접 고치면 build 중
    // 상태 변경 예외가 나므로(8-2 에서 겪었다) `ref.listen` 으로 채널
    // 변경만 듣는다.
    ref.listen<String?>(currentChannelIdProvider, (previous, next) {
      ref.read(selectionControllerProvider.notifier).clear();
    });

    return NxPage(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (selection.active)
            SelectionAppBar(
              onAsk: () => _openAi(
                context,
                ref,
                (channelId) => MessagesContext(
                  channelId: channelId,
                  messageIds: chronologicalSelection(selection.ids, [
                    for (final m in messages.value ?? const <Message>[]) m.id,
                  ]),
                ),
              ),
            )
          else if (channel != null && channel.isDm)
            DmHeader(
              channel: channel,
              onAsk: () => _openAi(
                context,
                ref,
                (channelId) => ChannelContext(
                  channelId: channelId,
                  channelName: dmPeerName(
                    ref.read(memberProfilesProvider),
                    channel,
                  ),
                ),
              ),
            )
          else if (channel != null)
            ChannelHeader(
              name: channel.name,
              topic: channel.topic,
              onAsk: () => _openAi(
                context,
                ref,
                (channelId) => ChannelContext(
                  channelId: channelId,
                  channelName: channel.name,
                ),
              ),
            ),
          Expanded(
            child: messages.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(NxSpacing.sp7),
                child: NxSkeleton(lines: 6, lineHeight: 16),
              ),
              error: (error, _) => _ErrorBlock(
                error: error,
                onRetry: () => ref.invalidate(messagesProvider),
              ),
              data: (items) => items.isEmpty
                  ? const _EmptyBlock()
                  : MessageList(items: items),
            ),
          ),
          if (channel != null) TypingLine(channelId: channel.id),
          // 보낼 수 없는 채널은 입력창 대신 이유를 말한다(16단계 D27).
          if (channel != null && !channel.canSend)
            channel.isDm
                ? const ReadOnlyBar(text: '상대가 스페이스를 떠나 보낼 수 없습니다')
                : const ReadOnlyBar()
          else
            const MessageComposer(),
        ],
      ),
    );
  }
}

/// AI 패널을 연다 — 선택 모드의 「AI」와 채널 헤더의 AI 아이콘이 부른다.
/// 붙는 칩만 다르다(13-2 설계 §6). 패널이 닫히면 선택을 비운다.
void _openAi(
  BuildContext context,
  WidgetRef ref,
  AiContext Function(String channelId) contextFor,
) {
  final spaceId = ref.read(currentSpaceIdProvider);
  final channelId = ref.read(currentChannelIdProvider);
  if (spaceId == null || channelId == null) return;

  showAiPanel(
    context,
    spaceId: spaceId,
    contexts: [contextFor(channelId)],
    canAddRepo: true,
    // 「채널에 붙이기」는 평범한 메시지 전송이다 — 서버에 새 경로가 없다.
    // 읽기 전용 채널에서는 붙일 수 없으니 버튼을 두지 않는다(§3-7).
    onPost: ref.read(channelCanSendProvider(channelId))
        ? (markdown) => ref.read(messageActionsProvider).send(markdown)
        : null,
    // 이슈 초안은 기존 생성 화면을 채운 채로 연다 — 사람이 확인한 뒤
    // 만든다(판단 #7). 첫 메시지를 원문으로 넘겨 9-2b 의 링크를 살린다.
    onCreateIssue: ({required title, required description, originMessageId}) {
      if (!context.mounted) return;
      showNewIssueSheet(
        context,
        originMessageId: originMessageId,
        initialTitle: title,
        initialDescription: description,
      );
    },
  ).then((_) {
    if (context.mounted) {
      ref.read(selectionControllerProvider.notifier).clear();
    }
  });
}

class MessageList extends ConsumerStatefulWidget {
  const MessageList({super.key, required this.items});

  final List<Message> items;

  @override
  ConsumerState<MessageList> createState() => MessageListState();
}

class MessageListState extends ConsumerState<MessageList> {
  final _controller = ScrollController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onScroll);
  }

  @override
  void dispose() {
    _controller.removeListener(_onScroll);
    _controller.dispose();
    super.dispose();
  }

  /// reverse 리스트라 maxScrollExtent 쪽이 **과거**다. 끝에 가까워지면 더 불러온다.
  void _onScroll() {
    if (!_controller.hasClients) return;
    final position = _controller.position;
    if (position.pixels >= position.maxScrollExtent - 300) {
      ref.read(messageActionsProvider).loadOlder();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: _controller,
      // 채팅은 아래가 최신이다. 목록이 최신순이므로 뒤집어서 그린다.
      reverse: true,
      padding: const EdgeInsets.symmetric(vertical: NxSpacing.sp6),
      itemCount: widget.items.length,
      itemBuilder: (context, i) {
        final message = widget.items[i];
        // 바로 아래(= 목록에서 다음) 메시지와 작성자가 같으면 머리말을 생략한다.
        final next = i + 1 < widget.items.length ? widget.items[i + 1] : null;
        // 날이 바뀌는 곳(= 아래 메시지와 날짜가 다르거나, 불러온 것 중 가장 오래된 것)에 구분선.
        final newDay =
            next == null || !isSameLocalDay(message.createdAt, next.createdAt);
        final grouped =
            !newDay &&
            next.author.id == message.author.id &&
            !message.isDeleted &&
            !next.isDeleted &&
            message.createdAt.difference(next.createdAt).inMinutes.abs() < 5;

        final tile = MessageTile(message: message, grouped: grouped);
        if (!newDay) return tile;
        // reverse 목록이라 Column 의 위쪽이 화면에서도 위(더 옛날 쪽)다.
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DaySeparator(at: message.createdAt),
            tile,
          ],
        );
      },
    );
  }
}

/// 날짜 구분선 — 가운데 「오늘」 · 「10월 3일 (금)」 + 양옆 선.
class DaySeparator extends StatelessWidget {
  const DaySeparator({super.key, required this.at});

  final DateTime at;

  @override
  Widget build(BuildContext context) {
    final nx = NxTheme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        NxSpacing.sp7,
        NxSpacing.sp6,
        NxSpacing.sp7,
        NxSpacing.sp2,
      ),
      child: Semantics(
        header: true,
        child: Row(
          children: [
            const Expanded(child: NxDivider()),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: NxSpacing.sp4),
              child: Text(dayLabel(at), style: nx.text.meta),
            ),
            const Expanded(child: NxDivider()),
          ],
        ),
      ),
    );
  }
}

class _EmptyBlock extends StatelessWidget {
  const _EmptyBlock();

  @override
  Widget build(BuildContext context) => const NxEmptyState(
    title: '아직 대화가 없습니다',
    description: '아래 입력창에 첫 메시지를 보내 보세요.',
  );
}

class _ErrorBlock extends StatelessWidget {
  const _ErrorBlock({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final text = messageForError(error);

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(text, style: NxTheme.of(context).text.base),
          const SizedBox(height: NxSpacing.sp4),
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
