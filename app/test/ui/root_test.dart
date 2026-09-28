import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_app/data/settings_storage.dart';
import 'package:nexus_app/ui/root.dart';
import 'package:nexus_app/ui/theme.dart';
import 'package:nexus_app/ui/toast.dart';

void main() {
  test('시스템이면 OS 밝기를, 아니면 고른 밝기를 따른다', () {
    expect(
      resolveBrightness(ThemePreference.system, Brightness.light),
      Brightness.light,
    );
    expect(
      resolveBrightness(ThemePreference.system, Brightness.dark),
      Brightness.dark,
    );
    expect(
      resolveBrightness(ThemePreference.light, Brightness.dark),
      Brightness.light,
    );
    expect(
      resolveBrightness(ThemePreference.dark, Brightness.light),
      Brightness.dark,
    );
  });

  testWidgets('NxRoot 아래에서 자체 테마와 토스트를 쓴다', (tester) async {
    late Brightness seen;
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(platformBrightness: Brightness.light),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: NxRoot(
            preference: ThemePreference.system,
            child: Builder(
              builder: (context) {
                seen = NxTheme.of(context).brightness;
                return GestureDetector(
                  onTap: () => NxToast.show(context, '저장했습니다'),
                  child: const Text('누르기'),
                );
              },
            ),
          ),
        ),
      ),
    );
    expect(seen, Brightness.light);
    await tester.tap(find.text('누르기'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('저장했습니다'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });

  testWidgets('★ 라이트면 시스템 바 아이콘이 어둡다 - AppBar 가 대신 해 주던 일', (tester) async {
    Future<SystemUiOverlayStyle> styleFor(ThemePreference p) async {
      await tester.pumpWidget(Directionality(
        textDirection: TextDirection.ltr,
        child: NxRoot(preference: p, child: const SizedBox()),
      ));
      return tester.widget<AnnotatedRegion<SystemUiOverlayStyle>>(
        find.byType(AnnotatedRegion<SystemUiOverlayStyle>),
      ).value;
    }

    expect((await styleFor(ThemePreference.light)).statusBarIconBrightness, Brightness.dark);
    expect((await styleFor(ThemePreference.dark)).statusBarIconBrightness, Brightness.light);
  });
}

