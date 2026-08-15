import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../data/api/api_failure.dart';
import '../../domain/models/message.dart';
import '../../shared/widgets/nexus_avatar.dart';
import '../channel/channel_controller.dart';
import '../realtime/socket_controller.dart';
import 'message_controller.dart';

/// 채널 하나의 대화. 메시지 리스트 + 입력창.
class ChatScreen extends ConsumerWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final channel = ref.watch(currentChannelProvider);
    final messages = ref.watch(messagesProvider);

    return Column(
      children: [
        if (channel != null) _ChannelHeader(name: channel.name, topic: channel.topic),
        Expanded(
          child: messages.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => _ErrorBlock(
              error: error,
              onRetry: () => ref.invalidate(messagesProvider),
            ),
            data: (items) => items.isEmpty
                ? const _EmptyBlock()
                : _MessageList(items: items),
          ),
        ),
        const _Composer(),
      ],
    );
  }
}

class _ChannelHeader extends StatelessWidget {
  const _ChannelHeader({required this.name, this.topic});

  final String name;
  final String? topic;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: NexusSpacing.sp5),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: theme.dividerColor)),
      ),
      child: Row(
        children: [
          Icon(Icons.tag, size: 18, color: theme.textTheme.bodySmall?.color),
          const SizedBox(width: NexusSpacing.sp2),
          Text(name, style: theme.textTheme.titleSmall),
          if (topic != null && topic!.isNotEmpty) ...[
            const SizedBox(width: NexusSpacing.sp4),
            Expanded(
              child: Text(
                topic!,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall,
              ),
            ),
          ] else
            const Spacer(),
          const _ConnectionDot(),
        ],
      ),
    );
  }
}

/// 실시간 연결 표시.
///
/// 끊겨 있으면 화면은 그대로 보이지만 **새 메시지가 오지 않는다.** 그 상태를
/// 사용자가 알 수 있어야 한다 — 조용히 멈춘 채팅은 버그로 오인된다.
class _ConnectionDot extends ConsumerWidget {
  const _ConnectionDot();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connected = ref.watch(socketConnectedProvider);
    final theme = Theme.of(context);

    return Tooltip(
      message: connected ? '실시간 연결됨' : '연결 끊김 — 새 메시지가 오지 않습니다',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: connected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.error,
            ),
          ),
          if (!connected) ...[
            const SizedBox(width: NexusSpacing.sp2),
            Text('연결 끊김', style: theme.textTheme.labelSmall),
          ],
        ],
      ),
    );
  }
}

class _MessageList extends ConsumerStatefulWidget {
  const _MessageList({required this.items});

  final List<Message> items;

  @override
  ConsumerState<_MessageList> createState() => _MessageListState();
}

class _MessageListState extends ConsumerState<_MessageList> {
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
      padding: const EdgeInsets.symmetric(vertical: NexusSpacing.sp4),
      itemCount: widget.items.length,
      itemBuilder: (context, i) {
        final message = widget.items[i];
        // 바로 아래(= 목록에서 다음) 메시지와 작성자가 같으면 머리말을 생략한다.
        final next = i + 1 < widget.items.length ? widget.items[i + 1] : null;
        final grouped = next != null &&
            next.author.id == message.author.id &&
            !message.isDeleted &&
            !next.isDeleted &&
            message.createdAt.difference(next.createdAt).inMinutes.abs() < 5;

        return _MessageTile(message: message, grouped: grouped);
      },
    );
  }
}

class _MessageTile extends ConsumerWidget {
  const _MessageTile({required this.message, required this.grouped});

  final Message message;
  final bool grouped;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    if (message.isDeleted) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(
          NexusSpacing.sp5,
          NexusSpacing.sp1,
          NexusSpacing.sp5,
          NexusSpacing.sp1,
        ),
        child: Text(
          '삭제된 메시지입니다.',
          style: theme.textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
        ),
      );
    }

    return GestureDetector(
      // 리액션을 다는 입구. 탭은 이미 다른 뜻으로 쓰일 여지가 있어(스레드 등)
      // 길게 누르기로 둔다.
      behavior: HitTestBehavior.opaque,
      onLongPress: message.isLocal
          ? null
          : () => _pickReaction(context, ref, message),
      child: Padding(
      padding: EdgeInsets.fromLTRB(
        NexusSpacing.sp5,
        grouped ? 1 : NexusSpacing.sp3,
        NexusSpacing.sp5,
        1,
      ),
      child: Opacity(
        // 아직 서버에 닿지 않은 메시지는 흐리게 — 보냈는지 아닌지가 보여야 한다.
        opacity: message.pending ? 0.5 : 1,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 36,
              child: grouped
                  ? null
                  : NexusAvatar(
                      seed: message.author.id,
                      label: message.author.name,
                      size: 32,
                    ),
            ),
            const SizedBox(width: NexusSpacing.sp3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!grouped)
                    Row(
                      children: [
                        Text(message.author.name,
                            style: theme.textTheme.titleSmall),
                        const SizedBox(width: NexusSpacing.sp2),
                        Text(_hhmm(message.createdAt),
                            style: theme.textTheme.labelSmall),
                      ],
                    ),
                  Text(message.body, style: theme.textTheme.bodyMedium),
                  if (message.editedAt != null)
                    Text('(수정됨)', style: theme.textTheme.labelSmall),
                  if (message.reactions.isNotEmpty)
                    _ReactionBar(message: message),
                  if (message.failed) _FailedActions(message: message),
                ],
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  static String _hhmm(DateTime at) {
    final local = at.toLocal();
    return '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
  }
}

/// 자주 쓰는 이모지. 전체 이모지 검색은 나중 일이고, 지금은 **한 번에 손이
/// 닿는 것**이 목적이라 짧게 둔다.
const _quickEmojis = ['👍', '🎉', '😄', '👀', '🙏', '🔥', '❤️', '😢'];

/// 길게 눌렀을 때 뜨는 이모지 고르기. 이미 누른 것은 표시해 둔다.
Future<void> _pickReaction(
  BuildContext context,
  WidgetRef ref,
  Message message,
) async {
  final mine = {
    for (final r in message.reactions)
      if (r.mine) r.emoji,
  };

  final picked = await showModalBottomSheet<String>(
    context: context,
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(NexusSpacing.sp4),
        child: Wrap(
          spacing: NexusSpacing.sp2,
          runSpacing: NexusSpacing.sp2,
          children: [
            for (final emoji in _quickEmojis)
              InkWell(
                onTap: () => Navigator.of(sheetContext).pop(emoji),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(NexusSpacing.sp3),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    // 이미 누른 것은 테두리로 표시한다 — 다시 누르면 취소다.
                    border: mine.contains(emoji)
                        ? Border.all(
                            color: Theme.of(sheetContext).colorScheme.primary)
                        : null,
                  ),
                  child: Text(emoji, style: const TextStyle(fontSize: 24)),
                ),
              ),
          ],
        ),
      ),
    ),
  );

  if (picked != null) {
    await ref.read(messageActionsProvider).toggleReaction(message, picked);
  }
}

/// 메시지에 달린 이모지들. 누르면 켜고 꺼진다.
class _ReactionBar extends ConsumerWidget {
  const _ReactionBar({required this.message});

  final Message message;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(top: NexusSpacing.sp1),
      child: Wrap(
        spacing: NexusSpacing.sp2,
        runSpacing: NexusSpacing.sp1,
        children: [
          for (final reaction in message.reactions)
            InkWell(
              onTap: () => ref
                  .read(messageActionsProvider)
                  .toggleReaction(message, reaction.emoji),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: NexusSpacing.sp2,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  // 내가 누른 것은 강조한다. 개수만 보여서는 내가 눌렀는지 알 수 없다.
                  color: reaction.mine
                      ? theme.colorScheme.primary.withValues(alpha: 0.18)
                      : theme.colorScheme.surfaceContainerHighest,
                  border: reaction.mine
                      ? Border.all(color: theme.colorScheme.primary)
                      : null,
                ),
                child: Text(
                  '${reaction.emoji} ${reaction.count}',
                  style: theme.textTheme.labelSmall,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// 전송 실패한 메시지는 지우지 않고 남긴다 — 조용히 사라지면 보냈다고 믿는다.
class _FailedActions extends ConsumerWidget {
  const _FailedActions({required this.message});

  final Message message;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final actions = ref.read(messageActionsProvider);

    return Row(
      children: [
        Text('보내지 못했습니다',
            style: theme.textTheme.labelSmall
                ?.copyWith(color: theme.colorScheme.error)),
        TextButton(
          onPressed: () => actions.retry(message),
          child: const Text('재시도'),
        ),
        TextButton(
          onPressed: () => actions.discard(message),
          child: const Text('삭제'),
        ),
      ],
    );
  }
}

/// Enter 로 전송하기 위한 Intent. Shift+Enter 는 여기 걸리지 않는다.
class _SendIntent extends Intent {
  const _SendIntent();
}

class _Composer extends ConsumerStatefulWidget {
  const _Composer();

  @override
  ConsumerState<_Composer> createState() => _ComposerState();
}

class _ComposerState extends ConsumerState<_Composer> {
  final _controller = TextEditingController();
  final _focus = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _send() {
    final text = _controller.text;
    if (text.trim().isEmpty) return;
    // 낙관적 전송이라 기다리지 않는다. 입력창은 즉시 비운다.
    ref.read(messageActionsProvider).send(text);
    _controller.clear();
    _focus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final channel = ref.watch(currentChannelProvider);

    return Container(
      padding: const EdgeInsets.all(NexusSpacing.sp4),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: theme.dividerColor)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              // 여러 줄 입력이라 Enter 가 기본적으로 줄바꿈이 된다. 채팅에서는
              // Enter 가 전송이어야 하므로 가로챈다. **Shift+Enter 는 그대로
              // 줄바꿈** — SingleActivator 가 수식키까지 정확히 일치할 때만
              // 발동하므로, Shift 가 눌린 Enter 는 TextField 로 흘러간다.
              child: Shortcuts(
                shortcuts: const <ShortcutActivator, Intent>{
                  SingleActivator(LogicalKeyboardKey.enter): _SendIntent(),
                  SingleActivator(LogicalKeyboardKey.numpadEnter): _SendIntent(),
                },
                child: Actions(
                  actions: <Type, Action<Intent>>{
                    _SendIntent: CallbackAction<_SendIntent>(
                      onInvoke: (_) {
                        _send();
                        return null;
                      },
                    ),
                  },
                  child: TextField(
                    controller: _controller,
                    focusNode: _focus,
                    minLines: 1,
                    maxLines: 5,
                    decoration: InputDecoration(
                      hintText: channel == null
                          ? '채널을 선택하세요'
                          : '#${channel.name} 에 메시지 보내기',
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: NexusSpacing.sp3),
            IconButton.filled(
              onPressed: channel == null ? null : _send,
              icon: const Icon(Icons.send, size: 18),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyBlock extends StatelessWidget {
  const _EmptyBlock();

  @override
  Widget build(BuildContext context) => Center(
        child: Text(
          '첫 메시지를 보내 보세요.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      );
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(text, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: NexusSpacing.sp4),
          OutlinedButton(onPressed: onRetry, child: const Text('다시 시도')),
        ],
      ),
    );
  }
}
