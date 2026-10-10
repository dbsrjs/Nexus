import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/api/api_failure.dart';
import '../../domain/models/message.dart';
import '../../ui/ui.dart';
import '../space/members_controller.dart';
import 'mention_autocomplete.dart';
import 'message_controller.dart';

/// 메시지 수정 · 삭제(2026-10-11). 서버 API 는 7단계부터 있었는데 앱에 입구가 없었다.
///
/// 수정은 대화상자다 — 입력창(`MessageComposer`)을 빌리면 쓰던 글 · 답장 대상 · 첨부와
/// 섞인다. 멘션은 입력창과 같은 규칙이다: 보이는 것은 `@이름`, 저장은 `<@id>`(`MentionDraft`).
/// 대화상자에서 새 멘션을 고르는 자동완성은 없다 — 서버도 수정 때 멘션 알림을 다시 내지 않는다.

/// 수정 대화상자를 연다. 저장하면 닫히고, 실패하면 이유를 보인 채 남는다(고친 글을 잃지 않게).
Future<void> showEditMessageDialog(
  BuildContext context,
  WidgetRef ref,
  Message message,
) {
  final draft = MentionDraft.fromBody(
    message.body,
    ref.read(memberNamesProvider),
  );
  return NxDialog.panel<void>(
    context,
    title: '메시지 수정',
    width: 560,
    builder: (_) => EditMessageForm(
      initial: draft,
      onSave: (body) => ref.read(messageActionsProvider).edit(message, body),
    ),
  );
}

/// 삭제를 묻고 지운다. 실패하면 토스트로 알린다 — 지울 것이 사라진 채 아무 말이 없으면 안 된다.
Future<void> confirmDeleteMessage(
  BuildContext context,
  WidgetRef ref,
  Message message,
) async {
  final ok = await NxDialog.confirm(
    context,
    title: '메시지를 삭제할까요?',
    body: '본문이 「삭제된 메시지입니다」로 바뀝니다. 첨부와 스레드 답글은 남습니다.',
    confirmLabel: '삭제',
    danger: true,
  );
  if (!ok) return;
  try {
    await ref.read(messageActionsProvider).remove(message);
  } on ApiException catch (e) {
    if (context.mounted) {
      NxToast.show(
        context,
        '삭제하지 못했습니다. ${messageFor(e.failure)}',
        kind: NxToastKind.error,
      );
    }
  }
}

class EditMessageForm extends StatefulWidget {
  const EditMessageForm({
    super.key,
    required this.initial,
    required this.onSave,
  });

  final MentionDraft initial;

  /// `<@id>` 로 되돌린 본문을 받는다.
  final Future<void> Function(String body) onSave;

  @override
  State<EditMessageForm> createState() => _EditMessageFormState();
}

class _EditMessageFormState extends State<EditMessageForm> {
  late final _controller = TextEditingController(text: widget.initial.text);
  late MentionDraft _draft = widget.initial;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _changed =>
      _draft.text.trim().isNotEmpty &&
      _draft.toBody().trim() != widget.initial.toBody().trim();

  Future<void> _save() async {
    if (!_changed || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.onSave(_draft.toBody().trim());
      if (mounted) Navigator.of(context).pop();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = '저장하지 못했습니다. ${messageFor(e.failure)}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        NxSpacing.sp7,
        0,
        NxSpacing.sp7,
        NxSpacing.sp7,
      ),
      child: CallbackShortcuts(
        // 입력창과 같다 — Enter 저장 · Shift+Enter 줄바꿈(물리 키보드).
        bindings: {const SingleActivator(LogicalKeyboardKey.enter): _save},
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            NxField(
              controller: _controller,
              label: '본문',
              minLines: 2,
              maxLines: 10,
              maxLength: 10000,
              autofocus: true,
              error: _error,
              onChanged: (text) =>
                  setState(() => _draft = _draft.withText(text)),
            ),
            const SizedBox(height: NxSpacing.sp7),
            Align(
              alignment: Alignment.centerRight,
              child: NxButton(
                label: '저장',
                loading: _busy,
                onPressed: _changed ? _save : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
