import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/markdown/markdown_body.dart';
import 'ai_controller.dart';

/// 요약 결과 패널.
///
/// **「채널에 붙이기」는 평범한 메시지 전송이다** — 서버에 새 경로가 없다
/// (설계 §7.1). 사람이 한 번 거르므로 틀린 요약이 대화에 남지 않는다.
Future<void> showAiResultSheet(
  BuildContext context, {
  required Future<void> Function(String markdown) onPost,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => Consumer(
      builder: (context, ref, _) {
        final state = ref.watch(aiSummaryControllerProvider);

        return switch (state) {
          AiIdle() => const SizedBox.shrink(),
          AiRunning() => _Running(
            onAbandon: () {
              ref.read(aiSummaryControllerProvider.notifier).abandon();
              Navigator.of(sheetContext).pop();
            },
          ),
          AiFailed(:final failure) => _Failed(message: aiMessageFor(failure)),
          AiReady(:final run) => _Ready(
            markdown: run.markdown ?? '',
            onPost: () async {
              await onPost(run.markdown ?? '');
              if (sheetContext.mounted) Navigator.of(sheetContext).pop();
            },
          ),
        };
      },
    ),
  );
}

class _Running extends StatelessWidget {
  const _Running({required this.onAbandon});
  final VoidCallback onAbandon;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(24),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const CircularProgressIndicator(),
        const SizedBox(height: 16),
        const Text('요약하고 있습니다'),
        const SizedBox(height: 16),
        // 「중단」이 아니라 「기다리지 않기」다 — 서버의 호출은 계속 돈다.
        TextButton(onPressed: onAbandon, child: const Text('기다리지 않기')),
      ],
    ),
  );
}

class _Failed extends StatelessWidget {
  const _Failed({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) =>
      Padding(padding: const EdgeInsets.all(24), child: Text(message));
}

/// **StatefulWidget 이다** — 「채널에 붙이기」가 진행 중인지를 여기서 직접
/// 들고 있어야 한다. 버튼을 막지 않으면 두 번 빠르게 눌러 **같은 요약이
/// 채널에 두 번** 올라간다. 메시지는 소프트 삭제라 한 번 올라간 것을 깨끗이
/// 되돌릴 수 없고 모두에게 보이므로, 여기서 반드시 막는다.
class _Ready extends StatefulWidget {
  const _Ready({required this.markdown, required this.onPost});
  final String markdown;
  final Future<void> Function() onPost;

  @override
  State<_Ready> createState() => _ReadyState();
}

class _ReadyState extends State<_Ready> {
  bool _posting = false;

  Future<void> _handlePost() async {
    if (_posting) return;
    setState(() => _posting = true);
    try {
      await widget.onPost();
    } finally {
      // 성공하면 곧 시트가 닫히지만, 실패해서 시트가 남으면 다시 누를 수
      // 있어야 한다 — 계속 막아 두면 사용자가 되돌릴 방법이 없어진다.
      if (mounted) setState(() => _posting = false);
    }
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(24),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Flexible(
          child: SingleChildScrollView(
            // `body:` 다 — `source:` 가 아니다 (markdown_body.dart:16).
            child: MarkdownBody(body: widget.markdown),
          ),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: _posting ? null : _handlePost,
          icon: _posting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.send_outlined),
          label: const Text('채널에 붙이기'),
        ),
      ],
    ),
  );
}
