import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nexus_app/data/api/auth_api.dart';
import 'package:nexus_app/features/auth/auth_card.dart';
import 'package:nexus_app/features/auth/auth_controller.dart';
import 'package:nexus_app/features/auth/login_screen.dart';
import 'package:nexus_app/features/auth/signup_screen.dart';
import 'package:nexus_app/ui/ui.dart';

import 'support/fake_http.dart';
import 'support/nx_host.dart';

/// 가입 화면(«마지막» — 배포 전에 초대받은 사람이 앱에서 계정을 만들 길).
void main() {
  group('authSwitchLocation', () {
    test('로그인 ↔ 가입을 오가도 가려던 주소를 들고 간다', () {
      expect(
        authSwitchLocation('/signup', Uri.parse('/login?from=/invite/ABCD')),
        '/signup?from=%2Finvite%2FABCD',
      );
    });

    test('앱 밖 주소 · 거쳐 가는 화면은 버린다', () {
      expect(
        authSwitchLocation('/signup', Uri.parse('/login?from=//evil.example')),
        '/signup',
      );
      expect(
        authSwitchLocation('/login', Uri.parse('/signup?from=/login')),
        '/login',
      );
      expect(authSwitchLocation('/login', Uri.parse('/signup')), '/login');
    });
  });

  group('AuthApi.signup', () {
    Future<AuthFailure> failureFor(int status) async {
      final adapter = FakeHttpAdapter(
        (_) async => (status: status, body: {'statusCode': status}),
      );
      final api = AuthApi(await fakeApiClient(adapter, tokens: null));
      try {
        await api.signup(name: 'n', email: 'a@b.c', password: '0123456789');
      } on AuthException catch (e) {
        return e.failure;
      }
      fail('던져야 한다');
    }

    test('응답을 로그인과 같은 모양으로 받는다 · native 로 보낸다', () async {
      final adapter = FakeHttpAdapter(
        (_) async => (
          status: 201,
          body: {
            'accessToken': 'a',
            'refreshToken': 'r',
            'user': {
              'id': 'u1',
              'email': 'a@b.c',
              'name': '새 사람',
              'avatarUrl': null,
              'globalStatus': 'online',
              'createdAt': '2026-10-09T00:00:00.000Z',
            },
          },
        ),
      );
      final api = AuthApi(await fakeApiClient(adapter, tokens: null));
      final result = await api.signup(
        name: '새 사람',
        email: 'a@b.c',
        password: '0123456789',
      );
      expect(result.user.name, '새 사람');
      expect(result.tokens.accessToken, 'a');
      final sent = adapter.requests.single;
      expect(sent.path, '/auth/signup');
      expect(sent.data, {
        'name': '새 사람',
        'email': 'a@b.c',
        'password': '0123456789',
        'client': 'native',
      });
    });

    test('409 는 이미 가입된 이메일, 400 은 거절, 429 는 한도', () async {
      expect(await failureFor(409), AuthFailure.emailTaken);
      expect(await failureFor(400), AuthFailure.rejected);
      expect(await failureFor(429), AuthFailure.throttled);
      expect(await failureFor(500), AuthFailure.server);
    });
  });

  group('가입 화면', () {
    late _FakeAuth auth;

    Future<GoRouter> open(WidgetTester tester, String location) async {
      final router = GoRouter(
        initialLocation: location,
        routes: [
          GoRoute(path: '/signup', builder: (_, _) => const SignupScreen()),
          GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
        ],
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [authControllerProvider.overrideWith(() => auth)],
          child: nxTestApp(router: router),
        ),
      );
      await tester.pump();
      return router;
    }

    Finder field(String label) => find.widgetWithText(NxField, label);

    Future<void> fill(
      WidgetTester tester, {
      String name = '새 사람',
      String email = 'new@example.com',
      String password = 'correct-horse',
      String? confirm,
    }) async {
      await tester.enterText(field('이름'), name);
      await tester.enterText(field('이메일'), email);
      await tester.enterText(field('비밀번호'), password);
      await tester.enterText(field('비밀번호 확인'), confirm ?? password);
      await tester.pump();
    }

    Future<void> submit(WidgetTester tester) async {
      await tester.tap(find.widgetWithText(NxButton, '계정 만들기'));
      await tester.pump();
      await tester.pump();
    }

    setUp(() => auth = _FakeAuth());

    testWidgets('★ 칸을 채워 보내면 다듬은 값으로 가입한다', (tester) async {
      await open(tester, '/signup');
      await fill(tester, name: '  새 사람 ', email: ' new@example.com ');
      await submit(tester);
      expect(auth.calls, [('새 사람', 'new@example.com', 'correct-horse')]);
    });

    testWidgets('★ 짧은 비밀번호 · 다른 확인은 칸 옆에 알리고 보내지 않는다', (tester) async {
      await open(tester, '/signup');
      await fill(tester, password: 'short', confirm: 'shorter');
      await submit(tester);
      expect(auth.calls, isEmpty);
      expect(find.text('비밀번호는 10자 이상이어야 합니다.'), findsOneWidget);
      expect(find.text('비밀번호가 서로 다릅니다.'), findsOneWidget);
    });

    testWidgets('빈 이름 · 이메일 같지 않은 값은 보내지 않는다', (tester) async {
      await open(tester, '/signup');
      await fill(tester, name: '   ', email: 'nope');
      await submit(tester);
      expect(auth.calls, isEmpty);
      expect(find.text('이름을 입력하십시오.'), findsOneWidget);
      expect(find.text('이메일을 입력하십시오.'), findsOneWidget);
    });

    testWidgets('고치기 시작하면 그 칸의 오류만 지운다', (tester) async {
      await open(tester, '/signup');
      await fill(tester, name: '', password: 'short', confirm: 'short');
      await submit(tester);
      await tester.enterText(field('이름'), '이름');
      await tester.pump();
      expect(find.text('이름을 입력하십시오.'), findsNothing);
      expect(find.text('비밀번호는 10자 이상이어야 합니다.'), findsOneWidget);
    });

    testWidgets('★ 이미 가입된 이메일이면 앱의 문구로 알린다', (tester) async {
      auth.result = AuthFailure.emailTaken;
      await open(tester, '/signup');
      await fill(tester);
      await submit(tester);
      expect(find.text('이미 가입된 이메일입니다. 로그인하거나 다른 이메일을 쓰십시오.'), findsOneWidget);
    });

    testWidgets('★ 로그인으로 넘어가도 from 을 들고 간다 · 다시 돌아와도', (tester) async {
      final router = await open(tester, '/signup?from=/invite/ABCD');
      await tester.tap(find.widgetWithText(NxButton, '로그인'));
      await tester.pump();
      await tester.pump();
      expect(
        router.routeInformationProvider.value.uri.toString(),
        '/login?from=%2Finvite%2FABCD',
      );
      expect(find.text('Nexus에 로그인'), findsOneWidget);

      await tester.tap(find.widgetWithText(NxButton, '계정 만들기'));
      await tester.pump();
      await tester.pump();
      expect(
        router.routeInformationProvider.value.uri.toString(),
        '/signup?from=%2Finvite%2FABCD',
      );
    });
  });
}

class _FakeAuth extends AuthController {
  final calls = <(String, String, String)>[];
  AuthFailure? result;

  @override
  AuthState build() => const AuthSignedOut();

  @override
  Future<AuthFailure?> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    calls.add((name, email, password));
    return result;
  }
}
