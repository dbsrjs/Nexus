import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';
import '../../domain/models/issue.dart';
import '../../domain/models/issue_comment.dart';
import '../../shared/widgets/nexus_avatar.dart';
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
    final issue = ref.watch(currentIssueProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.issueKey),
        actions: [
          if (issue.value != null)
            IconButton(
              tooltip: '지우기',
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _confirmDelete(issue.value!),
            ),
        ],
      ),
      body: issue.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const Center(child: Text('이슈를 불러오지 못했습니다.')),
        data: (value) => value == null
            ? const Center(child: Text('이슈를 찾을 수 없습니다.'))
            : _Body(issue: value),
      ),
    );
  }

  /// **하드 삭제라 되돌릴 수 없다.** 그래서 한 번 묻는다.
  Future<void> _confirmDelete(Issue issue) async {
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);

    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('${issue.key} 를 지울까요?'),
        content: const Text('되돌릴 수 없습니다. 댓글도 함께 사라집니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('지우기'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    final removed = await ref.read(issueDetailActionsProvider).remove(issue.id);
    if (!mounted) return;
    if (removed) {
      router.pop();
      return;
    }
    messenger.showSnackBar(
      const SnackBar(content: Text('지우지 못했습니다. 연결을 확인해 주세요.')),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.issue});

  final Issue issue;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final comments = ref.watch(issueCommentsProvider);

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(NexusSpacing.sp6),
            children: [
              Text(issue.title, style: theme.textTheme.titleLarge),
              const SizedBox(height: NexusSpacing.sp5),
              Wrap(
                spacing: NexusSpacing.sp4,
                runSpacing: NexusSpacing.sp4,
                children: [
                  _Chip(label: issueStatusLabel(issue.status)),
                  _Chip(label: '우선순위 ${issuePriorityLabel(issue.priority)}'),
                  if (issue.storyPoints != null)
                    _Chip(label: '${issue.storyPoints}p'),
                  if (issue.assignee != null)
                    _Chip(label: '담당 ${issue.assignee!.name}'),
                ],
              ),
              const SizedBox(height: NexusSpacing.sp5),
              // 스프린트와 포인트. 이 둘이 없으면 번다운이 언제나 비어 있다.
              IssuePlanningRow(issue: issue),
              const SizedBox(height: NexusSpacing.sp5),
              _LabelRow(issue: issue),
              if (issue.originMessage != null) ...[
                const SizedBox(height: NexusSpacing.sp5),
                _OriginCard(origin: issue.originMessage!),
              ],
              if (issue.description != null &&
                  issue.description!.trim().isNotEmpty) ...[
                const SizedBox(height: NexusSpacing.sp6),
                Text(issue.description!, style: theme.textTheme.bodyMedium),
              ],
              const SizedBox(height: NexusSpacing.sp8),
              Text('댓글', style: theme.textTheme.titleSmall),
              const SizedBox(height: NexusSpacing.sp4),
              comments.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(NexusSpacing.sp6),
                  child: Center(child: CircularProgressIndicator()),
                ),
                // 댓글은 캐시하지 않으므로 오프라인에서는 비어 보인다.
                // 그 사실을 그대로 말한다 — 댓글이 없는 것과 구분되어야 한다.
                error: (_, _) => Text(
                  '댓글을 불러오지 못했습니다.',
                  style: theme.textTheme.bodySmall,
                ),
                data: (items) => items.isEmpty
                    ? Text('아직 댓글이 없습니다.', style: theme.textTheme.bodySmall)
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
      spacing: NexusSpacing.sp4,
      runSpacing: NexusSpacing.sp4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (final label in issue.labels) LabelChip(label: label),
        ActionChip(
          avatar: const Icon(Icons.label_outline, size: 16),
          label: Text(issue.labels.isEmpty ? '라벨 붙이기' : '라벨 고치기'),
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
    final theme = Theme.of(context);
    final spaceId = ref.watch(currentSpaceIdProvider);

    return InkWell(
      borderRadius: BorderRadius.circular(NexusRadius.md),
      onTap: spaceId == null
          ? null
          : () => context.push('/s/$spaceId/c/${origin.channelId}'),
      child: Container(
        padding: const EdgeInsets.all(NexusSpacing.sp5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(NexusRadius.md),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Row(
          children: [
            const Icon(Icons.forum_outlined, size: 16),
            const SizedBox(width: NexusSpacing.sp4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('이 대화에서 만들어졌습니다', style: theme.textTheme.labelSmall),
                  const SizedBox(height: NexusSpacing.sp1),
                  Text(
                    origin.deleted
                        ? '${origin.authorName} · 지워진 메시지'
                        : '${origin.authorName} · ${origin.body ?? ''}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall,
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

class _Chip extends StatelessWidget {
  const _Chip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: NexusSpacing.sp5,
        vertical: NexusSpacing.sp3,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(NexusRadius.md),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Text(label, style: theme.textTheme.labelMedium),
    );
  }
}

class _CommentTile extends StatelessWidget {
  const _CommentTile({required this.comment});

  final IssueComment comment;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: NexusSpacing.sp5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          NexusAvatar(
            seed: comment.author.id,
            label: comment.author.name,
            size: 28,
          ),
          const SizedBox(width: NexusSpacing.sp4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(comment.author.name, style: theme.textTheme.labelMedium),
                const SizedBox(height: NexusSpacing.sp1),
                Text(comment.body, style: theme.textTheme.bodyMedium),
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
    final messenger = ScaffoldMessenger.of(context);
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
    messenger.showSnackBar(
      const SnackBar(content: Text('댓글을 달지 못했습니다. 연결을 확인해 주세요.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.only(
        left: NexusSpacing.sp6,
        right: NexusSpacing.sp6,
        top: NexusSpacing.sp5,
        bottom: MediaQuery.viewInsetsOf(context).bottom + NexusSpacing.sp5,
      ),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: theme.dividerColor)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: const InputDecoration(hintText: '댓글 쓰기'),
              onSubmitted: (_) => _send(),
            ),
          ),
          const SizedBox(width: NexusSpacing.sp4),
          IconButton(
            tooltip: '보내기',
            icon: const Icon(Icons.send),
            onPressed: _sending ? null : _send,
          ),
        ],
      ),
    );
  }
}
