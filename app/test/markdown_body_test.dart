import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_app/shared/markdown/markdown_body.dart';

Future<void> pump(WidgetTester tester, String body) => tester.pumpWidget(
      MaterialApp(home: Scaffold(body: MarkdownBody(body: body))),
    );

void main() {
  testWidgets('굵은 글자를 그린다', (tester) async {
    await pump(tester, '**굵게**');
    await tester.pumpAndSettle();

    expect(find.textContaining('굵게'), findsOneWidget);
    // 별표는 화면에 남지 않는다.
    expect(find.textContaining('**'), findsNothing);
  });

  testWidgets('서식이 없으면 그대로 그린다', (tester) async {
    await pump(tester, '평범한 문장');
    await tester.pumpAndSettle();

    expect(find.text('평범한 문장'), findsOneWidget);
  });

  testWidgets('코드블록을 언어 라벨과 함께 그린다', (tester) async {
    await pump(tester, '```dart\nvar a = 1;\n```');
    await tester.pumpAndSettle();

    expect(find.textContaining('var a = 1;'), findsOneWidget);
    expect(find.text('dart'), findsOneWidget);
  });

  testWidgets('스포일러는 누르기 전에 가려져 있다', (tester) async {
    await pump(tester, '||비밀||');
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('spoiler-covered')), findsOneWidget);

    await tester.tap(find.byKey(const Key('spoiler-covered')));
    await tester.pumpAndSettle();

    // 드러난 뒤에는 되돌리지 않는다.
    expect(find.byKey(const Key('spoiler-covered')), findsNothing);
  });

  testWidgets('표를 그린다', (tester) async {
    await pump(tester, '| 이름 | 값 |\n|---|---|\n| a | 1 |');
    await tester.pumpAndSettle();

    expect(find.text('이름'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
  });

  testWidgets('인용과 목록을 그린다', (tester) async {
    await pump(tester, '> 인용문\n\n- 하나\n- 둘');
    await tester.pumpAndSettle();

    expect(find.textContaining('인용문'), findsOneWidget);
    expect(find.textContaining('하나'), findsOneWidget);
    expect(find.textContaining('둘'), findsOneWidget);
  });
}
