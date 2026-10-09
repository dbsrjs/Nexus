import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../ui/ui.dart';
import 'auth_card.dart';
import 'auth_controller.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();

  bool _busy = false;
  String? _error;

  /// 칸마다의 입력 오류. 보낼 때 한 번 보고, 고치기 시작하면 지운다.
  String? _emailError;
  String? _passwordError;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final emailError = _email.text.contains('@') ? null : '이메일을 입력하십시오.';
    final passwordError = _password.text.isEmpty ? '비밀번호를 입력하십시오.' : null;
    if (emailError != null || passwordError != null) {
      setState(() {
        _emailError = emailError;
        _passwordError = passwordError;
      });
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    final failure = await ref
        .read(authControllerProvider.notifier)
        .signIn(email: _email.text.trim(), password: _password.text);

    if (!mounted) return;
    setState(() {
      _busy = false;
      _error = failure == null ? null : authFailureMessage(failure);
    });
    // 성공하면 라우터의 redirect 가 알아서 홈으로 보낸다.
  }

  @override
  Widget build(BuildContext context) {
    final nx = NxTheme.of(context);

    return AuthCard(
      title: 'Nexus에 로그인',
      switchPrompt: '계정이 없으신가요?',
      switchLabel: '계정 만들기',
      switchTo: '/signup',
      children: [
        NxField(
          label: '이메일',
          controller: _email,
          error: _emailError,
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.username],
          textInputAction: TextInputAction.next,
          onChanged: (_) {
            if (_emailError != null) {
              setState(() => _emailError = null);
            }
          },
        ),
        const SizedBox(height: NxSpacing.sp5),
        NxField(
          label: '비밀번호',
          controller: _password,
          error: _passwordError,
          obscure: true,
          autofillHints: const [AutofillHints.password],
          textInputAction: TextInputAction.done,
          onChanged: (_) {
            if (_passwordError != null) {
              setState(() => _passwordError = null);
            }
          },
          onSubmitted: (_) => _busy ? null : _submit(),
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
          label: '로그인',
          size: NxSize.lg,
          expand: true,
          loading: _busy,
          onPressed: _submit,
        ),
      ],
    );
  }
}
