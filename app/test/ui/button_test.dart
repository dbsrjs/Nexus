import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_app/ui/button.dart';
import 'package:nexus_app/ui/icons.dart';
import 'package:nexus_app/ui/loading.dart';
import 'package:nexus_app/ui/theme.dart';

Widget host(Widget child, {Brightness brightness = Brightness.dark}) => Directionality(
      textDirection: TextDirection.ltr,
      child: NxTheme(
        data: NxThemeData.of(brightness),
        child: Center(child: child),
      ),
    );

void main() {
  testWidgets('누르면 부른다', (tester) async {
    var pressed = 0;
    await tester.pumpWidget(host(NxButton(label: '저장', onPressed: () => pressed++)));
    await tester.tap(find.text('저장'));
    expect(pressed, 1);
  });

  testWidgets('★ Enter · Space 로도 누른다 - 키보드만으로 쓸 수 있어야 한다', (tester) async {
    var pressed = 0;
    await tester.pumpWidget(host(NxButton(label: '저장', onPressed: () => pressed++, autofocus: true)));
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    expect(pressed, 2);
  });

  testWidgets('비활성이면 부르지 않는다', (tester) async {
    await tester.pumpWidget(host(const NxButton(label: '저장', onPressed: null)));
    await tester.tap(find.text('저장'));
    expect(tester.takeException(), isNull);
  });

  testWidgets('★ loading 이면 부르지 않고 스피너를 보인다', (tester) async {
    var pressed = 0;
    await tester.pumpWidget(host(NxButton(label: '저장', loading: true, onPressed: () => pressed++)));
    await tester.tap(find.text('저장'));
    expect(pressed, 0);
    expect(find.byType(NxSpinner), findsOneWidget);
  });

  testWidgets('★ 보조 기술에 버튼 · 활성 · 이름이 실린다', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(host(NxButton(label: '저장', onPressed: () {})));
    expect(
      tester.getSemantics(find.text('저장')),
      matchesSemantics(
        label: '저장',
        isButton: true,
        isEnabled: true,
        hasEnabledState: true,
        hasTapAction: true,
        isFocusable: true,
        hasFocusAction: true,
      ),
    );
    handle.dispose();
  });

  testWidgets('★ 아이콘 버튼은 라벨을 보조 기술에 싣는다 - 글자가 없으니 이름이 곧 뜻이다', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(host(NxIconButton(icon: NxIcons.pin, label: '고정', onPressed: () {})));
    expect(find.bySemanticsLabel('고정'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('★ 키보드로 포커스하면 링이 보이고, 마우스로 누를 때는 안 보인다', (tester) async {
    await tester.pumpWidget(host(NxButton(label: '저장', onPressed: () {}, autofocus: true)));
    FocusManager.instance.highlightStrategy = FocusHighlightStrategy.alwaysTraditional;
    await tester.pump();
    expect(find.byKey(const ValueKey('nx-focus-ring')), findsOneWidget);
    FocusManager.instance.highlightStrategy = FocusHighlightStrategy.alwaysTouch;
    await tester.pump();
    expect(find.byKey(const ValueKey('nx-focus-ring')), findsNothing);
    FocusManager.instance.highlightStrategy = FocusHighlightStrategy.automatic;
  });

  testWidgets('호버하면 배경이 한 단 바뀐다 - 물결이 아니다', (tester) async {
    await tester.pumpWidget(host(NxButton(label: '취소', kind: NxButtonKind.secondary, onPressed: () {})));
    Color? bg() => (tester.widget<AnimatedContainer>(find.byType(AnimatedContainer)).decoration
            as BoxDecoration?)
        ?.color;
    final before = bg();
    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: Offset.zero);
    await gesture.moveTo(tester.getCenter(find.text('취소')));
    await tester.pump();
    expect(bg(), isNot(before));
    await gesture.removePointer();
  });

  testWidgets('크기마다 높이가 정해져 있다 - lg 는 모바일 터치 44', (tester) async {
    for (final (size, h) in [(NxSize.sm, 28.0), (NxSize.md, 36.0), (NxSize.lg, 44.0)]) {
      await tester.pumpWidget(host(NxButton(label: 'x', size: size, onPressed: () {})));
      await tester.pumpAndSettle();
      expect(tester.getSize(find.byType(AnimatedContainer)).height, h);
    }
  });

  testWidgets('라이트 테마에서도 그려진다', (tester) async {
    await tester.pumpWidget(host(
      Column(mainAxisSize: MainAxisSize.min, children: [
        for (final k in NxButtonKind.values) NxButton(label: k.name, kind: k, onPressed: () {}),
      ]),
      brightness: Brightness.light,
    ));
    expect(tester.takeException(), isNull);
  });
}
