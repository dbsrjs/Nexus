import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/api/api_failure.dart';
import '../../ui/ui.dart';
import 'settings_controller.dart';
import 'settings_widgets.dart';

/// 비밀번호 바꾸기(14단계 설계 D11~D14).
///
/// **새 비밀번호 규칙은 여기서 먼저 막는다** — 10~128자 · 현재와 다름 · 확인과
/// 같음. 그래서 서버가 400 을 주면 남은 이유는 「현재 비밀번호가 틀림」 하나다.
class PasswordSection extends ConsumerStatefulWidget {
  const PasswordSection({super.key});

  @override
  ConsumerState<PasswordSection> createState() => _PasswordSectionState();
}

class _PasswordSectionState extends ConsumerState<PasswordSection> {
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  /// 앱이 먼저 거르는 조건. 통과하면 null.
  String? _localError() {
    if (_current.text.isEmpty) return '현재 비밀번호를 입력하세요';
    if (_next.text.length < 10) return '새 비밀번호는 10자 이상이어야 합니다';
    if (_next.text.length > 128) return '새 비밀번호는 128자 이하여야 합니다';
    if (_next.text == _current.text) return '새 비밀번호가 지금과 같습니다';
    if (_next.text != _confirm.text) return '새 비밀번호 확인이 맞지 않습니다';
    return null;
  }

  Future<void> _submit() async {
    final local = _localError();
    if (local != null) {
      setState(() => _error = local);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(settingsApiProvider).changePassword(
            current: _current.text,
            next: _next.text,
          );
      _current.clear();
      _next.clear();
      _confirm.clear();
      if (mounted) {
        NxToast.show(
          context,
          '비밀번호를 바꿨습니다. 다른 기기에서는 다시 로그인해야 합니다.',
          kind: NxToastKind.success,
        );
      }
    } on ApiException catch (e) {
      _error = settingsMessageFor(e.failure, password: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SettingsPage(
      title: '비밀번호',
      children: [
        _field('현재 비밀번호', _current),
        _field('새 비밀번호', _next, helper: '10자 이상'),
        _field(
          '새 비밀번호 확인',
          _confirm,
          onSubmitted: (_) => _busy ? null : _submit(),
        ),
        const SizedBox(height: NxSpacing.sp4),
        Row(
          children: [
            NxButton(label: '비밀번호 바꾸기', loading: _busy, onPressed: _submit),
          ],
        ),
        if (_error != null) SettingsError(_error!),
      ],
    );
  }

  Widget _field(
    String label,
    TextEditingController controller, {
    String? helper,
    ValueChanged<String>? onSubmitted,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: NxSpacing.sp6),
      child: NxField(
        label: label,
        controller: controller,
        obscure: true,
        helper: helper,
        textInputAction: onSubmitted == null
            ? TextInputAction.next
            : TextInputAction.done,
        onSubmitted: onSubmitted,
      ),
    );
  }
}
