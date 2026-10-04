import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
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
import '../shared/widgets/nexus_logo.dart';
import '../features/space/space_picker_screen.dart';
import '../features/space_settings/space_settings_controller.dart';
import '../features/space_settings/space_settings_screen.dart';
import '../features/settings/settings_controller.dart';
import '../features/settings/settings_screen.dart';
import '../ui/gallery.dart';
import '../ui/ui.dart';
import '../features/channel_settings/channel_settings_controller.dart';
import '../features/channel_settings/channel_settings_screen.dart';

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
    // 디버그 빌드에서만 시작 화면을 바꿀 수 있다(`--dart-define=NX_START=/dev/ui`) —
    // 갤러리에서 한글 입력을 확인하려고 둔다. 릴리스는 늘 '/' 다.
    initialLocation: kDebugMode
        ? const String.fromEnvironment('NX_START', defaultValue: '/')
        : '/',
    refreshListenable: authChanged,
    redirect: (context, state) {
      final auth = authChanged.value;
      final path = state.matchedLocation;

      // 갤러리는 로그인과 무관하다(디버그 빌드에서만 있는 라우트).
      if (kDebugMode && path == '/dev/ui') return null;

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
  // 자체 UI 갤러리(15단계) — 디버그 빌드에서만. 디자인 캔버스와 대조하고 한글 입력을 본다.
  if (kDebugMode)
    GoRoute(path: '/dev/ui', builder: (_, _) => const NxGallery()),
  // 설정 창(14단계). 셸 밖에 덮어서 연다 — 스페이스에 묶이지 않는다.
  // `space` 는 알림 섹션이 먼저 보일 스페이스, `from` 은 닫을 때 돌아갈 곳이다.
  _overlay(
    path: '/settings',
    build: (state) => SettingsScreen(
      spaceId: state.uri.queryParameters['space'],
      from: state.uri.queryParameters['from'],
    ),
    routes: [
      // 섹션끼리는 **같은 페이지 키**다 — 옮겨 다닐 때 화면 전체가 다시 떠오르지 않고
      // 제자리에서 본문만 바뀐다(탭처럼).
      _overlay(
        path: ':section',
        pageKey: const ValueKey('settings-section'),
        build: (state) => SettingsScreen(
          section: SettingsSection.parse(state.pathParameters['section']),
          spaceId: state.uri.queryParameters['space'],
          from: state.uri.queryParameters['from'],
        ),
      ),
    ],
  ),
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
          GoRoute(path: 'c/:channelId', builder: (_, _) => const ChatScreen()),
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
  // 채널 설정 창(16단계 설계 D16). 대화 라우트(셸 안 `c/:channelId`)는 자식이 없어 이
  // 주소와 겹치지 않는다 — 스레드(`…/t/:messageId`)와 같은 자리다.
  _overlay(
    path: '/s/:spaceId/c/:channelId/settings',
    build: (state) => ChannelSettingsScreen(
      spaceId: state.pathParameters['spaceId']!,
      channelId: state.pathParameters['channelId']!,
    ),
    routes: [
      _overlay(
        path: ':section',
        pageKey: const ValueKey('channel-settings-section'),
        build: (state) => ChannelSettingsScreen(
          spaceId: state.pathParameters['spaceId']!,
          channelId: state.pathParameters['channelId']!,
          section: ChannelSettingsSection.parse(state.pathParameters['section']),
        ),
      ),
    ],
  ),
  // 스페이스 설정 창(16단계 설계 D5). 사용자 설정 창과 같은 틀 · 같은 페이지 키 규칙 —
  // 섹션을 옮겨도 화면 전체가 다시 떠오르지 않는다.
  _overlay(
    path: '/s/:spaceId/settings',
    build: (state) =>
        SpaceSettingsScreen(spaceId: state.pathParameters['spaceId']!),
    routes: [
      _overlay(
        path: ':section',
        pageKey: const ValueKey('space-settings-section'),
        build: (state) => SpaceSettingsScreen(
          spaceId: state.pathParameters['spaceId']!,
          section: SpaceSettingsSection.parse(state.pathParameters['section']),
        ),
      ),
    ],
  ),
  _overlay(
    // 저장소 안 들여다보기. **폴더 이동은 라우트를 쌓지 않는다** —
    // 경로는 화면의 상태이고 되돌아가는 길은 빵부스러기가 맡는다.
    path: '/s/:spaceId/repos/:repoId/browse',
    build: (state) => BrowseScreen(
      spaceId: state.pathParameters['spaceId']!,
      repoId: state.pathParameters['repoId']!,
      // 커밋 상세 · PR 상세에서 오면 그 sha·브랜치와 경로로 시작한다.
      initialRef: state.uri.queryParameters['ref'],
      initialPath: state.uri.queryParameters['path'],
    ),
  ),
  _overlay(
    path: '/s/:spaceId/c/:channelId/t/:messageId',
    build: (state) => ThreadScreen(
      spaceId: state.pathParameters['spaceId']!,
      channelId: state.pathParameters['channelId']!,
      messageId: state.pathParameters['messageId']!,
    ),
  ),
  // 그 push 에 들어온 커밋들. 채널 메시지에서 들어온다(10-3b).
  _overlay(
    path: '/s/:spaceId/repo-events/:eventId',
    build: (state) => CommitsScreen(
      spaceId: state.pathParameters['spaceId']!,
      eventId: state.pathParameters['eventId'],
    ),
  ),
  // 브랜치 이력. 탐색 화면의 커밋 버튼에서 들어온다.
  _overlay(
    path: '/s/:spaceId/repos/:repoId/commits',
    build: (state) => CommitsScreen(
      spaceId: state.pathParameters['spaceId']!,
      repoId: state.pathParameters['repoId']!,
      branchRef: state.uri.queryParameters['ref'],
    ),
  ),
  _overlay(
    path: '/s/:spaceId/repos/:repoId/commits/:sha',
    build: (state) => CommitDetailScreen(
      spaceId: state.pathParameters['spaceId']!,
      repoId: state.pathParameters['repoId']!,
      sha: state.pathParameters['sha']!,
    ),
  ),
  _overlay(
    path: '/s/:spaceId/repos/:repoId/pulls',
    build: (state) => PullsScreen(
      spaceId: state.pathParameters['spaceId']!,
      repoId: state.pathParameters['repoId']!,
    ),
  ),
  _overlay(
    path: '/s/:spaceId/repos/:repoId/pulls/:number',
    build: (state) => PullDetailScreen(
      spaceId: state.pathParameters['spaceId']!,
      repoId: state.pathParameters['repoId']!,
      number: int.parse(state.pathParameters['number']!),
    ),
  ),
];

/// 덮어 여는 화면(셸 밖)의 라우트 — 180ms 페이드 + 8px 올라옴(15단계 D14). 셸 안은 전환이
/// 없다(`builder` 라우트는 WidgetsApp 아래에서 go_router 가 전환 없이 그린다).
GoRoute _overlay({
  required String path,
  required Widget Function(GoRouterState state) build,
  LocalKey? pageKey,
  List<RouteBase> routes = const [],
}) => GoRoute(
  path: path,
  routes: routes,
  pageBuilder: (_, state) => CustomTransitionPage<void>(
    key: pageKey ?? state.pageKey,
    child: build(state),
    transitionDuration: NxMotion.panel,
    reverseTransitionDuration: NxMotion.panel,
    transitionsBuilder: (_, animation, _, child) {
      final t = CurvedAnimation(parent: animation, curve: NxMotion.ease);
      return FadeTransition(
        opacity: t,
        child: AnimatedBuilder(
          animation: t,
          builder: (_, child) => Transform.translate(
            offset: Offset(0, 8 * (1 - t.value)),
            child: child,
          ),
          child: child,
        ),
      );
    },
  ),
);

/// 토큰 복원이 끝날 때까지 보여 준다. 서버가 꺼져 있으면 타임아웃까지 여기 머문다.
/// 그 시간이 짧지 않을 수 있어 **브랜드 마크를 둔다**(`NexusSplash`) — 빈
/// 스피너 하나만 있으면 «켜지는 중» 인지 «멈춘 것» 인지 구분되지 않는다.
class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) => const NexusSplash();
}

/// 회원가입은 아직 범위 밖이다. 시드 계정으로 로그인해 검증한다.
class _SignupPlaceholder extends StatelessWidget {
  const _SignupPlaceholder();

  @override
  Widget build(BuildContext context) => NxPage(
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '회원가입은 아직 만들지 않았습니다.',
            style: NxTheme.of(context).text.base,
          ),
          const SizedBox(height: NxSpacing.sp5),
          NxButton(
            label: '로그인으로',
            kind: NxButtonKind.secondary,
            onPressed: () => context.go('/login'),
          ),
        ],
      ),
    ),
  );
}
