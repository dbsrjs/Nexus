import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_app/features/auth/login_backdrop.dart';
import 'package:nexus_app/ui/theme.dart';

/// 로그인 배경(시안 A1 «연결망»)의 배치 — 2026-10-06 검토에서 찾은 두 결함의 회귀 방지.
void main() {
  Future<void> pump(
    WidgetTester tester,
    Size size, {
    double textScale = 1,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(
          size: size,
          textScaler: TextScaler.linear(textScale),
        ),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: NxTheme(
            data: NxThemeData.of(Brightness.dark),
            child: const LoginBackdrop(child: SizedBox.shrink()),
          ),
        ),
      ),
    );
  }

  /// 조각 카드(점선 출발점에 세로 가운데를 맞춘 상자)의 화면 위 사각형.
  Rect fragmentRect(WidgetTester tester, String text) => tester.getRect(
    find.ancestor(of: find.text(text), matching: find.byType(Container)).last,
  );

  testWidgets('★ 조각이 다 들어가지 않는 폭에서는 조각을 그리지 않는다', (tester) async {
    // 옛 기준(1100)에서는 이 폭에서 AI · 커밋 조각이 화면 밖으로 잘렸다.
    await pump(tester, const Size(1200, 900));
    expect(find.text('서윤'), findsNothing);
  });

  testWidgets('★ 그릴 때는 모든 조각이 화면 안에 있다', (tester) async {
    for (final size in const [Size(1328, 740), Size(1440, 900)]) {
      await pump(tester, size);
      final screen = Offset.zero & size;
      for (final t in [
        '서윤',
        'AI · 채널 요약',
        'NX-142',
        'nexus / main',
        'release-notes.pdf',
      ]) {
        final r = fragmentRect(tester, t);
        expect(
          screen.contains(r.topLeft) &&
              screen.contains(r.bottomRight - const Offset(1, 1)),
          isTrue,
          reason: '$t 조각 $r 이 $size 화면 밖으로 나간다',
        );
      }
    }
  });

  testWidgets('★ 글자 배율을 키워도 조각의 세로 가운데가 점선 출발점에 붙어 있다', (tester) async {
    for (final scale in const [1.0, 1.5]) {
      await pump(tester, const Size(1440, 900), textScale: scale);
      // 대화 조각의 출발점은 가운데에서 위로 268.
      final r = fragmentRect(tester, '서윤');
      expect(
        r.center.dy,
        moreOrLessEquals(450 - 268, epsilon: .5),
        reason: '배율 $scale',
      );
    }
  });
}
