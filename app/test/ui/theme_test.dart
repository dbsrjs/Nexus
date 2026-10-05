import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_app/ui/theme.dart';

/// 토큰은 `design-system/tokens.css` 와 1:1 이어야 한다(15단계 설계 D4).
void main() {
  test('★ 다크 값이 tokens.css 와 같다', () {
    const c = NxColors.dark;
    expect(c.bgBase, const Color(0xFF121314));
    expect(c.bgSurface, const Color(0xFF1C1D1F));
    expect(c.bgElevated, const Color(0xFF282A2C));
    expect(c.textPrimary, const Color(0xFFDDE6ED));
    expect(c.textSecondary, const Color(0xFF9DA0A4));
    expect(c.accent, const Color(0xFF77AECF));
    expect(c.accentPress, const Color(0xFF5197C2));
    expect(c.borderStrong, const Color(0xFF63676B));
    expect(c.danger, const Color(0xFFD47D7D));
  });

  test('★ 라이트 값이 tokens.css 와 같다', () {
    const c = NxColors.light;
    expect(c.bgBase, const Color(0xFFEFF0F1));
    expect(c.bgElevated, const Color(0xFFFFFFFF));
    expect(c.textPrimary, const Color(0xFF27374D));
    expect(c.accent, const Color(0xFF326C8F));
  });

  test('아바타 8색은 밝기와 무관하다', () {
    expect(NxColors.dark.avatars, NxColors.light.avatars);
    expect(NxColors.dark.avatars, hasLength(8));
  });

  testWidgets('NxTheme 는 기본 글자 색 · 크기를 깐다', (tester) async {
    late TextStyle seen;
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: NxTheme(
          data: NxThemeData.of(Brightness.light),
          child: Builder(builder: (context) {
            seen = DefaultTextStyle.of(context).style;
            return const SizedBox();
          }),
        ),
      ),
    );
    expect(seen.color, NxColors.light.textPrimary);
    expect(seen.fontSize, 14);
  });

  testWidgets('NxTheme.of 는 가장 가까운 테마를 준다', (tester) async {
    late NxThemeData seen;
    await tester.pumpWidget(
      NxTheme(
        data: NxThemeData.of(Brightness.dark),
        child: Builder(builder: (context) {
          seen = NxTheme.of(context);
          return const SizedBox();
        }),
      ),
    );
    expect(seen.brightness, Brightness.dark);
    expect(seen.colors, NxColors.dark);
  });

  test('★ 액센트 위 글자는 두 밝기 모두 4.5:1 이상 - 라이트에서 어두운 글자를 얹었었다', () {
    double ratio(Color a, Color b) {
      final l1 = a.computeLuminance(), l2 = b.computeLuminance();
      final hi = l1 > l2 ? l1 : l2, lo = l1 > l2 ? l2 : l1;
      return (hi + .05) / (lo + .05);
    }

    for (final c in [NxColors.dark, NxColors.light]) {
      expect(ratio(c.accent, c.onAccent), greaterThanOrEqualTo(4.5));
      // 멘션 뱃지(danger 바탕) — 라이트의 danger 는 어두워져 흰 글자(onDanger)를 얹는다.
      expect(ratio(c.danger, c.onDanger), greaterThanOrEqualTo(4.5));
    }
  });
}

