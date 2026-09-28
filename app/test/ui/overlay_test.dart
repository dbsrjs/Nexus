import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_app/ui/button.dart';
import 'package:nexus_app/ui/dialog.dart';
import 'package:nexus_app/ui/overlay.dart';
import 'package:nexus_app/ui/theme.dart';
import 'package:nexus_app/ui/toast.dart';

/// Material 없이 — 15-3 의 앱과 같은 짜임(WidgetsApp + NxTheme + NxToastHost).
Widget app(Widget home) => WidgetsApp(
      color: const Color(0xFF77AECF),
      pageRouteBuilder: <T>(RouteSettings settings, WidgetBuilder builder) =>
          PageRouteBuilder<T>(settings: settings, pageBuilder: (c, _, _) => builder(c)),
      builder: (context, child) => NxTheme(
        data: NxThemeData.of(Brightness.dark),
        child: NxToastHost(child: child!),
      ),
      home: Center(child: home),
    );

void main() {
  group('NxMenu', () {
    Widget menu(List<String> picked) => NxMenu(
          entries: [
            const NxMenuHeader('이윤경', subtitle: 'yun@nexus.dev'),
            const NxMenuDivider(),
            NxMenuItem('설정', onSelected: () => picked.add('설정'), shortcut: 'Ctrl ,'),
            NxMenuItem('로그아웃', danger: true, onSelected: () => picked.add('로그아웃')),
          ],
          anchorBuilder: (context, toggle) => NxButton(label: '계정', onPressed: toggle),
        );

    testWidgets('누르면 열리고 항목을 고르면 닫힌다', (tester) async {
      final picked = <String>[];
      await tester.pumpWidget(app(menu(picked)));
      await tester.tap(find.text('계정'));
      await tester.pumpAndSettle();
      expect(find.text('yun@nexus.dev'), findsOneWidget);
      await tester.tap(find.text('설정'));
      await tester.pumpAndSettle();
      expect(picked, ['설정']);
      expect(find.text('yun@nexus.dev'), findsNothing);
    });

    testWidgets('★ Esc 로 닫힌다', (tester) async {
      await tester.pumpWidget(app(menu([])));
      await tester.tap(find.text('계정'));
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.text('설정'), findsNothing);
    });

    testWidgets('★ 열리면 첫 항목에 포커스, 방향키 · Enter 로 고른다', (tester) async {
      final picked = <String>[];
      await tester.pumpWidget(app(menu(picked)));
      await tester.tap(find.text('계정'));
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(picked, ['로그아웃']);
    });

    testWidgets('바깥을 누르면 닫힌다', (tester) async {
      await tester.pumpWidget(app(menu([])));
      await tester.tap(find.text('계정'));
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();
      expect(find.text('설정'), findsNothing);
    });
  });

  group('NxDialog.confirm', () {
    Future<bool?> open(WidgetTester tester) async {
      bool? result;
      await tester.pumpWidget(app(Builder(
        builder: (context) => NxButton(
          label: '삭제',
          onPressed: () async => result = await NxDialog.confirm(
            context,
            title: '메시지를 삭제할까요?',
            body: '본문은 가려지고 스레드와 첨부는 남습니다.',
            confirmLabel: '삭제',
            danger: true,
          ),
        ),
      )));
      await tester.tap(find.text('삭제'));
      await tester.pumpAndSettle();
      expect(find.text('메시지를 삭제할까요?'), findsOneWidget);
      return result;
    }

    testWidgets('확인은 true', (tester) async {
      bool? result;
      await tester.pumpWidget(app(Builder(
        builder: (context) => NxButton(
          label: '열기',
          onPressed: () async => result = await NxDialog.confirm(context, title: '제목', confirmLabel: '예'),
        ),
      )));
      await tester.tap(find.text('열기'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('예'));
      await tester.pumpAndSettle();
      expect(result, isTrue);
    });

    testWidgets('★ Esc 는 false - 확인하지 않은 것이다', (tester) async {
      await open(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.text('메시지를 삭제할까요?'), findsNothing);
    });

    testWidgets('취소는 false', (tester) async {
      await open(tester);
      await tester.tap(find.text('취소'));
      await tester.pumpAndSettle();
      expect(find.text('메시지를 삭제할까요?'), findsNothing);
    });
  });

  group('NxToast', () {
    testWidgets('★ 둘이면 차례로 — 앞의 것이 사라진 뒤 다음이 뜬다', (tester) async {
      await tester.pumpWidget(app(Builder(
        builder: (context) => NxButton(
          label: '알리기',
          onPressed: () {
            NxToast.show(context, '첫째');
            NxToast.show(context, '둘째', kind: NxToastKind.error);
          },
        ),
      )));
      await tester.tap(find.text('알리기'));
      await tester.pump();
      expect(find.text('첫째'), findsOneWidget);
      expect(find.text('둘째'), findsNothing);
      await tester.pump(NxToastHostState.shown);
      expect(find.text('첫째'), findsNothing);
      expect(find.text('둘째'), findsOneWidget);
      await tester.pump(NxToastHostState.shown);
      expect(find.text('둘째'), findsNothing);
    });

    testWidgets('동작을 누르면 부르고 바로 닫힌다', (tester) async {
      var undone = 0;
      await tester.pumpWidget(app(Builder(
        builder: (context) => NxButton(
          label: '고정',
          onPressed: () => NxToast.show(context, '고정했습니다', actionLabel: '되돌리기', onAction: () => undone++),
        ),
      )));
      await tester.tap(find.text('고정'));
      await tester.pump();
      await tester.tap(find.text('되돌리기'));
      await tester.pump();
      expect(undone, 1);
      expect(find.text('고정했습니다'), findsNothing);
    });
  });

  testWidgets('NxTooltip 은 호버 뒤 잠시 있다 뜬다', (tester) async {
    await tester.pumpWidget(app(const NxTooltip(message: '고정된 메시지', child: SizedBox(width: 32, height: 32))));
    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: Offset.zero);
    await gesture.moveTo(tester.getCenter(find.byType(NxTooltip)));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('고정된 메시지'), findsNothing);
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('고정된 메시지'), findsOneWidget);
    await gesture.removePointer();
  });

  testWidgets('★ 동작 카드는 누른 것 곁에 뜨고 바깥을 누르면 닫힌다', (tester) async {
    final picked = <String>[];
    await tester.pumpWidget(app(Builder(
      builder: (context) => NxButton(
        label: '길게',
        onPressed: () => NxActionCard.show(
          context,
          anchor: const Rect.fromLTWH(20, 100, 300, 40),
          entries: [NxMenuItem('스레드로 답글', onSelected: () => picked.add('스레드'))],
        ),
      ),
    )));
    await tester.tap(find.text('길게'));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.text('스레드로 답글')).dy, greaterThan(140));
    await tester.tap(find.text('스레드로 답글'));
    await tester.pumpAndSettle();
    expect(picked, ['스레드']);
    expect(find.text('스레드로 답글'), findsNothing);
  });

  group('NxDialog.panel', () {
    testWidgets('제목과 본문을 띄우고, 본문이 pop 한 값을 돌려준다', (tester) async {
      String? result = 'none';
      await tester.pumpWidget(app(Builder(
        builder: (context) => NxButton(
          label: '열기',
          onPressed: () async => result = await NxDialog.panel<String>(
            context,
            title: '저장소 추가',
            builder: (context) => NxButton(
              label: '고르기',
              onPressed: () => Navigator.of(context).pop('repo-1'),
            ),
          ),
        ),
      )));
      await tester.tap(find.text('열기'));
      await tester.pumpAndSettle();
      expect(find.text('저장소 추가'), findsOneWidget);
      await tester.tap(find.text('고르기'));
      await tester.pumpAndSettle();
      expect(result, 'repo-1');
    });

    testWidgets('Esc 로 닫으면 null', (tester) async {
      String? result = 'none';
      await tester.pumpWidget(app(Builder(
        builder: (context) => NxButton(
          label: '열기',
          onPressed: () async => result = await NxDialog.panel<String>(
            context,
            title: '패널',
            builder: (_) => const Text('본문'),
          ),
        ),
      )));
      await tester.tap(find.text('열기'));
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.text('본문'), findsNothing);
      expect(result, isNull);
    });
  });

  testWidgets('★ 동작 카드는 안쪽 내비게이터 속에서 열어도 화면 전체를 덮는다 - 셸 안에서 탭 줄이 안 덮였다', (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(app(SizedBox(
      width: 400,
      height: 800,
      child: Column(children: [
        // 셸 본문처럼 안쪽 내비게이터 — 아래 50px 는 탭 줄 자리.
        Expanded(
          child: Navigator(
            onGenerateRoute: (_) => PageRouteBuilder<void>(
              pageBuilder: (context, _, _) => Center(
                child: NxButton(
                  label: '길게',
                  onPressed: () => NxActionCard.show(
                    context,
                    anchor: const Rect.fromLTWH(20, 600, 300, 40),
                    above: (_) => const Text('리액션 줄'),
                    entries: [NxMenuItem('답장', onSelected: () {})],
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 50, child: Text('탭 줄')),
      ]),
    )));
    await tester.tap(find.text('길게'));
    await tester.pumpAndSettle();
    final scrim = tester.getSize(find.ancestor(of: find.byType(ColoredBox).last, matching: find.byType(GestureDetector)).last);
    expect(scrim.height, 800, reason: '막이 탭 줄까지 덮어야 한다');
    expect(tester.getTopLeft(find.text('리액션 줄')).dy, greaterThanOrEqualTo(0));
  });
}

