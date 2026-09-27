import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_app/ui/field.dart';
import 'package:nexus_app/ui/theme.dart';

Widget host(Widget child) => MediaQuery(
  data: const MediaQueryData(),
  child: Directionality(
    textDirection: TextDirection.ltr,
    child: NxTheme(
      data: NxThemeData.of(Brightness.dark),
      child: Overlay(
        initialEntries: [
          OverlayEntry(
            builder: (_) => Center(child: SizedBox(width: 320, child: child)),
          ),
        ],
      ),
    ),
  ),
);

void main() {
  testWidgets('입력하면 onChanged · 컨트롤러에 들어간다', (tester) async {
    final controller = TextEditingController();
    final changes = <String>[];
    await tester.pumpWidget(
      host(NxField(controller: controller, onChanged: changes.add)),
    );
    await tester.enterText(find.byType(EditableText), '안녕');
    expect(controller.text, '안녕');
    expect(changes.last, '안녕');
  });

  testWidgets('Enter 로 onSubmitted', (tester) async {
    String? submitted;
    await tester.pumpWidget(host(NxField(onSubmitted: (v) => submitted = v)));
    await tester.enterText(find.byType(EditableText), '저장');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    expect(submitted, '저장');
  });

  testWidgets('★ 라벨을 누르면 입력칸에 포커스가 간다', (tester) async {
    final focus = FocusNode();
    await tester.pumpWidget(host(NxField(label: '표시 이름', focusNode: focus)));
    await tester.tap(find.text('표시 이름'));
    await tester.pump();
    expect(focus.hasFocus, isTrue);
  });

  testWidgets('비어 있으면 힌트, 입력하면 힌트가 사라진다', (tester) async {
    await tester.pumpWidget(host(const NxField(hint: '메시지 보내기')));
    expect(find.text('메시지 보내기'), findsOneWidget);
    await tester.enterText(find.byType(EditableText), 'a');
    await tester.pump();
    expect(find.text('메시지 보내기'), findsNothing);
  });

  testWidgets('★ 오류가 있으면 문구를 보이고 도움말을 대신한다', (tester) async {
    await tester.pumpWidget(
      host(const NxField(helper: '10자 이상', error: '너무 짧습니다')),
    );
    expect(find.text('너무 짧습니다'), findsOneWidget);
    expect(find.text('10자 이상'), findsNothing);
  });

  testWidgets('★ maxLength 를 넘게 들어가지 않고 글자 수를 보인다', (tester) async {
    final controller = TextEditingController();
    await tester.pumpWidget(
      host(NxField(controller: controller, maxLength: 5)),
    );
    await tester.enterText(find.byType(EditableText), '123456789');
    await tester.pump();
    expect(controller.text, '12345');
    expect(find.text('5/5'), findsOneWidget);
  });

  testWidgets('비밀번호는 가려 그린다', (tester) async {
    await tester.pumpWidget(host(const NxField(obscure: true)));
    expect(
      tester.widget<EditableText>(find.byType(EditableText)).obscureText,
      isTrue,
    );
  });

  testWidgets('★ 비활성이면 입력할 수 없다', (tester) async {
    final controller = TextEditingController();
    await tester.pumpWidget(
      host(NxField(controller: controller, enabled: false)),
    );
    final editable = tester.widget<EditableText>(find.byType(EditableText));
    expect(editable.readOnly, isTrue);
    expect(editable.focusNode.canRequestFocus, isFalse);
  });

  testWidgets('여러 줄이면 줄바꿈이 들어간다', (tester) async {
    final controller = TextEditingController();
    await tester.pumpWidget(host(NxField(controller: controller, maxLines: 5)));
    await tester.enterText(find.byType(EditableText), '첫 줄\n둘째 줄');
    expect(controller.text, '첫 줄\n둘째 줄');
    expect(
      tester.widget<EditableText>(find.byType(EditableText)).keyboardType,
      TextInputType.multiline,
    );
  });

  testWidgets('★ 보조 기술에 입력칸과 라벨이 실린다', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(host(const NxField(label: '이메일')));
    expect(
      tester.getSemantics(find.byType(EditableText)),
      matchesSemantics(
        label: '이메일',
        isTextField: true,
        hasEnabledState: true,
        isEnabled: true,
        hasTapAction: true,
        isFocusable: true,
      ),
    );
    handle.dispose();
  });

  testWidgets('★ 우클릭 메뉴는 자체 메뉴다 - 한국어 항목', (tester) async {
    final controller = TextEditingController(text: '복사할 글');
    await tester.pumpWidget(host(NxField(controller: controller)));
    // 사람처럼 길게 눌러 연다 — 단어가 선택되고 메뉴가 뜬다.
    await tester.longPress(find.byType(EditableText));
    await tester.pumpAndSettle();
    // 빈 커서에서는 전체 선택만 뜬다(클립보드가 비었다).
    expect(find.text('전체 선택'), findsOneWidget);
    await tester.tap(find.text('전체 선택'));
    await tester.pumpAndSettle();
    expect(
      controller.selection,
      const TextSelection(baseOffset: 0, extentOffset: 5),
    );
    // 선택이 생기면 같은 자체 메뉴에 복사 · 잘라내기가 붙는다.
    expect(find.text('복사'), findsOneWidget);
    expect(find.text('잘라내기'), findsOneWidget);
  });

  testWidgets('★ 한글 조합(IME) — 조합 중인 글자가 확정되기 전까지 밑줄 구간으로 남고, 확정되면 그대로 들어간다', (
    tester,
  ) async {
    final controller = TextEditingController();
    final changes = <String>[];
    await tester.pumpWidget(
      host(NxField(controller: controller, onChanged: changes.add)),
    );
    await tester.tap(find.byType(EditableText));
    await tester.pump();

    // Windows 한글 IME 가 「안녕」을 조합하며 보내는 순서 그대로.
    const steps = ['ㅇ', '아', '안', '안ㄴ', '안녀', '안녕'];
    for (final text in steps) {
      tester.testTextInput.updateEditingValue(
        TextEditingValue(
          text: text,
          selection: TextSelection.collapsed(offset: text.length),
          // 앞 글자는 확정, 마지막 글자만 조합 중.
          composing: TextRange(start: text.length - 1, end: text.length),
        ),
      );
      await tester.pump();
      expect(controller.value.composing.isValid, isTrue, reason: text);
    }
    // 조합 확정(스페이스 · 다른 키).
    tester.testTextInput.updateEditingValue(
      const TextEditingValue(
        text: '안녕',
        selection: TextSelection.collapsed(offset: 2),
      ),
    );
    await tester.pump();
    expect(controller.text, '안녕');
    expect(controller.value.composing.isValid, isFalse);
    expect(changes.last, '안녕');
  });

  testWidgets('★ 글자 수 상한은 조합 중인 글자를 자르지 않는다', (tester) async {
    final controller = TextEditingController();
    await tester.pumpWidget(
      host(NxField(controller: controller, maxLength: 2)),
    );
    await tester.tap(find.byType(EditableText));
    await tester.pump();
    tester.testTextInput.updateEditingValue(
      const TextEditingValue(
        text: '안녀',
        selection: TextSelection.collapsed(offset: 2),
        composing: TextRange(start: 1, end: 2),
      ),
    );
    await tester.pump();
    tester.testTextInput.updateEditingValue(
      const TextEditingValue(
        text: '안녕',
        selection: TextSelection.collapsed(offset: 2),
      ),
    );
    await tester.pump();
    expect(controller.text, '안녕');
  });
}
