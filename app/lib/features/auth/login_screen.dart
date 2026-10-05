import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/api/auth_api.dart';
import '../../shared/widgets/nexus_logo.dart';
import '../../ui/ui.dart';
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

  /// 서버 문구를 그대로 쓰지 않는다. 서버가 메시지를 바꿔도 앱 UX 는 그대로다.
  String _messageFor(AuthFailure failure) => switch (failure) {
        AuthFailure.invalidCredentials => '이메일 또는 비밀번호가 올바르지 않습니다.',
        AuthFailure.network => '서버에 연결할 수 없습니다. 주소와 서버 상태를 확인하십시오.',
        AuthFailure.server => '로그인에 실패했습니다. 잠시 후 다시 시도하십시오.',
      };

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
    final nx = NxTheme.of(context);

    return NxPage(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(NxSpacing.sp8),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: AutofillGroup(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // **워드마크가 로고 안에 있어 'Nexus' 글자를 따로 두지
                  // 않는다.** 둘 다 두면 같은 이름이 두 번 나온다.
                  const Center(child: NexusLogo()),
                  const SizedBox(height: NxSpacing.sp5),
                  Text(
                    '대화 · 파일 · 이슈 · 저장소를 한곳에',
                    style: nx.text.secondary,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: NxSpacing.sp9),
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
                        style: nx.text.secondary.copyWith(
                          color: nx.colors.danger,
                        ),
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
              ),
            ),
          ),
        ),
      ),
    );
  }
}
