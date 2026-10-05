import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_app/data/settings_storage.dart';
import 'package:nexus_app/ui/root.dart';
import 'package:nexus_app/ui/theme.dart';

/// WCAG 대비 — (밝은 쪽 + 0.05) / (어두운 쪽 + 0.05).
double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final hi = la > lb ? la : lb;
  final lo = la > lb ? lb : la;
  return (hi + .05) / (lo + .05);
}

void main() {
  group('대비 — 글자로 쓰는 색은 세 표면 모두에서 4.5 : 1(AA) 이상', () {
    for (final (name, c) in [('다크', NxColors.dark), ('라이트', NxColors.light)]) {
      final surfaces = {
        'bgBase': c.bgBase,
        'bgSurface': c.bgSurface,
        'bgElevated': c.bgElevated,
      };
      final inks = {
        'textPrimary': c.textPrimary,
        'textSecondary': c.textSecondary,
        'accent': c.accent,
        'success': c.success,
        'warning': c.warning,
        'danger': c.danger,
        'merged': c.merged,
      };
      // 2026-10-06 이전에는 의미색이 두 테마에 한 값이라 라이트에서 1.8~2.6 : 1 이었다.
      test('★ $name', () {
        final fails = <String>[];
        inks.forEach((ink, fg) {
          surfaces.forEach((surface, bg) {
            final r = _contrast(fg, bg);
            if (r < 4.5) fails.add('$ink / $surface = ${r.toStringAsFixed(2)}');
          });
        });
        expect(fails, isEmpty, reason: fails.join('\n'));
      });

      test('$name — danger 를 바탕으로 칠한 자리의 글자(onDanger)', () {
        expect(_contrast(c.onDanger, c.danger), greaterThanOrEqualTo(4.5));
      });
    }
  });

  group('애니메이션 줄이기', () {
    tearDown(() => NxMotion.reduced = false);

    Future<void> pumpRoot(WidgetTester tester, {required bool disable}) =>
        tester.pumpWidget(
          MediaQuery(
            data: MediaQueryData(disableAnimations: disable),
            child: const Directionality(
              textDirection: TextDirection.ltr,
              child: NxRoot(
                preference: ThemePreference.dark,
                child: SizedBox.shrink(),
              ),
            ),
          ),
        );

    testWidgets('★ OS 설정이 켜지면 전환 시간이 0 이 된다', (tester) async {
      await pumpRoot(tester, disable: true);
      expect(NxMotion.micro, Duration.zero);
      expect(NxMotion.panel, Duration.zero);
    });

    testWidgets('꺼져 있으면 토큰 값 그대로', (tester) async {
      await pumpRoot(tester, disable: false);
      expect(NxMotion.micro, const Duration(milliseconds: 120));
      expect(NxMotion.panel, const Duration(milliseconds: 180));
    });
  });
}
