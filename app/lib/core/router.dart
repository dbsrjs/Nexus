import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/auth_controller.dart';
import '../features/chat/thread_screen.dart';
import '../features/files/files_screen.dart';
import '../features/auth/login_screen.dart';
import '../features/shell/app_shell.dart';
import '../features/space/space_picker_screen.dart';

/// 라우트는 docs/앱-설계.md §5 를 따른다. 슬라이스 2 시점에서
/// `/login` · `/spaces` · `/s/:spaceId` 까지 채웠다.
/// `/s/:spaceId/c/:channelId`(채널)는 슬라이스 3 에서 붙인다.
final routerProvider = Provider<GoRouter>((ref) {
  // GoRouter 를 상태마다 새로 만들면 내비게이션 스택이 날아간다.
  // 대신 Listenable 하나를 두고 인증 상태 변화만 흘려보낸다.
  final authChanged = ValueNotifier<AuthState>(const AuthRestoring());
  ref.listen<AuthState>(
    authControllerProvider,
    (_, next) => authChanged.value = next,
    fireImmediately: true,
  );
  ref.onDispose(authChanged.dispose);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: authChanged,
    redirect: (context, state) {
      final auth = authChanged.value;
      final path = state.matchedLocation;

      // 저장된 토큰을 확인하는 동안에는 아무 데도 보내지 않는다.
      // 여기서 /login 으로 보내면 앱을 켤 때마다 로그인 화면이 깜빡인다.
      if (auth is AuthRestoring) {
        return path == '/' ? null : '/';
      }

      final signedIn = auth is AuthSignedIn;
      final onAuthPage = path == '/login' || path == '/signup';

      if (!signedIn) return onAuthPage ? null : '/login';
      if (onAuthPage || path == '/') return '/spaces';
      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (_, _) => const _SplashScreen()),
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      GoRoute(path: '/signup', builder: (_, _) => const _SignupPlaceholder()),
      GoRoute(path: '/spaces', builder: (_, _) => const SpacePickerScreen()),
      GoRoute(
        path: '/s/:spaceId',
        builder: (_, state) =>
            AppShell(spaceId: state.pathParameters['spaceId']!),
        routes: [
          // 스페이스 파일 목록. 스레드와 같이 셸 위에 덮어서 연다 — 대화의
          // 곁가지라 돌아오는 길이 분명한 편이 낫다.
          GoRoute(
            path: 'files',
            builder: (_, state) =>
                FilesScreen(spaceId: state.pathParameters['spaceId']!),
          ),
          // 채널을 연 상태. 셸은 같고 본문만 대화로 바뀐다.
          GoRoute(
            path: 'c/:channelId',
            builder: (_, state) => AppShell(
              spaceId: state.pathParameters['spaceId']!,
              channelId: state.pathParameters['channelId'],
            ),
            routes: [
              // 스레드는 셸 위에 **덮어서** 연다. 채널 목록·레일을 유지한 채
              // 본문만 바꾸면 좁은 화면에서 뒤로 가기가 애매해지고, 스레드는
              // 대화의 곁가지라 채널로 돌아오는 길이 분명한 편이 낫다.
              GoRoute(
                path: 't/:messageId',
                builder: (_, state) => ThreadScreen(
                  spaceId: state.pathParameters['spaceId']!,
                  channelId: state.pathParameters['channelId']!,
                  messageId: state.pathParameters['messageId']!,
                ),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

/// 토큰 복원이 끝날 때까지 보여 준다. 서버가 꺼져 있으면 타임아웃까지 여기 머문다.
class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: CircularProgressIndicator()));
}

/// 회원가입은 아직 범위 밖이다. 시드 계정으로 로그인해 검증한다.
class _SignupPlaceholder extends StatelessWidget {
  const _SignupPlaceholder();

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('회원가입은 아직 만들지 않았습니다.'),
              TextButton(
                onPressed: () => context.go('/login'),
                child: const Text('로그인으로'),
              ),
            ],
          ),
        ),
      );
}
