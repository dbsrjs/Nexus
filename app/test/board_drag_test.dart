import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_app/data/repositories/issue_repository.dart';
import 'package:nexus_app/domain/models/issue.dart';
import 'package:nexus_app/features/issue/board_controller.dart';
import 'package:nexus_app/features/issue/board_screen.dart';
import 'package:nexus_app/features/issue/sprint_controller.dart';

import 'support/nx_host.dart';

/// 보드 끌어 옮기기(15단계 D15). 서버 계약(`PUT .../position`)은 9-1 부터 있었고,
/// 화면이 이웃(앞 · 뒤)을 제대로 골라 보내는지가 이 테스트의 주제다.
void main() {
  Issue issue(String id, IssueStatus status, String position) => Issue(
    id: id,
    key: 'NEXUS-$id',
    title: '이슈 $id',
    status: status,
    priority: IssuePriority.mid,
    position: position,
    createdAt: DateTime.utc(2026, 9, 28),
    updatedAt: DateTime.utc(2026, 9, 28),
  );

  final a = issue('a', IssueStatus.backlog, '1');
  final b = issue('b', IssueStatus.backlog, '2');
  final c = issue('c', IssueStatus.backlog, '3');
  final d = issue('d', IssueStatus.doing, '1');

  group('dropNeighbours', () {
    test('같은 컬럼 안에서는 끄는 카드를 빼고 센다', () {
      // a 를 b 와 c 사이(빼고 센 목록 [b, c] 의 1번 앞)로.
      final at = dropNeighbours([a, b, c], 'a', 1);
      expect(at.after?.id, 'b');
      expect(at.before?.id, 'c');
    });

    test('맨 위 · 맨 아래는 한쪽 이웃이 없다', () {
      final top = dropNeighbours([a, b], 'c', 0);
      expect(top.after, isNull);
      expect(top.before?.id, 'a');
      final bottom = dropNeighbours([a, b], 'c', 2);
      expect(bottom.after?.id, 'b');
      expect(bottom.before, isNull);
    });

    test('빈 컬럼은 둘 다 없다 · 범위를 넘으면 끝에 붙인다', () {
      final empty = dropNeighbours(const [], 'a', 0);
      expect(empty.after, isNull);
      expect(empty.before, isNull);
      expect(dropNeighbours([d], 'a', 9).after?.id, 'd');
    });
  });

  group('localPositionBetween', () {
    test('두 이웃의 가운데, 한쪽이 없으면 하나 떨어진 자리', () {
      expect(double.parse(localPositionBetween('1', '2')), 1.5);
      expect(double.parse(localPositionBetween(null, '2')), 1);
      expect(double.parse(localPositionBetween('2', null)), 3);
      expect(double.parse(localPositionBetween(null, null)), 1);
    });
  });

  group('보드', () {
    late _FakeBoardActions actions;

    Future<void> pump(WidgetTester tester) async {
      actions = _FakeBoardActions();
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            scopedBoardProvider.overrideWithValue({
              IssueStatus.backlog: [a, b, c],
              IssueStatus.doing: [d],
              IssueStatus.review: const [],
              IssueStatus.done: const [],
            }),
            activeSprintProvider.overrideWithValue(null),
            boardActionsProvider.overrideWith((ref) => actions),
            sprintActionsProvider.overrideWith((ref) => _FakeSprintActions()),
          ],
          child: nxTestApp(home: const BoardScreen(spaceId: 's1')),
        ),
      );
      await tester.pumpAndSettle();
    }

    Future<void> focusCard(WidgetTester tester, String title) async {
      Focus.of(tester.element(find.text(title))).requestFocus();
      await tester.pump();
    }

    testWidgets('머리 줄 제목은 「이슈」다 — 앱 전체가 이 자리를 「이슈」로 부른다', (
      tester,
    ) async {
      await pump(tester);
      expect(find.text('이슈'), findsOneWidget);
      expect(find.text('보드'), findsNothing);
    });

    testWidgets('★ 키보드 — Space 로 집고 → 로 옆 컬럼, Space 로 놓으면 그 이웃으로 보낸다', (
      tester,
    ) async {
      await pump(tester);
      await focusCard(tester, '이슈 a');

      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();
      expect(find.byKey(const ValueKey('board-drop-spot')), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();

      expect(actions.calls, hasLength(1));
      final call = actions.calls.single;
      expect(call.issue.id, 'a');
      expect(call.status, IssueStatus.doing);
      // 진행 컬럼 [d] 의 1번 앞 = d 뒤.
      expect(call.after?.id, 'd');
      expect(call.before, isNull);
      expect(find.byKey(const ValueKey('board-drop-spot')), findsNothing);
    });

    testWidgets('Esc 는 취소 · 제자리에 놓으면 서버를 부르지 않는다', (tester) async {
      await pump(tester);
      await focusCard(tester, '이슈 b');

      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();
      expect(find.byKey(const ValueKey('board-drop-spot')), findsNothing);

      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();
      expect(actions.calls, isEmpty);
    });

    testWidgets('★ 같은 컬럼 위쪽으로 끄는 동안 끄는 카드만 흐리다 - 옆 카드가 흐려졌었다', (tester) async {
      await pump(tester);

      final from = tester.getCenter(find.text('이슈 c'));
      final to = tester.getTopLeft(find.text('이슈 a')) + const Offset(10, 2);
      final gesture = await tester.startGesture(from);
      await gesture.moveBy(const Offset(0, -20));
      await tester.pump();
      await gesture.moveTo(to);
      await tester.pump();
      await gesture.moveTo(to + const Offset(1, 0));
      await tester.pump();

      bool faded(String title) => find
          .ancestor(
            of: find.text(title),
            matching: find.byWidgetPredicate((w) => w is Opacity && w.opacity < 1),
          )
          .evaluate()
          .isNotEmpty;
      // 손에 든 카드(피드백)가 아니라 목록 안의 카드만 본다.
      expect(faded('이슈 a'), isFalse);
      expect(faded('이슈 b'), isFalse);

      await gesture.up();
      await tester.pumpAndSettle();
      expect(actions.calls.single.before?.id, 'a');
    }, variant: TargetPlatformVariant.only(TargetPlatform.windows));

    testWidgets('★ 마우스로 끌어 다른 컬럼 카드 위에 놓으면 그 앞으로 간다', (tester) async {
      await pump(tester);

      final from = tester.getCenter(find.text('이슈 c'));
      // d 카드의 윗부분 — 가운데보다 위라 d 앞에 놓인다.
      final to = tester.getTopLeft(find.text('이슈 d')) + const Offset(10, 2);

      final gesture = await tester.startGesture(from);
      await gesture.moveBy(const Offset(20, 0));
      await tester.pump();
      await gesture.moveTo(to);
      await tester.pump();
      await gesture.moveTo(to + const Offset(1, 0));
      await tester.pump();
      expect(find.byKey(const ValueKey('board-drop-spot')), findsOneWidget);

      await gesture.up();
      await tester.pumpAndSettle();

      expect(actions.calls, hasLength(1));
      final call = actions.calls.single;
      expect(call.issue.id, 'c');
      expect(call.status, IssueStatus.doing);
      expect(call.after, isNull);
      expect(call.before?.id, 'd');
    }, variant: TargetPlatformVariant.only(TargetPlatform.windows));
  });
}

typedef _Call = ({Issue issue, IssueStatus status, Issue? after, Issue? before});

class _FakeBoardActions implements BoardActions {
  final calls = <_Call>[];

  @override
  Future<bool> place(
    Issue issue,
    IssueStatus status, {
    Issue? after,
    Issue? before,
  }) async {
    calls.add((issue: issue, status: status, after: after, before: before));
    return true;
  }

  @override
  Future<bool> refresh() async => true;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeSprintActions implements SprintActions {
  @override
  Future<bool> refresh() async => true;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
