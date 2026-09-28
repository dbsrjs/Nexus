import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/models/issue.dart';
import '../../domain/models/issue_comment.dart';
import '../../shared/markdown/markdown_body.dart';
import '../../shared/widgets/back_button.dart';
import '../../shared/widgets/user_avatar.dart';
import '../../ui/ui.dart';
import '../space/members_controller.dart';
import 'board_controller.dart';
import 'issue_detail_controller.dart';
import 'issue_planning_row.dart';
import 'label_widgets.dart';
import 'sprint_controller.dart';
import '../space/space_controller.dart';

/// 이슈 상세. 보드 위에 덮어서 연다.
///
/// **라우트는 키(`NEXUS-12`)로 잡는다** — 사람이 대화에 붙여 넣는 것도
/// uuid 가 아니라 키다. 본문은 캐시에서 그리고 댓글만 서버에서 받는다.
class IssueDetailScreen extends ConsumerStatefulWidget {
  const IssueDetailScreen({
    super.key,
    required this.spaceId,
    required this.issueKey,
  });

  final String spaceId;
  final String issueKey;

  @override
  ConsumerState<IssueDetailScreen> createState() => _IssueDetailScreenState();
}

class _IssueDetailScreenState extends ConsumerState<IssueDetailScreen> {
  @override
  void initState() {
    super.initState();
    // 라우트가 진실의 원천이다. build 안에서 하면 build 중 상태 변경이라 예외다.
    Future.microtask(() {
      if (!mounted) return;
      ref.read(currentIssueKeyProvider.notifier).set(widget.issueKey);
      // 스프린트 선택기가 쓰는 목록. 보드를 거치지 않고 딥링크로 들어오면
      // 캐시가 비어 있어 고를 것이 없다.
      ref.read(sprintActionsProvider).refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final nx = NxTheme.of(context);
    final issue = ref.watch(currentIssueProvider);

    return NxPage(
      header: NxHeader(
        titleWidget: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            widget.issueKey,
            style: nx.text.mono.copyWith(
              fontSize: 14,
              color: nx.colors.textPrimary,
            ),
          ),
        ),
        leading: NxBackButton(fallback: '/s/${widget.spaceId}/issues'),
        actions: [
          if (issue.value != null)
            NxIconButton(
              icon: NxIcons.trash,
              label: '지우기',
              onPressed: () => _confirmDelete(issue.value!),
            ),
        ],
      ),
      body: issue.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(NxSpacing.sp7),
          child: NxSkeleton(lines: 6),
        ),
        error: (_, _) => Center(
          child: Text('이슈를 불러오지 못했습니다.', style: nx.text.secondary),
        ),
        data: (value) => value == null
            ? Center(child: Text('이슈를 찾을 수 없습니다.', style: nx.text.secondary))
            : _Body(issue: value),
      ),
    );
  }

  /// **하드 삭제라 되돌릴 수 없다.** 그래서 한 번 묻는다.
  Future<void> _confirmDelete(Issue issue) async {
    final router = GoRouter.of(context);

    final ok = await NxDialog.confirm(
      context,
      title: '${issue.key} 를 지울까요?',
      body: '되돌릴 수 없습니다. 댓글도 함께 사라집니다.',
      confirmLabel: '지우기',
      danger: true,
    );
    if (!ok) return;

    final removed = await ref.read(issueDetailActionsProvider).remove(issue.id);
    if (!mounted) return;
    if (removed) {
      router.canPop() ? router.pop() : router.go('/s/${widget.spaceId}/issues');
      return;
    }
    NxToast.show(context, '지우지 못했습니다. 연결을 확인해 주세요.', kind: NxToastKind.error);
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.issue});

  final Issue issue;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nx = NxTheme.of(context);
    final c = nx.colors;
    final comments = ref.watch(issueCommentsProvider);
    final priorityColor = switch (issue.priority) {
      IssuePriority.high => c.danger,
      IssuePriority.mid => c.warning,
      IssuePriority.low => c.success,
    };

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(NxSpacing.sp7),
            children: [
              Text(issue.title, style: nx.text.heading),
              const SizedBox(height: NxSpacing.sp5),
              Wrap(
                spacing: NxSpacing.sp5,
                runSpacing: NxSpacing.sp4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  NxTag(issueStatusLabel(issue.status)),
                  NxTag(
                    '우선순위 ${issuePriorityLabel(issue.priority)}',
                    dot: true,
                    color: priorityColor,
                  ),
                  if (issue.assignee != null)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        UserAvatar(
                          userId: issue.assignee!.id,
                          name: issue.assignee!.name,
                          avatarUrl: issue.assignee!.avatarUrl,
                          size: 18,
                        ),
                        const SizedBox(width: NxSpacing.sp3),
                        Text('담당 ${issue.assignee!.name}', style: nx.text.meta),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: NxSpacing.sp6),
              // 스프린트와 포인트. 이 둘이 없으면 번다운이 언제나 비어 있다.
              IssuePlanningRow(issue: issue),
              const SizedBox(height: NxSpacing.sp5),
              _LabelRow(issue: issue),
              if (issue.originMessage != null) ...[
                const SizedBox(height: NxSpacing.sp6),
                _OriginCard(origin: issue.originMessage!),
              ],
              if (issue.description != null &&
                  issue.description!.trim().isNotEmpty) ...[
                const SizedBox(height: NxSpacing.sp7),
                // 채팅과 **같은 위젯**을 쓴다 — 규칙이 갈라지면 "채팅에서는
                // 되는데 이슈에서는 안 되는" 일이 생긴다(마크다운 설계 §4).
                MarkdownBody(
                  body: issue.description!,
                  // 이슈에는 서버가 멘션 목록을 실어 주지 않는다. 본문에
                  // `<@id>` 가 있을 수 있으므로 멤버 이름으로 채운다.
                  fallbackNames: ref.watch(memberNamesProvider),
                ),
              ],
              const Padding(
                padding: EdgeInsets.symmetric(vertical: NxSpacing.sp7),
                child: NxDivider(),
              ),
              Semantics(
                header: true,
                child: Text('댓글', style: nx.text.strong),
              ),
              const SizedBox(height: NxSpacing.sp5),
              comments.when(
                loading: () => const NxSkeleton(lines: 2),
                // 댓글은 캐시하지 않으므로 오프라인에서는 비어 보인다.
                // 그 사실을 그대로 말한다 — 댓글이 없는 것과 구분되어야 한다.
                error: (_, _) =>
                    Text('댓글을 불러오지 못했습니다.', style: nx.text.secondary),
                data: (items) => items.isEmpty
                    ? Text('아직 댓글이 없습니다.', style: nx.text.secondary)
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (final c in items) _CommentTile(comment: c),
                        ],
                      ),
              ),
            ],
          ),
        ),
        _CommentComposer(issueId: issue.id),
      ],
    );
  }
}

/// 라벨 줄. 눌러서 고른다 — 통째 교체라 "지금 선택된 것"만 보내면 된다.
class _LabelRow extends ConsumerWidget {
  const _LabelRow({required this.issue});

  final Issue issue;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Wrap(
      spacing: NxSpacing.sp4,
      runSpacing: NxSpacing.sp4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (final label in issue.labels) LabelChip(label: label),
        NxChip(
          label: issue.labels.isEmpty ? '라벨 붙이기' : '라벨 고치기',
          icon: NxIcons.plus,
          onPressed: () => showLabelPicker(context, issue),
        ),
      ],
    );
  }
}

/// 이 이슈가 나온 대화. 눌러서 원문으로 돌아간다.
///
/// **원문이 지워져도 링크는 남는다** — 이슈의 맥락은 원문이 사라져도
/// 필요하다. 다만 본문은 서버가 싣지 않는다.
class _OriginCard extends ConsumerWidget {
  const _OriginCard({required this.origin});

  final IssueOrigin origin;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nx = NxTheme.of(context);
    final c = nx.colors;
    final spaceId = ref.watch(currentSpaceIdProvider);

    return NxPressable(
      onPressed: spaceId == null
          ? null
          : () => context.go('/s/$spaceId/c/${origin.channelId}'),
      builder: (context, s) => AnimatedContainer(
        duration: NxMotion.micro,
        padding: const EdgeInsets.all(NxSpacing.sp5),
        decoration: BoxDecoration(
          color: s.hovered ? c.bgElevated : c.bgSurface,
          borderRadius: BorderRadius.circular(NxRadius.md),
          // 인용처럼 왼쪽 선 하나로 「다른 곳에서 온 글」임을 말한다.
          border: Border(left: BorderSide(color: c.accent, width: 2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('이 대화에서 만들어졌습니다', style: nx.text.meta),
            const SizedBox(height: NxSpacing.sp2),
            Text(
              origin.deleted
                  ? '${origin.authorName} · 지워진 메시지'
                  : '${origin.authorName} · ${origin.body ?? ''}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: nx.text.sm,
            ),
          ],
        ),
      ),
    );
  }
}

/// 댓글도 마크다운을 그린다. **`ConsumerWidget` 인 이유**는 멘션 이름을
/// 멤버 목록에서 채워야 하기 때문이다 — 이슈 쪽에는 서버가 멘션 목록을
/// 실어 주지 않는다.
class _CommentTile extends ConsumerWidget {
  const _CommentTile({required this.comment});

  final IssueComment comment;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nx = NxTheme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: NxSpacing.sp6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          UserAvatar(
            userId: comment.author.id,
            name: comment.author.name,
            avatarUrl: comment.author.avatarUrl,
            size: 28,
          ),
          const SizedBox(width: NxSpacing.sp5),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(comment.author.name, style: nx.text.strong),
                const SizedBox(height: NxSpacing.sp1),
                MarkdownBody(
                  body: comment.body,
                  fallbackNames: ref.watch(memberNamesProvider),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CommentComposer extends ConsumerStatefulWidget {
  const _CommentComposer({required this.issueId});

  final String issueId;

  @override
  ConsumerState<_CommentComposer> createState() => _CommentComposerState();
}

class _CommentComposerState extends ConsumerState<_CommentComposer> {
  final _controller = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final body = _controller.text.trim();
    if (body.isEmpty || _sending) return;

    setState(() => _sending = true);
    final ok = await ref
        .read(issueDetailActionsProvider)
        .comment(widget.issueId, body);

    if (!mounted) return;
    setState(() => _sending = false);
    if (ok) {
      _controller.clear();
      return;
    }
    // 댓글은 큐에 넣지 않으므로 오프라인에서는 달 수 없다. 그대로 말한다.
    NxToast.show(context, '댓글을 달지 못했습니다. 연결을 확인해 주세요.', kind: NxToastKind.error);
  }

  @override
  Widget build(BuildContext context) {
    final c = NxTheme.of(context).colors;

    // 키보드는 NxPage 가 비킨다 — 여기서 인셋을 또 더하면 두 번 올라간다.
    return Container(
      padding: const EdgeInsets.fromLTRB(
        NxSpacing.sp7,
        NxSpacing.sp5,
        NxSpacing.sp7,
        NxSpacing.sp5,
      ),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: c.divider)),
      ),
      child: Row(
        children: [
          Expanded(
            child: NxField(
              controller: _controller,
              hint: '댓글 쓰기',
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _send(),
            ),
          ),
          const SizedBox(width: NxSpacing.sp4),
          NxIconButton(
            icon: NxIcons.send,
            label: '보내기',
            filled: true,
            onPressed: _sending ? null : _send,
          ),
        ],
      ),
    );
  }
}
