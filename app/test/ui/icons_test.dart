import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_app/ui/icons.dart';

void main() {
  group('parseSvgPath', () {
    test('M 뒤의 좌표 쌍은 L 로 이어진다(암시적 반복)', () {
      final b = parseSvgPath('M8 13V3M3.5 7.5 8 3l4.5 4.5').getBounds();
      expect(b.left, closeTo(3.5, .01));
      expect(b.right, closeTo(12.5, .01));
      expect(b.top, closeTo(3, .01));
      expect(b.bottom, closeTo(13, .01));
    });

    test('붙은 소수점과 음수(-.4 · .5)를 가른다', () {
      final b = parseSvgPath('M6 2h4l-.5 4 2.5 2H4z').getBounds();
      expect(b.left, closeTo(4, .01));
      expect(b.bottom, closeTo(8, .01));
    });

    test('호(A)의 플래그를 읽는다 — 반원이 위로 볼록', () {
      final b = parseSvgPath('M5.5 7V5a2.5 2.5 0 0 1 5 0v2').getBounds();
      expect(b.top, closeTo(2.5, .05));
      expect(b.width, closeTo(5, .05));
    });

    test('S 는 앞 곡선의 조절점을 반사한다', () {
      expect(() => parseSvgPath('M5.5 9.5c.7.9 1.5 1.3 2.5 1.3s1.8-.4 2.5-1.3'), returnsNormally);
    });

    test('★ 모르는 명령은 던진다 - 조용히 틀린 그림을 그리지 않는다', () {
      expect(() => parseSvgPath('M0 0T4 4'), throwsFormatException);
      expect(() => parseSvgPath('4 4'), throwsFormatException);
    });
  });

  test('★ 모든 아이콘이 읽히고 16 격자 안에 있다', () {
    for (final icon in NxIcons.values) {
      for (final d in debugIconPaths(icon)) {
        expect(() => parseSvgPath(d), returnsNormally, reason: '$icon');
      }
      final b = debugIconBounds(icon);
      expect(b.left >= 0 && b.top >= 0 && b.right <= 16 && b.bottom <= 16, isTrue,
          reason: '$icon 가 격자를 벗어난다: $b');
      expect(b.isEmpty, isFalse, reason: '$icon 가 비었다');
    }
  });

  testWidgets('모든 아이콘이 예외 없이 그려진다', (tester) async {
    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: Wrap(children: [for (final i in NxIcons.values) NxIcon(i)]),
    ));
    expect(tester.takeException(), isNull);
  });

  testWidgets('크기 · 색은 IconTheme 을 따른다', (tester) async {
    await tester.pumpWidget(const Directionality(
      textDirection: TextDirection.ltr,
      child: IconTheme(
        data: IconThemeData(size: 24, color: Color(0xFF112233)),
        child: Center(child: NxIcon(NxIcons.pin)),
      ),
    ));
    expect(tester.getSize(find.byType(CustomPaint).last), const Size(24, 24));
  });

  testWidgets('라벨이 있으면 보조 기술에 드러나고, 없으면 숨는다', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(const Directionality(
      textDirection: TextDirection.ltr,
      child: Column(children: [
        NxIcon(NxIcons.warning, semanticLabel: '경고'),
        NxIcon(NxIcons.pin),
      ]),
    ));
    expect(find.bySemanticsLabel('경고'), findsOneWidget);
    handle.dispose();
  });
}
