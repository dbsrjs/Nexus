import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_app/ui/chips.dart';
import 'package:nexus_app/ui/layout.dart';
import 'package:nexus_app/ui/loading.dart';

import 'overlay_test.dart' show app;

void main() {
  testWidgets('뱃지는 99 를 넘으면 99+ 로 접는다', (tester) async {
    await tester.pumpWidget(app(const Row(mainAxisSize: MainAxisSize.min, children: [
      NxBadge(count: 7),
      NxBadge(count: 120),
      NxBadge(count: 1, mention: true),
      NxBadge(count: 3, mention: true),
    ])));
    expect(find.text('7'), findsOneWidget);
    expect(find.text('99+'), findsOneWidget);
    // 멘션은 개수보다 「불렸다」가 먼저 — 한 건이면 @ 만.
    expect(find.text('@'), findsOneWidget);
    expect(find.text('@3'), findsOneWidget);
  });

  testWidgets('칩은 누르면 부르고 고른 상태를 보조 기술에 싣는다', (tester) async {
    final handle = tester.ensureSemantics();
    var pressed = 0;
    await tester.pumpWidget(app(NxChip(label: '채널 최근 대화', selected: true, onPressed: () => pressed++)));
    await tester.tap(find.text('채널 최근 대화'));
    expect(pressed, 1);
    expect(tester.getSemantics(find.byType(NxChip)), isSemantics(isSelected: true, isButton: true));
    handle.dispose();
  });

  testWidgets('뼈대는 줄 수만큼 그린다', (tester) async {
    await tester.pumpWidget(app(const SizedBox(width: 300, child: NxSkeleton(lines: 4))));
    expect(find.byWidgetPredicate((w) => w.key is ValueKey<String> && (w.key! as ValueKey<String>).value.startsWith('nx-skeleton-line')), findsNWidgets(4));
  });

  testWidgets('★ NxPage 는 키보드만큼 본문을 올린다 - 입력창이 가려지지 않게', (tester) async {
    await tester.pumpWidget(MediaQuery(
      data: const MediaQueryData(size: Size(400, 800), viewInsets: EdgeInsets.only(bottom: 300)),
      child: app(const NxPage(
        header: NxHeader(title: '스레드'),
        body: SizedBox.expand(key: ValueKey('body')),
      )),
    ));
    final bottom = tester.getBottomLeft(find.byKey(const ValueKey('body'))).dy;
    expect(bottom, lessThanOrEqualTo(800 - 300));
  });

  testWidgets('탭은 고르면 부르고 고른 탭에 막대가 있다', (tester) async {
    int? picked;
    await tester.pumpWidget(app(NxTabBar(
      tabs: const [NxTab('대화'), NxTab('이슈', count: 3), NxTab('저장소')],
      index: 0,
      onChanged: (i) => picked = i,
    )));
    await tester.tap(find.text('저장소'));
    expect(picked, 2);
    expect(find.byKey(const ValueKey('nx-tab-indicator')), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
  });

  testWidgets('★ 스크롤 끝에서 안드로이드 글로 · 늘어남을 그리지 않는다', (tester) async {
    await tester.pumpWidget(app(ScrollConfiguration(
      behavior: const NxScrollBehavior(),
      child: ListView(children: [for (var i = 0; i < 50; i++) Text('줄 $i')]),
    )));
    expect(find.byType(GlowingOverscrollIndicator), findsNothing);
    expect(find.byType(StretchingOverscrollIndicator), findsNothing);
  });

  testWidgets('목록 행은 누르면 부르고 선택이면 배경이 다르다', (tester) async {
    var pressed = 0;
    await tester.pumpWidget(app(Column(mainAxisSize: MainAxisSize.min, children: [
      NxRow(title: '개발', selected: true, onPressed: () => pressed++),
      const NxRow(title: '일반', subtitle: '아무 이야기나'),
    ])));
    await tester.tap(find.text('개발'));
    expect(pressed, 1);
    expect(find.text('아무 이야기나'), findsOneWidget);
  });
}
