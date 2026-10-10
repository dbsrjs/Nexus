import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/models/ai_run.dart';
import '../../domain/models/ai_thread.dart';
import '../../shared/markdown/markdown_body.dart';
import '../../ui/ui.dart';
import '../repo/repo_controller.dart';
import '../shell/side_panel.dart';
import 'ai_controller.dart';
import 'ai_history.dart';
import 'ai_request.dart';

/// 이슈 초안을 이슈 생성 화면으로 넘긴다. 시트를 닫은 뒤에 불린다.
typedef CreateIssueFromDraft =
    void Function({
      required String title,
      required String description,
      String? originMessageId,
    });

/// AI 패널을 연다 (13-2 설계 §6). 입력과 결과가 한 패널에 있다 — 바텀시트가 아니라
/// 가운데 패널이다(15단계 D8).
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
  final container = ProviderScope.containerOf(context, listen: false);
  container.read(aiControllerProvider.notifier).abandon();

  // 넓은 셸이면 대화 옆 오른쪽 판에 연다 — 묻는 동안 그 대화가 막에 가리지 않게
  // (2026-10-10 UI/UX 검토). 닫힐 때 끝나는 Future 는 대화상자와 같다.
  if (sidePanelAvailable(context)) {
    final closed = Completer<void>();
    container
        .read(sidePanelProvider.notifier)
        .open(
          AiSidePanel(
            onClosed: () {
              if (!closed.isCompleted) closed.complete();
            },
            builder: (close) => AiPanel(
              spaceId: spaceId,
              initialContexts: contexts,
              onPost: onPost,
              onCreateIssue: onCreateIssue,
              canAddRepo: canAddRepo,
              onClose: close,
            ),
          ),
        );
    return closed.future;
  }

  return NxDialog.panel<void>(
    context,
    title: 'AI',
    width: 600,
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
    this.onClose,
  });

  final String spaceId;
  final List<AiContext> initialContexts;
  final Future<void> Function(String markdown)? onPost;
  final CreateIssueFromDraft? onCreateIssue;
  final bool canAddRepo;

  /// 패널을 닫는 방법. 비우면 감싼 대화상자를 닫는다(Navigator.pop) — 오른쪽 판은 넘긴다.
  final VoidCallback? onClose;

  @override
  ConsumerState<AiPanel> createState() => _AiPanelState();
}

class _AiPanelState extends ConsumerState<AiPanel> {
  /// 칩. **패널이 들고 있다** — 「다시 묻기」가 같은 칩으로 돌아오게. 실패 문구(저장소
  /// 여부) · 인용 링크 · 이슈 원문도 여기서 읽는다 — 보낸 뒤에는 칩이 바뀌지 않는다
  /// (문답 화면의 칩은 읽기 전용이다). 지난 대화를 열면 그 사슬의 칩으로 바뀐다(19).
  late final List<AiContext> _contexts = [...widget.initialContexts];
  final _instruction = TextEditingController();

  /// 끝난 문답들 — 오래된 것부터 (13-3). 패널을 닫으면 화면에서 사라지고, 「지난
  /// 대화」에서 다시 연다(19).
  final List<_Turn> _turns = [];

  /// 입력 화면 대신 지난 대화 목록을 보이는가(19 설계 §3).
  bool _browsing = false;

  /// 지금 기다리는 질문의 화면 문구. 답이 오면 그 문답의 질문이 된다.
  String? _asking;

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
    final AiRequest request;
    if (_turns.isNotEmpty) {
      // 이어 묻기 — 부모는 마지막 답이다. 근거는 서버가 첫 문답에서 물려받는다.
      request = AiRequest.followUp(
        instruction: text,
        parentRunId: _turns.last.run.runId,
        contexts: List.of(_contexts),
      );
    } else if (preset != null) {
      request = AiRequest(preset: preset, contexts: List.of(_contexts));
    } else {
      request = AiRequest(instruction: text, contexts: List.of(_contexts));
    }
    setState(() => _asking = preset == null ? text : aiPresetLabel(preset));
    ref
        .read(aiControllerProvider.notifier)
        .run(spaceId: widget.spaceId, request: request);
  }

  /// 같은 칩으로 첫 입력 화면에 돌아간다 — **새 대화**다. 지시문과 문답을
  /// 비운다 (13-2 D9 · 13-3 §5).
  void _askAgain() {
    setState(() {
      _turns.clear();
      _asking = null;
    });
    _instruction.clear();
    ref.read(aiControllerProvider.notifier).abandon();
  }

  /// 지난 대화를 연다(19). 칩과 문답을 그 사슬로 바꾼다 — 이어 묻기는 새로 묻는
  /// 사슬과 같은 길을 탄다(부모는 마지막 턴).
  void _resume(AiThread thread) {
    final repos =
        ref.read(spaceReposProvider(widget.spaceId)).value ?? const [];
    final repoName = repos
        .where((r) => r.id == thread.repoId)
        .map((r) => r.name)
        .firstOrNull;
    ref.read(aiControllerProvider.notifier).abandon();
    _instruction.clear();
    setState(() {
      _contexts
        ..clear()
        ..addAll([
          // 「채널 최근 대화」도 실제로 읽은 메시지가 저장된다 — 같은 메시지 칩으로
          // 되살린다(설계 D11).
          if (thread.channelId != null && thread.messageIds != null)
            MessagesContext(
              channelId: thread.channelId!,
              messageIds: thread.messageIds!,
            ),
          if (thread.repoId != null)
            RepoContext(repoId: thread.repoId!, repoName: repoName ?? '저장소'),
        ]);
      _turns
        ..clear()
        ..addAll([for (final t in thread.turns) _Turn(t.question, t.run)]);
      _asking = null;
      _browsing = false;
    });
  }

  void _close() {
    final onClose = widget.onClose;
    if (onClose != null) {
      onClose();
    } else {
      Navigator.of(context).pop();
    }
  }

  Future<void> _addRepo() async {
    final picked = await NxDialog.panel<RepoContext>(
      context,
      title: '저장소 고르기',
      width: 420,
      builder: (_) => _RepoPickerDialog(spaceId: widget.spaceId),
    );
    if (picked != null && mounted) setState(() => _contexts.add(picked));
  }

  @override
  Widget build(BuildContext context) {
    // 답이 오면 문답 목록에 덧붙인다. 같은 runId(캐시 적중)는 두 번 넣지 않는다.
    ref.listen<AiState>(aiControllerProvider, (_, next) {
      if (next is! AiReady) return;
      if (_turns.any((t) => t.run.runId == next.run.runId)) return;
      setState(() => _turns.add(_Turn(_asking ?? '', next.run)));
      _instruction.clear();
    });
    final state = ref.watch(aiControllerProvider);

    final Widget body;
    if (_turns.isNotEmpty) {
      body = _thread(context, state);
    } else if (_browsing && state is AiIdle) {
      body = AiHistoryList(
        spaceId: widget.spaceId,
        onOpen: _resume,
        onBack: () => setState(() => _browsing = false),
      );
    } else {
      body = switch (state) {
        AiIdle() => _input(context),
        AiRunning() => _Running(
          onAbandon: () {
            ref.read(aiControllerProvider.notifier).abandon();
            _close();
          },
          onRetry: () => ref.read(aiControllerProvider.notifier).retry(),
        ),
        AiFailed(:final failure) => _Failed(
          message: aiMessageFor(failure, hasRepo: _contexts.hasRepo),
          onAskAgain: _askAgain,
        ),
        // 목록에 들어가기 직전 한 프레임 — 리스너가 곧 _turns 에 넣는다.
        AiReady() => const SizedBox.shrink(),
      };
    }

    // 키보드가 올라오면 감싼 NxDialog.panel 이 비킨다 — 여기서 또 비키면 두 배가 된다.
    return body;
  }

  /// 문답 목록 (13-3 설계 §5). 지난 문답은 상태와 상관없이 그대로 보이고,
  /// 아래 꼬리만 기다림 · 실패 · 이어서 묻기로 바뀐다.
  Widget _thread(BuildContext context, AiState state) {
    final nx = NxTheme.of(context);
    final last = _turns.last.run;
    // 이슈 초안(JSON)에는 이어 묻지 않는다(설계 D6).
    final canFollow = !_turns.first.run.isIssueDraft;
    final atLimit = _turns.length >= maxThreadTurns;
    final canSend = _instruction.text.trim().isNotEmpty;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        NxSpacing.sp7,
        0,
        NxSpacing.sp7,
        NxSpacing.sp7,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: NxSpacing.sp3,
            runSpacing: NxSpacing.sp3,
            children: [for (final c in _contexts) NxChip(label: c.label)],
          ),
          const SizedBox(height: NxSpacing.sp6),
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final (i, turn) in _turns.indexed) ...[
                    if (i > 0)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: NxSpacing.sp7),
                        child: NxDivider(),
                      ),
                    _TurnView(
                      turn: turn,
                      spaceId: widget.spaceId,
                      repoId: _contexts.repoId,
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: NxSpacing.sp6),
          if (state is AiRunning)
            _Waiting(
              compact: true,
              onRetry: () => ref.read(aiControllerProvider.notifier).retry(),
              onAbandon: () =>
                  ref.read(aiControllerProvider.notifier).abandon(),
            )
          else ...[
            if (state case AiFailed(:final failure)) ...[
              // 그 질문만 실패다 — 지난 문답은 위에 그대로 남는다.
              Text(
                aiMessageFor(failure, hasRepo: _contexts.hasRepo),
                style: nx.text.secondary.copyWith(color: nx.colors.danger),
              ),
              const SizedBox(height: NxSpacing.sp4),
            ],
            if (canFollow && atLimit)
              Text(
                '이 대화는 여기까지입니다. 「다시 묻기」로 새로 시작해 주세요.',
                style: nx.text.secondary,
              )
            else if (canFollow) ...[
              NxField(
                controller: _instruction,
                hint: '이어서 묻기',
                minLines: 1,
                maxLines: 4,
                // 서버의 상한과 같다(ask-request.ts 의 MAX_INSTRUCTION).
                maxLength: 2000,
              ),
              const SizedBox(height: NxSpacing.sp4),
              Align(
                alignment: Alignment.centerRight,
                child: NxButton(
                  label: '보내기',
                  icon: NxIcons.ai,
                  onPressed: canSend ? _send : null,
                ),
              ),
            ],
          ],
          const SizedBox(height: NxSpacing.sp5),
          _Actions(
            run: last,
            onClose: _close,
            onPost: widget.onPost,
            onCreateIssue: widget.onCreateIssue == null
                ? null
                : () {
                    _close();
                    widget.onCreateIssue!(
                      title: last.title ?? '',
                      description: last.description ?? '',
                      originMessageId: _contexts.firstMessageId,
                    );
                  },
            onAskAgain: _askAgain,
          ),
        ],
      ),
    );
  }

  Widget _input(BuildContext context) {
    final nx = NxTheme.of(context);
    // 근거 없는 질문은 받지 않는다(설계 D5) — 칩이 없으면 보내기가 꺼진다.
    final canSend = _contexts.isNotEmpty && _instruction.text.trim().isNotEmpty;
    // 프리셋은 대화를 재료로 한다(설계 §1). 서버의 400 을 화면이 먼저 막는다.
    final canPreset = _contexts.hasConversation;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        NxSpacing.sp7,
        0,
        NxSpacing.sp7,
        NxSpacing.sp7,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 무엇을 근거로 묻는지 — 캔버스의 컨텍스트 칩. 빼기(×)로 거른다.
          Wrap(
            spacing: NxSpacing.sp3,
            runSpacing: NxSpacing.sp3,
            children: [
              for (final c in _contexts)
                NxChip(
                  label: c.label,
                  selected: true,
                  onRemove: () => setState(() => _contexts.remove(c)),
                ),
              if (widget.canAddRepo && !_contexts.hasRepo)
                NxChip(label: '저장소', icon: NxIcons.plus, onPressed: _addRepo),
            ],
          ),
          if (_contexts.isEmpty) ...[
            const SizedBox(height: NxSpacing.sp4),
            Text('대화나 저장소가 하나는 있어야 물을 수 있습니다.', style: nx.text.secondary),
          ],
          const SizedBox(height: NxSpacing.sp6),
          Row(
            children: [
              NxButton(
                label: '요약',
                kind: NxButtonKind.secondary,
                size: NxSize.sm,
                onPressed: canPreset
                    ? () => _send(preset: AiPreset.summary)
                    : null,
              ),
              const SizedBox(width: NxSpacing.sp4),
              NxButton(
                label: '이슈로 만들기',
                kind: NxButtonKind.secondary,
                size: NxSize.sm,
                onPressed: canPreset && widget.onCreateIssue != null
                    ? () => _send(preset: AiPreset.issue)
                    : null,
              ),
              const Spacer(),
              // 지난 대화(19). 문답 화면 · 기다리는 중에는 두지 않는다 — 대화 중에 옮겨
              // 가면 진행 중인 답을 버린 것처럼 보인다.
              NxButton(
                label: '지난 대화',
                kind: NxButtonKind.ghost,
                size: NxSize.sm,
                onPressed: () => setState(() => _browsing = true),
              ),
            ],
          ),
          const SizedBox(height: NxSpacing.sp6),
          NxField(
            controller: _instruction,
            hint: '무엇이든 물어보세요',
            autofocus: true,
            minLines: 2,
            maxLines: 6,
            // 서버의 상한과 같다(ask-request.ts 의 MAX_INSTRUCTION).
            maxLength: 2000,
          ),
          const SizedBox(height: NxSpacing.sp4),
          Align(
            alignment: Alignment.centerRight,
            child: NxButton(
              label: '보내기',
              icon: NxIcons.ai,
              onPressed: canSend ? _send : null,
            ),
          ),
        ],
      ),
    );
  }
}

/// 답을 기다리는 동안. 자리를 지키는 뼈대와 두 갈래 — 「다시 확인」 · 「기다리지 않기」.
class _Waiting extends StatelessWidget {
  const _Waiting({
    required this.onRetry,
    required this.onAbandon,
    this.compact = false,
  });

  /// 소켓 알림을 놓쳤을 때 결과가 이미 서버에 있는데 화면만 모르는 경우를
  /// 위한 것 — 같은 GET 을 다시 부른다 (13-1).
  final VoidCallback onRetry;

  /// 「중단」이 아니라 「기다리지 않기」다 — 서버의 호출은 계속 돈다.
  final VoidCallback onAbandon;

  /// 문답 목록 아래 꼬리 — 뼈대 없이 한 줄.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final nx = NxTheme.of(context);
    final actions = [
      NxButton(
        label: '다시 확인',
        kind: NxButtonKind.ghost,
        size: NxSize.sm,
        onPressed: onRetry,
      ),
      NxButton(
        label: '기다리지 않기',
        kind: NxButtonKind.ghost,
        size: NxSize.sm,
        onPressed: onAbandon,
      ),
    ];
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!compact) ...[
          const NxSkeleton(lines: 4),
          const SizedBox(height: NxSpacing.sp6),
        ],
        Row(
          children: [
            const NxSpinner(size: NxIconSize.sm),
            const SizedBox(width: NxSpacing.sp4),
            Expanded(
              child: Semantics(
                liveRegion: true,
                child: Text('답을 만들고 있습니다', style: nx.text.secondary),
              ),
            ),
            ...actions,
          ],
        ),
      ],
    );
  }
}

class _Running extends StatelessWidget {
  const _Running({required this.onAbandon, required this.onRetry});
  final VoidCallback onAbandon;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(
      NxSpacing.sp7,
      0,
      NxSpacing.sp7,
      NxSpacing.sp7,
    ),
    child: _Waiting(onRetry: onRetry, onAbandon: onAbandon),
  );
}

class _Failed extends StatelessWidget {
  const _Failed({required this.message, required this.onAskAgain});
  final String message;
  final VoidCallback onAskAgain;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(
      NxSpacing.sp7,
      0,
      NxSpacing.sp7,
      NxSpacing.sp7,
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(message, style: NxTheme.of(context).text.base),
        const SizedBox(height: NxSpacing.sp6),
        Align(
          alignment: Alignment.centerRight,
          child: NxButton(
            label: '다시 묻기',
            kind: NxButtonKind.secondary,
            onPressed: onAskAgain,
          ),
        ),
      ],
    ),
  );
}

/// 끝난 문답 하나 — 화면 문구로 쓴 질문과 그 답.
class _Turn {
  const _Turn(this.question, this.run);
  final String question;
  final AiRun run;
}

/// 문답 하나를 그린다 — 질문 · 답 · 인용 · 전환 모델 안내.
class _TurnView extends StatelessWidget {
  const _TurnView({
    required this.turn,
    required this.spaceId,
    required this.repoId,
  });

  final _Turn turn;
  final String spaceId;
  final String? repoId;

  @override
  Widget build(BuildContext context) {
    final run = turn.run;
    final nx = NxTheme.of(context);
    final c = nx.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (turn.question.isNotEmpty) ...[
          // 질문은 오른쪽 말풍선처럼 한 단 밝은 판 — 답과 한눈에 갈린다.
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: NxSpacing.sp5,
                vertical: NxSpacing.sp4,
              ),
              decoration: BoxDecoration(
                color: c.bgSurface,
                borderRadius: BorderRadius.circular(NxRadius.md),
              ),
              child: Text(turn.question, style: nx.text.base),
            ),
          ),
          const SizedBox(height: NxSpacing.sp5),
        ],
        if (run.isIssueDraft) ...[
          Text(run.title ?? '', style: nx.text.title),
          const SizedBox(height: NxSpacing.sp5),
          MarkdownBody(body: run.description ?? ''),
        ] else
          // `body:` 다 — `source:` 가 아니다 (markdown_body.dart:16).
          MarkdownBody(body: run.markdown ?? ''),
        if (run.citations.isNotEmpty && repoId != null) ...[
          const SizedBox(height: NxSpacing.sp6),
          Text('참고한 코드', style: nx.text.label),
          const SizedBox(height: NxSpacing.sp2),
          for (final citation in run.citations)
            _CitationTile(
              citation: citation,
              spaceId: spaceId,
              repoId: repoId!,
            ),
        ],
        if (run.fallback) ...[
          const SizedBox(height: NxSpacing.sp5),
          // 품질이 조용히 떨어지지 않게 한다 — 이 답은 캐시에도 남지 않아
          // 나중에 같은 질문을 하면 주 모델이 다시 답한다.
          Row(
            children: [
              NxIcon(NxIcons.info, size: NxIconSize.sm, color: c.textSecondary),
              const SizedBox(width: NxSpacing.sp3),
              Expanded(
                child: Text('사용량이 많아 가벼운 모델이 답했습니다', style: nx.text.secondary),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

/// 마지막 답에 대한 버튼들 (설계 D11). **StatefulWidget 이다** — 「채널에
/// 붙이기」가 진행 중인지를 여기서 직접 들고 있어야 한다. 버튼을 막지 않으면
/// 두 번 빠르게 눌러 **같은 답이 채널에 두 번** 올라간다(13-1). 메시지는
/// 소프트 삭제라 되돌릴 수 없다.
class _Actions extends StatefulWidget {
  const _Actions({
    required this.run,
    required this.onPost,
    required this.onCreateIssue,
    required this.onAskAgain,
    required this.onClose,
  });

  final AiRun run;
  final Future<void> Function(String markdown)? onPost;
  final VoidCallback? onCreateIssue;
  final VoidCallback onAskAgain;

  /// 붙인 뒤 패널을 닫는 방법(대화상자 · 오른쪽 판).
  final VoidCallback onClose;

  @override
  State<_Actions> createState() => _ActionsState();
}

class _ActionsState extends State<_Actions> {
  bool _posting = false;

  Future<void> _handlePost() async {
    if (_posting) return;
    setState(() => _posting = true);
    try {
      await widget.onPost!(widget.run.markdown ?? '');
      if (mounted) widget.onClose();
    } finally {
      // 실패해서 패널이 남으면 다시 누를 수 있어야 한다.
      if (mounted) setState(() => _posting = false);
    }
  }

  Future<void> _copy() async {
    final run = widget.run;
    final text = run.isIssueDraft
        ? '${run.title ?? ''}\n\n${run.description ?? ''}'
        : run.markdown ?? '';
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) NxToast.show(context, '복사했습니다', kind: NxToastKind.success);
  }

  @override
  Widget build(BuildContext context) {
    final run = widget.run;
    return Wrap(
      alignment: WrapAlignment.end,
      spacing: NxSpacing.sp3,
      runSpacing: NxSpacing.sp3,
      children: [
        NxButton(
          label: '다시 묻기',
          kind: NxButtonKind.ghost,
          onPressed: widget.onAskAgain,
        ),
        NxButton(
          label: '복사',
          icon: NxIcons.copy,
          kind: NxButtonKind.secondary,
          onPressed: _copy,
        ),
        if (run.isIssueDraft && widget.onCreateIssue != null)
          NxButton(label: '이슈 만들기', onPressed: widget.onCreateIssue),
        if (!run.isIssueDraft && widget.onPost != null)
          NxButton(
            label: '채널에 붙이기',
            icon: NxIcons.send,
            loading: _posting,
            onPressed: _handlePost,
          ),
      ],
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
  Widget build(BuildContext context) {
    final nx = NxTheme.of(context);
    return NxRow(
      dense: true,
      leading: Text('[${citation.n}]', style: nx.text.mono),
      title: citation.location,
      titleStyle: nx.text.codeLine,
      onPressed: () => context.push(
        '/s/$spaceId/repos/$repoId/browse'
        '?ref=${Uri.encodeQueryComponent(citation.commitSha)}'
        '&path=${Uri.encodeQueryComponent(citation.path)}',
      ),
    );
  }
}

/// 스페이스에 붙은 저장소 중 하나를 고른다. [NxDialog.panel] 안에 뜬다.
class _RepoPickerDialog extends ConsumerWidget {
  const _RepoPickerDialog({required this.spaceId});
  final String spaceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nx = NxTheme.of(context);
    final repos = ref.watch(spaceReposProvider(spaceId));
    Widget message(String text) => Padding(
      padding: const EdgeInsets.fromLTRB(
        NxSpacing.sp7,
        0,
        NxSpacing.sp7,
        NxSpacing.sp7,
      ),
      child: Text(text, style: nx.text.secondary),
    );
    return repos.when(
      loading: () => const Padding(
        padding: EdgeInsets.fromLTRB(
          NxSpacing.sp7,
          0,
          NxSpacing.sp7,
          NxSpacing.sp7,
        ),
        child: NxSkeleton(lines: 3, lineHeight: 28),
      ),
      error: (_, _) => message('저장소 목록을 불러오지 못했습니다.'),
      data: (items) => items.isEmpty
          ? message('이 스페이스에 붙은 저장소가 없습니다.')
          : ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(
                NxSpacing.sp5,
                0,
                NxSpacing.sp5,
                NxSpacing.sp6,
              ),
              children: [
                for (final r in items)
                  NxRow(
                    title: r.fullPath,
                    dense: true,
                    onPressed: () => Navigator.of(
                      context,
                    ).pop(RepoContext(repoId: r.id, repoName: r.name)),
                  ),
              ],
            ),
    );
  }
}
