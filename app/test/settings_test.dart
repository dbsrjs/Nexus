import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_app/data/api/api_failure.dart';
import 'package:nexus_app/data/api/settings_api.dart';
import 'package:nexus_app/domain/models/user.dart';
import 'package:nexus_app/data/local/app_database.dart';
import 'package:nexus_app/features/auth/auth_controller.dart';
import 'package:nexus_app/features/space/space_controller.dart';
import 'package:nexus_app/features/settings/account_section.dart';
import 'package:nexus_app/features/settings/password_section.dart';
import 'package:nexus_app/features/settings/settings_controller.dart';
import 'package:nexus_app/ui/ui.dart';

import 'support/nx_host.dart';

/// 14단계 설정 창.
void main() {
  group('settingsLocation', () {
    test('섹션 · 스페이스 · 돌아갈 곳을 주소에 싣는다', () {
      final uri = Uri.parse(settingsLocation(
        SettingsSection.notifications,
        spaceId: 's1',
        from: '/s/s1/c/c1',
      ));
      expect(uri.path, '/settings/notifications');
      expect(uri.queryParameters, {'space': 's1', 'from': '/s/s1/c/c1'});
    });

    test('없는 값은 싣지 않는다 - 빈 물음표도 남기지 않는다', () {
      expect(settingsLocation(null), '/settings');
      expect(settingsLocation(SettingsSection.account), '/settings/account');
    });

    test('모르는 섹션 이름은 null 이다', () {
      expect(SettingsSection.parse('nope'), isNull);
      expect(SettingsSection.parse('password'), SettingsSection.password);
    });
  });

  group('내 계정 섹션', () {
    testWidgets('★ 이름을 고쳐 저장하면 서버를 부르고 결과를 알린다', (tester) async {
      final api = _FakeSettingsApi();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            settingsApiProvider.overrideWithValue(api),
            authControllerProvider.overrideWith(_SignedIn.new),
            appDatabaseProvider.overrideWith((ref) {
              final db = AppDatabase(NativeDatabase.memory());
              ref.onDispose(db.close);
              return db;
            }),
          ],
          child: nxTestApp(home: const NxPage(body: AccountSection()),
          ),
        ),
      );
      await tester.enterText(find.byType(NxField), '새 이름');
      await tester.pump();
      await tester.tap(find.widgetWithText(NxButton, '저장'));
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
      await tester.pump();
      expect(api.names, ['새 이름']);
      expect(find.text('이름을 바꿨습니다'), findsOneWidget);
    });

    testWidgets('이름이 그대로거나 비었으면 저장 버튼이 꺼져 있다', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            settingsApiProvider.overrideWithValue(_FakeSettingsApi()),
            authControllerProvider.overrideWith(_SignedIn.new),
          ],
          child: nxTestApp(home: const NxPage(body: AccountSection())),
        ),
      );
      NxButton save() => tester.widget<NxButton>(find.widgetWithText(NxButton, '저장'));
      expect(save().onPressed, isNull);
      await tester.enterText(find.byType(NxField), '   ');
      await tester.pump();
      expect(save().onPressed, isNull);
    });
  });

  group('비밀번호 섹션 — 앱이 먼저 거른다', () {
    late _FakeSettingsApi api;

    Future<void> pump(WidgetTester tester) async {
      api = _FakeSettingsApi();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [settingsApiProvider.overrideWithValue(api)],
          child: nxTestApp(home: const NxPage(body: PasswordSection()),
          ),
        ),
      );
    }

    Future<void> fill(WidgetTester tester, String current, String next, String confirm) async {
      final fields = find.byType(NxField);
      await tester.enterText(fields.at(0), current);
      await tester.enterText(fields.at(1), next);
      await tester.enterText(fields.at(2), confirm);
      await tester.tap(find.text('비밀번호 바꾸기'));
      await tester.pump();
    }

    testWidgets('★ 9자면 서버를 부르지 않는다', (tester) async {
      await pump(tester);
      await fill(tester, 'current-pass-1', 'short-999', 'short-999');
      expect(api.calls, 0);
      expect(find.text('새 비밀번호는 10자 이상이어야 합니다'), findsOneWidget);
    });

    testWidgets('확인이 다르면 서버를 부르지 않는다', (tester) async {
      await pump(tester);
      await fill(tester, 'current-pass-1', 'new-password-1', 'new-password-2');
      expect(api.calls, 0);
      expect(find.text('새 비밀번호 확인이 맞지 않습니다'), findsOneWidget);
    });

    testWidgets('현재와 같으면 서버를 부르지 않는다', (tester) async {
      await pump(tester);
      await fill(tester, 'same-password-1', 'same-password-1', 'same-password-1');
      expect(api.calls, 0);
      expect(find.text('새 비밀번호가 지금과 같습니다'), findsOneWidget);
    });

    testWidgets('★ 서버가 400 이면 「현재 비밀번호가 맞지 않습니다」 다 - 서버 문구를 쓰지 않는다', (tester) async {
      await pump(tester);
      api.failWith = ApiFailure.badRequest;
      await fill(tester, 'wrong-current-1', 'new-password-1', 'new-password-1');
      await tester.pump();
      expect(api.calls, 1);
      expect(find.text('현재 비밀번호가 맞지 않습니다'), findsOneWidget);
    });

    testWidgets('성공하면 칸을 비우고 다른 기기 안내를 보인다', (tester) async {
      await pump(tester);
      await fill(tester, 'current-pass-1', 'new-password-1', 'new-password-1');
      await tester.pump();
      expect(api.calls, 1);
      expect(find.textContaining('다른 기기에서는 다시 로그인'), findsOneWidget);
      final first = tester.widget<NxField>(find.byType(NxField).first);
      expect(first.controller!.text, isEmpty);
    });
  });
}

class _SignedIn extends AuthController {
  @override
  AuthState build() => const AuthSignedIn(User(id: 'u1', email: 'a@x.io', name: '가영'));

  @override
  Future<void> replaceUser(User user) async => state = AuthSignedIn(user);
}

class _FakeSettingsApi implements SettingsApi {
  int calls = 0;
  ApiFailure? failWith;

  @override
  Future<void> changePassword({required String current, required String next}) async {
    calls++;
    if (failWith != null) throw ApiException(failWith!);
  }

  final names = <String>[];

  @override
  Future<User> updateName(String name) async {
    names.add(name);
    return User(id: 'u1', email: 'a@x.io', name: name);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
