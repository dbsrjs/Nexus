import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../domain/models/issue.dart';
import '../../domain/models/message.dart';
import 'board_controller.dart';

/// 새 이슈를 만드는 시트.
///
/// 만들면 **그 컬럼 맨 위**에 놓인다(서버가 정한다). 방금 만든 것이 보이지
/// 않으면 만든 사람은 실패했다고 믿는다.
/// `fromMessage` 를 주면 **대화 → 이슈**다. 제목을 원문에서 미리 채우고
/// 원문 링크를 함께 보낸다 — 이슈에서 그 대화로 돌아올 수 있어야 한다.
Future<void> showNewIssueSheet(BuildContext context, {Message? fromMessage}) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _NewIssueSheet(fromMessage: fromMessage),
    );

class _NewIssueSheet extends ConsumerStatefulWidget {
  const _NewIssueSheet({this.fromMessage});

  final Message? fromMessage;

  @override
  ConsumerState<_NewIssueSheet> createState() => _NewIssueSheetState();
}

class _NewIssueSheetState extends ConsumerState<_NewIssueSheet> {
  late final _title = TextEditingController(text: _titleFromMessage());
  final _description = TextEditingController();

  /// 원문의 첫 줄을 제목으로 쓴다. 긴 글을 통째로 제목에 넣으면 카드가
  /// 읽히지 않으므로 자른다 — 전문은 원문 링크를 눌러 보면 된다.
  String _titleFromMessage() {
    final body = widget.fromMessage?.body.trim();
    if (body == null || body.isEmpty) return '';
    final firstLine = body.split('\n').first.trim();
    return firstLine.length <= 80 ? firstLine : '${firstLine.substring(0, 79)}…';
  }

  IssueStatus _status = IssueStatus.backlog;
  IssuePriority _priority = IssuePriority.mid;
  bool _sending = false;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final title = _title.text.trim();
    if (title.isEmpty || _sending) return;

    setState(() => _sending = true);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final ok = await ref
        .read(boardActionsProvider)
        .create(
          title: title,
          description: _description.text.trim(),
          status: _status,
          priority: _priority,
          originMessageId: widget.fromMessage?.id,
        );

    if (!mounted) return;
    if (ok) {
      navigator.pop();
      return;
    }
    setState(() => _sending = false);
    // 큐에 넣지 않으므로 오프라인에서는 만들 수 없다. 그 사실을 그대로 말한다.
    messenger.showSnackBar(
      const SnackBar(content: Text('만들지 못했습니다. 연결을 확인해 주세요.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: NexusSpacing.sp6,
        right: NexusSpacing.sp6,
        top: NexusSpacing.sp6,
        // 키보드가 올라와도 입력창이 가리지 않게 한다.
        bottom: MediaQuery.viewInsetsOf(context).bottom + NexusSpacing.sp6,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.fromMessage == null ? '새 이슈' : '대화에서 이슈 만들기',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: NexusSpacing.sp5),
          TextField(
            controller: _title,
            autofocus: true,
            decoration: const InputDecoration(labelText: '제목'),
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: NexusSpacing.sp5),
          TextField(
            controller: _description,
            maxLines: 3,
            decoration: const InputDecoration(labelText: '설명 (선택)'),
          ),
          const SizedBox(height: NexusSpacing.sp5),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<IssueStatus>(
                  initialValue: _status,
                  decoration: const InputDecoration(labelText: '컬럼'),
                  items: [
                    for (final s in IssueStatus.values)
                      DropdownMenuItem(value: s, child: Text(issueStatusLabel(s))),
                  ],
                  onChanged: (v) => setState(() => _status = v ?? _status),
                ),
              ),
              const SizedBox(width: NexusSpacing.sp5),
              Expanded(
                child: DropdownButtonFormField<IssuePriority>(
                  initialValue: _priority,
                  decoration: const InputDecoration(labelText: '우선순위'),
                  items: [
                    for (final p in IssuePriority.values)
                      DropdownMenuItem(value: p, child: Text(issuePriorityLabel(p))),
                  ],
                  onChanged: (v) => setState(() => _priority = v ?? _priority),
                ),
              ),
            ],
          ),
          const SizedBox(height: NexusSpacing.sp6),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              onPressed: _sending ? null : _submit,
              child: Text(_sending ? '만드는 중…' : '만들기'),
            ),
          ),
        ],
      ),
    );
  }
}
