import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_app/core/settable.dart';
import 'package:nexus_app/domain/models/issue.dart';
import 'package:nexus_app/domain/models/space_member.dart';
import 'package:nexus_app/domain/models/sprint.dart';
import 'package:nexus_app/features/issue/board_controller.dart';
import 'package:nexus_app/features/issue/issue_card.dart';
import 'package:nexus_app/features/issue/new_issue_sheet.dart';
import 'package:nexus_app/features/issue/priority_mark.dart';
import 'package:nexus_app/features/issue/sprint_controller.dart';
import 'package:nexus_app/features/space/members_controller.dart';
import 'package:nexus_app/shared/widgets/user_avatar.dart';
import 'package:nexus_app/ui/ui.dart';

import 'support/nx_host.dart';

/// 이슈 보드 UI 리뷰에서 나온 것들 — 우선순위를 색이 아닌 모양으로 · 카드의 담당자 ·
/// 새 이슈 패널의 「상태」 이름표와 담당자 · 스프린트 고르기.
void main() {
  Issue issue({
    IssuePriority priority = IssuePriority.mid,
    IssueAuthor? assignee,
  }) => Issue(
    id: 'i1',
    key: 'NEXUS-1',
    title: '로그인 화면 다듬기',
    status: IssueStatus.review,
    priority: priority,
    assignee: assignee,
    position: '0',
    createdAt: DateTime.utc(2026, 10, 10),
    updatedAt: DateTime.utc(2026, 10, 10),
  );

  Future<void> pumpCard(WidgetTester tester, Issue value) async {
    await tester.pumpWidget(
      ProviderScope(
        child: nxTestApp(
          home: NxPage(
            body: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(width: 280, child: IssueCard(issue: value)),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// 막대 셋의 색을 왼쪽부터.
  List<Color?> barColors(WidgetTester tester, IssuePriority p) => tester
      .widgetList<Container>(
        find.descendant(
          of: find.byKey(ValueKey('priority-bars-${p.name}')),
          matching: find.byType(Container),
        ),
      )
      .map((c) => (c.decoration as BoxDecoration?)?.color)
      .toList();

  NxColors colorsOf(WidgetTester tester) =>
      NxTheme.of(tester.element(find.byType(IssueCard))).colors;

  group('우선순위 표시', () {
    test('채운 막대 수가 높낮이를 말한다', () {
      expect(issuePriorityLevel(IssuePriority.low), 1);
      expect(issuePriorityLevel(IssuePriority.mid), 2);
      expect(issuePriorityLevel(IssuePriority.high), 3);
    });

    testWidgets('★ 보통은 두 칸을 보조 글자색으로 — 컬럼 상태색(노랑 · 초록)을 쓰지 않는다', (
      tester,
    ) async {
      await pumpCard(tester, issue());
      final c = colorsOf(tester);

      expect(barColors(tester, IssuePriority.mid), [
        c.textSecondary,
        c.textSecondary,
        c.borderStrong,
      ]);
      // 색만으로 말하지 않는다 — 글자가 함께 있다.
      expect(find.text('보통'), findsOneWidget);
    });

    testWidgets('낮음은 한 칸 · 초록이 아니다(「끝났다」로 읽혔다)', (tester) async {
      await pumpCard(tester, issue(priority: IssuePriority.low));
      final c = colorsOf(tester);

      final bars = barColors(tester, IssuePriority.low);
      expect(bars, [c.textSecondary, c.borderStrong, c.borderStrong]);
      expect(bars, isNot(contains(c.success)));
      expect(find.text('낮음'), findsOneWidget);
    });

    testWidgets('높음만 위험색 — 세 칸 다', (tester) async {
      await pumpCard(tester, issue(priority: IssuePriority.high));
      final c = colorsOf(tester);

      expect(barColors(tester, IssuePriority.high), [
        c.danger,
        c.danger,
        c.danger,
      ]);
      final label = tester.widget<Text>(find.text('높음'));
      expect(label.style?.color, c.danger);
    });
  });

  group('카드의 담당자', () {
    testWidgets('★ 담당자가 있으면 카드 오른쪽 아래에 아바타가 있다', (tester) async {
      await pumpCard(
        tester,
        issue(
          assignee: const IssueAuthor(id: 'u1', name: '김하나'),
        ),
      );

      final avatar = find.byType(UserAvatar);
      expect(avatar, findsOneWidget);
      expect(tester.widget<UserAvatar>(avatar).userId, 'u1');

      final card = tester.getRect(find.byType(IssueCard));
      final rect = tester.getRect(avatar);
      final title = tester.getRect(find.text('로그인 화면 다듬기'));
      expect(rect.center.dx, greaterThan(card.center.dx));
      expect(rect.top, greaterThan(title.bottom));
    });

    testWidgets('담당자가 없으면 아바타 자리도 없다', (tester) async {
      await pumpCard(tester, issue());
      expect(find.byType(UserAvatar), findsNothing);
    });
  });

  group('새 이슈 패널', () {
    late _FakeBoardActions actions;

    const members = [
      SpaceMemberProfile(userId: 'u1', name: '김하나'),
      SpaceMemberProfile(userId: 'u2', name: '이둘', nickname: '둘'),
    ];
    const sprints = [
      Sprint(id: 'sp-active', name: '1주차', state: SprintState.active),
      Sprint(id: 'sp-planned', name: '2주차', state: SprintState.planned),
      Sprint(id: 'sp-closed', name: '0주차', state: SprintState.closed),
    ];

    Future<void> open(
      WidgetTester tester, {
      bool sprintsOn = true,
      BoardScope scope = BoardScope.all,
    }) async {
      actions = _FakeBoardActions();
      tester.view.physicalSize = const Size(1400, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            boardActionsProvider.overrideWith((ref) => actions),
            spaceMembersProvider.overrideWith((ref) async => members),
            sprintListProvider.overrideWith((ref) => Stream.value(sprints)),
            sprintsEnabledProvider.overrideWithValue(sprintsOn),
            // 보드의 보기 상태 — 패널이 그것을 보고 스프린트를 고른다.
            boardScopeProvider.overrideWith(() => SettableNotifier(scope)),
          ],
          child: nxTestApp(
            home: Builder(
              builder: (context) => NxPage(
                body: Center(
                  child: NxButton(
                    label: '열기',
                    onPressed: () => showNewIssueSheet(context),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('열기'));
      await tester.pumpAndSettle();
    }

    testWidgets('★ 이름표는 「상태」다 — 「컬럼」이 아니다', (tester) async {
      await open(tester);
      expect(find.text('상태'), findsOneWidget);
      expect(find.text('컬럼'), findsNothing);
    });

    testWidgets('★ 담당자는 기본 없음 · 멤버 중에서 고르면 그 id 로 만든다', (tester) async {
      await open(tester);
      expect(find.text('담당자'), findsOneWidget);

      await tester.tap(find.text('없음'));
      await tester.pumpAndSettle();
      // 별명이 있으면 별명으로 부른다(스페이스에서 부르는 이름).
      expect(find.text('김하나'), findsOneWidget);
      expect(find.text('둘'), findsOneWidget);
      await tester.tap(find.text('둘'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(EditableText).first, '새 일');
      await tester.pump();
      await tester.tap(find.text('만들기'));
      await tester.pumpAndSettle();

      expect(actions.created, hasLength(1));
      expect(actions.created.single.title, '새 일');
      expect(actions.created.single.assigneeId, 'u2');
      expect(actions.created.single.sprintId, isNull);
    });

    testWidgets('담당자를 고르지 않으면 보내지 않는다', (tester) async {
      await open(tester);
      await tester.enterText(find.byType(EditableText).first, '새 일');
      await tester.pump();
      await tester.tap(find.text('만들기'));
      await tester.pumpAndSettle();

      expect(actions.created.single.assigneeId, isNull);
    });

    testWidgets('★ 스프린트는 닫힌 것을 빼고 고를 수 있고, 고른 id 로 만든다', (tester) async {
      await open(tester);

      await tester.tap(find.text('백로그 (스프린트 없음)'));
      await tester.pumpAndSettle();
      expect(find.text('1주차 · 진행 중'), findsOneWidget);
      expect(find.text('2주차 · 계획'), findsOneWidget);
      expect(find.textContaining('0주차'), findsNothing);
      await tester.tap(find.text('2주차 · 계획'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(EditableText).first, '새 일');
      await tester.pump();
      await tester.tap(find.text('만들기'));
      await tester.pumpAndSettle();

      expect(actions.created.single.sprintId, 'sp-planned');
    });

    testWidgets('★ 보드가 「이번 스프린트」를 보고 있으면 그 스프린트로 시작한다', (tester) async {
      // 비워 두면 방금 만든 이슈가 지금 보이는 보드에서 빠진다.
      await open(tester, scope: BoardScope.activeSprint);
      expect(find.text('1주차 · 진행 중'), findsOneWidget);

      await tester.enterText(find.byType(EditableText).first, '새 일');
      await tester.pump();
      await tester.tap(find.text('만들기'));
      await tester.pumpAndSettle();

      expect(actions.created.single.sprintId, 'sp-active');
    });

    testWidgets('스프린트를 끈 스페이스는 스프린트 칸을 감추고 보내지도 않는다', (tester) async {
      await open(tester, sprintsOn: false, scope: BoardScope.activeSprint);
      expect(find.text('스프린트'), findsNothing);
      expect(find.text('백로그 (스프린트 없음)'), findsNothing);

      await tester.enterText(find.byType(EditableText).first, '새 일');
      await tester.pump();
      await tester.tap(find.text('만들기'));
      await tester.pumpAndSettle();

      expect(actions.created.single.sprintId, isNull);
    });
  });
}

typedef _Created = ({String title, String? assigneeId, String? sprintId});

class _FakeBoardActions implements BoardActions {
  final created = <_Created>[];

  @override
  Future<bool> create({
    required String title,
    String? description,
    IssueStatus? status,
    IssuePriority? priority,
    String? assigneeId,
    String? sprintId,
    String? originMessageId,
  }) async {
    created.add((title: title, assigneeId: assigneeId, sprintId: sprintId));
    return true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
