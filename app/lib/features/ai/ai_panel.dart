import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';
import '../../domain/models/ai_run.dart';
import '../../shared/markdown/markdown_body.dart';
import '../repo/repo_controller.dart';
import 'ai_controller.dart';
import 'ai_request.dart';

/// 이슈 초안을 이슈 생성 화면으로 넘긴다. 시트를 닫은 뒤에 불린다.
typedef CreateIssueFromDraft =
    void Function({
      required String title,
      required String description,
      String? originMessageId,
    });

/// AI 패널을 연다 (13-2 설계 §6). 입력과 결과가 한 시트에 있다.
///
/// - `onPost` 가 있으면 결과에 「채널에 붙이기」가 붙는다 — 채널에서 열었을 때
/// - `onCreateIssue` 가 있으면 「이슈로 만들기」 프리셋의 결과를 이슈 생성
///   화면으로 넘길 수 있다
/// - `canAddRepo` 면 「+ 저장소」 칩이 보인다
///
/// 열 때마다 이전 결과를 버린다 — 다른 자리에서 연 패널이 지난 답을 보이면
/// 그 답이 지금 칩에 대한 것처럼 읽힌다.
Future<void> showAiPanel(
  BuildContext context, {
  required String spaceId,
  required List<AiContext> contexts,
  Future<void> Function(String markdown)? onPost,
  CreateIssueFromDraft? onCreateIssue,
  bool canAddRepo = false,
}) {
  ProviderScope.containerOf(
    context,
    listen: false,
  ).read(aiControllerProvider.notifier).abandon();

  return showModalBottomSheet<void>(
    context: context,
    // 기본 최대 높이(화면의 9/16)면 결과가 길 때 조용히 넘친다 (13-1 에서 겪었다).
    isScrollControlled: true,
    builder: (_) => AiPanel(
      spaceId: spaceId,
      initialContexts: contexts,
      onPost: onPost,
      onCreateIssue: onCreateIssue,
      canAddRepo: canAddRepo,
    ),
  );
}

class AiPanel extends ConsumerStatefulWidget {
  const AiPanel({
    super.key,
    required this.spaceId,
    required this.initialContexts,
    this.onPost,
    this.onCreateIssue,
    this.canAddRepo = false,
  });

  final String spaceId;
  final List<AiContext> initialContexts;
  final Future<void> Function(String markdown)? onPost;
  final CreateIssueFromDraft? onCreateIssue;
  final bool canAddRepo;

  @override
  ConsumerState<AiPanel> createState() => _AiPanelState();
}

class _AiPanelState extends ConsumerState<AiPanel> {
  /// 칩. **패널이 들고 있다** — 「다시 묻기」가 같은 칩으로 돌아오게.
  late final List<AiContext> _contexts = [...widget.initialContexts];
  final _instruction = TextEditingController();

  /// 마지막으로 보낸 요청. 실패 문구(저장소 여부)와 이슈 원문 링크에 쓴다.
  AiRequest? _sent;

  @override
  void initState() {
    super.initState();
    // 보내기 버튼의 켜짐이 입력에 따라 바뀐다.
    _instruction.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _instruction.dispose();
    super.dispose();
  }


  void _send({AiPreset? preset}) {
    final text = _instruction.text.trim();
    final request = preset != null
        ? AiRequest(preset: preset, contexts: List.of(_contexts))
        : AiRequest(instruction: text, contexts: List.of(_contexts));
    setState(() => _sent = request);
    ref
        .read(aiControllerProvider.notifier)
        .run(spaceId: widget.spaceId, request: request);
  }

  /// 같은 칩으로 입력 화면에 돌아간다. 지시문은 비운다 (설계 D9).
  void _askAgain() {
    _instruction.clear();
    ref.read(aiControllerProvider.notifier).abandon();
  }

  Future<void> _addRepo() async {
    final picked = await showDialog<RepoContext>(
      context: context,
      builder: (_) => _RepoPickerDialog(spaceId: widget.spaceId),
    );
    if (picked != null && mounted) setState(() => _contexts.add(picked));
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(aiControllerProvider);

    final body = switch (state) {
      AiIdle() => _input(context),
      AiRunning() => _Running(
        onAbandon: () {
          ref.read(aiControllerProvider.notifier).abandon();
          Navigator.of(context).pop();
        },
        onRetry: () => ref.read(aiControllerProvider.notifier).retry(),
      ),
      AiFailed(:final failure) => _Failed(
        message: aiMessageFor(failure, hasRepo: _sent?.hasRepo ?? _contexts.hasRepo),
        onAskAgain: _askAgain,
      ),
      AiReady(:final run) => _Result(
        run: run,
        spaceId: widget.spaceId,
        repoId: _sent?.repoId,
        onPost: widget.onPost,
        onCreateIssue: widget.onCreateIssue == null
            ? null
            : () {
                Navigator.of(context).pop();
                widget.onCreateIssue!(
                  title: run.title ?? '',
                  description: run.description ?? '',
                  originMessageId: _sent?.firstMessageId,
                );
              },
        onAskAgain: _askAgain,
      ),
    };

    return Padding(
      padding: EdgeInsets.only(
        // 키보드가 올라와도 입력창이 가리지 않게 한다.
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: body,
    );
  }


  Widget _input(BuildContext context) {
    final theme = Theme.of(context);
    // 근거 없는 질문은 받지 않는다(설계 D5) — 칩이 없으면 보내기가 꺼진다.
    final canSend = _contexts.isNotEmpty && _instruction.text.trim().isNotEmpty;
    // 프리셋은 대화를 재료로 한다(설계 §1). 서버의 400 을 화면이 먼저 막는다.
    final canPreset = _contexts.hasConversation;

    return Padding(
      padding: const EdgeInsets.all(NexusSpacing.sp6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('AI', style: theme.textTheme.titleMedium),
          const SizedBox(height: NexusSpacing.sp5),
          Wrap(
            spacing: NexusSpacing.sp4,
            runSpacing: NexusSpacing.sp4,
            children: [
              for (final c in _contexts)
                InputChip(
                  avatar: Icon(_iconOf(c), size: 16),
                  label: Text(c.label),
                  onDeleted: () => setState(() => _contexts.remove(c)),
                  deleteButtonTooltipMessage: '빼기',
                ),
              if (widget.canAddRepo && !_contexts.hasRepo)
                ActionChip(
                  avatar: const Icon(Icons.add, size: 16),
                  label: const Text('저장소'),
                  onPressed: _addRepo,
                ),
            ],
          ),
          if (_contexts.isEmpty) ...[
            const SizedBox(height: NexusSpacing.sp4),
            Text(
              '대화나 저장소가 하나는 있어야 물을 수 있습니다.',
              style: theme.textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: NexusSpacing.sp5),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: canPreset
                    ? () => _send(preset: AiPreset.summary)
                    : null,
                icon: const Icon(Icons.notes, size: 18),
                label: const Text('요약'),
              ),
              const SizedBox(width: NexusSpacing.sp4),
              OutlinedButton.icon(
                onPressed: canPreset && widget.onCreateIssue != null
                    ? () => _send(preset: AiPreset.issue)
                    : null,
                icon: const Icon(Icons.task_alt, size: 18),
                label: const Text('이슈로 만들기'),
              ),
            ],
          ),
          const SizedBox(height: NexusSpacing.sp5),
          TextField(
            controller: _instruction,
            autofocus: true,
            minLines: 1,
            maxLines: 6,
            // 서버의 상한과 같다(ask-request.ts 의 MAX_INSTRUCTION).
            maxLength: 2000,
            decoration: const InputDecoration(hintText: '무엇이든 물어보세요'),
          ),
          const SizedBox(height: NexusSpacing.sp4),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: canSend ? _send : null,
              icon: const Icon(Icons.auto_awesome_outlined, size: 18),
              label: const Text('보내기'),
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconOf(AiContext c) => switch (c) {
    MessagesContext() => Icons.chat_bubble_outline,
    ChannelContext() => Icons.tag,
    RepoContext() => Icons.inventory_2_outlined,
  };
}

class _Running extends StatelessWidget {
  const _Running({required this.onAbandon, required this.onRetry});
  final VoidCallback onAbandon;

  /// 소켓 알림을 놓쳤을 때 결과가 이미 서버에 있는데 화면만 모르는 경우를
  /// 위한 것 — 같은 GET 을 다시 부른다 (13-1).
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(24),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const CircularProgressIndicator(),
        const SizedBox(height: 16),
        const Text('답을 만들고 있습니다'),
        const SizedBox(height: 16),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextButton(onPressed: onRetry, child: const Text('다시 확인')),
            const SizedBox(width: 8),
            // 「중단」이 아니라 「기다리지 않기」다 — 서버의 호출은 계속 돈다.
            TextButton(onPressed: onAbandon, child: const Text('기다리지 않기')),
          ],
        ),
      ],
    ),
  );
}

class _Failed extends StatelessWidget {
  const _Failed({required this.message, required this.onAskAgain});
  final String message;
  final VoidCallback onAskAgain;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(24),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(message),
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(onPressed: onAskAgain, child: const Text('다시 묻기')),
        ),
      ],
    ),
  );
}

/// 결과. **StatefulWidget 이다** — 「채널에 붙이기」가 진행 중인지를 여기서
/// 직접 들고 있어야 한다. 버튼을 막지 않으면 두 번 빠르게 눌러 **같은 답이
/// 채널에 두 번** 올라간다(13-1). 메시지는 소프트 삭제라 되돌릴 수 없다.
class _Result extends StatefulWidget {
  const _Result({
    required this.run,
    required this.spaceId,
    required this.repoId,
    required this.onPost,
    required this.onCreateIssue,
    required this.onAskAgain,
  });

  final AiRun run;
  final String spaceId;
  final String? repoId;
  final Future<void> Function(String markdown)? onPost;
  final VoidCallback? onCreateIssue;
  final VoidCallback onAskAgain;

  @override
  State<_Result> createState() => _ResultState();
}

class _ResultState extends State<_Result> {
  bool _posting = false;

  Future<void> _handlePost() async {
    if (_posting) return;
    setState(() => _posting = true);
    try {
      await widget.onPost!(widget.run.markdown ?? '');
      if (mounted) Navigator.of(context).pop();
    } finally {
      // 실패해서 시트가 남으면 다시 누를 수 있어야 한다.
      if (mounted) setState(() => _posting = false);
    }
  }

  Future<void> _copy() async {
    final run = widget.run;
    final text = run.isIssueDraft
        ? '${run.title ?? ''}\n\n${run.description ?? ''}'
        : run.markdown ?? '';
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('복사했습니다')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final run = widget.run;
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (run.isIssueDraft) ...[
                    Text('이슈 초안', style: theme.textTheme.labelMedium),
                    const SizedBox(height: 4),
                    Text(run.title ?? '', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 12),
                    MarkdownBody(body: run.description ?? ''),
                  ] else
                    // `body:` 다 — `source:` 가 아니다 (markdown_body.dart:16).
                    MarkdownBody(body: run.markdown ?? ''),
                  if (run.citations.isNotEmpty && widget.repoId != null) ...[
                    const SizedBox(height: 16),
                    Text('참고한 코드', style: theme.textTheme.labelMedium),
                    const SizedBox(height: 4),
                    for (final c in run.citations)
                      _CitationTile(
                        citation: c,
                        spaceId: widget.spaceId,
                        repoId: widget.repoId!,
                      ),
                  ],
                ],
              ),
            ),
          ),
          if (run.fallback) ...[
            const SizedBox(height: 12),
            // 품질이 조용히 떨어지지 않게 한다 — 이 답은 캐시에도 남지 않아
            // 나중에 같은 질문을 하면 주 모델이 다시 답한다.
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 14,
                  color: theme.textTheme.bodySmall?.color,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '사용량이 많아 가벼운 모델이 답했습니다',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          Wrap(
            alignment: WrapAlignment.end,
            spacing: 8,
            runSpacing: 8,
            children: [
              TextButton(
                onPressed: widget.onAskAgain,
                child: const Text('다시 묻기'),
              ),
              OutlinedButton.icon(
                onPressed: _copy,
                icon: const Icon(Icons.copy, size: 18),
                label: const Text('복사'),
              ),
              if (run.isIssueDraft && widget.onCreateIssue != null)
                FilledButton.icon(
                  onPressed: widget.onCreateIssue,
                  icon: const Icon(Icons.task_alt, size: 18),
                  label: const Text('이슈 만들기'),
                ),
              if (!run.isIssueDraft && widget.onPost != null)
                FilledButton.icon(
                  onPressed: _posting ? null : _handlePost,
                  icon: _posting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send_outlined, size: 18),
                  label: const Text('채널에 붙이기'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 인용 한 줄. 누르면 **답이 근거로 삼은 그 커밋의** 파일을 연다 — 지금
/// 브랜치 끝이 아니다(10-3b 가 커밋 상세에서 sha 를 넘긴 이유와 같다).
class _CitationTile extends StatelessWidget {
  const _CitationTile({
    required this.citation,
    required this.spaceId,
    required this.repoId,
  });

  final AiCitation citation;
  final String spaceId;
  final String repoId;

  @override
  Widget build(BuildContext context) => ListTile(
    dense: true,
    contentPadding: EdgeInsets.zero,
    leading: Text('[${citation.n}]'),
    title: Text(citation.location, overflow: TextOverflow.ellipsis),
    onTap: () => context.push(
      '/s/$spaceId/repos/$repoId/browse'
      '?ref=${Uri.encodeQueryComponent(citation.commitSha)}'
      '&path=${Uri.encodeQueryComponent(citation.path)}',
    ),
  );
}

/// 스페이스에 붙은 저장소 중 하나를 고른다.
class _RepoPickerDialog extends ConsumerWidget {
  const _RepoPickerDialog({required this.spaceId});
  final String spaceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repos = ref.watch(spaceReposProvider(spaceId));
    return SimpleDialog(
      title: const Text('저장소 고르기'),
      children: repos.when(
        loading: () => const [
          Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          ),
        ],
        error: (_, _) => const [
          Padding(
            padding: EdgeInsets.all(24),
            child: Text('저장소 목록을 불러오지 못했습니다.'),
          ),
        ],
        data: (items) => items.isEmpty
            ? const [
                Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('이 스페이스에 붙은 저장소가 없습니다.'),
                ),
              ]
            : [
                for (final r in items)
                  SimpleDialogOption(
                    onPressed: () => Navigator.of(
                      context,
                    ).pop(RepoContext(repoId: r.id, repoName: r.name)),
                    child: Text(r.fullPath),
                  ),
              ],
      ),
    );
  }
}
