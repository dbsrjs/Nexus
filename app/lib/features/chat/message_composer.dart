import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/message.dart';
import '../../domain/models/space_member.dart';
import '../../shared/widgets/user_avatar.dart';
import '../../ui/ui.dart';
import '../auth/auth_controller.dart';
import '../channel/channel_controller.dart';
import '../channel/dm.dart';
import '../presence/typing_controller.dart';
import '../realtime/socket_controller.dart';
import '../space/members_controller.dart';
import '../space/space_controller.dart';
import 'attachment_draft.dart';
import 'attachment_widgets.dart';
import 'mention_autocomplete.dart';
import 'mention_composer_controller.dart';
import 'mention_text.dart';
import 'message_controller.dart';

/// Enter 로 전송하기 위한 Intent. Shift+Enter 는 여기 걸리지 않는다.
class _SendIntent extends Intent {
  const _SendIntent();
}

/// 물리 키보드가 주인 플랫폼 — Enter 전송 안내를 보인다. 모바일 소프트 키보드는 Enter 를
/// IME 가 줄바꿈으로 쓴다(CLAUDE.md 앱 규칙). 폭이 아니라 입력 방식의 차이다.
bool get _hardwareKeyboard =>
    defaultTargetPlatform != TargetPlatform.android &&
    defaultTargetPlatform != TargetPlatform.iOS;

/// 채널(또는 스레드)마다 쓰다 만 글. 채널을 옮겨도 입력창 State 는 그대로라, 이것이 없으면
/// **쓰던 글이 다른 대화의 입력창에 남았다** — 엉뚱한 곳으로 보내기 쉽다(17단계 Android 확인에서 봤다).
/// 앱이 사는 동안만 둔다(저장하지 않는다). 열쇠는 `channelId|parentId`.
final composerDraftsProvider = Provider<ComposerDrafts>((ref) => ComposerDrafts());

class ComposerDrafts {
  final Map<String, MentionDraft> byKey = {};
}

/// 입력창. 채널과 스레드가 함께 쓴다 — Enter 전송 · IME 처리가 한 벌이어야 한다.
class MessageComposer extends ConsumerStatefulWidget {
  const MessageComposer({super.key, this.onSend, this.hint, this.channelId, this.parentId});

  /// 비우면 채널 전송. 스레드는 답글 전송을 넘긴다.
  final void Function(String body, List<MessageAttachment> attachments)? onSend;

  /// 비우면 현재 채널 이름으로 만든다.
  final String? hint;

  /// 「입력 중」을 알릴 채널(17단계 D21). 비우면 현재 채널. 스레드는 셸 밖이라 넘긴다.
  final String? channelId;

  /// 스레드면 그 부모 메시지 — 스레드의 「입력 중」은 스레드에만 뜬다(D24).
  final String? parentId;

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

  /// 초안 보관함. dispose 에서 ref 를 읽지 않도록 처음 build 에서 잡아 둔다(CLAUDE.md §2).
  Map<String, MentionDraft>? _store;

  String? _draftKey;

  String? _keyFor(String? channelId) =>
      channelId == null ? null : '$channelId|${widget.parentId ?? ''}';

  /// 지금 글을 그 대화의 초안으로 넣어 둔다. 비었으면 지운다.
  void _stash(String? key) {
    final store = _store;
    if (key == null || store == null) return;
    if (_controller.text.trim().isEmpty) {
      store.remove(key);
    } else {
      store[key] = _controller.draft;
    }
  }

  @override
  void dispose() {
    // 셸 밖(설정 창)으로 나가며 입력창이 내려가도 쓰던 글을 잃지 않는다.
    _stash(_draftKey);
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

  /// 마지막으로 「입력 중」을 보낸 시각(D21 — 3초에 한 번).
  DateTime? _typingSentAt;

  void _announceTyping() {
    if (_controller.text.trim().isEmpty) return;
    final now = DateTime.now();
    final last = _typingSentAt;
    if (last != null && now.difference(last) < typingSendEvery) return;
    final spaceId = ref.read(currentSpaceIdProvider);
    final channelId = widget.channelId ?? ref.read(currentChannelIdProvider);
    if (spaceId == null || channelId == null) return;
    _typingSentAt = now;
    ref.read(socketClientProvider).sendTyping(
          spaceId: spaceId,
          channelId: channelId,
          parentId: widget.parentId,
        );
  }

  /// 글자가 바뀌었을 때만 알린다 — 커서만 옮긴 것은 입력이 아니다.
  String _lastText = '';

  void _onTextChanged() {
    if (_controller.text != _lastText) {
      _lastText = _controller.text;
      _announceTyping();
    }
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
    final send =
        widget.onSend ??
        (String b, List<MessageAttachment> a) =>
            ref.read(messageActionsProvider).send(b, attachments: a);
    send(body, attachments);
    _attachments?.clear();
    _controller.clear();
    _store?.remove(_draftKey);
    setState(() => _mentionQuery = null);
    _focus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final nx = NxTheme.of(context);
    final c = nx.colors;
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

    // **쓰던 글은 그 대화에 남긴다.** 옮기기 전 대화의 초안으로 넣어 두고, 옮긴 대화의 초안을
    // 꺼낸다. 입력창을 고치면 리스너가 setState 를 부르므로 꺼내는 일은 프레임 뒤로 미룬다.
    final store = _store ?? ref.read(composerDraftsProvider).byKey;
    _store = store;
    final key = _keyFor(widget.channelId ?? channelId);
    if (key != _draftKey) {
      _stash(_draftKey);
      _draftKey = key;
      final next = key == null ? null : store.remove(key);
      if (next != null || _controller.text.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted || _draftKey != key) return;
          final draft = next ?? const MentionDraft();
          // 되살린 글은 입력이 아니다 — 「입력 중」을 보내지 않는다.
          _lastText = draft.text;
          _controller.restore(draft);
          setState(() => _mentionQuery = null);
        });
      }
    }

    final drafts = _attachments?.drafts ?? const <AttachmentDraft>[];
    final uploading = _attachments?.isUploading ?? false;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        NxSpacing.sp7,
        NxSpacing.sp4,
        NxSpacing.sp7,
        NxSpacing.sp6,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_mentionQuery != null)
            _MentionSuggestions(query: _mentionQuery!, onPick: _insertMention),
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
          // 캔버스 「채널」 — 한 판 안에 첨부 · 입력 · 보내기.
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: c.bgElevated,
              borderRadius: BorderRadius.circular(NxRadius.md),
              border: Border.all(color: c.borderStrong),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                NxIconButton(
                  icon: NxIcons.attach,
                  label: '파일 첨부',
                  onPressed: channel == null ? null : _pickFiles,
                ),
                const SizedBox(width: NxSpacing.sp2),
                Expanded(
                  // 여러 줄 입력이라 Enter 가 기본적으로 줄바꿈이 된다. 채팅에서는
                  // Enter 가 전송이어야 하므로 가로챈다. **Shift+Enter 는 그대로
                  // 줄바꿈** — SingleActivator 가 수식키까지 정확히 일치할 때만
                  // 발동하므로, Shift 가 눌린 Enter 는 입력으로 흘러간다.
                  child: Shortcuts(
                    shortcuts: const <ShortcutActivator, Intent>{
                      SingleActivator(LogicalKeyboardKey.enter): _SendIntent(),
                      SingleActivator(LogicalKeyboardKey.numpadEnter):
                          _SendIntent(),
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
                      // 아이콘 버튼(32px)과 같은 최소 높이에 가운데 — 한 줄일 때 글자가 버튼과
                      // 가운데가 맞는다. 없으면 한 줄(24px)이 줄의 바닥에 붙어 4px 처졌다.
                      // 여러 줄로 늘면 칸이 커지고 버튼은 바닥에 남는다(줄은 end 맞춤).
                      child: Container(
                        constraints: const BoxConstraints(minHeight: 32),
                        alignment: Alignment.centerLeft,
                        child: NxField(
                          controller: _controller,
                          focusNode: _focus,
                          borderless: true,
                          minLines: 1,
                          maxLines: 5,
                          style: nx.text.body,
                          hint:
                              widget.hint ??
                              (channel == null
                                  ? '채널을 선택하세요'
                                  : channel.isDm
                                  ? '${dmPeerName(ref.watch(memberProfilesProvider), channel)} 님에게 메시지 보내기'
                                  : '#${channel.name} 에 메시지 보내기'),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: NxSpacing.sp2),
                NxIconButton(
                  icon: NxIcons.send,
                  label: '보내기',
                  filled: true,
                  // 올라가는 중에는 막는다 — 아직 id 가 없는 첨부는 실을 수 없다.
                  onPressed: channel == null || uploading ? null : _send,
                ),
              ],
            ),
          ),
          if (_hardwareKeyboard)
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 6, 4, 0),
              child: ExcludeSemantics(
                child: Text(
                  'Enter 보내기 · Shift+Enter 줄바꿈',
                  style: nx.text.mono.copyWith(color: c.borderStrong),
                ),
              ),
            ),
        ],
      ),
    );
  }
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
    final c = NxTheme.of(context).colors;
    final members = ref.watch(spaceMembersProvider).value ?? const [];
    final auth = ref.watch(authControllerProvider);
    final myId = auth is AuthSignedIn ? auth.user.id : null;

    final matches = filterMembers(members, query.text, excludeUserId: myId);
    if (matches.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: NxSpacing.sp4),
      padding: const EdgeInsets.all(NxSpacing.sp2),
      constraints: const BoxConstraints(maxHeight: 220),
      decoration: BoxDecoration(
        color: c.bgElevated,
        borderRadius: BorderRadius.circular(NxRadius.md),
        border: Border.all(color: c.divider),
      ),
      child: ListView.builder(
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        itemCount: matches.length,
        itemBuilder: (context, i) {
          final member = matches[i];
          return NxRow(
            dense: true,
            leading: UserAvatar(
              userId: member.userId,
              name: member.displayName,
              avatarUrl: member.avatarUrl,
              size: 22,
            ),
            title: member.displayName,
            onPressed: () => onPick(member),
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

    final nx = NxTheme.of(context);
    final c = nx.colors;

    return Container(
      margin: const EdgeInsets.only(bottom: NxSpacing.sp4),
      padding: const EdgeInsets.only(left: NxSpacing.sp4),
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: c.accent, width: 2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${target.author.name} 에게 답장',
                  style: nx.text.meta.copyWith(
                    color: c.accent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  mentionPlainText(
                    target.body,
                    target.mentions,
                    fallbackNames: ref.watch(memberNamesProvider),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: nx.text.secondary,
                ),
              ],
            ),
          ),
          // 취소가 없으면 한번 고른 답장에서 빠져나올 수 없다.
          NxIconButton(
            icon: NxIcons.close,
            label: '답장 취소',
            onPressed: () => ref.read(replyTargetProvider.notifier).clear(),
          ),
        ],
      ),
    );
  }
}
