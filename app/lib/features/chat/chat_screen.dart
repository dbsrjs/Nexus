import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';
import '../../data/api/api_failure.dart';
import '../../domain/models/message.dart';
import '../../shared/markdown/markdown_body.dart';
import '../../shared/widgets/nexus_avatar.dart';
import '../channel/channel_controller.dart';
import '../realtime/socket_controller.dart';
import '../space/space_controller.dart';
import '../../domain/models/space_member.dart';
import '../auth/auth_controller.dart';
import '../space/members_controller.dart';
import 'attachment_draft.dart';
import 'attachment_widgets.dart';
import 'mention_autocomplete.dart';
import 'mention_composer_controller.dart';
import 'mention_text.dart';
import 'message_controller.dart';
import '../issue/new_issue_sheet.dart';

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
                : MessageList(items: items),
          ),
        ),
        const MessageComposer(),
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
          const _PinnedButton(),
          const _FilesButton(),
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

        return MessageTile(message: message, grouped: grouped);
      },
    );
  }
}

class MessageTile extends ConsumerWidget {
  const MessageTile({super.key, required this.message, required this.grouped});

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

    // 저장소 이벤트가 만든 메시지면 그 push 의 커밋으로 들어간다(10-3b).
    // **`repoEventId` 가 없는 메시지는 탭이 아무 일도 하지 않는다** — 사람이
    // 쓴 메시지를 눌렀을 때 빈 화면이 열리면 안 된다.
    final repoEventId = message.repoEventId;
    final spaceId = ref.watch(currentSpaceIdProvider);

    return GestureDetector(
      // 리액션을 다는 입구. 탭은 이미 다른 뜻으로 쓰일 여지가 있어(스레드 등)
      // 길게 누르기로 둔다.
      behavior: HitTestBehavior.opaque,
      onTap: repoEventId == null || spaceId == null
          ? null
          : () => context.push('/s/$spaceId/repo-events/$repoEventId'),
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
                  if (message.quoted != null) _QuoteBlock(quoted: message.quoted!),
                  // 본문이 비어 있을 수 있다 — 첨부만 보낸 메시지다.
                  if (message.body.isNotEmpty || message.attachments.isEmpty)
                    _MessageBody(message: message),
                  for (final attachment in message.attachments)
                    AttachmentRow(attachment: attachment, message: message),
                  if (message.editedAt != null)
                    Text('(수정됨)', style: theme.textTheme.labelSmall),
                  if (message.reactions.isNotEmpty)
                    _ReactionBar(message: message),
                  if (message.pinned) const _PinnedMark(),
                  if (message.hasThread) _ThreadSummary(message: message),
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

/// 메시지 본문. 멘션을 이름으로 바꿔 그린다.
///
/// 본문에는 `<@uuid>` 가 박혀 있고 사람이 읽을 이름은 따로 온다. 이름을 본문에
/// 저장하지 않는 이유는 사용자가 이름을 바꾸면 지난 메시지가 낡기 때문이다.
class _MessageBody extends ConsumerWidget {
  const _MessageBody({required this.message});

  final Message message;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final base = theme.textTheme.bodyMedium;

    // **마크다운은 멘션까지 함께 그린다** — 파서가 하나이기 때문이다
    // (마크다운 설계 §0). 서식이 없으면 위젯이 파싱을 건너뛴다.
    //
    // 아직 보내지 못한 메시지에는 서버가 붙여 주는 멘션 목록이 없다. 멤버
    // 목록으로 이름을 채우지 않으면 큐에 있는 동안만 `@알 수 없음` 으로 보인다.
    return MarkdownBody(
      body: message.body,
      mentions: message.mentions,
      fallbackNames: ref.watch(memberNamesProvider),
      style: base,
    );
  }
}

/// 답장이 가리키는 원본. 본문 위에 접어서 보여 준다.
///
/// 한 겹만 그린다 — 인용의 인용까지 펼치면 화면이 계단이 된다. 서버도 요약을
/// 한 겹만 준다.
class _QuoteBlock extends ConsumerWidget {
  const _QuoteBlock({required this.quoted});

  final QuotedMessage quoted;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.color;

    return Container(
      margin: const EdgeInsets.only(bottom: NexusSpacing.sp1),
      padding: const EdgeInsets.only(left: NexusSpacing.sp3),
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(color: theme.dividerColor, width: 3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(quoted.authorName, style: theme.textTheme.labelSmall),
          Text(
            // 원본이 지워져도 인용은 남긴다 — 답장의 맥락은 그때도 필요하다.
            //
            // 인용 요약에는 멘션 목록이 없다(서버가 본문만 준다). 멤버 목록으로
            // 이름을 채우지 않으면 인용문에 uuid 가 그대로 보인다.
            quoted.deleted
                ? '삭제된 메시지입니다.'
                : mentionPlainText(
                    quoted.body,
                    const [],
                    fallbackNames: ref.watch(memberNamesProvider),
                  ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: muted,
              fontStyle: quoted.deleted ? FontStyle.italic : null,
            ),
          ),
        ],
      ),
    );
  }
}

/// "답글 3개" — 스레드로 들어가는 입구.
///
/// 답글 수가 0 이면 그리지 않는다. 스레드를 시작하는 것은 길게 누르기 메뉴다.
class _ThreadSummary extends ConsumerWidget {
  const _ThreadSummary({required this.message});

  final Message message;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(top: NexusSpacing.sp1),
      child: InkWell(
        onTap: () => _openThread(context, ref, message),
        borderRadius: BorderRadius.circular(NexusRadius.md),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Text(
            '답글 ${message.replyCount}개',
            style: theme.textTheme.labelSmall
                ?.copyWith(color: theme.colorScheme.primary),
          ),
        ),
      ),
    );
  }
}

/// 스레드 화면으로. 라우트가 진실의 원천이라 push 로 연다.
void _openThread(BuildContext context, WidgetRef ref, Message message) {
  final spaceId = ref.read(currentSpaceIdProvider);
  if (spaceId == null) return;
  context.push('/s/$spaceId/c/${message.channelId}/t/${message.id}');
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: NexusSpacing.sp2,
              runSpacing: NexusSpacing.sp2,
              children: [
                for (final emoji in _quickEmojis)
                  InkWell(
                    onTap: () => Navigator.of(sheetContext).pop(emoji),
                    borderRadius: BorderRadius.circular(NexusRadius.md),
                    child: Container(
                      padding: const EdgeInsets.all(NexusSpacing.sp3),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(NexusRadius.md),
                        // 이미 누른 것은 테두리로 표시한다 — 다시 누르면 취소다.
                        border: mine.contains(emoji)
                            ? Border.all(
                                color:
                                    Theme.of(sheetContext).colorScheme.primary)
                            : null,
                      ),
                      child: Text(emoji, style: const TextStyle(fontSize: 24)),
                    ),
                  ),
              ],
            ),
            const Divider(height: NexusSpacing.sp5),
            // 답장은 흐름 안에 남고, 스레드는 곁가지로 접힌다. 둘을 나란히
            // 두어 차이가 보이게 한다.
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.reply_outlined),
              title: const Text('답장'),
              subtitle: const Text('이 메시지를 인용해 대화에서 답한다'),
              onTap: () => Navigator.of(sheetContext).pop(_replyAction),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.forum_outlined),
              title: const Text('스레드로 답글'),
              subtitle: const Text('대화에서 빼내어 따로 이어 간다'),
              onTap: () => Navigator.of(sheetContext).pop(_threadAction),
            ),
            // 대화 → 이슈. 원문이 이슈에 링크로 남아, 이슈에서 이 대화로
            // 돌아올 수 있다.
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.dashboard_customize_outlined),
              title: const Text('이슈로 만들기'),
              subtitle: const Text('이 메시지를 보드의 할 일로 옮긴다'),
              onTap: () => Navigator.of(sheetContext).pop(_issueAction),
            ),
            // 답글은 고정할 수 없다(서버가 400). 항목 자체를 감춘다 -
            // 눌러 봐야 실패하는 버튼은 없느니만 못하다.
            if (message.parentId == null)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  message.pinned ? Icons.push_pin : Icons.push_pin_outlined,
                ),
                title: Text(message.pinned ? '고정 해제' : '고정'),
                subtitle: const Text('채널 상단에서 언제든 찾을 수 있다'),
                onTap: () => Navigator.of(sheetContext).pop(_pinAction),
              ),
          ],
        ),
      ),
    ),
  );

  if (picked == null) return;
  if (picked == _threadAction) {
    if (context.mounted) _openThread(context, ref, message);
    return;
  }
  if (picked == _replyAction) {
    ref.read(replyTargetProvider.notifier).set(message);
    return;
  }
  if (picked == _pinAction) {
    await ref.read(messageActionsProvider).togglePin(message);
    return;
  }
  if (picked == _issueAction) {
    if (context.mounted) await showNewIssueSheet(context, fromMessage: message);
    return;
  }
  await ref.read(messageActionsProvider).toggleReaction(message, picked);
}

/// 이모지가 아닌 선택지를 같은 시트에서 돌려주기 위한 표식.
/// 앞의 공백 덕분에 실제 이모지와 겹칠 일이 없다 — 이모지는 공백을 못 쓴다.
const _threadAction = ' thread';
const _replyAction = ' reply';
const _pinAction = ' pin';
const _issueAction = ' issue';

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
              borderRadius: BorderRadius.circular(NexusRadius.md),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: NexusSpacing.sp2,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(NexusRadius.md),
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

/// 입력창. 채널과 스레드가 함께 쓴다 — Enter 전송·IME 처리가 한 벌이어야 한다.
class MessageComposer extends ConsumerStatefulWidget {
  const MessageComposer({super.key, this.onSend, this.hint});

  /// 비우면 채널 전송. 스레드는 답글 전송을 넘긴다.
  final void Function(String body, List<MessageAttachment> attachments)? onSend;

  /// 비우면 현재 채널 이름으로 만든다.
  final String? hint;

  @override
  ConsumerState<MessageComposer> createState() => MessageComposerState();
}

class MessageComposerState extends ConsumerState<MessageComposer> {
  /// 입력창에는 `@닉네임` 이 보이고 보낼 때만 `<@id>` 로 되돌린다.
  final _controller = MentionComposerController();
  final _focus = FocusNode();

  /// 지금 치고 있는 멘션. null 이면 후보를 띄우지 않는다.
  MentionQuery? _mentionQuery;

  /// 담아 둔 첨부. 고르는 즉시 올라간다.
  AttachmentDraftController? _attachments;

  /// 첨부를 담아 둔 채로 채널을 옮겼는지 보기 위해 들고 있는다.
  String? _channelId;

  @override
  void initState() {
    super.initState();
    // 선택 영역이 바뀌어도(커서 이동) 다시 판단해야 한다 — 커서를 옮겨 이전
    // 멘션 자리로 돌아갈 수 있다.
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _attachments?.dispose();
    _focus.dispose();
    super.dispose();
  }

  /// 첨부 컨트롤러를 늦게 만든다 — `ref` 를 initState 에서 읽을 수 없다.
  ///
  /// **`??=` 와 캐스케이드를 한 줄에 쓰지 않는다.** Dart 에서 `..` 는 대입보다
  /// 느슨해서 `a ??= B()..listen()` 이 `(a ??= B())..listen()` 으로 묶인다 —
  /// 이 getter 를 읽을 때마다 리스너가 하나씩 더 붙는다.
  AttachmentDraftController get _drafts {
    final existing = _attachments;
    if (existing != null) return existing;

    final created = AttachmentDraftController(ref.read(attachmentsApiProvider));
    created.addListener(_onDraftsChanged);
    return _attachments = created;
  }

  void _onDraftsChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _pickFiles() async {
    final spaceId = ref.read(currentSpaceIdProvider);
    final channelId = ref.read(currentChannelIdProvider);
    if (spaceId == null || channelId == null) return;

    await _drafts.pick(spaceId: spaceId, channelId: channelId);
    _focus.requestFocus();
  }

  void _onTextChanged() {
    final selection = _controller.selection;
    // 범위를 잡고 있으면(드래그) 멘션을 치는 중이 아니다.
    final query = selection.isValid && selection.isCollapsed
        ? findMentionQuery(_controller.text, selection.baseOffset)
        : null;

    if (query?.start != _mentionQuery?.start ||
        query?.text != _mentionQuery?.text) {
      setState(() => _mentionQuery = query);
    }
  }

  void _insertMention(SpaceMemberProfile member) {
    final query = _mentionQuery;
    if (query == null) return;

    _controller.insertMention(query, member);
    setState(() => _mentionQuery = null);
    _focus.requestFocus();
  }

  void _send() {
    // **올라가는 중에는 보내지 않는다.** 아직 id 가 없는 첨부는 실을 수 없고,
    // 빼고 보내면 사용자가 붙인 파일이 조용히 사라진다.
    if (_attachments?.isUploading ?? false) return;

    final attachments = _attachments?.uploaded ?? const <MessageAttachment>[];
    // 첨부만 보내는 경우가 있어 본문이 비어도 된다.
    if (_controller.text.trim().isEmpty && attachments.isEmpty) return;

    // 보내는 것은 보이는 글자가 아니라 id 로 되돌린 본문이다.
    final body = _controller.body;
    // 낙관적 전송이라 기다리지 않는다. 입력창은 즉시 비운다.
    final send = widget.onSend ??
        (String b, List<MessageAttachment> a) =>
            ref.read(messageActionsProvider).send(b, attachments: a);
    send(body, attachments);
    _attachments?.clear();
    _controller.clear();
    setState(() => _mentionQuery = null);
    _focus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final channel = ref.watch(currentChannelProvider);

    // **채널을 옮기면 담아 둔 첨부를 버린다.** 업로드 주소에 채널이 들어 있어,
    // 들고 옮기면 엉뚱한 채널에 올라간 파일을 붙이게 된다.
    //
    // 비우는 일을 **프레임이 끝난 뒤로 미룬다.** `clear()` 는 리스너를 통해
    // `setState` 를 부르는데, build 안에서 그러면 Flutter 가 예외를 던진다.
    final channelId = ref.watch(currentChannelIdProvider);
    if (_channelId != channelId) {
      _channelId = channelId;
      final pending = _attachments;
      if (pending != null && !pending.isEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) => pending.clear());
      }
    }

    final drafts = _attachments?.drafts ?? const <AttachmentDraft>[];
    final uploading = _attachments?.isUploading ?? false;

    return Container(
      padding: const EdgeInsets.all(NexusSpacing.sp4),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: theme.dividerColor)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_mentionQuery != null)
              _MentionSuggestions(
                query: _mentionQuery!,
                onPick: _insertMention,
              ),
            // 답장 대상이 있으면 입력창 위에 띄운다. 무엇에 답하는지 보이지
            // 않으면 엉뚱한 메시지에 답하기 쉽다.
            if (widget.onSend == null) const _ReplyPreview(),
            if (drafts.isNotEmpty)
              AttachmentDraftBar(
                drafts: drafts,
                onRemove: (id) => _drafts.remove(id),
                onRetry: (id) {
                  final spaceId = ref.read(currentSpaceIdProvider);
                  final channel = ref.read(currentChannelIdProvider);
                  if (spaceId == null || channel == null) return;
                  _drafts.retry(id, spaceId: spaceId, channelId: channel);
                },
              ),
            Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            IconButton(
              onPressed: channel == null ? null : _pickFiles,
              icon: const Icon(Icons.attach_file, size: 20),
              tooltip: '파일 첨부',
            ),
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
                      hintText: widget.hint ??
                          (channel == null
                              ? '채널을 선택하세요'
                              : '#${channel.name} 에 메시지 보내기'),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: NexusSpacing.sp3),
            IconButton.filled(
              // 올라가는 중에는 막는다 — 아직 id 가 없는 첨부는 실을 수 없다.
              onPressed: channel == null || uploading ? null : _send,
              icon: const Icon(Icons.send, size: 18),
            ),
          ],
        ),
          ],
        ),
      ),
    );
  }
}

/// 고정된 메시지 표시. 목록에서도 한눈에 갈리게 한다.
class _PinnedMark extends StatelessWidget {
  const _PinnedMark();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: NexusSpacing.sp1),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.push_pin, size: 12, color: theme.textTheme.bodySmall?.color),
          const SizedBox(width: 4),
          Text('고정됨', style: theme.textTheme.labelSmall),
        ],
      ),
    );
  }
}

/// 채널 헤더의 고정 목록 버튼. 누르면 시트로 목록을 연다.
class _PinnedButton extends ConsumerWidget {
  const _PinnedButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      tooltip: '고정된 메시지',
      icon: const Icon(Icons.push_pin_outlined, size: 18),
      onPressed: () => _showPinned(context, ref),
    );
  }
}

/// 스페이스 파일 목록으로 가는 버튼.
///
/// 채널이 아니라 **스페이스** 단위인 이유는 파일을 찾을 때 어느 채널에
/// 올렸는지 기억하지 못하는 편이 흔해서다. 서버가 볼 수 있는 채널의 것만 준다.
class _FilesButton extends ConsumerWidget {
  const _FilesButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spaceId = ref.watch(currentSpaceIdProvider);
    return IconButton(
      tooltip: '파일',
      icon: const Icon(Icons.folder_outlined, size: 18),
      onPressed: spaceId == null ? null : () => context.push('/s/$spaceId/files'),
    );
  }
}

/// 고정 목록 시트.
///
/// 캐시를 거치지 않고 열 때마다 서버에서 받는다 - 자주 여는 화면이 아니고,
/// 없다고 대화를 읽는 데 지장이 없다.
Future<void> _showPinned(BuildContext context, WidgetRef ref) async {
  final messages = await ref.read(messageActionsProvider).pinnedMessages();
  if (!context.mounted) return;

  await showModalBottomSheet<void>(
    context: context,
    builder: (sheetContext) {
      final theme = Theme.of(sheetContext);
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(NexusSpacing.sp4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('고정된 메시지', style: theme.textTheme.titleSmall),
              const SizedBox(height: NexusSpacing.sp3),
              if (messages.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: NexusSpacing.sp5,
                  ),
                  child: Text(
                    '아직 고정된 메시지가 없습니다.',
                    style: theme.textTheme.bodySmall,
                  ),
                )
              else
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: messages.length,
                    itemBuilder: (_, i) => MessageTile(
                      message: messages[i],
                      grouped: false,
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    },
  );
}

/// 멘션 후보 목록. 입력창 위에 뜬다.
///
/// 서버가 본문에 `<@userId>` 형식을 요구하므로 **이것이 없으면 사용자가 멘션을
/// 만들 방법이 없다.** 자동완성은 편의가 아니라 필수 경로다.
class _MentionSuggestions extends ConsumerWidget {
  const _MentionSuggestions({required this.query, required this.onPick});

  final MentionQuery query;
  final void Function(SpaceMemberProfile) onPick;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final members = ref.watch(spaceMembersProvider).value ?? const [];
    final auth = ref.watch(authControllerProvider);
    final myId = auth is AuthSignedIn ? auth.user.id : null;

    final matches =
        filterMembers(members, query.text, excludeUserId: myId);
    if (matches.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: NexusSpacing.sp3),
      constraints: const BoxConstraints(maxHeight: 220),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(NexusRadius.md),
        border: Border.all(color: theme.dividerColor),
      ),
      child: ListView.builder(
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        itemCount: matches.length,
        itemBuilder: (context, i) {
          final member = matches[i];
          return ListTile(
            dense: true,
            leading: NexusAvatar(
              seed: member.userId,
              label: member.displayName,
              size: 28,
            ),
            title: Text(member.displayName, style: theme.textTheme.bodyMedium),
            onTap: () => onPick(member),
          );
        },
      ),
    );
  }
}

/// 답장 대상 미리보기. 입력창 바로 위에 붙는다.
class _ReplyPreview extends ConsumerWidget {
  const _ReplyPreview();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final target = ref.watch(replyTargetProvider);
    if (target == null) return const SizedBox.shrink();

    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: NexusSpacing.sp3),
      padding: const EdgeInsets.only(left: NexusSpacing.sp3),
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(color: theme.colorScheme.primary, width: 3),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${target.author.name} 에게 답장',
                  style: theme.textTheme.labelSmall
                      ?.copyWith(color: theme.colorScheme.primary),
                ),
                Text(
                  mentionPlainText(
                    target.body,
                    target.mentions,
                    fallbackNames: ref.watch(memberNamesProvider),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          IconButton(
            // 취소가 없으면 한번 고른 답장에서 빠져나올 수 없다.
            onPressed: () => ref.read(replyTargetProvider.notifier).clear(),
            icon: const Icon(Icons.close, size: 18),
            tooltip: '답장 취소',
          ),
        ],
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
