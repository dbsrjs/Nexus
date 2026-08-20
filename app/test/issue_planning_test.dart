import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_app/domain/models/issue.dart';
import 'package:nexus_app/domain/models/sprint.dart';
import 'package:nexus_app/features/issue/issue_planning_row.dart';
import 'package:nexus_app/features/issue/sprint_controller.dart';

/// 이슈 상세의 계획 줄(스프린트 · 스토리 포인트).
///
/// **이 프로젝트의 첫 위젯 테스트다.** 지금까지 화면 계층은 실기기 확인에만
/// 기댔는데, 9-3 에서 "서버 API 는 다 만들고 화면만 빠뜨린" 일이 실제로
/// 일어났다 — 그런 구멍은 사람이 눈으로 볼 때만 드러났다.
void main() {
  Issue issue({String? sprintId, int? storyPoints}) => Issue(
    id: 'i1',
    key: 'NEXUS-1',
    title: '이슈',
    status: IssueStatus.backlog,
    priority: IssuePriority.mid,
    position: '0',
    sprintId: sprintId,
    storyPoints: storyPoints,
    createdAt: DateTime.utc(2026, 8, 20),
    updatedAt: DateTime.utc(2026, 8, 20),
  );

  const sprints = [
    Sprint(id: 'sp-active', name: '1주차', state: SprintState.active),
    Sprint(id: 'sp-planned', name: '2주차', state: SprintState.planned),
    Sprint(id: 'sp-closed', name: '0주차', state: SprintState.closed),
  ];

  Future<void> pump(WidgetTester tester, Issue value) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sprintListProvider.overrideWith((ref) => Stream.value(sprints)),
        ],
        child: MaterialApp(
          home: Scaffold(body: IssuePlanningRow(issue: value)),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('스프린트가 없으면 백로그로 보인다', (tester) async {
    await pump(tester, issue());

    expect(find.text('백로그'), findsOneWidget);
  });

  testWidgets('스프린트에 들어 있으면 그 이름이 보인다', (tester) async {
    await pump(tester, issue(sprintId: 'sp-active'));

    expect(find.text('1주차'), findsOneWidget);
    expect(find.text('백로그'), findsNothing);
  });

  testWidgets('포인트가 없으면 그렇다고 말한다', (tester) async {
    await pump(tester, issue());

    expect(find.text('포인트 없음'), findsOneWidget);
  });

  testWidgets('포인트가 있으면 p 를 붙여 보인다', (tester) async {
    await pump(tester, issue(storyPoints: 5));

    expect(find.text('5p'), findsOneWidget);
  });

  testWidgets('★ 닫힌 스프린트는 고를 수 없다', (tester) async {
    // 이미 끝난 기간에 새 일을 넣으면 그 스프린트의 번다운이 뒤늦게 바뀐다.
    // 지난 기록이 흔들리면 안 된다.
    await pump(tester, issue());

    await tester.tap(find.byIcon(Icons.flag_outlined));
    await tester.pumpAndSettle();

    expect(find.text('1주차 · 진행 중'), findsOneWidget);
    expect(find.text('2주차 · 계획'), findsOneWidget);
    expect(find.textContaining('0주차'), findsNothing);
  });

  testWidgets('백로그로 되돌리는 길이 메뉴에 있다', (tester) async {
    await pump(tester, issue(sprintId: 'sp-active'));

    await tester.tap(find.byIcon(Icons.flag_outlined));
    await tester.pumpAndSettle();

    expect(find.text('백로그 (스프린트 없음)'), findsOneWidget);
  });

  testWidgets('포인트 메뉴는 피보나치와 지우기를 준다', (tester) async {
    // 7과 8을 나누는 것은 정확이 아니라 착각이다 — 눈금이 그것을 말한다.
    await pump(tester, issue());

    await tester.tap(find.byIcon(Icons.timeline_outlined));
    await tester.pumpAndSettle();

    for (final points in ['1', '2', '3', '5', '8', '13']) {
      expect(find.text(points), findsOneWidget);
    }
    // 안 매기는 것도 뜻이 있어 되돌릴 길을 둔다.
    expect(find.text('포인트 없음'), findsWidgets);
    expect(find.text('4'), findsNothing);
  });
}
