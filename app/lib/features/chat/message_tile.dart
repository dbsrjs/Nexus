/// 메시지 한 줄 — 본문 · 인용 · 스레드 요약 · 리액션 · 호버 도구 막대 · 길게 누르기 동작.
/// `chat_screen.dart` 에서 2026-10-06 에 떼어 냈다.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/api/api_failure.dart';
import '../../domain/models/message.dart';
import '../../domain/models/repo_browse.dart';
import '../../shared/markdown/markdown_body.dart';
import '../../shared/widgets/user_avatar.dart';
import '../../ui/ui.dart';
import '../channel/channel_controller.dart';
import '../repo/browse_controller.dart';
import '../space/space_controller.dart';
import '../space/members_controller.dart';
import 'attachment_widgets.dart';
import 'mention_text.dart';
import 'message_controller.dart';
import '../issue/new_issue_sheet.dart';
import 'selection_controller.dart';

/// 마우스가 주인 플랫폼 — 메시지에 올리면 동작 줄이 뜬다. 터치는 길게 눌러 동작 카드를
/// 연다(바텀시트가 아니다, 15단계 D8). 폭이 아니라 입력 방식의 차이다.
bool get _pointerFirst =>
    defaultTargetPlatform != TargetPlatform.android &&
    defaultTargetPlatform != TargetPlatform.iOS;

class MessageTile extends ConsumerStatefulWidget {
  const MessageTile({
    super.key,
    required this.message,
    required this.grouped,
    this.showThreadSummary = true,
  });

  final Message message;
  final bool grouped;

  /// 「답글 N개」. 스레드 화면의 뿌리 메시지는 끈다 — 이미 그 스레드 안이라 누르면
  /// 같은 화면이 한 겹 더 열렸다.
  final bool showThreadSummary;

  @override
  ConsumerState<MessageTile> createState() => _MessageTileState();
}

class _MessageTileState extends ConsumerState<MessageTile> {
  bool _hovered = false;

  Message get message => widget.message;

  /// 동작 카드를 이 메시지 곁에 연다. 터치면 누른 메시지를 막 위로 띄운다(캔버스
  /// 「채널 · 모바일 길게 누르기」).
  void _openActions({required bool withPreview}) {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    final anchor = box.localToGlobal(Offset.zero) & box.size;
    _showMessageActions(
      context,
      ref,
      message,
      anchor: anchor,
      preview: withPreview ? _MessagePreview(message: message) : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final nx = NxTheme.of(context);
    final c = nx.colors;
    final selection = ref.watch(selectionControllerProvider);
    final selected = selection.ids.contains(message.id);
    void toggle() =>
        ref.read(selectionControllerProvider.notifier).toggle(message.id);

    // 선택 모드의 체크 — 탭과 같은 toggle 을 부른다. 곁의 메시지가 이름이라 글자는 숨긴다.
    Widget check() => Padding(
      padding: const EdgeInsets.only(right: NxSpacing.sp4, top: NxSpacing.sp3),
      child: NxCheck(
        value: selected,
        label: '메시지 선택',
        showLabel: false,
        onChanged: (_) => toggle(),
      ),
    );

    if (message.isDeleted) {
      // 선택해 둔 메시지를 다른 사람이 지우면 그 id 가 선택에 남는다 —
      // **골라 둔 것을 뺄 길**이 있어야 한다(전체 닫기 말고). 그래서 지워진
      // 줄도 선택 모드에서는 체크를 보이고 탭 · 체크 둘 다 toggle 을 부른다.
      return Padding(
        padding: const EdgeInsets.fromLTRB(
          NxSpacing.sp7,
          NxSpacing.sp1,
          NxSpacing.sp7,
          NxSpacing.sp1,
        ),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: selection.active ? toggle : null,
          child: Row(
            children: [
              if (selection.active) check(),
              // 본문 칸에 맞춘다(아바타 32 + 간격). 맨 왼쪽에 붙어 있어 앞뒤 메시지의
              // 글과 어긋났다(Android 에서 발견).
              const SizedBox(width: 32 + NxSpacing.sp5),
              Text(
                '삭제된 메시지입니다.',
                style: nx.text.secondary.copyWith(fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
      );
    }

    // 저장소 이벤트가 만든 메시지면 그 kind 로 갈 곳을 가른다(11단계) —
    // **`repoEventId` 가 없는 메시지는 탭이 아무 일도 하지 않는다** — 사람이
    // 쓴 메시지를 눌렀을 때 빈 화면이 열리면 안 된다.
    final repoEventId = message.repoEventId;
    final spaceId = ref.watch(currentSpaceIdProvider);
    final canAct = !message.isLocal && !selection.active;
    final showToolbar = _pointerFirst && _hovered && canAct;

    final body = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (selection.active) check(),
        SizedBox(
          width: 32,
          child: widget.grouped
              ? null
              : UserAvatar(
                  userId: message.author.id,
                  name: message.author.name,
                  avatarUrl: message.author.avatarUrl,
                  size: 32,
                ),
        ),
        const SizedBox(width: NxSpacing.sp5),
        Expanded(
          // **선택 모드에서는 본문 영역 안쪽의 제스처를 전부 죽인다.**
          // 답글 진입(`_ThreadSummary`) · 마크다운 링크 · 첨부 이미지 전체
          // 보기 · 재시도·삭제(`_FailedActions`) 는 각자 자기 탭 인식기를
          // 갖고 있고, Flutter 는 같은 포인터에 대해 **자식 인식기를 부모보다
          // 먼저** 아레나에 올린다 — 바깥 `GestureDetector` 의 `selection.active`
          // 분기만으로는 막히지 않고, 선택 모드에서 이 항목들을 누르면
          // 선택 대신 스레드로 들어가거나 이미지가 열려 사용자가 선택 모드
          // 밖으로 밀려난다(실제로 재현했다). 안쪽 제스처를 하나씩 감싸는
          // 대신 `IgnorePointer` 로 이 서브트리 전체를 한번에 막아, 바깥
          // `GestureDetector`(HitTestBehavior.opaque) 만 탭을 받게 한다.
          child: IgnorePointer(
            ignoring: selection.active,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!widget.grouped)
                  Padding(
                    padding: const EdgeInsets.only(bottom: NxSpacing.sp1),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Flexible(
                          child: Text(
                            message.author.name,
                            overflow: TextOverflow.ellipsis,
                            style: nx.text.strong,
                          ),
                        ),
                        const SizedBox(width: NxSpacing.sp4),
                        Text(_hhmm(message.createdAt), style: nx.text.mono),
                      ],
                    ),
                  ),
                if (message.quoted != null)
                  _QuoteBlock(quoted: message.quoted!),
                // 본문이 비어 있을 수 있다 — 첨부만 보낸 메시지다.
                if (message.body.isNotEmpty || message.attachments.isEmpty)
                  _MessageBody(message: message),
                for (final attachment in message.attachments)
                  AttachmentRow(attachment: attachment, message: message),
                if (message.editedAt != null)
                  Text('(수정됨)', style: nx.text.meta),
                if (message.reactions.isNotEmpty)
                  _ReactionBar(message: message),
                if (message.pinned) const _PinnedMark(),
                if (message.hasThread && widget.showThreadSummary)
                  _ThreadSummary(message: message),
                if (message.failed) _FailedActions(message: message),
              ],
            ),
          ),
        ),
      ],
    );

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        // 선택 모드면 탭이 고르고 빼는 일을 한다 — **평소의 탭 동작은 그대로
        // 둔다**(선택 모드가 아닐 때는 이 분기에 닿지 않는다).
        onTap: selection.active
            ? toggle
            : (repoEventId == null || spaceId == null
                  ? null
                  : () => _openRepoEvent(context, ref, spaceId, repoEventId)),
        // 터치는 길게 눌러, 마우스는 오른쪽 단추로 동작 카드를 연다.
        onLongPress: canAct ? () => _openActions(withPreview: true) : null,
        onSecondaryTap: canAct ? () => _openActions(withPreview: false) : null,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            AnimatedContainer(
              duration: NxMotion.micro,
              color: selected
                  ? c.accentSubtle
                  : (showToolbar ? c.bgSurface : NxColors.transparent),
              padding: EdgeInsets.fromLTRB(
                NxSpacing.sp7,
                widget.grouped ? NxSpacing.sp1 : NxSpacing.sp4,
                NxSpacing.sp7,
                NxSpacing.sp1,
              ),
              // 아직 서버에 닿지 않은 메시지는 흐리게 — 보냈는지 아닌지가 보여야 한다.
              child: Opacity(opacity: message.pending ? 0.5 : 1, child: body),
            ),
            if (showToolbar)
              Positioned(
                top: -14,
                right: NxSpacing.sp7,
                child: _HoverToolbar(
                  message: message,
                  onMore: () => _openActions(withPreview: false),
                ),
              ),
          ],
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

/// 마우스를 올린 메시지 오른쪽 위의 동작 줄(캔버스 「채널」) — 리액션 · 답장 · 스레드 · 더 보기.
class _HoverToolbar extends ConsumerWidget {
  const _HoverToolbar({required this.message, required this.onMore});

  final Message message;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = NxTheme.of(context).colors;
    // 읽기 전용 채널에서는 답장 · 스레드를 감춘다 — 리액션은 남는다(16단계 D27).
    final canSend = ref.watch(channelCanSendProvider(message.channelId));
    return Container(
      padding: const EdgeInsets.all(NxSpacing.sp1),
      decoration: BoxDecoration(
        color: c.bgElevated,
        borderRadius: BorderRadius.circular(NxRadius.md),
        border: Border.all(color: c.divider),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          NxIconButton(
            icon: NxIcons.reaction,
            label: '리액션',
            size: NxSize.sm,
            onPressed: onMore,
          ),
          if (canSend) ...[
            NxIconButton(
              icon: NxIcons.reply,
              label: '답장',
              size: NxSize.sm,
              onPressed: () =>
                  ref.read(replyTargetProvider.notifier).set(message),
            ),
            NxIconButton(
              icon: NxIcons.thread,
              label: '스레드로 답글',
              size: NxSize.sm,
              onPressed: () => _openThread(context, ref, message),
            ),
          ],
          NxIconButton(
            icon: NxIcons.more,
            label: '더 보기',
            size: NxSize.sm,
            onPressed: onMore,
          ),
        ],
      ),
    );
  }
}

/// 동작 카드 위에 띄우는 누른 메시지(캔버스 「채널 · 모바일 길게 누르기」).
class _MessagePreview extends ConsumerWidget {
  const _MessagePreview({required this.message});

  final Message message;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nx = NxTheme.of(context);
    final c = nx.colors;
    return Container(
      padding: const EdgeInsets.fromLTRB(
        NxSpacing.sp5,
        NxSpacing.inset,
        NxSpacing.sp5,
        NxSpacing.inset,
      ),
      decoration: BoxDecoration(
        color: c.bgSurface,
        borderRadius: BorderRadius.circular(NxRadius.lg),
        border: Border.all(color: c.divider),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          UserAvatar(
            userId: message.author.id,
            name: message.author.name,
            avatarUrl: message.author.avatarUrl,
            size: 32,
          ),
          const SizedBox(width: NxSpacing.inset),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(message.author.name, style: nx.text.strong),
                const SizedBox(height: NxSpacing.sp2),
                Text(
                  mentionPlainText(
                    message.body,
                    message.mentions,
                    fallbackNames: ref.watch(memberNamesProvider),
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: nx.text.body,
                ),
              ],
            ),
          ),
        ],
      ),
    );
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
    // **마크다운은 멘션까지 함께 그린다** — 파서가 하나이기 때문이다
    // (마크다운 설계 §0). 서식이 없으면 위젯이 파싱을 건너뛴다.
    //
    // 아직 보내지 못한 메시지에는 서버가 붙여 주는 멘션 목록이 없다. 멤버
    // 목록으로 이름을 채우지 않으면 큐에 있는 동안만 `@알 수 없음` 으로 보인다.
    return MarkdownBody(
      body: message.body,
      mentions: message.mentions,
      fallbackNames: ref.watch(memberNamesProvider),
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
    final nx = NxTheme.of(context);
    final c = nx.colors;

    return Container(
      margin: const EdgeInsets.only(bottom: NxSpacing.sp2),
      padding: const EdgeInsets.only(left: NxSpacing.sp4),
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: c.borderStrong, width: 2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            quoted.authorName,
            style: nx.text.meta.copyWith(fontWeight: FontWeight.w600),
          ),
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
            style: nx.text.secondary.copyWith(
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
/// 답글 수가 0 이면 그리지 않는다. 스레드를 시작하는 것은 동작 카드 · 동작 줄이다.
class _ThreadSummary extends ConsumerWidget {
  const _ThreadSummary({required this.message});

  final Message message;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nx = NxTheme.of(context);
    final c = nx.colors;

    return Padding(
      padding: const EdgeInsets.only(top: NxSpacing.sp2),
      child: NxHoverSurface(
        onPressed: () => _openThread(context, ref, message),
        padding: const EdgeInsets.symmetric(
          horizontal: NxSpacing.sp4,
          vertical: NxSpacing.sp2,
        ),
        radius: NxRadius.inner,
        child: Text(
          '답글 ${message.replyCount}개',
          style: nx.text.sm.copyWith(
            color: c.accent,
            fontWeight: FontWeight.w600,
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

/// 저장소 이벤트 메시지를 눌렀을 때 그 `kind` 로 갈 곳을 가른다(11단계).
/// push 는 그 push 의 커밋 목록으로, pr 은 PR 화면으로 간다. `other`(이슈 ·
/// 릴리스)는 열 곳이 없어 조용히 아무 일도 하지 않는다 — 눌러 봐야 빈
/// 화면인 버튼은 없느니만 못하다.
Future<void> _openRepoEvent(
  BuildContext context,
  WidgetRef ref,
  String spaceId,
  String repoEventId,
) async {
  final RepoEventView view;
  try {
    view = await ref.read(browseApiProvider).event(spaceId, repoEventId);
  } on ApiException catch (e) {
    // **조용히 삼키지 않는다.** 10-3b 에서는 곧바로 화면을 열어 그 화면이
    // 자기 오류를 보여 줬는데, 여기서 먼저 서버를 부르게 되면서 실패가
    // 아무 표시도 없이 사라졌다 — 오프라인에서 누르면 «고장난 버튼» 과
    // 구분되지 않는다.
    if (!context.mounted) return;
    NxToast.show(context, messageFor(e.failure), kind: NxToastKind.error);
    return;
  }
  if (!context.mounted) return;

  switch (view.kind) {
    case 'push':
      context.push('/s/$spaceId/repo-events/$repoEventId');
    case 'pr':
      context.push('/s/$spaceId/repos/${view.repoId}/pulls/${view.number}');
    case _:
      break; // other 는 열 곳이 없다
  }
}

/// 메시지 동작 카드 — **바텀시트가 아니라 누른 메시지 곁에 뜬다**(15단계 D8, 캔버스
/// 「채널 · 모바일 길게 누르기」). 위에 리액션 줄, 아래에 동작 목록.
Future<void> _showMessageActions(
  BuildContext context,
  WidgetRef ref,
  Message message, {
  required Rect anchor,
  Widget? preview,
}) {
  final mine = {
    for (final r in message.reactions)
      if (r.mine) r.emoji,
  };
  final actions = ref.read(messageActionsProvider);
  final selection = ref.read(selectionControllerProvider.notifier);
  final reply = ref.read(replyTargetProvider.notifier);
  // 읽기 전용이면 답장 · 스레드 · 고정을 감춘다. 리액션 줄 · 이슈 · 선택은 남는다(D27).
  final canSend = ref.read(channelCanSendProvider(message.channelId));

  return NxActionCard.show(
    context,
    anchor: anchor,
    header: preview,
    above: (close) => _EmojiRow(
      mine: mine,
      onPick: (emoji) {
        close();
        actions.toggleReaction(message, emoji);
      },
    ),
    entries: [
      // 답장은 흐름 안에 남고, 스레드는 곁가지로 접힌다. 둘을 나란히 두어 차이가 보이게.
      if (canSend) ...[
        NxMenuItem('답장', onSelected: () => reply.set(message)),
        NxMenuItem(
          '스레드로 답글',
          onSelected: () => _openThread(context, ref, message),
        ),
      ],
      // 대화 → 이슈. 원문이 이슈에 링크로 남아, 이슈에서 이 대화로 돌아올 수 있다.
      NxMenuItem(
        '이슈로 만들기',
        onSelected: () {
          if (context.mounted) showNewIssueSheet(context, fromMessage: message);
        },
      ),
      // 답글은 고정할 수 없다(서버가 400). 항목 자체를 감춘다 —
      // 눌러 봐야 실패하는 버튼은 없느니만 못하다.
      if (canSend && message.parentId == null)
        NxMenuItem(
          message.pinned ? '고정 해제' : '고정',
          onSelected: () => actions.togglePin(message),
        ),
      const NxMenuDivider(),
      // 여러 메시지를 함께 AI 에게 묻는 입구. 「이슈로 만들기」는 한 개만 고르지만
      // (originMessageId 가 단수), 요약은 구간이 필요해 다중 선택 모드로 들어간다.
      NxMenuItem('여러 개 선택', onSelected: () => selection.start(message.id)),
    ],
  );
}

/// 리액션 고르기 줄. 이미 누른 것은 액센트 테두리 — 다시 누르면 취소다.
class _EmojiRow extends StatelessWidget {
  const _EmojiRow({required this.mine, required this.onPick});

  final Set<String> mine;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    final c = NxTheme.of(context).colors;
    return Container(
      padding: const EdgeInsets.all(NxSpacing.sp2),
      decoration: BoxDecoration(
        color: c.bgElevated,
        borderRadius: BorderRadius.circular(NxRadius.full),
        border: Border.all(color: c.divider),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final emoji in _quickEmojis)
            NxPressable(
              onPressed: () => onPick(emoji),
              selected: mine.contains(emoji),
              semanticLabel: '$emoji 리액션',
              excludeChildSemantics: true,
              focusRingRadius: NxRadius.full,
              builder: (context, s) => AnimatedContainer(
                duration: NxMotion.micro,
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: s.hovered ? c.bgSurface : NxColors.transparent,
                  border: mine.contains(emoji)
                      ? Border.all(color: c.accent)
                      : null,
                ),
                child: Text(
                  emoji,
                  style: const TextStyle(fontSize: NxFontSize.lg),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// 메시지에 달린 이모지들. 누르면 켜고 꺼진다.
class _ReactionBar extends ConsumerWidget {
  const _ReactionBar({required this.message});

  final Message message;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.only(top: NxSpacing.sp3),
      child: Wrap(
        spacing: NxSpacing.sp3,
        runSpacing: NxSpacing.sp3,
        children: [
          for (final reaction in message.reactions)
            // 내가 누른 것은 강조한다. 개수만 보여서는 내가 눌렀는지 알 수 없다.
            NxChip(
              label: reaction.emoji,
              trailing: '${reaction.count}',
              selected: reaction.mine,
              onPressed: () => ref
                  .read(messageActionsProvider)
                  .toggleReaction(message, reaction.emoji),
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
    final nx = NxTheme.of(context);
    final actions = ref.read(messageActionsProvider);

    return Padding(
      padding: const EdgeInsets.only(top: NxSpacing.sp2),
      child: Row(
        children: [
          NxIcon(NxIcons.warning, size: NxIconSize.sm, color: nx.colors.danger),
          const SizedBox(width: NxSpacing.sp2),
          Text(
            '보내지 못했습니다',
            style: nx.text.meta.copyWith(color: nx.colors.danger),
          ),
          const SizedBox(width: NxSpacing.sp3),
          NxButton(
            label: '재시도',
            kind: NxButtonKind.ghost,
            size: NxSize.sm,
            onPressed: () => actions.retry(message),
          ),
          NxButton(
            label: '삭제',
            kind: NxButtonKind.ghost,
            size: NxSize.sm,
            onPressed: () => actions.discard(message),
          ),
        ],
      ),
    );
  }
}

/// 고정된 메시지 표시. 목록에서도 한눈에 갈리게 한다.
class _PinnedMark extends StatelessWidget {
  const _PinnedMark();

  @override
  Widget build(BuildContext context) {
    final nx = NxTheme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: NxSpacing.sp2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          NxIcon(
            NxIcons.pin,
            size: NxIconSize.xs,
            color: nx.colors.textSecondary,
          ),
          const SizedBox(width: NxSpacing.sp2),
          Text('고정됨', style: nx.text.meta),
        ],
      ),
    );
  }
}
