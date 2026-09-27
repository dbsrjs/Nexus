import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_app/core/theme.dart';
import 'package:nexus_app/data/api/api_failure.dart';
import 'package:nexus_app/data/api/settings_api.dart';
import 'package:nexus_app/features/settings/password_section.dart';
import 'package:nexus_app/features/settings/settings_controller.dart';

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

  group('비밀번호 섹션 — 앱이 먼저 거른다', () {
    late _FakeSettingsApi api;

    Future<void> pump(WidgetTester tester) async {
      api = _FakeSettingsApi();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [settingsApiProvider.overrideWithValue(api)],
          child: MaterialApp(
            theme: buildNexusTheme(brightness: Brightness.dark),
            home: const Scaffold(body: PasswordSection()),
          ),
        ),
      );
    }

    Future<void> fill(WidgetTester tester, String current, String next, String confirm) async {
      final fields = find.byType(TextField);
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
      final first = tester.widget<TextField>(find.byType(TextField).first);
      expect(first.controller!.text, isEmpty);
    });
  });
}

class _FakeSettingsApi implements SettingsApi {
  int calls = 0;
  ApiFailure? failWith;

  @override
  Future<void> changePassword({required String current, required String next}) async {
    calls++;
    if (failWith != null) throw ApiException(failWith!);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
