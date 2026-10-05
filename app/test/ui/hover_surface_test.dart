import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_app/ui/pressable.dart';
import 'package:nexus_app/ui/theme.dart';

Widget _host(Widget child) => Directionality(
  textDirection: TextDirection.ltr,
  child: NxTheme(
    data: NxThemeData.of(Brightness.dark),
    child: Center(child: child),
  ),
);

Color? _bg(WidgetTester tester) {
  final box = tester.widget<AnimatedContainer>(find.byType(AnimatedContainer));
  return (box.decoration as BoxDecoration?)?.color;
}

void main() {
  final c = NxColors.dark;

  testWidgets('쉴 때는 base(없으면 투명), 호버면 bgElevated', (tester) async {
    await tester.pumpWidget(
      _host(NxHoverSurface(onPressed: () {}, child: const Text('줄'))),
    );
    expect(_bg(tester), NxColors.transparent);

    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    await mouse.moveTo(tester.getCenter(find.text('줄')));
    await tester.pumpAndSettle();
    expect(_bg(tester), c.bgElevated);
  });

  testWidgets('★ 누르는 동안에도 bgElevated — 호버가 없는 터치 기기에서 반응이 보여야 한다', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        NxHoverSurface(
          onPressed: () {},
          base: c.bgSurface,
          child: const Text('카드'),
        ),
      ),
    );
    expect(_bg(tester), c.bgSurface);
    final touch = await tester.startGesture(tester.getCenter(find.text('카드')));
    await tester.pump();
    expect(_bg(tester), c.bgElevated);
    await touch.up();
  });

  testWidgets('누르면 부르고, 상태에 따른 테두리를 그린다', (tester) async {
    var pressed = 0;
    await tester.pumpWidget(
      _host(
        NxHoverSurface(
          onPressed: () => pressed++,
          border: (s) => Border.all(color: s.pressed ? c.accent : c.divider),
          child: const Text('칸'),
        ),
      ),
    );
    final box = tester.widget<AnimatedContainer>(
      find.byType(AnimatedContainer),
    );
    expect(
      ((box.decoration as BoxDecoration).border as Border).top.color,
      c.divider,
    );
    await tester.tap(find.text('칸'));
    expect(pressed, 1);
  });
}
