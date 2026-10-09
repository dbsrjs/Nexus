import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth_redirect.dart';
import '../../data/api/auth_api.dart';
import '../../shared/widgets/nexus_logo.dart';
import '../../ui/ui.dart';
import 'login_backdrop.dart';

/// 로그인 · 가입이 함께 쓰는 틀 — «연결망» 배경 위에 뜬 카드 하나, 머리에 마크와 제목.
///
/// 두 화면이 같은 자리에서 서로를 오가므로 틀이 같아야 한다. 바뀌는 것은 제목 · 칸 · 버튼 ·
/// 아래의 「다른 쪽으로」 줄뿐이다.
class AuthCard extends StatelessWidget {
  const AuthCard({
    super.key,
    required this.title,
    required this.children,
    required this.switchPrompt,
    required this.switchLabel,
    required this.switchTo,
  });

  final String title;
  final List<Widget> children;

  /// 아래 줄 — 「계정이 없으신가요?」 · 「계정 만들기」 · `/signup` 처럼.
  final String switchPrompt;
  final String switchLabel;
  final String switchTo;

  @override
  Widget build(BuildContext context) {
    final nx = NxTheme.of(context);

    return NxPage(
      body: LoginBackdrop(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(NxSpacing.sp6),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              // 카드는 점 격자 위에 뜨는 판이다. 그림자 없이 표면 한 단(bgSurface)과
              // 구분선으로만 떼어 낸다(디자인 시스템 §4).
              child: Container(
                padding: const EdgeInsets.all(NxSpacing.sp9),
                decoration: BoxDecoration(
                  color: nx.colors.bgSurface,
                  borderRadius: BorderRadius.circular(NxRadius.lg),
                  border: Border.all(color: nx.colors.divider),
                ),
                child: AutofillGroup(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Center(child: NexusMarkTile(size: 56)),
                      const SizedBox(height: NxSpacing.sp5),
                      Semantics(
                        header: true,
                        child: Text(
                          title,
                          style: nx.text.heading,
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: NxSpacing.sp8),
                      ...children,
                      const SizedBox(height: NxSpacing.sp5),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(switchPrompt, style: nx.text.secondary),
                          NxButton(
                            label: switchLabel,
                            kind: NxButtonKind.ghost,
                            size: NxSize.sm,
                            onPressed: () => context.go(
                              authSwitchLocation(
                                switchTo,
                                GoRouterState.of(context).uri,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 로그인 ↔ 가입을 오갈 때 **가려던 주소(`from`)를 잃지 않는다** — 초대 링크로 들어와
/// 「계정 만들기」를 눌러도 가입 뒤 그 초대 화면으로 돌아가야 한다.
String authSwitchLocation(String to, Uri current) {
  final from = safeReturnPath(current.queryParameters['from']);
  if (from == null) return to;
  return Uri(path: to, queryParameters: {'from': from}).toString();
}

/// 서버가 왜 거절했는지를 사람의 말로. **서버 문구를 그대로 쓰지 않는다** — 서버가 문구를
/// 바꿔도 앱 UX 는 그대로다. [signUp] 이면 가입 쪽 문장이다.
String authFailureMessage(AuthFailure failure, {bool signUp = false}) =>
    switch (failure) {
      AuthFailure.invalidCredentials => '이메일 또는 비밀번호가 올바르지 않습니다.',
      AuthFailure.network => '서버에 연결할 수 없습니다. 주소와 서버 상태를 확인하십시오.',
      AuthFailure.emailTaken => '이미 가입된 이메일입니다. 로그인하거나 다른 이메일을 쓰십시오.',
      AuthFailure.rejected => '이 이메일로는 가입할 수 없습니다. 입력한 값을 확인하십시오.',
      AuthFailure.throttled => '시도가 너무 많습니다. 잠시 뒤 다시 시도하십시오.',
      AuthFailure.server =>
        signUp ? '가입에 실패했습니다. 잠시 후 다시 시도하십시오.' : '로그인에 실패했습니다. 잠시 후 다시 시도하십시오.',
    };
