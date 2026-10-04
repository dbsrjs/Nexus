import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/api/api_failure.dart';
import '../../ui/ui.dart';
import 'invite_code.dart';
import 'members_controller.dart';
import 'space_controller.dart';

/// 초대 수락 실패 문구(16단계 설계 D3). 만료와 소진을 가르지 않는다 — 할 일(새 코드를
/// 받는다)이 같다.
String joinMessageFor(ApiFailure failure) => switch (failure) {
  ApiFailure.notFound => '없는 초대 코드입니다',
  ApiFailure.badRequest => '만료됐거나 사용 한도가 찬 초대 코드입니다',
  _ => messageFor(failure),
};

/// 스페이스 만들기(설계 D1). 만들면 목록을 다시 받고 그 스페이스로 들어간다.
Future<void> showCreateSpaceDialog(BuildContext context, WidgetRef ref) =>
    NxDialog.panel<void>(
      context,
      title: '스페이스 만들기',
      builder: (_) => _OneFieldForm(
        label: '이름',
        submitLabel: '만들기',
        maxLength: 60,
        onSubmit: (name) async {
          final space = await ref.read(spacesApiProvider).create(name);
          await ref.read(workspaceRepositoryProvider).refreshSpaces();
          return space.id;
        },
        messageFor: messageFor,
        onDone: (id) {
          if (context.mounted) context.go('/s/$id');
        },
      ),
    );

/// 초대 코드로 참여(설계 D2 · D3).
Future<void> showJoinSpaceDialog(BuildContext context, WidgetRef ref) =>
    NxDialog.panel<void>(
      context,
      title: '초대 코드로 참여',
      builder: (_) => _OneFieldForm(
        label: '초대 코드',
        hint: '받은 코드나 문장을 그대로 붙여넣으세요',
        submitLabel: '참여',
        normalize: parseInviteCode,
        onSubmit: (code) async {
          final id = await ref.read(invitesApiProvider).accept(code);
          await ref.read(workspaceRepositoryProvider).refreshSpaces();
          return id;
        },
        messageFor: joinMessageFor,
        onDone: (id) {
          if (context.mounted) context.go('/s/$id');
        },
      ),
    );

/// 입력 한 칸 + 버튼. 두 다이얼로그가 같은 모양이라 하나로 둔다.
class _OneFieldForm extends StatefulWidget {
  const _OneFieldForm({
    required this.label,
    required this.submitLabel,
    required this.onSubmit,
    required this.messageFor,
    required this.onDone,
    this.hint,
    this.normalize,
    this.maxLength,
  });

  final String label;
  final String? hint;
  final String submitLabel;
  final int? maxLength;

  /// 입력을 보낼 값으로 바꾼다. null 이면 버튼이 꺼진다. 없으면 앞뒤 공백만 걷는다.
  final String? Function(String input)? normalize;
  final Future<String> Function(String value) onSubmit;
  final String Function(ApiFailure failure) messageFor;
  final void Function(String id) onDone;

  @override
  State<_OneFieldForm> createState() => _OneFieldFormState();
}

class _OneFieldFormState extends State<_OneFieldForm> {
  final _controller = TextEditingController();
  bool _busy = false;
  String? _error;

  String? get _value {
    final normalize = widget.normalize;
    if (normalize != null) return normalize(_controller.text);
    final trimmed = _controller.text.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final value = _value;
    if (value == null || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final id = await widget.onSubmit(value);
      if (!mounted) return;
      Navigator.of(context).pop();
      widget.onDone(id);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = widget.messageFor(e.failure);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // 패널(NxDialog.panel)은 머리 줄만 그린다 — 본문 여백은 여기서 준다.
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
          NxField(
            controller: _controller,
            label: widget.label,
            hint: widget.hint,
            error: _error,
            maxLength: widget.maxLength,
            autofocus: true,
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: NxSpacing.sp6),
          Align(
            alignment: Alignment.centerRight,
            child: NxButton(
              label: widget.submitLabel,
              loading: _busy,
              onPressed: _value == null ? null : _submit,
            ),
          ),
        ],
      ),
    );
  }
}
