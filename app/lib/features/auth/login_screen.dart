import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../data/api/auth_api.dart';
import '../../shared/widgets/nexus_logo.dart';
import 'auth_controller.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  /// 서버 문구를 그대로 쓰지 않는다. 서버가 메시지를 바꿔도 앱 UX 는 그대로다.
  String _messageFor(AuthFailure failure) => switch (failure) {
        AuthFailure.invalidCredentials => '이메일 또는 비밀번호가 올바르지 않습니다.',
        AuthFailure.network => '서버에 연결할 수 없습니다. 주소와 서버 상태를 확인하십시오.',
        AuthFailure.server => '로그인에 실패했습니다. 잠시 후 다시 시도하십시오.',
      };

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _busy = true;
      _error = null;
    });

    final failure = await ref.read(authControllerProvider.notifier).signIn(
          email: _email.text.trim(),
          password: _password.text,
        );

    if (!mounted) return;
    setState(() {
      _busy = false;
      _error = failure == null ? null : _messageFor(failure);
    });
    // 성공하면 라우터의 redirect 가 알아서 홈으로 보낸다.
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(NexusSpacing.sp8),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // **워드마크가 그림 안에 있어 'Nexus' 글자를 따로 두지
                  // 않는다.** 둘 다 두면 같은 이름이 두 번 나온다.
                  const Center(child: NexusLogo()),
                  const SizedBox(height: NexusSpacing.sp5),
                  Text('대화 · 파일 · 이슈 · 저장소를 한곳에',
                      style: theme.textTheme.bodySmall,
                      textAlign: TextAlign.center),
                  const SizedBox(height: NexusSpacing.sp9),
                  TextFormField(
                    controller: _email,
                    decoration: const InputDecoration(labelText: '이메일'),
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.username],
                    textInputAction: TextInputAction.next,
                    validator: (v) =>
                        (v == null || !v.contains('@')) ? '이메일을 입력하십시오.' : null,
                  ),
                  const SizedBox(height: NexusSpacing.sp5),
                  TextFormField(
                    controller: _password,
                    decoration: const InputDecoration(labelText: '비밀번호'),
                    obscureText: true,
                    autofillHints: const [AutofillHints.password],
                    onFieldSubmitted: (_) => _busy ? null : _submit(),
                    validator: (v) =>
                        (v == null || v.isEmpty) ? '비밀번호를 입력하십시오.' : null,
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: NexusSpacing.sp5),
                    Text(
                      _error!,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: NexusColors.danger),
                    ),
                  ],
                  const SizedBox(height: NexusSpacing.sp7),
                  FilledButton(
                    onPressed: _busy ? null : _submit,
                    child: _busy
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child:
                                CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('로그인'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
