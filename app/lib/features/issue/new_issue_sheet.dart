import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/issue.dart';
import '../../domain/models/message.dart';
import '../../ui/ui.dart';
import 'board_controller.dart';

/// 새 이슈를 만드는 패널(바텀시트의 자리, 15단계 D8).
///
/// 만들면 **그 컬럼 맨 위**에 놓인다(서버가 정한다). 방금 만든 것이 보이지
/// 않으면 만든 사람은 실패했다고 믿는다.
/// `fromMessage` 를 주면 **대화 → 이슈**다. 제목을 원문에서 미리 채우고
/// 원문 링크를 함께 보낸다 — 이슈에서 그 대화로 돌아올 수 있어야 한다.
///
/// AI 이슈 초안(13-2)은 `initialTitle` · `initialDescription` 으로 채우고
/// 원문은 id(`originMessageId`)로만 넘긴다 — 메시지 객체를 들고 있지 않다.
Future<void> showNewIssueSheet(
  BuildContext context, {
  Message? fromMessage,
  String? originMessageId,
  String? initialTitle,
  String? initialDescription,
}) => NxDialog.panel<void>(
  context,
  title: (fromMessage?.id ?? originMessageId) == null ? '새 이슈' : '대화에서 이슈 만들기',
  width: 520,
  builder: (_) => _NewIssueSheet(
    fromMessage: fromMessage,
    originMessageId: originMessageId,
    initialTitle: initialTitle,
    initialDescription: initialDescription,
  ),
);

class _NewIssueSheet extends ConsumerStatefulWidget {
  const _NewIssueSheet({
    this.fromMessage,
    this.originMessageId,
    this.initialTitle,
    this.initialDescription,
  });

  final Message? fromMessage;
  final String? originMessageId;
  final String? initialTitle;
  final String? initialDescription;

  String? get _originId => fromMessage?.id ?? originMessageId;

  @override
  ConsumerState<_NewIssueSheet> createState() => _NewIssueSheetState();
}

class _NewIssueSheetState extends ConsumerState<_NewIssueSheet> {
  late final _title = TextEditingController(
    text: widget.initialTitle ?? _titleFromMessage(),
  );
  late final _description = TextEditingController(
    text: widget.initialDescription ?? '',
  );

  /// 원문의 첫 줄을 제목으로 쓴다. 긴 글을 통째로 제목에 넣으면 카드가
  /// 읽히지 않으므로 자른다 — 전문은 원문 링크를 눌러 보면 된다.
  String _titleFromMessage() {
    final body = widget.fromMessage?.body.trim();
    if (body == null || body.isEmpty) return '';
    final firstLine = body.split('\n').first.trim();
    return firstLine.length <= 80
        ? firstLine
        : '${firstLine.substring(0, 79)}…';
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
    final navigator = Navigator.of(context);

    final ok = await ref
        .read(boardActionsProvider)
        .create(
          title: title,
          description: _description.text.trim(),
          status: _status,
          priority: _priority,
          originMessageId: widget._originId,
        );

    if (!mounted) return;
    if (ok) {
      navigator.pop();
      return;
    }
    setState(() => _sending = false);
    // 큐에 넣지 않으므로 오프라인에서는 만들 수 없다. 그 사실을 그대로 말한다.
    NxToast.show(context, '만들지 못했습니다. 연결을 확인해 주세요.', kind: NxToastKind.error);
  }

  @override
  Widget build(BuildContext context) {
    final nx = NxTheme.of(context);
    Widget label(String text) => Padding(
      padding: const EdgeInsets.only(bottom: NxSpacing.sp3),
      child: Text(
        text,
        style: nx.text.xs.copyWith(
          fontWeight: FontWeight.w600,
          color: nx.colors.textSecondary,
        ),
      ),
    );

    return SingleChildScrollView(
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
          NxField(
            label: '제목',
            controller: _title,
            autofocus: true,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: NxSpacing.sp6),
          NxField(
            label: '설명 (선택)',
            controller: _description,
            minLines: 3,
            maxLines: 6,
          ),
          const SizedBox(height: NxSpacing.sp6),
          label('컬럼'),
          NxSegmented<IssueStatus>(
            label: '컬럼',
            value: _status,
            segments: [
              for (final s in IssueStatus.values) (s, issueStatusLabel(s)),
            ],
            onChanged: (v) => setState(() => _status = v),
          ),
          const SizedBox(height: NxSpacing.sp6),
          label('우선순위'),
          NxSegmented<IssuePriority>(
            label: '우선순위',
            value: _priority,
            segments: [
              for (final p in IssuePriority.values) (p, issuePriorityLabel(p)),
            ],
            onChanged: (v) => setState(() => _priority = v),
          ),
          const SizedBox(height: NxSpacing.sp7),
          Align(
            alignment: Alignment.centerRight,
            child: NxButton(
              label: '만들기',
              loading: _sending,
              onPressed: _submit,
            ),
          ),
        ],
      ),
    );
  }
}
