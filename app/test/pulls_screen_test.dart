import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_app/domain/models/pull.dart';
import 'package:nexus_app/features/repo/pull_detail_screen.dart';

/// `repos_screen_test.dart` 와 같은 방식이다 — **override 목록이 아니라 적재
/// 함수를 받는다.** Riverpod 3 은 `Override` 를 export 하지 않아 목록에 타입을
/// 붙일 수 없다.
Widget harness(Future<PullView> Function() load) {
  return ProviderScope(
    overrides: [pullDetailProvider.overrideWith((ref, key) => load())],
    child: const MaterialApp(
      home: PullDetailScreen(spaceId: 'space-1', repoId: 'repo-1', number: 12),
    ),
  );
}

PullView view({
  PullState state = PullState.open,
  PullReviewState? review,
  int? additions,
  List<PullChangedFile> files = const [],
  bool truncated = false,
}) {
  return (
    pull: PullDetail(
      number: 12,
      title: '멘션을 파서 안으로 넣는다',
      state: state,
      review: review,
      additions: additions,
      deletions: additions == null ? null : 3,
      changedFiles: additions == null ? null : 1,
      sourceBranch: 'feat/x',
      targetBranch: 'main',
    ),
    files: files,
    truncated: truncated,
  );
}

void main() {
  testWidgets('리뷰가 null 이면 리뷰 칸을 그리지 않는다', (tester) async {
    await tester.pumpWidget(harness(() async => view()));
    await tester.pumpAndSettle();

    // 혼자 쓰는 저장소에서는 늘 비는 값이다. 빈 칸은 잡음이다.
    expect(find.text('리뷰'), findsNothing);
  });

  testWidgets('승인되면 리뷰 칸이 생긴다', (tester) async {
    await tester.pumpWidget(
      harness(() async => view(review: PullReviewState.approved)),
    );
    await tester.pumpAndSettle();

    expect(find.text('승인됨'), findsOneWidget);
  });

  testWidgets('변경량이 null 이면 그리지 않는다 — 0 으로 보이면 안 된다', (tester) async {
    await tester.pumpWidget(harness(() async => view()));
    await tester.pumpAndSettle();

    expect(find.textContaining('+'), findsNothing);
  });

  testWidgets('변경량을 알면 그린다', (tester) async {
    await tester.pumpWidget(harness(() async => view(additions: 12)));
    await tester.pumpAndSettle();

    expect(find.textContaining('+12'), findsOneWidget);
  });

  testWidgets('머지된 PR 은 머지됨 칩이 뜬다', (tester) async {
    await tester.pumpWidget(harness(() async => view(state: PullState.merged)));
    await tester.pumpAndSettle();

    expect(find.text('머지됨'), findsOneWidget);
    expect(find.text('닫힘'), findsNothing);
  });

  testWidgets('지워진 파일은 누를 수 없다', (tester) async {
    await tester.pumpWidget(harness(() async => view(files: const [
          PullChangedFile(path: 'gone.dart', status: 'removed'),
          PullChangedFile(path: 'live.dart', status: 'modified'),
        ])));
    await tester.pumpAndSettle();

    // 그 커밋 시점에 없어 열어도 404 다.
    final gone = tester.widget<ListTile>(
      find.ancestor(of: find.text('gone.dart'), matching: find.byType(ListTile)),
    );
    expect(gone.onTap, isNull);

    final live = tester.widget<ListTile>(
      find.ancestor(of: find.text('live.dart'), matching: find.byType(ListTile)),
    );
    expect(live.onTap, isNotNull);
  });

  testWidgets('truncated 면 안내가 뜬다 — 조용히 자르지 않는다', (tester) async {
    await tester.pumpWidget(harness(() async => view(truncated: true)));
    await tester.pumpAndSettle();

    expect(find.textContaining('300개'), findsOneWidget);
  });
}
