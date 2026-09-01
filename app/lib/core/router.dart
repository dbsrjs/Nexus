import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/auth_controller.dart';
import '../features/chat/chat_screen.dart';
import '../features/chat/thread_screen.dart';
import '../features/files/files_screen.dart';
import '../features/issue/board_screen.dart';
import '../features/issue/issue_detail_screen.dart';
import '../features/issue/sprint_screen.dart';
import '../features/auth/login_screen.dart';
import '../features/repo/browse_screen.dart';
import '../features/repo/commit_detail_screen.dart';
import '../features/repo/commits_screen.dart';
import '../features/repo/pull_detail_screen.dart';
import '../features/repo/pulls_screen.dart';
import '../features/repo/repos_screen.dart';
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
    routes: appRoutes(),
  );
});

/// 라우트 트리. **provider 밖에 둔 이유는 테스트가 구조를 검사하기 위해서다** —
/// 저장소 갈래가 셸 안으로 되돌아오면 `router_shell_test.dart` 가 잡는다.
List<RouteBase> appRoutes() => [
      GoRoute(path: '/', builder: (_, _) => const _SplashScreen()),
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      GoRoute(path: '/signup', builder: (_, _) => const _SignupPlaceholder()),
      GoRoute(path: '/spaces', builder: (_, _) => const SpacePickerScreen()),
      // ── 셸 안 — 한 번 가서 머무는 곳 ──────────────────
      //
      // ShellRoute 가 셸을 마운트한 채로 두므로, 갈래를 옮겨도 레일과 채널
      // 목록이 다시 만들어지지 않는다. **무엇을 그릴지는 여전히 라우터가
      // 정한다** — 셸이 본문을 탭으로 갈아 끼우면 "라우트가 진실의 원천"
      // 이라는 전제가 깨진다.
      ShellRoute(
        builder: (context, state, child) {
          // ShellRoute 빌더에서 자식 라우트의 pathParameters 가 실리는지는
          // go_router 버전에 따라 다를 수 있어, 경로에서 직접 읽는다.
          // 세그먼트는 [s, <spaceId>] 또는 [s, <spaceId>, c, <channelId>] 다.
          final seg = state.uri.pathSegments;
          final spaceId = seg.length >= 2 ? seg[1] : '';
          final channelId = seg.length >= 4 && seg[2] == 'c' ? seg[3] : null;

          return AppShell(
            spaceId: spaceId,
            // 대화 라우트에서만 채널이 열려 있다. 다른 갈래에서는 null 이라
            // 채널 목록의 선택 표시가 꺼진다.
            channelId: channelId,
            child: child,
          );
        },
        routes: [
          GoRoute(
            path: '/s/:spaceId',
            builder: (_, _) => const ShellHome(),
            routes: [
              // 이슈 보드와 스프린트는 대화의 곁가지가 아니라 나란한 주
              // 기능이다. 그래서 셸 안에 둔다.
              GoRoute(
                path: 'issues',
                builder: (_, state) =>
                    BoardScreen(spaceId: state.pathParameters['spaceId']!),
                routes: [
                  // 상세는 **키**로 잡는다 — 사람이 대화에 붙여 넣는 것도
                  // uuid 가 아니라 NEXUS-12 다. API 는 id 로 유지한다.
                  GoRoute(
                    path: ':issueKey',
                    builder: (_, state) => IssueDetailScreen(
                      spaceId: state.pathParameters['spaceId']!,
                      issueKey: state.pathParameters['issueKey']!,
                    ),
                  ),
                ],
              ),
              GoRoute(
                path: 'sprints',
                builder: (_, state) =>
                    SprintScreen(spaceId: state.pathParameters['spaceId']!),
              ),
              GoRoute(
                path: 'files',
                builder: (_, state) =>
                    FilesScreen(spaceId: state.pathParameters['spaceId']!),
              ),
              GoRoute(
                path: 'repos',
                builder: (_, state) =>
                    ReposScreen(spaceId: state.pathParameters['spaceId']!),
              ),
              // 채널을 연 상태. 셸은 같고 본문만 대화로 바뀐다.
              GoRoute(
                path: 'c/:channelId',
                builder: (_, _) => const ChatScreen(),
              ),
            ],
          ),
        ],
      ),

      // ── 셸 밖 — 보고 돌아오는 곳 ──────────────────────
      //
      // 특정 메시지 · 특정 저장소에서 파고드는 것이라 돌아오는 길이 분명한
      // 편이 낫다. 이것은 원래 판단이고 그대로 지킨다.
      //
      // **저장소 갈래는 넷이 다 여기 있어야 한다**(browse · commits ·
      // commit 상세 · pulls). 하나라도 셸 안에 두면 셸 밖 화면에서 그리로
      // `push` 할 때 `ShellRoute` 가 두 번 쌓인다 — go_router 는 셸 페이지
      // 키를 `ValueKey(route.hashCode)` 로 매기므로 **언제나 같은 키**라
      // `!keyReservation.contains(key)` 로 죽는다. 실제로 browse 만 셸 안에
      // 있었고, PR · 커밋 상세에서 파일을 누르면 빨간 화면이 떴다.
      // 근거와 재현은 `test/router_shell_test.dart` 에 있다.
      GoRoute(
        // 저장소 안 들여다보기. **폴더 이동은 라우트를 쌓지 않는다** —
        // 경로는 화면의 상태이고 되돌아가는 길은 빵부스러기가 맡는다.
        path: '/s/:spaceId/repos/:repoId/browse',
        builder: (_, state) => BrowseScreen(
          spaceId: state.pathParameters['spaceId']!,
          repoId: state.pathParameters['repoId']!,
          // 커밋 상세 · PR 상세에서 오면 그 sha·브랜치와 경로로 시작한다.
          initialRef: state.uri.queryParameters['ref'],
          initialPath: state.uri.queryParameters['path'],
        ),
      ),
      GoRoute(
        path: '/s/:spaceId/c/:channelId/t/:messageId',
        builder: (_, state) => ThreadScreen(
          spaceId: state.pathParameters['spaceId']!,
          channelId: state.pathParameters['channelId']!,
          messageId: state.pathParameters['messageId']!,
        ),
      ),
      // 그 push 에 들어온 커밋들. 채널 메시지에서 들어온다(10-3b).
      GoRoute(
        path: '/s/:spaceId/repo-events/:eventId',
        builder: (_, state) => CommitsScreen(
          spaceId: state.pathParameters['spaceId']!,
          eventId: state.pathParameters['eventId'],
        ),
      ),
      // 브랜치 이력. 탐색 화면의 커밋 버튼에서 들어온다.
      GoRoute(
        path: '/s/:spaceId/repos/:repoId/commits',
        builder: (_, state) => CommitsScreen(
          spaceId: state.pathParameters['spaceId']!,
          repoId: state.pathParameters['repoId']!,
          branchRef: state.uri.queryParameters['ref'],
        ),
      ),
      GoRoute(
        path: '/s/:spaceId/repos/:repoId/commits/:sha',
        builder: (_, state) => CommitDetailScreen(
          spaceId: state.pathParameters['spaceId']!,
          repoId: state.pathParameters['repoId']!,
          sha: state.pathParameters['sha']!,
        ),
      ),
      GoRoute(
        path: '/s/:spaceId/repos/:repoId/pulls',
        builder: (_, state) => PullsScreen(
          spaceId: state.pathParameters['spaceId']!,
          repoId: state.pathParameters['repoId']!,
        ),
      ),
      GoRoute(
        path: '/s/:spaceId/repos/:repoId/pulls/:number',
        builder: (_, state) => PullDetailScreen(
          spaceId: state.pathParameters['spaceId']!,
          repoId: state.pathParameters['repoId']!,
          number: int.parse(state.pathParameters['number']!),
        ),
      ),
    ];

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
