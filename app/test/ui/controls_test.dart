import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_app/ui/controls.dart';

import 'overlay_test.dart' show app;

void main() {
  testWidgets('스위치는 누르면 반대 값을 알린다', (tester) async {
    bool? next;
    await tester.pumpWidget(app(NxSwitch(value: false, label: '음소거', onChanged: (v) => next = v)));
    await tester.tap(find.byType(NxSwitch));
    expect(next, isTrue);
  });

  testWidgets('★ 스위치는 보조 기술에 켜짐 상태를 싣는다', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(app(NxSwitch(value: true, label: '음소거', onChanged: (_) {})));
    expect(
      tester.getSemantics(find.byType(NxSwitch)),
      matchesSemantics(
        label: '음소거',
        hasToggledState: true,
        isToggled: true,
        hasEnabledState: true,
        isEnabled: true,
        hasTapAction: true,
        isFocusable: true,
        hasFocusAction: true,
        isButton: true,
      ),
    );
    handle.dispose();
  });

  testWidgets('비활성 스위치는 부르지 않는다', (tester) async {
    await tester.pumpWidget(app(const NxSwitch(value: false, label: '음소거', onChanged: null)));
    await tester.tap(find.byType(NxSwitch));
    expect(tester.takeException(), isNull);
  });

  testWidgets('체크는 글자를 눌러도 바뀐다', (tester) async {
    bool? next;
    await tester.pumpWidget(app(NxCheck(value: false, label: '메시지 3개 선택', onChanged: (v) => next = v)));
    await tester.tap(find.text('메시지 3개 선택'));
    expect(next, isTrue);
  });

  group('NxSegmented', () {
    Widget seg(ValueChanged<String> onChanged, {String value = 'dark'}) => NxSegmented<String>(
          label: '테마',
          value: value,
          segments: const [('system', '시스템'), ('light', '라이트'), ('dark', '다크')],
          onChanged: onChanged,
        );

    testWidgets('누르면 그 값', (tester) async {
      String? picked;
      await tester.pumpWidget(app(seg((v) => picked = v)));
      await tester.tap(find.text('라이트'));
      expect(picked, 'light');
    });

    testWidgets('★ 방향키로 옮긴다 - 키보드만으로 고를 수 있어야 한다', (tester) async {
      String? picked;
      await tester.pumpWidget(app(seg((v) => picked = v, value: 'light')));
      // 키보드 사용자처럼 Tab 으로 들어간다(마우스로 누르면 포커스가 오지 않는다).
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      expect(picked, 'dark');
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      expect(picked, 'system');
    });

    testWidgets('보조 기술에 고른 것이 실린다', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(app(seg((_) {})));
      expect(
        tester.getSemantics(find.text('다크')),
        isSemantics(isChecked: true, isInMutuallyExclusiveGroup: true),
      );
      expect(
        tester.getSemantics(find.text('라이트')),
        isSemantics(isChecked: false, isInMutuallyExclusiveGroup: true),
      );
      handle.dispose();
    });
  });

  testWidgets('★ 셀렉트는 메뉴로 고른다 - DropdownButton 이 아니다', (tester) async {
    String? picked;
    await tester.pumpWidget(app(NxSelect<String>(
      value: 's1',
      options: const [('s1', 'Nexus'), ('s2', '사이드 프로젝트')],
      onChanged: (v) => picked = v,
    )));
    expect(find.text('Nexus'), findsOneWidget);
    await tester.tap(find.text('Nexus'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('사이드 프로젝트'));
    await tester.pumpAndSettle();
    expect(picked, 's2');
  });
}
