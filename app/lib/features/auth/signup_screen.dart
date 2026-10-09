import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../ui/ui.dart';
import 'auth_card.dart';
import 'auth_controller.dart';

/// 가입 — 이름 · 이메일 · 비밀번호 · 비밀번호 확인.
///
/// **비밀번호 확인 칸을 둔다.** 비밀번호를 되찾는 길(메일 재설정)이 없어, 오타 한 번이 곧
/// 잃어버린 계정이다. 규칙은 서버(`SignupDto`)와 같다 — 이름 1~50자, 비밀번호 10~128자.
/// 앞에서 막는 것은 고칠 곳을 칸 옆에 보이려는 것이고, 판정의 원본은 서버다.
///
/// 성공하면 로그인한 것과 같은 상태가 되고, 라우터의 redirect 가 `from`(초대 링크 등)으로 보낸다.
class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  bool _busy = false;
  String? _error;

  /// 칸마다의 입력 오류. 보낼 때 한 번 보고, 그 칸을 고치기 시작하면 지운다.
  final _fieldErrors = <_Field, String>{};

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Map<_Field, String> _validate() {
    final name = _name.text.trim();
    final email = _email.text.trim();
    return {
      if (name.isEmpty) _Field.name: '이름을 입력하십시오.',
      if (name.length > 50) _Field.name: '이름은 50자 이하여야 합니다.',
      if (!email.contains('@')) _Field.email: '이메일을 입력하십시오.',
      if (_password.text.length < 10) _Field.password: '비밀번호는 10자 이상이어야 합니다.',
      if (_password.text.length > 128) _Field.password: '비밀번호는 128자 이하여야 합니다.',
      if (_confirm.text != _password.text) _Field.confirm: '비밀번호가 서로 다릅니다.',
    };
  }

  Future<void> _submit() async {
    if (_busy) return;
    final errors = _validate();
    if (errors.isNotEmpty) {
      setState(() {
        _fieldErrors
          ..clear()
          ..addAll(errors);
      });
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    final failure = await ref
        .read(authControllerProvider.notifier)
        .signUp(
          name: _name.text.trim(),
          email: _email.text.trim(),
          password: _password.text,
        );

    if (!mounted) return;
    setState(() {
      _busy = false;
      _error = failure == null
          ? null
          : authFailureMessage(failure, signUp: true);
    });
  }

  void _clear(_Field field) {
    if (_fieldErrors.containsKey(field)) {
      setState(() => _fieldErrors.remove(field));
    }
  }

  @override
  Widget build(BuildContext context) {
    final nx = NxTheme.of(context);

    return AuthCard(
      title: 'Nexus 계정 만들기',
      switchPrompt: '이미 계정이 있으신가요?',
      switchLabel: '로그인',
      switchTo: '/login',
      children: [
        NxField(
          label: '이름',
          controller: _name,
          error: _fieldErrors[_Field.name],
          helper: '다른 멤버에게 보이는 이름입니다',
          autofillHints: const [AutofillHints.name],
          textInputAction: TextInputAction.next,
          onChanged: (_) => _clear(_Field.name),
        ),
        const SizedBox(height: NxSpacing.sp5),
        NxField(
          label: '이메일',
          controller: _email,
          error: _fieldErrors[_Field.email],
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
          textInputAction: TextInputAction.next,
          onChanged: (_) => _clear(_Field.email),
        ),
        const SizedBox(height: NxSpacing.sp5),
        NxField(
          label: '비밀번호',
          controller: _password,
          error: _fieldErrors[_Field.password],
          helper: '10자 이상',
          obscure: true,
          autofillHints: const [AutofillHints.newPassword],
          textInputAction: TextInputAction.next,
          onChanged: (_) => _clear(_Field.password),
        ),
        const SizedBox(height: NxSpacing.sp5),
        NxField(
          label: '비밀번호 확인',
          controller: _confirm,
          error: _fieldErrors[_Field.confirm],
          obscure: true,
          autofillHints: const [AutofillHints.newPassword],
          textInputAction: TextInputAction.done,
          onChanged: (_) => _clear(_Field.confirm),
          onSubmitted: (_) => _submit(),
        ),
        if (_error != null) ...[
          const SizedBox(height: NxSpacing.sp5),
          Semantics(
            liveRegion: true,
            child: Text(
              _error!,
              style: nx.text.secondary.copyWith(color: nx.colors.danger),
            ),
          ),
        ],
        const SizedBox(height: NxSpacing.sp7),
        NxButton(
          label: '계정 만들기',
          size: NxSize.lg,
          expand: true,
          loading: _busy,
          onPressed: _submit,
        ),
      ],
    );
  }
}

enum _Field { name, email, password, confirm }
